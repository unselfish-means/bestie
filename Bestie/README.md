# Bestie

Broadcasts your achievements to your Battle.net besties via whisper, regardless of which guild
either of you is in. See [../SPEC.md](../SPEC.md) for the full spec.

## Install

**You (local testing):** run the build script from the repo root — it stamps a build version into
a staged copy, installs it into your local AddOns folder, and produces a zip:

    .\scripts\build-addon.ps1 -AddonPath Bestie

**Your bestie:** send them the zip from `dist\` (e.g. `dist\Bestie-0.1.0+<timestamp>.zip`) over
Discord. They unzip it directly into their own `<WoW install>/_retail_/Interface/AddOns/` folder —
the zip already contains a `Bestie` folder, so they should end up with
`Interface/AddOns/Bestie/Bestie.toc`, not a nested `Bestie/Bestie/...`.

You both need to already be Battle.net friends with each other for any of this to work — Bestie
rides on top of that, it doesn't manage BNet friendships itself.

If the addon doesn't appear in the AddOns list after a client patch, check "Load out of date
AddOns" first, then confirm your interface version in-game with:

    /run print(select(4, GetBuildInfo()))

If anything misbehaves during testing, turn on Lua error popups so you can capture the actual
error text: `/console scriptErrors 1`, or the "Show Lua Errors" checkbox in the AddOns list.

## Commands

- `/bestie add Name#1234` — send a Bestie request (only works if they're currently online)
- `/bestie remove Name#1234` — tear down a pending or active relationship
- `/bestie mute Name#1234` / `/bestie unmute Name#1234` — silence/restore notifications from an
  active Bestie without removing them
- `/bestie block Name#1234` / `/bestie unblock Name#1234` — prevent/re-allow future requests from
  a BattleTag
- `/bestie list` — show your besties and their status

Accepting/declining an incoming request happens via the popup that appears automatically, not a
slash command.

## Test plan

### Part 1 — on your own, whenever (Bestie not installed on the other side yet, or they're offline)

These don't need your bestie online — they check that the addon loaded and that its local,
no-network paths behave.

1. Run `/bestie` with no arguments — confirms the addon loaded and the slash command works. You
   should see the command list printed.
2. Run `/bestie list` — with nobody added yet, it should say "No besties yet."
3. Run `/bestie remove Someone#0000` (a BattleTag you've never added) — should say they're not on
   your list. Confirms it doesn't error on an unknown tag.
4. Run `/bestie mute Someone#0000` — should say they're not an active Bestie, for the same reason.
5. Run `/bestie block Test#1111` then `/bestie unblock Test#1111` — pure local state, should just
   print "blocked" then "unblocked." No BattleTag needs to be real for this one.
6. **Only while your bestie is confirmed offline:** run `/bestie add <TheirTag>`. It should tell
   you they're not online rather than silently doing nothing. This is the one case in this section
   that depends on their status, so do it before they log in.

### Part 2 — together, both of you online at once

This is the real end-to-end test. Do these roughly in order since some depend on earlier ones.

1. **Confirm both loaded the same build.** Run `/bestie` on both sides — if either errors instead
   of printing the command list, stop and capture the Lua error before continuing.
2. **Send + accept a request.** One of you runs `/bestie add <TheirTag>`. The other should see a
   popup: "Name#1234 wants to be Besties" with Accept/Decline. Click **Accept**. The sender should
   see a chat line saying the request was accepted; both sides should now show `Active` in
   `/bestie list`.
3. **Achievement notification, different guilds (the main feature).** With neither of you muted,
   have one of you earn any achievement (pick something easy/near-complete you haven't gotten yet
   — a zone exploration achievement is usually the quickest to trigger on demand). The other should
   receive a whisper reading `"<Name> earned <Achievement>"` with a clickable, colored achievement
   link — not raw text. Confirm it renders and clicking it opens the achievement.
4. **Mute suppresses notifications.** Run `/bestie mute <TheirTag>`. Have them earn another
   achievement — you should get nothing this time. Run `/bestie unmute <TheirTag>` and confirm a
   subsequent achievement does notify again.
5. **Same-guild suppression (optional, needs you both in one guild).** If you can get into the
   same guild for a few minutes, earn an achievement there — you should each see Blizzard's own
   guild announcement, but *not* also get a Bestie whisper for it. Skip this one if getting into
   the same guild isn't convenient; it's the one part of the spec that's hardest to test in
   isolation.
6. **Decline a request.** Remove each other (`/bestie remove <TheirTag>` on both sides, so you're
   back to a clean slate), then have one of you send a new request and the other click **Decline**.
   The sender should see a chat line saying the request was declined.
7. **Remove syncs both directions.** Re-add and accept each other to get back to `Active`, then
   have one of you run `/bestie remove <TheirTag>`. Both sides' `/bestie list` should now show
   nobody (removed entries don't show up in the list) — confirming the removal reaches the other
   side too, not just your own.
8. **Unanswered request survives a reload.** Have one of you send a request and have the other
   *not* respond to the popup — instead run `/reload`. The popup should reappear after the UI
   reloads. (This part can be done solo once the request has been sent — the sender doesn't need
   to stay online for it.)

### Exit criteria

All of Part 2 works as described, with no Lua errors along the way. If something behaves
unexpectedly, note exactly what happened (what you ran, what you expected, what you saw, and any
Lua error text) so it can be fixed before this goes to CurseForge.
