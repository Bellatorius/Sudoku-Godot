# Handover: Logic Wiz – Sudoku Variants (Godot → Steam)

This is a handover from a Claude (Cowork) session to Claude Code. Read this first, then `README.md`.

## Goal
The user (Bellatorius) is building a Steam game in **Godot**. It's a Sudoku variants game that copies the UI of
https://logic-wiz.com/variants/. The user asked for a similar look and suggestions, and wants to be asked when
anything is unclear.

## Where things are
- Project: `C:\Users\User\Games\LogicWiz` (Windows 11). Open `project.godot`.
- Godot editor: `C:\Users\User\Games\Godot\Godot_v4.7.2-stable_win64.exe` (Godot **4.7.2**, standard build, not .NET).
  - **Keep the .exe out of the project folder.** When it sat next to `project.godot`, double-clicking it ran the
    game without an editor import. No `.godot/` cache meant no `class_name` registry, so parse errors showed
    only the nav bar and a blank screen. Always open the project through the Project Manager (Import) first.
- A `Claude outputs` folder in `Games` holds stray screenshots. The user can delete it.
- The claude.ai Project "Steam" has notes in `claude/logic-wiz-sudoku-plan.md`.

## Decisions made with the user
| Topic | Decision |
|---|---|
| Scope v1 | Started with 8 playable variants (classic, killer, thermo, arrow, jigsaw, diagonal, kropki, xv); all 42 site variants are playable now (see "New variants"). |
| New variants (2026-10-18 →) | Adding the other 34 in tested batches of ~6, most popular first; logic-wiz.com originals last, rules read from the site. Packs were first 50 per difficulty; topped up to 500 on 2026-10-18 (all 42 packs now 1500 puzzles). Batch 1: non_consecutive, king (Anti-King), knight (Anti-Knight), even_odd, german_whispers, renban. Then the remaining 28 (all 42 now playable). Design choices not fixed by the site's text: Slingshot = source cell next to the arrow cell, the arrow bends 90° and the arrow digit N is the distance to the repeat; Vertex arms are 8-neighbours of the tip; Axia = diagonal corner ticks, Pulse = rings, Index Lookup = double arrows (↔ row / ↕ column), Reflection groups = shapes at the line start; Little Killer sums use no "?" clues; Ascending/Running clues only on the left/top. |
| More variants (2026-10-21) | 25 more (67 in total): region_sum, entropic, modular, parity_lines, nabner, ten_lines, double_arrow, pill_arrow, fortress, min_max, clone, frame, numbered_rooms, rossini, battlefield, sum_product_dots, anti_diagonal, center_dot, asterisk, girandola, argyle, queen, miracle, magic_square, toroidal. Their expert/master grade bars live in puzzles/grades.json (tools/build_grades.gd, measured from their Hard puzzles). Chaos Construction and "Killer with negative constraints" were not added (see chat). Dailies (puzzles/daily.json) only use the first 42. |
| Puzzles | **Both**: verified JSON packs in `puzzles/*.json` (500 per difficulty per variant, 42 × 1500 = 63,000 total) **and** an in-game generator that checks each puzzle has a unique solution. |
| Features | Pencil marks + undo/redo, timer/hints/save-resume, daily puzzle + stats/streaks, Steam achievements. |
| Levels (2026-10-21) | Six levels for every variant: **beginner, easy, medium, hard, expert, master** (`GameState.DIFFICULTIES`, `Generator.LEVELS`), 500 pack puzzles each. Beginner = easy clues + 8 more givens. Expert/master = minimal givens, fewer variant clues (`Generator.CLUE_TIER` → medium amounts) and only puzzles whose `Generator.grade()` (solver nodes to prove uniqueness ÷ empty cells) reaches `Generator.GRADE[variant]` = median / top-quarter grade of that variant's Hard pack. |
| Hints | Limited per puzzle by level (`Session.HINT_LIMITS` / `CHECK_LIMITS` / `MISTAKE_LIMITS`): hints beginner 20, easy 10, medium 3, hard/expert/master 0; checks 10/5/2/0/0/0; mistakes beginner unlimited (0), easy 14, medium 7, hard 3, expert 2, master 1. Restart/undo don't refund either. Mistakes: beginner/easy/medium = wrong digit (vs solution), hard/expert/master = rule break (`Session.RULE_BREAK_LEVELS`). Reaching the limit loses the puzzle (Try again / New puzzle). Restart can't be undone and keeps the mistake count. The ? button opens a clickable shortcuts panel (Esc or click outside closes). |
| Multiplayer (2026-10-20) | 1v1 race over **Steam lobbies**: nav "Multiplayer" → room list (auto-refresh), Create room dialog (mode = any of the 42 or Random, difficulty, optional password), password prompt on join. Same pack puzzle for both, side by side; the opponent panel shows only *which* cells are filled (no digits) + %, with their rule-breaking cells in red; when the race ends both grids are revealed ("grid" message). Given digits are always visible on the opponent grid. Chat (room view + beside the race board, `ChatPanel`, shared `Net.chat_log`) with a frame-drum "tek-tek" sound on incoming messages. Pure vanilla: no hints, checks, pause, restart or mistake limit; only rule conflicts are marked (never solution mismatches). 3-2-1 countdown with the board hidden. The host decides the winner (first "finished" to reach the host). Leaving mid-race = forfeit. After a race: the loser can Keep solving (result unchanged) or go to Main menu (leaves the room); both press **Play again** to start the next race (host starts it when both are ready); a per-room score (`Net.score`) shows on the result card, above the opponent grid and in the room view. The room belongs to the host: if the host leaves, the guest is taken out too (`Net.room_closed`) and sent to the room list; mid-race nobody is kicked: the one who stays just wins ("Your opponent left the match"). Quitting/closing the game leaves the room immediately (`Net._notification`). Clicking the board takes keyboard focus back from the chat. Wins/losses in stats.multiplayer. The Mode picker is a searchable drop-down. Steam is re-checked when the screen opens and on Refresh (`SteamManager.try_init`, `Net.recheck_steam`), and a banner says why Steam isn't used: plugin missing / Steam not running / couldn't connect. Two windows on one Steam account can't play each other (joining your own lobby closes it), so own rooms show "YOUR ROOM" with Join disabled; editor builds have a **Test mode** switch (`settings.mp_test_mode`) that forces the local two-window backend. |
| Delivery | Files go straight into the user's folder (not zips in chat). |
| Notes input (2nd request) | Copy the user's reference app (SudokuPad-style). **Hold Shift** = corner marks, each digit in a fixed keypad spot (1 2 3 / 4 5 6 / 7 8 9; the user asked for this over SudokuPad's fill order). **Hold Ctrl** = centre marks (in one row; when a cell also has corner marks they shrink/wrap between the 4 and 6 spots and corner 5 moves to the top row so nothing overlaps). **Hold Ctrl+Shift** = colour mode. This applies to keyboard digits *and* clicks on the on-screen pad. Pencil marks are coloured blue (possible) / red (already placed in a unit). Cells can be coloured (9-colour palette, several colours shown as stripes). |

