# Claude Code instructions

Read the handover before starting work:

@HANDOVER.md

- Godot 4.7.2 project (GDScript). The editor is at ../Godot/Godot_v4.7.2-stable_win64.exe; keep it outside this folder.
- After changing generator or solver logic, rebuild the packs: `godot --headless -s tools/build_packs.gd -- 500` (keeps existing puzzles; delete `puzzles/<variant>.json` first to regenerate one variant from scratch)
