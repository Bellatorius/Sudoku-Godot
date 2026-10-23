# Sudoku Variants (Godot 4)

A Steam-ready Sudoku variants game styled after logic-wiz.com/variants, with a warm paper
background, ink text, a blue accent, DM Serif Display and DM Sans fonts, and rounded variant cards.

## Open & run
1. Install **Godot 4.4 or newer** (standard build, not .NET).
2. Open Godot → **Import** → choose this folder's `project.godot` → **Run** (F5).
   Keep the Godot .exe **outside** this folder. If it sits next to `project.godot`, double-clicking it runs the
   game without importing first, and you get only the header and a blank screen.

## What's in v0.1
- **42 variant cards** with search and an "All / Playable" filter. 8 are playable now:
  Classic, Killer, Thermo, Arrow, Jigsaw, Diagonal, Kropki, XV. The rest show as *Coming soon*.
- **Puzzles from two sources**
  - *Pack puzzles*: 240 verified puzzles in `puzzles/*.json` (10 per difficulty per variant).
  - *New puzzle*: endless puzzles from the in-game generator (background thread). Every one is checked to have exactly one solution.
- **Play**: Normal, Corner and Centre pencil marks, cell colouring, multi-select (drag, Ctrl/Shift+click, double-click a digit),
  undo/redo, erase, hint, check, restart, rule-conflict highlighting, and automatic note cleanup.
- **Timer, pause** (auto-pauses when the window loses focus), and **autosave/resume** for each variant and difficulty.
- **Daily puzzle**: the same puzzle for everyone each day, rotating through the 8 variants. Tracks your streak.
- **Stats**: solve counts, best times, streaks and the achievement list.
- **Steam achievements**: these are optional. See below.

### Controls
- **Hold Shift**: corner marks (laid out like SudokuPad: 1 5 2 / 7 9 8 / 3 6 4)
- **Hold Ctrl**: centre marks (one row of small digits)
- **Hold Ctrl+Shift**: colours (9-colour palette; several colours split the cell)

These work with the keyboard digits **and** when you click the on-screen number pad. The mode buttons light up while you hold the keys.
Pencil marks are coloured **blue** when the digit is still possible and **red** when it is already placed in the same row, column, box or cage. You can turn this off in Settings.

Other keys: `Space` cycles mode · `Z/X/C/V` Normal/Corner/Centre/Colour · arrows/WASD move (`Shift` extends) ·
`Backspace` erases digits first, then marks, then colours · `Ctrl+Z / Ctrl+Y` undo/redo · `H` hint · `P` pause · `F11` fullscreen

## Project layout
```
scenes/main.tscn            entry scene
scripts/autoload/           UI (theme + palette), GameState (save/stats/daily), SteamManager
scripts/core/               Puzzle (data + JSON), Solver (bitmask backtracking), Generator, Session (undo, notes, hints), Variants (catalog)
scripts/ui/                 main (nav + toast), home/variant/game/stats/settings screens, Board (renderer), VariantIcon
puzzles/<variant>.json      puzzle packs
tools/build_packs.gd        regenerate packs:  godot --headless -s tools/build_packs.gd -- 10
tools/shots.tscn            dev helper that renders screenshots of every screen
```

## Adding hand-made puzzles
Append to `puzzles/<variant>.json` → `"puzzles": [...]`. Use the format documented at the top of
`scripts/core/puzzle.gd`. The `solution` field is optional because the game solves the puzzle on load. Give each entry a unique
`"id"` that starts with `pack-`.

## Adding a new variant
1. Set `rules` and `tip` in `scripts/core/variants.gd` and add its id to `CORE`.
2. Add any new constraint to `Solver` in two places: build it in `_build()` and check it in `extra_ok()`. The UI uses the same code to detect conflicts.
3. Generate it in `Generator._attempt()`, the same way thermos, arrows and cages are generated from a solved grid.
4. Draw it in `Board._draw()`.
5. Run `tools/build_packs.gd` to create its pack.

Good next ones, because they reuse existing code: **Non-consecutive** and **Consecutive** (edge relations, like Kropki),
**Windoku** (4 extra units), **Even-Odd**, **German Whispers**, **Renban** and **Palindrome** (line constraints, like Thermo),
and **Sandwich** and **X-Sum** (outside clues).

## Steam
1. In Godot, open **AssetLib**, search **GodotSteam GDExtension** (matching your Godot version), and install it into `addons/`.
2. `steam_appid.txt` contains `480` (Valve's Spacewar test app) for local testing. Keep the Steam client running.
3. After you buy your Steam app (Steam Direct), put your App ID in `steam_appid.txt` and `SteamManager.APP_ID`.
4. Create the achievements in Steamworks using the API names listed in `scripts/autoload/steam_manager.gd`
   (`FIRST_SOLVE`, `SOLVE_10`, `ALL_CORE`, `HARD_NO_HINTS`, `DAILY_STREAK_7`, and so on).
5. Export: **Project → Export → Windows Desktop**. Install the export templates when Godot asks. Upload `build/windows/`
   with SteamPipe. Don't ship `steam_appid.txt` in the depot.

Without GodotSteam the game runs normally and logs `[Steam] (offline) achievement: ...`.

## Fonts
DM Sans and DM Serif Display are licensed under the SIL Open Font License (`fonts/OFL-DMSans.txt`), so you can ship them in a commercial game.
