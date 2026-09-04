# scripts

## build-addon.ps1

Builds a versioned copy of a WoW addon for local testing — no CurseForge involved (that's a
later, separate step once an addon here has actually been tested and is in use). Takes the
`## Version:` already in the addon's `.toc`, appends a build timestamp
(`<version>+<yyyyMMdd.HHmm>`), and stamps that into a staged copy so both the local install and
the zip are unambiguously versioned and always match each other.

```powershell
.\scripts\build-addon.ps1 -AddonPath spike\BestieSpike
```

By default this:
1. Copies the addon into `F:\Blizzard\World of Warcraft\_retail_\Interface\AddOns\<AddonName>`
   for your own local testing (overwriting whatever was there before).
2. Zips the same build into `dist\<AddonName>-<version>.zip` for you to send to whoever else is
   testing (e.g., over Discord) — they just unzip it into their own AddOns folder.

Options:
- `-AddonPath <path>` — which addon folder to build, relative to the repo root. Defaults to
  `spike\BestieSpike`; pass a different path once other addons exist in this repo.
- `-WowAddOnsDir <path>` — override the local WoW AddOns folder (defaults to the path above).
- `-OutDir <path>` — override where zips go (defaults to `dist`).
- `-SkipLocalInstall` — only produce the zip, don't touch the local AddOns folder.
- `-SkipZip` — only install locally, don't produce a zip.

The source `.toc` in the repo is never modified — the build stamp only exists in the staged copy
that gets installed/zipped.
