# Steam setup (Logic Wiz – Sudoku Variants)

Written 2026-10-22. The game still uses **480** (Valve's "Spacewar" test app) until you have your own App ID.

## 1. Get your own App ID (once, about 1-2 weeks of paperwork)
1. Go to <https://partner.steamgames.com> and sign in with the Steam account that should own the game.
2. Click **Join the Steamworks program** and fill in:
   - your legal name and address,
   - bank details (to get paid),
   - the tax form. From Jordan this is the **W-8BEN** interview; it asks for your Jordanian tax/ID number.
3. Steam checks your identity. This can take a few days.
4. Pay the **Steam Direct fee**: **$100 per game**. You get it back once the game earns $1,000.
5. After payment, Steamworks shows **"Your app ID is: 1234560"** (a 6-7 digit number). It is also under **Dashboard → All Applications**.
6. **Send me that number.** I'll put it in:
   - `steam_appid.txt` (project folder, only for testing; it is not shipped),
   - `APP_ID` in `scripts/autoload/steam_manager.gd`.

Steam rules to plan around:
- New developers wait **30 days** after paying before the game can be released.
- The store page must be public as **"Coming Soon" for at least 2 weeks** before release.

## 2. Create the achievements (after you have the App ID)
1. Steamworks → **App Admin** → your game → **Stats & Achievements** → **Achievements**.
2. For every row in the table below:
   1. Click **New Achievement**.
   2. Fill in **API Name** (copy it exactly), **Display Name** and **Description**.
   3. Set **Set By: Client** and **Hidden: no**.
   4. Upload the two icons from `docs/steam/achievements/`:
      - **Achieved** = `<API>.png`
      - **Unachieved** = `<API>_locked.png`
3. When all 42 are in, go to the **Publish** tab → **Prepare for Publishing** → **Publish to Steam**. Until you publish, the game can't unlock them.
4. Test: run the game with Steam open and solve a puzzle. "First Steps" should pop up.

Daily leaderboards (`daily_YYYY-MM-DD`) are created by the game itself; nothing to set up.

## 3. Achievements (42)
| # | API name | Display name | Description | Icon (achieved) | Icon (locked) |
|---|---|---|---|---|---|
| 1 | `FIRST_SOLVE` | First Steps | Solve your first puzzle. | achievements/FIRST_SOLVE.png | achievements/FIRST_SOLVE_locked.png |
| 2 | `SOLVE_10` | Getting Warm | Solve 10 puzzles. | achievements/SOLVE_10.png | achievements/SOLVE_10_locked.png |
| 3 | `SOLVE_50` | Puzzle Addict | Solve 50 puzzles. | achievements/SOLVE_50.png | achievements/SOLVE_50_locked.png |
| 4 | `SOLVE_100` | Logic Wizard | Solve 100 puzzles. | achievements/SOLVE_100.png | achievements/SOLVE_100_locked.png |
| 5 | `ALL_CORE` | Variety Pack | Solve every core variant. | achievements/ALL_CORE.png | achievements/ALL_CORE_locked.png |
| 6 | `HARD_SOLVE` | Hard Boiled | Solve a Hard puzzle. | achievements/HARD_SOLVE.png | achievements/HARD_SOLVE_locked.png |
| 7 | `HARD_NO_HINTS` | Unassisted | Solve a Hard puzzle without hints. | achievements/HARD_NO_HINTS.png | achievements/HARD_NO_HINTS_locked.png |
| 8 | `SPEED_CLASSIC` | Speed Demon | Solve a Medium or Hard Classic in under 5 minutes. | achievements/SPEED_CLASSIC.png | achievements/SPEED_CLASSIC_locked.png |
| 9 | `KILLER_INSTINCT` | Killer Instinct | Solve 10 Killer puzzles. | achievements/KILLER_INSTINCT.png | achievements/KILLER_INSTINCT_locked.png |
| 10 | `DAILY_FIRST` | Daily Habit | Complete a daily puzzle. | achievements/DAILY_FIRST.png | achievements/DAILY_FIRST_locked.png |
| 11 | `DAILY_STREAK_7` | On a Roll | 7-day daily streak. | achievements/DAILY_STREAK_7.png | achievements/DAILY_STREAK_7_locked.png |
| 12 | `DAILY_STREAK_30` | Devoted | 30-day daily streak. | achievements/DAILY_STREAK_30.png | achievements/DAILY_STREAK_30_locked.png |
| 13 | `SOLVE_250` | Grid Regular | Solve 250 puzzles. | achievements/SOLVE_250.png | achievements/SOLVE_250_locked.png |
| 14 | `SOLVE_500` | Grid Veteran | Solve 500 puzzles. | achievements/SOLVE_500.png | achievements/SOLVE_500_locked.png |
| 15 | `SOLVE_1000` | Thousand Grids | Solve 1,000 puzzles. | achievements/SOLVE_1000.png | achievements/SOLVE_1000_locked.png |
| 16 | `EXPERT_SOLVE` | Expert Eye | Solve an Expert puzzle. | achievements/EXPERT_SOLVE.png | achievements/EXPERT_SOLVE_locked.png |
| 17 | `EXPERT_10` | Sharp Mind | Solve 10 Expert puzzles. | achievements/EXPERT_10.png | achievements/EXPERT_10_locked.png |
| 18 | `MASTER_SOLVE` | Master Class | Solve a Master puzzle. | achievements/MASTER_SOLVE.png | achievements/MASTER_SOLVE_locked.png |
| 19 | `MASTER_10` | Grandmaster | Solve 10 Master puzzles. | achievements/MASTER_10.png | achievements/MASTER_10_locked.png |
| 20 | `MASTER_50` | Living Legend | Solve 50 Master puzzles. | achievements/MASTER_50.png | achievements/MASTER_50_locked.png |
| 21 | `MASTER_FLAWLESS` | Flawless | Solve a Master puzzle without a mistake. | achievements/MASTER_FLAWLESS.png | achievements/MASTER_FLAWLESS_locked.png |
| 22 | `ALL_LEVELS` | Full Ladder | Solve one variant at all six levels. | achievements/ALL_LEVELS.png | achievements/ALL_LEVELS_locked.png |
| 23 | `BLANK_SLATE` | Blank Slate | Solve a puzzle that starts with no digits. | achievements/BLANK_SLATE.png | achievements/BLANK_SLATE_locked.png |
| 24 | `NO_HINTS_25` | Self-Made | Solve 25 puzzles without hints. | achievements/NO_HINTS_25.png | achievements/NO_HINTS_25_locked.png |
| 25 | `VARIETY_25` | Explorer | Solve 25 different variants. | achievements/VARIETY_25.png | achievements/VARIETY_25_locked.png |
| 26 | `CAT_REGIONS` | Region Ranger | Solve every Regions variant. | achievements/CAT_REGIONS.png | achievements/CAT_REGIONS_locked.png |
| 27 | `CAT_LINES` | Line Walker | Solve every Lines variant. | achievements/CAT_LINES.png | achievements/CAT_LINES_locked.png |
| 28 | `CAT_SUMS` | Sum Total | Solve every Sums & Arrows variant. | achievements/CAT_SUMS.png | achievements/CAT_SUMS_locked.png |
| 29 | `CAT_OUTSIDE` | Outsider | Solve every Outside Clues variant. | achievements/CAT_OUTSIDE.png | achievements/CAT_OUTSIDE_locked.png |
| 30 | `CAT_DOTS` | Dot Connector | Solve every Dots & Signs variant. | achievements/CAT_DOTS.png | achievements/CAT_DOTS_locked.png |
| 31 | `CAT_MARKS` | Marked Cells | Solve every Cell Marks variant. | achievements/CAT_MARKS.png | achievements/CAT_MARKS_locked.png |
| 32 | `CAT_THEMES` | Polyglot | Solve every Letters & Symbols variant. | achievements/CAT_THEMES.png | achievements/CAT_THEMES_locked.png |
| 33 | `CAT_GLOBAL` | Chess Club | Solve every Chess & Global Rules variant. | achievements/CAT_GLOBAL.png | achievements/CAT_GLOBAL_locked.png |
| 34 | `CAT_MINI` | Small Wonders | Solve every Mini 6×6 variant. | achievements/CAT_MINI.png | achievements/CAT_MINI_locked.png |
| 35 | `MINI_FIRST` | Pocket Puzzle | Solve a Mini 6×6 puzzle. | achievements/MINI_FIRST.png | achievements/MINI_FIRST_locked.png |
| 36 | `MINI_SPRINT` | Mini Sprint | Solve a Mini Medium or harder in under 2 minutes. | achievements/MINI_SPRINT.png | achievements/MINI_SPRINT_locked.png |
| 37 | `DAILY_10` | Ten Days | Complete 10 daily puzzles. | achievements/DAILY_10.png | achievements/DAILY_10_locked.png |
| 38 | `DAILY_STREAK_100` | Unbreakable | 100-day daily streak. | achievements/DAILY_STREAK_100.png | achievements/DAILY_STREAK_100_locked.png |
| 39 | `MP_FIRST_RACE` | At the Start Line | Finish a 1v1 race. | achievements/MP_FIRST_RACE.png | achievements/MP_FIRST_RACE_locked.png |
| 40 | `MP_FIRST_WIN` | First Blood | Win a 1v1 race. | achievements/MP_FIRST_WIN.png | achievements/MP_FIRST_WIN_locked.png |
| 41 | `MP_WINS_10` | Racer | Win 10 races. | achievements/MP_WINS_10.png | achievements/MP_WINS_10_locked.png |
| 42 | `MP_WINS_50` | Champion | Win 50 races. | achievements/MP_WINS_50.png | achievements/MP_WINS_50_locked.png |
The icons are made by `tools/achievement_icons.tscn`. Change `ICONS` there and run
`godot --path . res://tools/achievement_icons.tscn` to redraw them.

## 3b. Steam Cloud: progress follows the player to any PC (after you have the App ID)
The game keeps all progress in 3 small files in a fixed folder: `%APPDATA%\LogicWizSudoku\`
(`settings.json`, `stats.json`, `saves.json`). Steam Auto-Cloud copies that folder to Steam's servers; no code needed.
1. Steamworks → **App Admin** → your game → **Cloud** tab.
2. **Byte quota per user**: `10000000` (10 MB). **Number of files allowed per user**: `50`. Click **Save**.
3. Tick **Enable Auto-Cloud support**. Under **Root Paths** click **Add Root**:
   - Root: `WinAppDataRoaming`  ·  Subdirectory: `LogicWizSudoku`  ·  Pattern: `*.json`  ·  OS: `Windows`  ·  Recursive: no
   - (Only if you ship Mac/Linux later: add the same with roots `MacAppSupport` / `LinuxXdgDataHome`.)
4. Click **Save**, then **Publish** tab → **Prepare for Publishing** → **Publish to Steam**.
5. Test: play on one PC, close the game (Steam shows "Cloud status: up to date" in the Library), then start it on
   another PC with the same Steam account: the stats and streaks are there.
Players can switch Steam Cloud off per game in Steam; it is on by default.

## 4. Before release (later)
- **Store page assets:**
  - header capsule 920×430,
  - small capsule 462×174,
  - main capsule 1232×706,
  - vertical capsule 748×896,
  - library capsule 600×900,
  - library hero 3840×1240,
  - logo 1280×720,
  - at least 5 screenshots (1920×1080).
- **Build upload:** export Windows Desktop (preset exists), then upload it with SteamPipe. I can write that script when you get there.
- **Final name:** change it in `project.godot` (`config/name`), in the nav bar logo text and in the export preset.
