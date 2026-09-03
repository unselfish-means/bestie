# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

Pre-implementation. No v1 addon code exists yet — what's in the repo so far is
[SPEC.md](SPEC.md) (the product spec) and a throwaway `spike/BestieSpike/` addon built to prove
out the spec's open technical unknowns before real development starts. Read SPEC.md first; it's
the source of truth for product decisions, requirements, and what's still undecided.

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

- **`spike/BestieSpike/`** — throwaway addon proving out SPEC.md's technical unknowns (BattleTag
  whisper delivery + achievement links). See [spike/README.md](spike/README.md) for install and
  test steps. Requires two Battle.net-friended accounts to actually test. Not meant to be kept
  once the spike concludes.
- The real v1 addon doesn't exist yet. Once it does, update this file with: its folder layout,
  the `.toc` file's `## Interface` version (must be bumped each WoW patch to avoid an "out of
  date" warning), its `SavedVariables` schema (besties list + relationship state — see SPEC.md's
  Requirements), and any vendored library dependencies and how they're updated.
