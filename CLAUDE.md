# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

[README.md](README.md) is the player-facing description, and it's also the description to paste into
CurseForge. Keep development notes out of it. Building, installing, and the in-game test plan are in
[TESTING.md](TESTING.md); product decisions are in [SPEC.md](SPEC.md).

## GitHub account

The GitHub account and commit setup are in `CLAUDE.local.md` at the repo root (in a worktree, look in
the main checkout's root). It isn't committed. Read it before any commit, push, or `gh` command.

## Project status

v1 is implemented in `Bestie/` — all P0 requirements from SPEC.md (besties list with
handshake/mute/block, same-guild-aware notifications). Untested in-game and not yet packaged for
CurseForge. `spike/BestieSpike/` is the throwaway addon that proved out the spec's technical
unknowns before v1 development started; it's no longer load-bearing but is left in the repo for ad
hoc testing. Read SPEC.md first; it's the source of truth for product decisions, requirements, and
what's still undecided.

## Purpose

Bestie broadcasts achievement notifications to specific players, not just guild/party/raid chat.
The motivating scenario: two players play together but often end up on alts in different guilds
(e.g. a guild with a member cap). Standard achievement broadcasts (guild chat, social) don't
reach each other in that case — Bestie lets them keep celebrating each other's achievements
regardless of which character or guild either of them is on, while explicitly not duplicating
Blizzard's own announcement on the rare occasion they *are* in the same guild.

The delivery mechanism (see SPEC.md for full detail) is a **Battle.net (BattleTag) whisper**
carrying a plain, human-readable message that mirrors Blizzard's own guild achievement phrasing
and includes a clickable achievement link — not the addon-message API
(`C_ChatInfo.SendAddonMessage`), which only works within a shared channel/party/guild and
therefore can't cross guild boundaries. This is still unproven in practice; that's what the spike
addon exists to test.

## Working in this repo

There's no build/lint/test tooling — WoW addons have no build step. To load an addon in-game,
symlink or copy its folder into `_retail_/Interface/AddOns/`, then `/reload` in-game to pick up
changes.

- **`Bestie/`** — the real v1 addon. Build/install locally with
  `.\scripts\build-addon.ps1 -AddonPath Bestie` (see [scripts/README.md](scripts/README.md)).
  Requires two Battle.net-friended accounts to test end-to-end, same as the spike; the steps are in
  [TESTING.md](TESTING.md).
  - `.toc` `## Interface` is `120100` (current Retail as of writing) — bump it each WoW patch or
    the addon shows an "out of date" warning.
  - `SavedVariables: BestieDB` — account-wide, `{ besties = { [battleTagLower] = { battleTag,
    status, muted, lastKnownGuild } }, blocked = { [battleTagLower] = true } }`. `status` is one of
    `PendingOutgoing` / `PendingIncoming` / `Active` / `Removed` (a soft tombstone, not a deleted
    entry — see SPEC.md's handshake-abuse-boundary requirement). Blocking is tracked separately
    from relationship status so it survives independent of any existing entry.
  - No vendored libraries — five plain Lua files, no build step, no third-party deps.
  - File layout: `Bestie.lua` (namespace bootstrap, SavedVariables init, BNet friend lookups),
    `Protocol.lua` (the BNSendWhisper-based handshake/guild-sync wire format — internal traffic is
    marked with a control-character prefix and filtered out of chat via
    `ChatFrame_AddMessageEventFilter`, while un-marked whispers, i.e. achievement notifications,
    pass through untouched), `Besties.lua` (relationship state machine + protocol handlers),
    `Notify.lua` (`ACHIEVEMENT_EARNED` handling + the guild-sync broadcast that implements
    SPEC.md's same-guild detection), `Popups.lua` (the incoming-request StaticPopup), `Slash.lua`
    (`/bestie add|remove|mute|unmute|block|unblock|list`).
  - `.github/workflows/release.yml` is the shared WIKR workflow (the `curseforge-packaging`
    runbook in `wow-addons-skill`; don't edit it here). On every pushed tag it packages with the
    BigWigs packager, following the root [.pkgmeta](.pkgmeta), and uploads to CurseForge. A tag
    containing `alpha`/`beta` uploads as that type. It needs the `CURSEFORGE_API_TOKEN` repository
    **Actions** secret and a `## X-Curse-Project-ID:` line in `Bestie.toc`. The ID is still TODO,
    so the workflow fails on purpose until the CurseForge project exists.
  - To release, push an annotated tag named for the `.toc` version:
    `git tag -m "Bestie <ver>" <ver>` then `git push origin refs/tags/<ver>`. A lightweight tag,
    or one created by `gh release create`, may not start the workflow.
- **`spike/BestieSpike/`** — throwaway addon that proved out SPEC.md's technical unknowns (BattleTag
  whisper delivery + achievement links) before `Bestie/` was built. See
  [spike/README.md](spike/README.md). No longer load-bearing; kept around for ad hoc testing and
  can be deleted whenever it's not wanted.
