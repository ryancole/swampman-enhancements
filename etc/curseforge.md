# CurseForge listing

Source text for the project page. Paste the summary into the "Summary"
field and the description into the description editor (Markdown mode).

## Summary

Small quality-of-life tweaks for WoW Forever: quests are accepted and turned in for you, the hidden in-game navigation pin gets its checkbox back, the camera zooms out further than the settings menu allows, and the cast animation on action buttons can be switched off. No libraries, no setup.

Short form: Auto quest accept and turn in, the hidden navigation pin, a farther camera, and no button cast animations for WoW Forever.

## Description

# Swampy Forever Enhancements

A small bundle of quality-of-life tweaks for **WoW Forever**. Each one is either something the game can already do but hides from its settings menu, or a small automation that saves clicks. Everything is optional, everything is off in one click, and there are no libraries or dependencies.

Open the options with `/sfe options`, or find it under **Options → AddOns → Swampy Forever Enhancements**.

## What it does

### Quest automation

Talk to a quest giver and the addon takes the clicks for you. Finished quests are handed in first, then new ones are picked up, and it moves on to the next quest the NPC has until the list is empty.

It is careful about the things that deserve a decision:

- **Reward choices are yours.** When a quest offers a choice of rewards, the reward page stays open so you pick the item and turn it in yourself. A quest with a fixed reward, or a single offered item, is turned in on the spot.
- **PvP-flagging quests wait for a deliberate click.**
- **Hold Shift to do it by hand.** Keep Shift held while talking to an NPC and the addon stays out of the way, so you can read the quest text, decline something, or hand in at your own pace without turning anything off.
- Escort quests started by a party member are joined automatically.

Accepting and turning in are separate switches, so you can keep one and drop the other.

### In-game navigation pin

The client can draw a floating marker in the world over your tracked quest objective, with the distance in yards underneath, and an arrow at the screen edge when it's out of view. WoW Forever ships this feature but leaves its checkbox out of the settings menu. The addon puts the option back. On by default.

### Max camera distance

The Controls settings stop the camera distance slider at 2.0, but the client itself accepts more. The addon's slider runs to the client's real limit, with a box beside it to type an exact value, and your choice is reapplied every login so a patch or a settings reset can't quietly pull the camera back in.

### Always sharpen

The Graphics settings' Resample Sharpness filter normally only applies while the game is upscaling. This checkbox turns on the client's hidden `ResampleAlwaysSharpen` setting so sharpening applies at 100% render scale too. If your client build doesn't have it, the checkbox says so and stays greyed out.

### Cast animation on action buttons

The fill that sweeps across a button's icon while its spell is cast or channelled has no setting anywhere in the game. Untick it here and it's gone. The cooldown swipe and everything else on the button keep working as normal.

## Options

All settings are account-wide and saved between sessions.

- **Quests:** Enable auto accept, Enable auto turn in
- **Navigation:** Show the in-game navigation pin
- **Camera:** Max camera distance slider and value box
- **Graphics:** Always sharpen
- **Action bars:** Show the cast animation on buttons

Settings that mirror a game setting are left untouched until you change them, so installing the addon doesn't alter anything by itself apart from turning the navigation pin on.

## Slash commands

`/sfe` or `/swampy`

- `/sfe` — show what's on
- `/sfe on` / `/sfe off` — quest automation as a whole
- `/sfe accept [on|off]` — picking up quests
- `/sfe turnin [on|off]` — handing in quests
- `/sfe nav [on|off]` — the in-game navigation pin
- `/sfe zoom <value>` — max camera distance, e.g. `/sfe zoom 2.6`
- `/sfe sharpen [on|off]` — always apply resample sharpening
- `/sfe castanim [on|off]` — the cast animation on action buttons
- `/sfe options` — open the settings panel

Commands that take `on|off` toggle when given no argument.

## Notes

- Built for WoW Forever (1.60). It will not load on other flavors.
- Quest automation only ever does what a click in the default quest frame would do; it never accepts a quest the game wouldn't offer you.
- Source and issue tracker on GitHub.