## Design tokens (from the site's CSS `:root`)
paper `#f8f7f2`, paper-warm `#f2f0e8`, ink `#0e0e12`, ink-muted `#5a5a6e`, ink-faint `#9898aa`,
accent `#2a4fff`, accent-soft `#e8edff`, gold `#e8a020`, gold-soft `#fff8ea`, radius 14px.
Fonts: DM Serif Display (headings) and DM Sans variable (body). Both are in `fonts/` (OFL).
All of this lives in `scripts/autoload/ui_theme.gd` (autoload `UI`).

## Architecture
```
scenes/main.tscn → scripts/ui/main.gd     nav bar + screen router + toast (GameState.go(screen, params))
scripts/autoload/ui_theme.gd   (UI)        palette, fonts, Theme (type variations: PrimaryButton, NavButton,
                                           ChipButton, PadButton), helpers label/heading/button/tag/page/toast,
                                           CELL_COLORS, NOTE_OK/NOTE_BAD
scripts/autoload/game_state.gd (GameState) settings/stats/saves as JSON in user://, packs, daily_info(), record_solve()
scripts/autoload/net.gd        (Net)       1v1 rooms + messages. Backend "steam" (lobbies tagged lw=1/ver/state; messages = lobby chat
                                           JSON; password checked by the host via sha256(room id:pw)) or, in debug builds without
                                           Steam, "local" (rooms = files in user://mp_local/, UDP on 127.0.0.1) to test with two
                                           game windows on one PC. Messages: hello/welcome/deny/start/prog/done/result/ping/bye.
scripts/ui/multiplayer_screen.gd           room list, create/password dialogs, room view (Start match for the host).
                                           game_screen.gd params {"versus": start msg} = race mode (_setup_versus etc.).
scripts/autoload/steam_manager.gd          optional GodotSteam via Engine.get_singleton("Steam"); APP_ID=480 placeholder;
                                           12 achievement API names; on_solve() unlock logic
scripts/core/variants.gd   (Variants)      catalog of 42 variants; CORE = playable ids; rules/tips for core
scripts/core/puzzle.gd     (Puzzle)        data model + JSON format (documented in the file header)
scripts/core/solver.gd     (Solver)        bitmask backtracking + MRV. "Units" (rows/cols/regions/diagonals/cages)
                                           + extra_ok() for thermo/arrow/cage-sum/edge (kropki, xv, negative constraint),
                                           parity masks (even_odd), lines (_line_ok: gw German Whispers, rb Renban) and
                                           clue-less global rules from the variant id (non_consecutive, king, knight).
                                           Later: more line types (dw/pal/bt/lo/st/bi/rf/zp), outside clues (_outer_ok:
                                           sandwich/skyscraper/x-sum/ascending/running), little-killer sums, quads, cell
                                           marks (axia/friendly/pulse/index), vertices, slingshots, edge codes c/>/</s/d,
                                           extra units (universal, windoku), flatmates and twisted (twist_gen while
                                           generating the solution). Board adds an outside margin when outer/sums exist.
                                           Also find_conflicts() for the UI. count_solutions(g, limit, node_limit) → -1 if aborted.
scripts/core/generator.gd  (Generator)     Generator.make(variant, difficulty, seed): solved grid → derive constraints →
                                           symmetric given removal while unique. TARGETS per variant/difficulty.
scripts/core/session.gd    (Session)       values/corner/center/colors/hinted, snapshot undo/redo, input_digit(cells,d,mode)
                                           mode ∈ normal|corner|center|color, layered erase(cells, mode), hint, note_possible().
scripts/ui/board.gd        (Board)         custom _draw of the grid and all overlays (cages with dashed inset outlines,
                                           thermos, arrows, dots, X/V, diagonals, colours, notes), mouse selection
                                           (drag, ctrl/shift add, double-click same digit), celebrate/flash.
scripts/ui/game_screen.gd                  play screen; _effective_mode() reads held Shift/Ctrl each frame and lights the
                                           mode chip; pad turns into colour swatches in colour mode; generator runs in a Thread.
scripts/ui/{home,variant,stats,settings}_screen.gd, variant_icon.gd (vector icons per variant id)
tools/build_packs.gd   top up packs, keeping existing/hand-made puzzles: `-- 500` (all), or `-- part <v> <d> 500` per
                       combo in parallel then `-- merge`. Resumable; hard killer/kropki/xv take ~25 min each.
scripts/core/daily.gd      (Daily)         daily schedule: UTC date (same day for everyone), always hard (never labelled), variant
                                           rotating through all 42 (shuffled per cycle). Puzzles pre-built in puzzles/daily.json
                                           (2026-01-01 … 2031-12-31, 6 years) so every player gets the same one and generator
                                           changes never alter a day; after the last day it starts again from the first.
tools/build_daily.gd   extend daily.json: `-- part <YYYY-MM-DD> <days>` (parallel-safe, resumable) then `-- merge`
                       (existing days are kept as they are).
tools/build_examples.gd  rebuild puzzles/examples.json (one solved-example puzzle per variant for the rules ⓘ); rerun after adding a variant.
tools/shots.tscn       dev screenshot harness → user://shots/*.png (needs a display / xvfb)
```
Saves: slot keys are `"<variant>:<difficulty>"` or `"daily:YYYY-MM-DD"`. Pack puzzle ids start with `pack-`.
Dark mode: colours in `UI` are vars filled from the LIGHT/DARK palettes. `UI.set_dark()` rebuilds the Theme in place and
emits `palette_changed`, and Main then rebuilds the nav and re-opens the current screen. Use UI colour vars, not hard-coded
colours. The nav "Continue" button resumes `GameState.last_unfinished()`; each save is stamped with `saved_at`.
New games: `GameState.new_game_params(v, d)` picks a random unsolved pack puzzle, always different from the last one.
One game per slot: an unfinished game in that slot is simply replaced (the user asked to drop the old "unfinished"
list); "Continue" always resumes the latest. The generator is only used after the whole pack is solved.

