# Bestie Spike

Throwaway addon to prove out (or disprove) the technical unknowns from
[../SPEC.md](../SPEC.md#technical-spike-do-this-before-building-anything-else) before real
development starts. Not meant to be kept, polished, or published — delete this folder once the
spike is done and its findings are folded back into SPEC.md.

## Install

**Both testers need it installed**, and need to already be Battle.net friends with each other —
this spike doesn't test befriending, only the addon-message-over-BattleTag mechanism itself.

**For yourself (local testing):** run the build script from the repo root — it stamps a build
version into a staged copy and installs it directly into your local AddOns folder:

    .\scripts\build-addon.ps1 -AddonPath spike\BestieSpike

**For your friend:** the same command also produces a versioned zip under `dist\` (e.g.
`dist\BestieSpike-0.1.0+20260903.1421.zip`) — send that over Discord. They unzip it directly into
their own `<WoW install>/_retail_/Interface/AddOns/` folder. See [../scripts/README.md](../scripts/README.md)
for the script's other options.

Each build prints its stamped version to chat on login (`Loaded version 0.1.0+...`), so when
comparing notes you can both confirm you're testing the same build.

The `.toc`'s `## Interface` line targets current Retail (`120100` as of writing). If the addon
doesn't appear in the AddOns list after a client patch, check "Load out of date AddOns" first,
then confirm your real interface version in-game with:

    /run print(select(4, GetBuildInfo()))

## Commands

- `/bspike friends` — lists your Battle.net friends with online status, presence ID
  (`bnetAccountID`), and — if they're currently in WoW — their character/realm/faction.
  Proves **unknown #1** (resolving a BattleTag to a sendable target).
- `/bspike online <BattleTag>` — checks one friend's online status in isolation.
  Proves **unknown #3** (presence check before sending).
- `/bspike send <BattleTag> <achievementID>` — sends `"<You> earned <Achievement Link>"` to that
  friend via `BNSendWhisper`, printing the payload length first.
  Proves **unknowns #2 and #4** (send/receive with a working achievement link, and payload size).
- `/bspike log` — reports how many whisper/achievement events have been captured this session.
  Run `/dump BestieSpikeDB.log` for the raw captured data.
- `/bspike clearlog` — clears the captured log.

Earning any real achievement while logged in also auto-prints its ID and link to chat — handy for
grabbing a real `achievementID` to test with instead of looking one up externally.

## Test procedure (needs both accounts online at once)

1. On each account, run `/bspike friends` and confirm the other account shows up with the
   expected BattleTag, `isOnline=true`, and a `bnetAccountID`. **(Unknown #1)**
2. On Account A, run `/bspike online <Account B's BattleTag>` and confirm it reports online.
   Log Account B out and repeat — confirm it now reports offline. **(Unknown #3)**
3. On Account A, run `/bspike send <Account B's BattleTag> <achievementID>` using any real
   achievement ID (grab one from the auto-printed `ACHIEVEMENT_EARNED` output, or look one up).
   On Account B, confirm:
   - `CHAT_MSG_BN_WHISPER` fires and its raw args get dumped to chat.
   - The message reads as `"<Name> earned <Achievement Link>"`, and the achievement portion
     renders as a clickable, colored link that opens the achievement's details when clicked —
     not raw `|H...|h` markup text. **(Unknown #2)**
4. Repeat step 3 with a long-named achievement and note the payload length `/bspike send` prints.
   Confirm the message arrives intact, not truncated or dropped. **(Unknown #4)**

## Exit criteria

All four steps above work end-to-end between two real accounts. If any step fails or behaves
unexpectedly — an error, a missing event, garbled link markup, a truncated or dropped message —
note exactly what happened. That's the input for reworking the relevant part of SPEC.md before
real development starts.
