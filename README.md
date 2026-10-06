# Bestie

**Never miss your best friend's achievements again.** Bestie tells your Battle.net besties when you
earn an achievement, whatever character, guild, or realm either of you is playing.

Blizzard only announces achievements to your guild. If you and your friend are on alts in different
guilds, you never see each other's moments. Bestie fixes that with a Battle.net whisper:
*"<Name> earned [Achievement]"*, with a clickable achievement link, just like the guild
announcement.

## What it does

- **Achievements reach your besties.** When you earn any achievement, each of your besties who's
  online in WoW gets a whisper with a clickable link to it.
- **No double announcements.** If your bestie is in the same guild as you, Bestie stays quiet and
  lets Blizzard's own guild announcement do the job.
- **Both of you agree first.** Adding a bestie sends them a request, and they choose **Accept** or
  **Decline**. Nothing is sent to anyone who hasn't accepted. If they decline, you're told.
- **Mute without removing.** Need some quiet? Mute a bestie and their achievements stop reaching
  you until you unmute them.
- **Block unwanted requests.** Block a BattleTag and Bestie ignores any request from it.

## What you need

- You and your friend are already **Battle.net friends**. Bestie uses that friendship; it doesn't
  manage it.
- **Both of you have Bestie installed**, so you can accept each other's requests.
- **Retail** WoW.

## Commands

| Command | What it does |
|---|---|
| `/bestie add Name#1234` | Send a bestie request (they need to be online) |
| `/bestie remove Name#1234` | Remove a bestie, or cancel a request you sent |
| `/bestie mute Name#1234` | Stop notifications from a bestie |
| `/bestie unmute Name#1234` | Start them again |
| `/bestie block Name#1234` | Ignore future requests from a BattleTag |
| `/bestie unblock Name#1234` | Allow requests from it again |
| `/bestie list` | Show your besties and their status |

Incoming requests appear as a popup with **Accept** and **Decline**. A request waits until it's
answered, even across a `/reload` or logout.

## Good to know

- Your besties list is saved for your whole account, so it works on every character.
- Notifications only go to besties who are online in WoW at the time. Nothing is saved up for later.
- Every achievement is shared. There's no filter yet.
