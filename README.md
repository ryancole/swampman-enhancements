# Quest Accept

WoW Forever (1.60.1, Interface 16001) addon that accepts quests and turns
them in for you. Talk to an NPC and the addon takes the clicks: finished
quests are handed in first, then new ones are picked up. A quest whose
reward you have to choose is left open on the reward page, so you pick
the item and turn it in yourself.

## Files

- `QuestAccept.toc` — addon manifest (must stay at the repo root — WoW
  looks for it at the top of the addon folder)
- `src/Core.lua` — SavedVariables, the quest event handlers, slash commands
- `assets/` — `logo.png` is the project art; `logo.tga` (addon list icon)
  is baked from it by `etc/logo.py` (Python + Pillow)
- `etc/check.ps1` — local lint (luacheck and a LuaJIT parse over `src`)

## How it works

The client walks a quest NPC conversation through a chain of events, and
the addon takes the one step at each that a click in the default quest
frame would:

- `GOSSIP_SHOW` / `QUEST_GREETING` — the NPC's list of quests. A finished
  quest is selected if there is one, otherwise the first available quest.
  NPCs with a gossip menu list their quests through `C_GossipInfo`; plain
  quest givers use the older greeting API. Only one quest is picked per
  list, since selecting it makes the server send the next page; when
  that page closes the list comes back and the next quest is handled.
- `QUEST_DETAIL` — the offer page: the quest is accepted. A quest the
  server already dropped into the log is acknowledged instead, the way
  the default Accept button does it. Quests that would flag you for PvP
  are left for a deliberate click.
- `QUEST_PROGRESS` — the "are you done yet" page: continues only when the
  objectives are met, otherwise the page stays up as it would by hand.
- `QUEST_COMPLETE` — the reward page. With no reward choice the quest is
  turned in; a single offered item isn't a choice either, so that is
  taken too. Two or more choices are left for you to pick and click
  Complete Quest.

Holding Shift while talking to an NPC pauses all of this, so a quest can
be read, declined, or handed in by hand without turning the addon off.

## Developing

WoW loads an addon from a folder whose name matches the `.toc`, so link this
repo into your AddOns directory as `QuestAccept` (PowerShell, adjust the
game path):

```powershell
New-Item -ItemType Junction `
  -Path "C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\QuestAccept" `
  -Target "C:\Users\Ryan\source\repos\quest-accept"
```

`/reload` in-game picks up Lua changes; a full restart is only needed for
`.toc` changes.

`.\etc\check.ps1` runs luacheck and a LuaJIT parse over `src`; CI runs the
same luacheck on every push.

## Releasing

Releases are built by the [BigWigs packager](https://github.com/BigWigsMods/packager)
via GitHub Actions (`.github/workflows/release.yml`). Pushing a tag like
`v0.1.0` packages the addon (with `@project-version@` in the .toc replaced
by the tag) and publishes it as a GitHub release. To upload to CurseForge
as well, add a `## X-Curse-Project-ID` line to the .toc and a `CF_API_KEY`
repo secret.

```bash
git tag v0.1.0 && git push origin master --tags
```

## Commands

- `/qa` (or `/questaccept`) — show what's on
- `/qa on` / `/qa off` / `/qa toggle` — the whole addon
- `/qa accept [on|off]` — picking up quests (toggles with no argument)
- `/qa turnin [on|off]` — handing in quests (toggles with no argument)

Settings are account-wide and saved between sessions.