## Gotchas found while building
- GDScript `:=` can't infer types from untyped Array/Dictionary elements. Use explicit types (`var h: float = arr[i]`).
- An autowrap Label with `max_lines_visible` collapses to 1px height. Give it a custom_minimum_size.y.
- The theme must be set on Main (`theme = UI.theme`) as well as on root, or it won't apply when Main is under a plain Node.
- `-s` SceneTree scripts can't see autoload identifiers at compile time, so test UI by running scenes.
- Windows reports Shift+numpad as nav keys, so game_screen also checks `physical_keycode` for KP_1..9.
- Generator timings in GDScript: the slowest is xv hard at about 3 s. It runs in a thread with a "Generating…" overlay.
- Non-consecutive full solutions are hard to find by random search (heavy-tailed: 0.3–15 s), so the generator gives it
  many short tries (`Generator.SOLVE_NODES` / `ATTEMPTS`); a puzzle takes ~5 s (max ~13 s).
- New clue types go in `Puzzle` (`parity`, `lines` = [{t, cells}]) + `Solver._build_new_rules/_line_ok` +
  `Generator._make_*` + `Board._draw`. Line type codes are kept short in JSON (gw, rb, …).

## How it was verified
- Headless: generator bench (all 24 variant/difficulty combos unique), Session unit checks (notes, undo/redo,
  hint, save/load round-trip, solve detection).
