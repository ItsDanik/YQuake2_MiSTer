# YQuake2 for MiSTer

Quake II on [MiSTer FPGA](https://github.com/MiSTer-devel/Main_MiSTer/wiki) as a hybrid port.

The game is [Yamagi Quake II](https://www.yamagi.org/quake2/) ([GitHub](https://github.com/yquake2/yquake2)), the source port of id Software's Quake II that stays closest to the original, with its software renderer. The mission packs *The Reckoning* and *Ground Zero* are supported as well. It runs on the MiSTer's ARM CPU. The YQuake2 FPGA core provides native 15kHz video (CRT, VGA and HDMI) at 320x200 or 320x240, 44.1kHz audio and keyboard, mouse and gamepad input. The two halves talk through shared DDR3 memory.

> **Beta.** Expect rough edges and please report problems in the issues.

Disclaimer: AI is being used to speed up development of this project.

## Requirements

- **danik_hybrid_ports**, the launcher (`Scripts/danik_hybrid_ports.sh`): run it **once** from the MiSTer's `Scripts` menu. It starts the game whenever its menu entry is loaded, keeps running after a reboot, and serves all our hybrid ports; its screen picks which ports and games to have, and can keep them up to date through `update_all`. It replaces `danik_hybrid_cores`, the launcher before it, and moves ports installed the old way (`games/YQuake2/`) into the new folders by itself. Without it the core says "Game not running".
- **Game data**, which is not included: Quake II from the CD (patched to 3.20), Steam or GOG, or the free demo. The original game files, not those of the 2023 remaster.

## Installation

With `update_all` (Downloader 2.4 or newer, which update_all keeps up to date):

1. Copy [`downloader_danik_hybrid_ports.ini`](https://raw.githubusercontent.com/ItsDanik/Hybrid_MiSTer/main/launcher/downloader_danik_hybrid_ports.ini) to the root of your SD card (`/media/fat`).
2. Run `update_all`. That installs the launcher, **danik_hybrid_ports**, in `Scripts`.
3. Run **danik_hybrid_ports** from the `Scripts` menu, tick the games you want and press *X: Apply*. They are installed, and update_all keeps them up to date.

By hand:

1. Download the newest `YQuake2_YYYYMMDD.zip` from [releases](releases/) and extract it to the root of your SD card (`/media/fat`). That gives you:
   - `_Other/dnk-Quake II.mgl`, `_Other/dnk-Q2 The Reckoning.mgl` and `_Other/dnk-Q2 Ground Zero.mgl`, the games' entries in the `Other` menu
   - `_Other/dnk/dnk-YQuake2_YYYYMMDD.rbf`, the FPGA core
   - `games/dnk/YQuake2/`, the game binary, the games' code in `baseq2`, `xatrix` and `rogue`, and the launch script
   - `Scripts/danik_hybrid_ports.sh`, the launcher (from [Hybrid_MiSTer](https://github.com/ItsDanik/Hybrid_MiSTer))
   - `downloader_danik_hybrid_ports.ini`, with which `update_all` keeps the ports up to date from then on

The game data goes into `/media/fat/games/dnk/YQuake2/`, next to the `game.so` files that are already in its folders:

| Folder | Files |
|---|---|
| `baseq2/` | **everything** in the `baseq2` folder of your Quake II, with its folders as they are, and leave nothing out (`pak0.pak`, `pak1.pak`, `pak2.pak`, `players/`, `video/` and the rest; files the port does not use do no harm). A CD version needs the 3.20 patch for `pak1.pak` and `pak2.pak`. The demo has only `pak0.pak` and `players/`. |
| `baseq2/music/` | the soundtrack, optional: `02.ogg` to `11.ogg`, ripped from the CD. The GOG version's `music/` folder (`Track02.ogg` ...) goes next to `baseq2/` instead, as `games/dnk/YQuake2/music/`. |
| `xatrix/` | *The Reckoning*, optional: everything in its folder `xatrix` (`pak0.pak`, `video/`, ...) |
| `rogue/` | *Ground Zero*, optional: everything in its folder `rogue` (`pak0.pak`, `video/`, ...) |

Then run **danik_hybrid_ports** from the `Scripts` menu, if you have not done so before (see Requirements), and load the game from the `Other` menu, e.g. **dnk-Quake II**.

The game data can go on a USB drive instead, into the same folders there (`/media/usb0/games/dnk/YQuake2/baseq2/` and so on): the game looks for it there first, and then keeps its settings and saved games there as well. Everything else, the `game.so` files among it, stays on the SD card.

The menu entry of Quake II starts the demo when the full game is not there; the mission packs need the full game. When a game's files are missing, the core says which files to copy where. Each game keeps its own OSD settings and button mappings. The core file itself (`_Other/dnk/dnk-YQuake2_*.rbf`, or from *Recent*) lists the games that are there to pick from; quitting a game then returns to the list. The game's log is in `/media/fat/logs/dnk/YQuake2/yquake2.log`. Settings and saved games are kept in the game's folder (on the USB drive, if the game data is there): `baseq2/config.cfg` and `baseq2/save/` (`xatrix/` and `rogue/` for the mission packs).

## OSD options

| Option | |
|---|---|
| Aspect ratio, Scale, Scandoubler Fx, Stereo Mix | as in other cores |
| FPS Counter | shows the pictures per second in the top left corner |
| HDMI Only | **Yes** if no CRT is connected: resolutions of 640x400 and more are then progressive instead of interlaced, and the analog output is switched off while one is shown, so that a 15kHz screen can never get such a signal. Nothing changes at lower resolutions. Not needed with `forced_scandoubler=1` (VGA monitor); not there with `direct_video=1` |
| CRT Options | for a 15kHz screen: *Horizontal Size*, *Horizontal Pos* and *Vertical Pos* fit the picture to it. The pixels stay as they are; HDMI is not affected. The size is for the game's picture: the core's own, with its messages, keeps its width. Not there with `forced_scandoubler=1`. *HUD (Bottom)*: at 320x240, how many lines the status bar sits above the bottom edge of the screen, 0 to 24 (0 by default, the very edge, for HDMI), so that a CRT's overscan does not hide it; greyed out at 320x200. *HUD (Top)* is always greyed out: the messages at the top stay at the edge, as in Quake II |
| Resolution | **320x200** (default) or **320x240**: the game's picture, switched at once. At 320x240 the view fills all 240 lines and the status bar is drawn over it at the *HUD* margin; it shows a little more and is a little slower |
| Rumble | the gamepad's rumble, Quake II's own (shots, hits, falls, explosions, doors and platforms nearby): **On** (default), **Strong** or **Off**. It takes the place of the game's *rumble intensity* |
| Cheats | single player only. *God Mode*, *No Clipping* (fly through walls), *Invisible to Monsters* and *Infinite Ammo* stay on while they are on, through saved games and level changes, and are gone when turned off. Once each time they are selected: *Give All* (every weapon with full ammo, armour, the power shield, keys and items), *Quad Damage* and *Invulnerability* (one in the inventory, used like one picked up), *Next Level* (the level is left through its exit, as if you had reached it: the first exit that does not lead back to the level you came from) |
| Save Diagnostic Report | the last line: see [If something is wrong](#if-something-is-wrong) |

## Controls

- **Keyboard and mouse:**

| Key | Action |
|---|---|
| W / S | forward / back |
| A / D | step left / right |
| Mouse | look around (always) |
| Mouse 1 | fire |
| Space | jump, swim up |
| Ctrl | crouch, swim down |
| Shift | walk while held (the game always runs) |
| 1 to 0, - | Blaster, Shotgun, Super Shotgun, Machinegun, Chaingun, Grenades, Grenade Launcher, Rocket Launcher, HyperBlaster, Railgun, BFG10K. The mission packs' weapons are on the key of the weapon they go with: pressed again, the key switches between them (1 Chainfist, 4 ETF Rifle, 6 Tesla and Trap, 7 Prox Launcher, 8 Phalanx, 9 Ion Ripper and Plasma Beam, - Disruptor) |

The other keys are as in Quake II: the arrow keys move and turn, Tab is the inventory, Enter uses the selected item, `[` / `]` select, `'` drops it, F1 is the field computer, F6 / F9 quick save / load and Esc the menu. Change them in the game's *Options* menu.


- **Gamepad** (default mapping):

| Button | Action |
|---|---|
| Left stick | move |
| Right stick | look around |
| D-pad | left / right: previous / next weapon, up / down: previous / next item |
| A (Xbox B / PlayStation Circle) | jump, swim up |
| B (Xbox A / PlayStation Cross) | crouch, swim down |
| X (Xbox Y / PlayStation Triangle) | inventory |
| Y (Xbox X / PlayStation Square) | use the selected item |
| L (LB / L1), L2 | walk while held |
| R (RB / R1), R2 | fire |
| L3 (left stick click) | drop the selected item |
| Select | field computer (help) |
| Start | Menu |

In the game's menus the d-pad and left stick move, and the buttons that confirm and go back are the ones of your MiSTer menu, whatever they do in the game: its *Menu OK* / *Menu Back* if you set them in *Define joystick buttons*, else its A / B. A controller never set up in MiSTer confirms and goes back as on its console: Cross / Circle on PlayStation, A / B on Xbox and on Nintendo. Rebind the keyboard and gamepad in the game's *Options* menu; the game keeps your changes. L2 and R2 work on controllers with analog triggers, L3 on those whose stick clicks Linux reports as such (a DualSense does).

Change the buttons in the OSD under *Define YQuake2 buttons*. *Menu OK* and *Menu Back* there are only needed for a spare button without a game function. While the OSD is open, the game gets no input. Controllers that can rumble do (the OSD's *Rumble*).

## If something is wrong

If the game stutters, the sound breaks up or something else is wrong, open the OSD while it happens and pick **Save Diagnostic Report**, the last line of the menu. The game keeps running; MiSTer's info box says the report is saved in `games/dnk/diagnostics/` on the SD card. Send that file (`YQuake2_<date>_<time>.zip`) with a few words on what went wrong.

The report has the setup (versions, the video and audio lines of `MiSTer.ini`, the OSD settings), how the last 60 seconds went, the game's log and a screenshot. Nothing else: no network settings, addresses, saved games or lists of your files.

## Building

Everything builds in Docker on a Linux PC.

```sh
git clone --recursive https://github.com/ItsDanik/YQuake2_MiSTer.git
cd YQuake2_MiSTer
./build.sh              # ARM game binary  -> build/mister/yquake2, game libraries -> build/mister/*/game.so
./core/build_core.sh    # FPGA core (Quartus Lite 17.0.2) -> core/output_files/YQuake2.rbf
./package.sh            # release zip      -> dist/YQuake2_YYYYMMDD.zip
```

The toolchain image (Debian bullseye, glibc 2.31 to match the MiSTer) is built from `hybrid/toolchain/` on first use. The first build also downloads and builds SDL2, SDL2_mixer and SDL2_net.

### Repository layout

| Path | |
|---|---|
| `hybrid/` | submodule: [ItsDanik/Hybrid_MiSTer](https://github.com/ItsDanik/Hybrid_MiSTer), what all our hybrid ports share: the FPGA host module, the ARM side library, SDL2 drivers, the launcher (`danik_hybrid_ports.sh`), toolchain and conventions. See its README. |
| `core/` | FPGA core, based on [Template_MiSTer](https://github.com/MiSTer-devel/Template_MiSTer): `YQuake2.sv` (OSD and button names) around `hybrid/rtl/hybrid_host.sv` |
| `yquake2/` | submodule: the game, [our fork of Yamagi Quake II](https://github.com/ItsDanik/yquake2), branch `mister`, with the MiSTer changes |
| `xatrix/`, `rogue/` | submodules: the game code of the mission packs, our forks of [xatrix](https://github.com/ItsDanik/xatrix) and [rogue](https://github.com/ItsDanik/rogue), branch `mister`, with the cheats of the OSD |
| `package/` | files shipped in the release next to the binary (`danik_hybrid_launch.sh`, README), `games.txt`: the games and their menu entries, and `logos/`: each game's logo, shown at its start (440x200) |
| `releases/` | release packages |

### Development notes

- `./build.sh host` builds the same game for the PC. It runs against `hybrid/tools/fakecore`, a stand-in for the FPGA core that takes scripted input and saves screenshots and audio:
  ```sh
  gcc -O2 -o build/host/fakecore hybrid/tools/fakecore.c
  build/host/fakecore /tmp/shm script.txt audio.raw &
  cd <data folder> && MISTER_HYBRID_SHM=/tmp/shm MISTER_HYBRID_CORE=YQuake2 <repository>/build/host/yquake2 -portable
  ```
- Speed: `MISTER=root@<address> tools/benchmark.sh <name> [<environment>]` runs the standard scenes on the MiSTer and prints frames per second and milliseconds per stage; `tools/bench.sh` runs one scene with the profiler, `tools/profile.py` reads its profile. `tools/pgo.sh` builds with profile guided optimisation (measured: no gain, not used).
- `MISTER=root@<address> tools/test_on_mister.sh <id>` (`Q2`, `RK`, `GZ`) tries the build on a MiSTer next to what is installed there, without installing it: from `/tmp`, with the installed game's folder mirrored there (what the game writes stays in `/tmp`) and its own OSD settings. `list` and `nodata` for the core started by itself and without data, `log` for the game's log, `stop` to remove all of it again.
- `touch /tmp/yquake2_nolaunch` on the MiSTer keeps the core loaded without starting the game, so you can start a development binary by hand (set `MISTER_HYBRID_CORE=YQuake2`, and `MISTER_HYBRID_SET` for a game's set name, e.g. `YQuake2_RK`). `/tmp/danik_hybrid_ports.log` shows what the launcher daemon did.

## Support

If you enjoy this project, you can support my work on [Patreon](https://www.patreon.com/itsdanik).

## Credits

- **[Yamagi Quake II](https://github.com/yquake2/yquake2)** by Yamagi Burmeister and contributors, and **Quake II** by id Software, whose source code it is based on. The mission pack code from [yquake2/xatrix](https://github.com/yquake2/xatrix) and [yquake2/rogue](https://github.com/yquake2/rogue).
- **[SDL](https://libsdl.org)** by Sam Lantinga and contributors.
- **[MiSTer](https://github.com/MiSTer-devel)** by Sorgelig and the MiSTer-devel contributors: the framework and Template_MiSTer.
- **[MiSTer Frontier](https://github.com/MiSTerOrganize/MiSTer_Frontier)** by MiSTer Organize: thank you for the inspiration. Hybrid cores on the MiSTer, and the way their game is launched (a daemon that watches the loaded core and runs a script from its games folder), come from MiSTer Frontier. Our launcher is a separate implementation and does not need MiSTer Frontier installed.

This project and its maintainers are in no way associated with or endorsed by id Software, Bethesda or ZeniMax. It does not include any game data.

## License

The top-level scripts, tools and documentation are licensed under the [GPL-3.0](LICENSE). The components keep their own licenses: the shared framework in `hybrid/` is GPL-3.0 except where its files say otherwise, Yamagi Quake II and the mission pack code are GPL-2.0 (`yquake2/LICENSE`), SDL and the SDL drivers in `hybrid/sdl2` are zlib, the FPGA core and the MiSTer framework are GPL-2.0 (`core/LICENSE`, with the core's own sources GPL-2.0-or-later).
