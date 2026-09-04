# Bestie — Spec

Status: Draft, pre-implementation
Scope: v1 (see Non-Goals for what's deliberately excluded)

## Problem Statement

The two players behind this addon play WoW together but often end up on alts in different guilds —
sometimes because their main guild has a member cap, sometimes just by choice. When one of them earns an
achievement, Blizzard's native notification only reaches guildmates, so the other misses it
entirely unless they happen to be told about it later, outside the game. The moment of "hey, look
what I just did" gets lost.

They're Battle.net (BattleTag) friends, which works regardless of which character, guild, realm,
or faction either of them is playing — making it the natural channel for a fix.

## Goals

- Either player sees the other's achievements in-game, in real time, regardless of guild — without
  duplicating Blizzard's own guild announcement when they happen to already be in the same guild.
- No personal data (BattleTags) ever enters source control.
- Setup and maintenance (adding/removing/muting/blocking each other) is fast enough to not be
  annoying.

## Non-Goals

- **Filtering which achievements notify** — v1 notifies on all achievements. A filter (points
  threshold, category allow-list) is a plausible v2 if all-achievements proves too noisy in
  practice, but it's not being designed for now.
- **Supporting more than a handful of besties** — the data model is a list, not a hardcoded pair,
  but this is not being built or tested as a broadcast/social feature for large friend groups.
- **Offline queueing/catch-up** — if a bestie is offline when an achievement fires, nothing is
  queued for later delivery. (The one exception: the whisper itself is still sent as a
  best-effort, human-readable message — see Requirements — but that's incidental, not a designed
  delivery guarantee.)
- **Client versions other than current Retail** — Classic Era / Classic progression clients are
  out of scope for now.
- **Cross-faction/cross-region edge cases beyond what BattleTag already handles** — riding on
  Battle.net whispers means these are inherited "for free" if they work at all; no additional
  engineering is planned to handle them specially.

## User Stories

- As a player, I want my bestie to see my achievements in real time, regardless of what guild
  either of us is in, so we can celebrate together in the moment.
- As a player, I want to add someone as a bestie by their BattleTag, so I don't have to hardcode
  or configure anything technical.
- As a player, I want to confirm/decline an incoming bestie request, so relationships require my
  consent rather than being one-sided.
- As a player, I want to know if my bestie request was declined, so I'm not left wondering whether
  it just never arrived.
- As a player, I want to block someone from sending me bestie requests, so I have a way to shut
  down unwanted requests for good.
- As a player, I want to mute a bestie temporarily without removing them, so I can silence
  notifications (e.g., during a stressful push) without losing the relationship.
- As a player, I want to manage my besties list via slash command, minimap icon, or options panel,
  so I can use whichever is convenient in the moment.

## Requirements

### Must-Have (P0)

**Bestie relationships**
- [ ] `/bestie add Name#1234` sends a bestie request to that BattleTag, if they're currently
      online. If they're not online, the command tells the user so instead of sending nothing and
      leaving them to wonder.
- [ ] The recipient sees a StaticPopup ("Name#1234 wants to be Besties") with Accept/Decline.
- [ ] Accepting activates the relationship bidirectionally in one step — no separate reciprocal
      `/bestie add` needed on the other side.
- [ ] Declining notifies the sender that their request was declined.
- [ ] Pending requests do not expire — they remain until accepted, declined, or canceled by the
      sender (via `/bestie remove`).
- [ ] `/bestie remove Name#1234` tears down an active or pending relationship.
- [ ] `/bestie mute Name#1234` / `/bestie unmute Name#1234` silences/restores notifications for an
      active relationship without removing it.
- [ ] `/bestie block Name#1234` / `/bestie unblock Name#1234` prevents/re-allows future bestie
      requests from that BattleTag.
- [ ] The besties list (and its state — pending/active/muted/blocked) is stored in account-wide
      `SavedVariables`, not per-character, and never in addon source.

**Achievement notifications**
- [ ] Notifications are only ever sent to a bestie with a completed (`Active`) handshake — never
      based on a known BattleTag alone, and never to a `Pending` or `Removed` entry. This is
      enforced deliberately, even though `BNSendWhisper` itself doesn't require any relationship
      to exist between sender and recipient — it's a boundary against one person spamming or
      pestering another through the addon, not a technical necessity.
- [ ] Before sending, the addon checks whether the bestie's currently active character is in the
      same guild as the achiever's; if so, no notification is sent — Blizzard's native guild
      achievement announcement already covers that case.
- [ ] Otherwise, on earning any achievement, the addon sends a Battle.net whisper to every
      `Active`, unmuted bestie who is currently online. The message mirrors Blizzard's own guild
      achievement phrasing and includes a clickable achievement link (see Open Design Decisions
      for exact format).
- [ ] No addon-side interception or reformatting happens on the receiving end — the whisper itself
      is the notification. (A custom popup/toast is a Future Consideration; see below.)

**Distribution**
- [ ] The addon is packaged and published to CurseForge (e.g., via the standard BigWigsMods
      packager GitHub Action) so it can be installed and updated without manually copying files.

### Nice-to-Have (P1)

- [ ] Optional sound effect on notification receipt (user-toggleable).
- [ ] "Add as Bestie" entry integrated into the Battle.net Friends UI (e.g., a right-click
      context-menu option on a friend), if Blizzard's UI exposes an extension point for it —
      falls back to slash-command-only if not feasible (see Open Questions).
- [ ] Minimap icon for quick access to the besties list / pending requests.
- [ ] Options panel (Blizzard Settings/Interface Options) showing: besties list with mute/block
      toggles and remove buttons, pending requests with accept/decline, add-by-BattleTag field,
      sound on/off toggle.

### Future Considerations (P2)

- Achievement filtering (points threshold, category allow-list).
- Custom popup/toast presentation instead of (or alongside) the plain chat whisper — would require
  intercepting/suppressing the raw chat line, which v1 deliberately avoids needing.
- "Send grats back" one-click reply from the notification.

## Technical Spike — Resolved

All four unknowns below were confirmed working end-to-end between two real, Battle.net-friended
accounts, using the throwaway `spike/BestieSpike/` addon (see [spike/README.md](spike/README.md)).
**Exit criteria met — no rework needed to the delivery model.** The spike addon is left in the
repo for now in case further ad hoc testing is useful during v1 development; it's not load-bearing
for anything and can be deleted whenever it's no longer wanted.

**What was tested, and what was found:**

1. **Resolve a BattleTag to a sendable target — confirmed.** `C_BattleNet.GetFriendAccountInfo(i)`
   is the correct modern API. One gotcha: its `accountName` field is a display name, not
   necessarily the literal BattleTag string — match against the separate `battleTag` field instead.
2. **Send + receive a whisper containing an achievement link — confirmed.** `GetAchievementLink()`
   output embeds correctly in `BNSendWhisper`, arrives via `CHAT_MSG_BN_WHISPER`, and renders as a
   clickable, functional achievement link on the receiving end (verified visually on both
   accounts) — same as a native guild announcement, not raw markup text.
3. **Presence check before sending — confirmed**, with a gotcha: online status is *not* a
   top-level field on the friend-info table — it's nested at `gameAccountInfo.isOnline`, and only
   reflects being online *in WoW specifically* (not Battle.net-online-in-general, e.g.
   mobile-app-only). Verified correct against both an online and an offline friend.
4. **Payload size — confirmed** via successful real sends; no truncation observed. Not stress-tested
   against a pathologically long achievement name, but not a concern worth blocking on.

Note: intercepting/suppressing the chat line was *not* part of this spike — v1 needs no
receive-side interception, since the whisper itself (formatted plainly, with a link) is the
notification. That becomes relevant only if the P2 custom-popup idea gets built later.

## Open Design Decisions

Direction is known; specifics aren't locked yet.

- **Payload format.** Mirror Blizzard's own guild achievement phrasing as closely as possible —
  `{Player} earned {Achievement Link}` — using `GetAchievementLink()` for the achievement portion.
  No addon branding/prefix unless the spike surfaces a concrete reason one's needed.
- **Same-guild detection mechanism.** Exactly how the sender determines whether the bestie's
  *currently active character* is in the sender's guild before deciding whether to send. Candidate
  approaches: comparing guild roster membership against a known bestie identity, or exchanging
  current-guild info as part of the relationship state. Needs investigation — no API has been
  confirmed for this yet.
- **Options panel layout.** Deferred until P1 work starts.

## Open Questions

- Does `BNSendWhisper` delivery have any rate limit or spam-throttle that could cause achievement
  bursts (e.g., a string of quest turn-ins) to drop messages? *(spike-dependent)*
- Does Blizzard's Battle.net Friends frame expose an addon-accessible UI extension point (e.g., a
  dropdown menu hook) to add a custom "Add as Bestie" option? *(feasibility unconfirmed — worth
  checking during P1 work, not blocking v1)*

## How We'll Know It Works

No formal metrics — this is a two-person addon. Success is simply: achievements show up for both
of you, reliably, without noise or false triggers, and managing the besties list stays a
non-event. If notifications turn out to be too frequent/noisy in practice, that's the signal to
revisit the achievement-filtering non-goal above.

## Phasing

1. ~~**Spike** — prove the whisper send/receive mechanism, including the achievement link.~~ Done.
2. **v1** — all P0 requirements: besties list with handshake/mute/block, same-guild-aware
   notifications, and CurseForge distribution.
3. **v1.1** — P1: sound toggle, Battle.net Friends UI integration, minimap icon, options panel.