- Rendering: `xvfb-run godot --rendering-driver opengl3 --path . res://tools/shots.tscn` on 4.4.1 and **4.7.2**.
  All screens render, including the daily flow (threaded generation), resume and the win dialog.
- **Not yet verified by the user on Windows** after the latest update (Shift/Ctrl/colour). Ask them how it went.

## Open items / suggested next steps
1. Ask the user to confirm the Shift/Ctrl/colour behaviour matches their reference app. They wanted Claude to
   inspect their Chrome tab, but the Claude in Chrome extension wasn't connected, so it was copied from screenshots.
2. Unanswered questions to the user: final Steam title (keep "Logic Wiz"?), real Steam App ID (currently 480 in
   `steam_appid.txt` + `SteamManager.APP_ID`), and which feature to build next.
3. All 42 variants are playable. Adding a new rule: Variants.CORE + rules → Puzzle field (to_dict/from_dict) →
   Solver._build_new_rules / extra_ok → Generator._attempt + TARGETS → Board._draw / _draw_extra_clues → build packs.
4. Difficulty is currently graded by the number of givens. A technique-based grader would be better.
5. Polish: sounds, gamepad/Steam Deck input, cloud saves, leaderboards, Steam store assets.
6. GodotSteam GDExtension 4.23 (Codeberg release v4.23-gde) is installed in addons/godotsteam (2026-10-20). Verified on
   the user's PC: Steam init OK (app 480), lobby create + list work. A real 2-player Steam match still needs two PCs with
   two Steam accounts (one account per PC). The local test backend was verified end to end.
7. Steam: install the GodotSteam GDExtension from AssetLib into `addons/`, create the achievements in Steamworks with the
   API names in steam_manager.gd, export Windows Desktop (preset exists, excludes `tools/` and `docs/`), and don't ship
   steam_appid.txt.

## Working with this user
- Uses Windows, timezone Asia/Amman. Fairly new to Godot (ran the exe from inside the project folder), so give
  click-by-click steps.
- Likes concise replies. Wants suggestions offered and questions asked rather than assumptions.
