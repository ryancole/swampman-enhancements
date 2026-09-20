# Swampman Enhancements

WoW Forever (1.60.1, Interface 16001) addon with a few quality-of-life
tweaks:

- **Quest automation** — talk to an NPC and the addon takes the clicks:
  finished quests are handed in first, then new ones are picked up. A
  quest whose reward you have to choose is left open on the reward page,
  so you pick the item and turn it in yourself.
- **In-game navigation pin** — the floating marker the client can draw in
  the world over your tracked quest objective, with the distance to it.
  WoW Forever ships the feature but removes its checkbox from the settings
  menu; the addon puts the option back.
- **Max camera distance** — a slider for `cameraDistanceMaxZoomFactor`
  that goes past the 2.0 the game's own Controls settings stop at, with a
  box to type an exact value.
- **Always sharpen** — a checkbox for `ResampleAlwaysSharpen`, which
  applies the Resample Sharpness filter even at 100% render scale and has
  no entry in the settings menu.
- **Cast animation on action buttons** — the fill that sweeps over an
  icon while its spell is cast or channelled has no setting at all; the
  addon can hide it.
- **Totem bar alignment** — the shaman totem bar's buttons fill its box
  from the left, leaving a gap on the right until all four totem
  elements are known; the addon can lay them out from the right edge
  instead.

## Files

- `SwampmanEnhancements.toc` — addon manifest (must stay at the repo
  root — WoW looks for it at the top of the addon folder)
- `src/Core.lua` — SavedVariables, the quest event handlers, slash commands
- `src/CVars.lua` — the on/off CVar toggles (navigation pin, always
  sharpen): what each is, and applying the options to the client
- `src/Camera.lua` — max camera distance: reads, sets, and reapplies the
  CVar, and probes the client's limit for it
- `src/ActionBars.lua` — hooks the action buttons' cast animation so it
  can be hidden
- `src/TotemBar.lua` — re-anchors the shaman totem bar's buttons to its
  right edge
- `src/Options.lua` — settings panel (Options -> AddOns -> Swampman Enhancements)
- `assets/` — `logo.png` is the project art; `logo.tga` (addon list icon)
  is baked from it by `etc/logo.py` (Python + Pillow)
- `etc/check.ps1` — local lint (luacheck and a LuaJIT parse over `src`)

## How it works

### Quest automation

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
- `QUEST_ACCEPT_CONFIRM` — a party member started an escort quest and the
  client asks whether to join: confirmed.
- `QUEST_PROGRESS` — the "are you done yet" page: continues only when the
  objectives are met, otherwise the page stays up as it would by hand.
- `QUEST_COMPLETE` — the reward page. With no reward choice the quest is
  turned in; a single offered item isn't a choice either, so that is
  taken too. Two or more choices are left for you to pick and click
  Complete Quest.

Holding Shift while talking to an NPC pauses all of this, so a quest can
be read, declined, or handed in by hand without turning the automation
off.

### CVar toggles

`src/CVars.lua` lists the on/off client settings the addon exposes. Each
is an option mirrored to a CVar: written at `PLAYER_LOGIN` and whenever
the option changes. A toggle with no default stays unset until it's first
used, so the CVar is left as the game has it and the checkbox shows the
live value. If a client build turns out not to know a CVar, its checkbox
is disabled and the note says so. Adding a toggle is one new entry in
that table; the options section and slash command come from it.

- **In-game navigation pin** (`showInGameNavigation`, on by default).
  Retail's `Blizzard_QuestNavigation` draws a marker over the super-tracked
  quest objective (the one the minimap arrow points at) and shows the
  yards to it. The WoW Forever flavor of the client still loads that code,
  but its settings overrides leave out the "In-Game Navigation" checkbox,
  so the CVar can't be reached from the menus.
- **Always sharpen** (`ResampleAlwaysSharpen`, untouched until set). The
  Graphics settings' Resample Sharpness slider only applies while the
  frame is being upscaled; with this on, it applies at 100% render scale
  too. There is no entry for it in the settings menu.

### Max camera distance

`cameraDistanceMaxZoomFactor` scales how far the camera can zoom out. WoW
Forever's Controls settings offer it as a slider from 1.0 to 2.0, but the
limit is enforced inside the client, not by that menu, and the client
accepts more. At `PLAYER_LOGIN` the addon finds the real limit by setting
the CVar far too high, reading back what stuck, and restoring the old
value; the slider runs from 1.0 to that limit (capped at 3.4, the
vanilla-era maximum). The box beside the slider takes an exact value on
Enter. Whatever the client keeps after a set is what the controls show,
and it is saved and reapplied at login. Until the slider or box is used
the addon leaves the CVar alone.

