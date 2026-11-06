<#
.SYNOPSIS
    Builds a versioned test copy of a WoW addon: installs it into the local WoW AddOns folder,
    and/or zips it for sharing. Test builds are named <Addon>-Test (folder, .toc, and title), so
    they can sit beside a CurseForge install of the release. Enable one at a time in-game.

.EXAMPLE
    .\scripts\build-addon.ps1 -AddonPath spike\BestieSpike

.EXAMPLE
    .\scripts\build-addon.ps1 -AddonPath spike\BestieSpike -SkipZip
#>
[CmdletBinding()]
param(
    [string]$AddonPath = "spike\BestieSpike",
    [string]$WowAddOnsDir = "F:\Blizzard\World of Warcraft\_retail_\Interface\AddOns",
    [string]$OutDir = "dist",
    [switch]$SkipLocalInstall,
    [switch]$SkipZip
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = Join-Path $repoRoot $AddonPath
if (-not (Test-Path $sourceDir)) {
    throw "Addon path not found: $sourceDir"
}

$addonName = Split-Path -Leaf $sourceDir
$tocPath = Join-Path $sourceDir "$addonName.toc"
if (-not (Test-Path $tocPath)) {
    throw "No .toc file found at $tocPath (expected to match the folder name)"
}

$tocText = Get-Content $tocPath -Raw
if ($tocText -notmatch '(?m)^## Version:\s*(.+)$') {
    throw "Could not find a '## Version:' line in $tocPath"
}
$baseVersion = $Matches[1].Trim()
$buildStamp = Get-Date -Format "yyyyMMdd.HHmm"
$buildVersion = "$baseVersion+$buildStamp"

# Stage a copy so the build-stamped version never touches the source .toc in the repo.
$stageRoot = Join-Path ([System.IO.Path]::GetTempPath()) "bestie-addon-build"
$testName = "$addonName-Test"
$stageDir = Join-Path $stageRoot $testName
if (Test-Path $stageRoot) { Remove-Item $stageRoot -Recurse -Force }
New-Item -ItemType Directory -Path $stageDir -Force | Out-Null
Copy-Item (Join-Path $sourceDir "*") $stageDir -Recurse -Force

$stagedTocPath = Join-Path $stageDir "$testName.toc"
Move-Item (Join-Path $stageDir "$addonName.toc") $stagedTocPath
$stagedTocText = (Get-Content $stagedTocPath -Raw) -replace '(?m)^## Version:\s*.+$', "## Version: $buildVersion"
$stagedTocText = $stagedTocText -replace '(?m)^(## Title(?:-\w+)?:[ \t]*)(.+?)(\r?)$', '${1}${2}-Test${3}'
Set-Content -Path $stagedTocPath -Value $stagedTocText -NoNewline

Write-Host "Building $testName $buildVersion" -ForegroundColor Cyan

if (-not $SkipLocalInstall) {
    $installDir = Join-Path $WowAddOnsDir $testName
    # Wiping through a link would delete the link's target.
    $existing = Get-Item $installDir -ErrorAction SilentlyContinue
    if ($existing -and $existing.LinkType) { throw "$installDir is a link. Remove it, then build again." }
    if (Test-Path $installDir) { Remove-Item $installDir -Recurse -Force }
    Copy-Item $stageDir $installDir -Recurse -Force
    Write-Host "Installed to $installDir"
}

if (-not $SkipZip) {
    $outDirFull = Join-Path $repoRoot $OutDir
    New-Item -ItemType Directory -Path $outDirFull -Force | Out-Null
    $zipPath = Join-Path $outDirFull "$testName-$buildVersion.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Compress-Archive -Path $stageDir -DestinationPath $zipPath
    Write-Host "Zipped to $zipPath"
}

Remove-Item $stageRoot -Recurse -Force
