# Zenith Sky Changer

**by ZenithDev** · Rivals (Roblox) · cosmetic only · no key · v7.00

Change the **sky** of Rivals with your own photo, and **repaint the blocks** of the map. It only changes how the game looks **on your own screen**. Nobody else sees it.

> **No aimbot, no auto-damage, no speed / jump / fly, no teleport, no kill aura.**
> **No key system, no account, no webhooks, no telemetry.** It never sends anything anywhere.

## What it does

- **Sky.** Use any photo as the sky of the game. A small app (`Zenith Sky Changer.exe`) turns your picture into a seamless sky and keeps a gallery of your skies. You can switch between them in game.
- **Block colors.** Pick a color and repaint the blocks of the map (all the gray ones, or only the ones you click). Zones such as walls and floor can have different colors.
- **Glass reflection.** An optional layer that makes the map reflect your sky from far away.
- **Back to normal in one click.** The sky and the colors can be turned off at any time (`F8` sky, `F6` colors), and the "Back to normal" button restores the original game.

## Install

You need **Xeno** (or any executor with `writefile`, `readfile`, `getcustomasset` and `request`).

**Option 1: one line.** Join Rivals and run:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Whiteaura776/Zenith-Sky-Changer/main/zenith_sky_changer_loader.lua"))()
```

It downloads its files into your executor's `ZenithSky/` folder the first time. The window opens with the **`+`** key (press it again to shrink it).

**Option 2: the app** (`Zenith Sky Changer.exe`, under *Releases*). Open it once: it installs everything, adds the script to Xeno's autoexec so it starts by itself when you join Rivals, and lets you **drag in your own photos** for the sky. (With option 1 you only have the sky of the game; the photos need the app.)

## Notes

- Use it at your own risk. Using an executor is against Roblox's rules, and Rivals can change what it detects. This only changes visuals, but **there is no guarantee**.
- The code is open and **not obfuscated**. Read it, it is all here.
- Kept **on your PC** (`ZenithSky/` folder): your photos and skies, your choices and debug logs (`*_log.txt`). Nothing leaves your computer.
- Code under the MIT license (see `LICENSE`).

Questions, bugs, ideas: **Discord** (link in the profile). Also check **Zenith Skin Changer** for weapon skins and wraps.