### Cast animation on action buttons

Each action button's `PlaySpellCastAnim` runs on the player's cast and
channel events and shows a fill animation over the icon. No setting or
CVar gates it. At `PLAYER_LOGIN` the addon post-hooks that method on the
twelve buttons of each of the eight action bars with `hooksecurefunc`;
when the option is off, the hook hides the animation frame as soon as it
is shown. That frame's own `OnHide` restores the cooldown swipe, so the
rest of the button behaves as normal. The hooks stay in place and read
the option live, so the checkbox works without a reload.

### Totem bar alignment

The shaman totem bar, `MultiCastActionBarFrame`, is a fixed-width box
(230 points) that Edit Mode positions as a whole. Blizzard's layout
anchors the Call of the Elements button to the box's bottom-left corner,
the first totem slot to the right of that, each further slot to the one
before it, and Totemic Recall to the last slot shown; the page frames
that hold the spell icons sit over the slots with the same anchor. So
with fewer than four elements known the buttons cluster at the left and
the right of the box is empty. When the option is on, the addon measures
what's shown (summon button, active slots, recall button) and re-anchors
the summon button, the first slot, and the page frames so the row ends
at the box's right edge; everything else follows through the chain.
Blizzard's `MultiCastActionBarFrame_Update` resets those anchors on every
refresh (login, learning a totem, changing the Call of the Elements
page), so that function is post-hooked and the layout reapplied after
it. Switching the option off sets the same anchors Blizzard would. The
summon button is a secure frame, so nothing is moved during combat; a
layout that comes due then waits for `PLAYER_REGEN_ENABLED`.

## Developing

WoW loads an addon from a folder whose name matches the `.toc`, so link this
repo into your AddOns directory as `SwampmanEnhancements` (PowerShell,
adjust the game path):

```powershell
New-Item -ItemType Junction `
  -Path "C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\SwampmanEnhancements" `
  -Target "C:\Users\Ryan\source\repos\swampman-enhancements"
```

`/reload` in-game picks up Lua changes; a full restart is only needed for
`.toc` changes.

If the addon's saved variables don't come back from disk at load (a first
run, or the file failed to load), it says so in chat at `PLAYER_LOGIN`
and runs on defaults. Seeing that message on a launch that isn't the first
means the client dropped the saved settings.

`.\etc\check.ps1` runs luacheck and a LuaJIT parse over `src`; CI runs the
same luacheck on every push.

## Releasing

Releases are built by the [BigWigs packager](https://github.com/BigWigsMods/packager)
via GitHub Actions (`.github/workflows/release.yml`). Pushing a tag like
`v0.1.0` packages the addon (with `@project-version@` in the .toc replaced
by the tag) and publishes it as a GitHub release. The .toc carries the
CurseForge project ID, so with a `CF_API_KEY` repository secret set on
GitHub the same run uploads the zip to CurseForge too.

```bash
git tag v0.1.0 && git push origin master --tags
```

## Commands

- `/sme` (or `/swampman`) — show what's on
- `/sme on` / `/sme off` / `/sme toggle` — quest automation as a whole
- `/sme accept [on|off]` — picking up quests (toggles with no argument)
- `/sme turnin [on|off]` — handing in quests (toggles with no argument)
- `/sme nav [on|off]` — the in-game navigation pin (toggles with no argument)
- `/sme zoom [value]` — max camera distance, e.g. `/sme zoom 2.6` (shows
  the current value with no argument)
- `/sme sharpen [on|off]` — always apply resample sharpening (toggles with
  no argument)
- `/sme castanim [on|off]` — the cast animation on action buttons (toggles
  with no argument)
- `/sme totembar [left|right]` — which edge of its box the totem bar's
  buttons fill from (toggles with no argument)
- `/sme options` — open the settings panel

## Options

Under Options -> AddOns -> Swampman Enhancements, or `/sme options`:

- Quests: Enable auto accept, Enable auto turn in (both on by default)
- Navigation: Show the in-game navigation pin (on by default)
- Camera: Max camera distance slider and value box (untouched until used)
- Graphics: Always sharpen (untouched until used)
- Action bars: Show the cast animation on buttons (on by default), Align
  the totem bar's buttons to the right (off by default)

Settings are account-wide and saved between sessions.
