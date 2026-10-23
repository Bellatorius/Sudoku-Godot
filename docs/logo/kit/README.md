# Sudoku Variants – logo kit (Nine Smile)

A face in a sudoku cell: the left eye is a dot, **the right eye is a 9 and its tail is the smile**.
Rules for using it: `Sudoku-Variants-logo-guide.pdf` (one page).

## Folders
| Folder | What | Use it for |
|---|---|---|
| `master/` | Symbols as SVG: `face` (no cell), `cell` (one colour), `tile-blue` (primary icon), `tile-ink`, `tile-gold`, `16px-*` (pixel cut), `face-black/white/mono-2a4fff` | Any new artwork |
| `lockups/` | `horizontal`, `oneline`, `stacked`, `stacked-2line`, `wordmark`, each in `color` (light bg), `reversed` (dark bg), `black`, `white` | Title screen, store page, website |
| `png/` | The masters at 64/256/512/1024 px and every lockup at 1200 px wide | Tools that need pixels |
| `godot/` | `icon.svg` (project icon), `icon-blue.ico` / `icon-ink.ico` (Windows export, 16–256 px), `icon-128.png` | The game itself |
| `steam/` | Header, small, main, vertical and library capsules, library hero + logo, community icon (SVG + PNG at exact size), `client-icon-32.ico`, `shortcut-icon-256.ico` | Steamworks store + library |
| `web/` | `favicon.ico/.svg`, 16/32 px PNGs, apple-touch icon, 192/512/maskable icons, `site.webmanifest`, `head-snippet.html` | A website later |
| `board/` | Presentation (`presentation.html`, `slides/*.png`) with mockups | Showing the logo to others |
| `source/` | The Python scripts that drew everything (`kit.py`, `kit_raster.py`, `guide.py`) | Rebuilding after a change |

## Notes
- All logo shapes are filled outlines (no strokes, no live text). The wordmark is DM Serif Display, outlined (OFL licence).
- The smile outline is an offset of the original stroke built from ellipses: exact enough on screen and in print. A vector
  editor's *Outline Stroke + Unite* would give a mathematically exact offset if a printer or cutter ever needs it.
- 16 px uses a hand-drawn pixel version (`master/nine-smile-16px-*.svg`); the `.ico` files already contain it.
- The icon tiles paint the face white on blue/ink: that's the full-colour version. For one colour use the `cell` files.
- Steam image sizes follow Steam's current (2×) guidelines as of 2026: check them in Steamworks when you upload, as Valve
  changes them from time to time. The library hero has no text or logo on purpose (Steam's rule).
- CMYK values in the guide are converted from RGB; ask the printer for a proof. No Pantone match was made.
- Not done: trademark search for the name and mark (recommended before launch).
