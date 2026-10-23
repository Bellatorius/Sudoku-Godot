"""One-page usage guide (HTML, printed to PDF by Chrome) for the Nine Smile kit. Usage: python guide.py <kit_dir>"""
import sys

K = sys.argv[1]
COLS = [("Ink", "#0e0e12", "Wordmark, one-colour logo, dark backgrounds"),
        ("Paper", "#f8f7f2", "Light backgrounds (the game's page colour)"),
        ("Sudoku Blue", "#2a4fff", "Primary: the icon tile, Steam art"),
        ("Gold", "#e8a020", "Accent only: highlights, badges; never the main logo")]


def cmyk(h):
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))
    k = 1 - max(r, g, b)
    if k >= 1:
        return "0 0 0 100"
    c, m, y = ((1 - v - k) / (1 - k) for v in (r, g, b))
    return " ".join(str(round(v * 100)) for v in (c, m, y, k))


def rgb(h):
    return ", ".join(str(int(h[i:i + 2], 16)) for i in (1, 3, 5))


swatches = "".join(
    f'<div class="sw"><div class="chip" style="background:{h};{"border:1px solid #ddd;" if n == "Paper" else ""}"></div>'
    f'<b>{n}</b><span>HEX {h}<br>RGB {rgb(h)}<br>CMYK {cmyk(h)}</span><i>{u}</i></div>' for n, h, u in COLS)

html = f"""<!doctype html><html><head><meta charset="utf-8"><title>Sudoku Variants - logo guide</title><style>
@page {{ size: A4 portrait; margin: 0; }}
* {{ box-sizing: border-box; }}
body {{ margin: 0; font-family: 'DM Sans', 'Segoe UI', Arial, sans-serif; color: #0e0e12; font-size: 8.6pt; line-height: 1.38; }}
.page {{ width: 210mm; height: 297mm; padding: 11mm 13mm; background: #fff; }}
h1 {{ font-family: 'DM Serif Display', Georgia, serif; font-weight: 400; font-size: 25pt; margin: 0; }}
h2 {{ font-size: 9.6pt; text-transform: uppercase; letter-spacing: .08em; margin: 0 0 2mm; color: #2a4fff; }}
.sub {{ color: #5a5a6e; margin: 1mm 0 4mm; font-size: 10pt; }}
.grid {{ column-count: 2; column-gap: 7mm; }}
.box {{ break-inside: avoid; margin-bottom: 4mm; }}
.full {{ }}
.sws {{ display: grid; grid-template-columns: 1fr 1fr; gap: 0 3mm; }}
.row {{ display: flex; gap: 3mm; align-items: center; flex-wrap: wrap; }}
.tile {{ background: #f8f7f2; border-radius: 3mm; padding: 3mm; display: flex; align-items: center; justify-content: center; }}
.dark {{ background: #0e0e12; }} .blue {{ background: #2a4fff; }}
.cap {{ font-size: 7.4pt; color: #5a5a6e; text-align: center; margin-top: 1mm; }}
.sw {{ display: grid; grid-template-columns: 9mm 1fr; grid-template-rows: auto auto auto; column-gap: 2.5mm; margin-bottom: 2mm; }}
.sw .chip {{ grid-row: 1 / 4; width: 9mm; height: 9mm; border-radius: 2mm; }}
.sw span {{ color: #5a5a6e; font-size: 7.4pt; }} .sw i {{ font-size: 7.4pt; color: #0e0e12; }}
table {{ border-collapse: collapse; width: 100%; }} td, th {{ padding: 1mm 1.5mm; border-bottom: 1px solid #e6e4dc; text-align: left; }}
th {{ color: #5a5a6e; font-weight: 600; }}
ul {{ margin: 0; padding-left: 4mm; }} li {{ margin: .4mm 0; }}
.dont {{ display: grid; grid-template-columns: repeat(6, 1fr); gap: 2mm; }}
.dont div {{ text-align: center; font-size: 7pt; color: #5a5a6e; }}
.dont img {{ width: 15mm; height: 15mm; }}
.x {{ color: #d0342c; font-weight: 700; }}
code {{ font-size: 7.4pt; background: #f2f0e8; padding: 0 1mm; border-radius: 1mm; }}
</style></head><body><div class="page">
<h1>Sudoku Variants</h1>
<div class="sub">Logo guide · the Nine Smile · v1.0</div>
<div class="grid">
<div class="box"><h2>The idea</h2>
A face in a sudoku cell. The left eye is a kropki-style dot; <b>the right eye is a 9, and the 9's tail is the smile</b>.
Friendly at a glance, clever on a second look: 9 is the number every sudoku is built on.</div>
<div class="box"><h2>Versions</h2>
<div class="row"><div><div class="tile"><img src="lockups/sudoku-variants-horizontal-color.svg" style="height:13mm"></div><div class="cap">Primary: horizontal</div></div>
<div><div class="tile"><img src="lockups/sudoku-variants-stacked-2line-color.svg" style="height:15mm"></div><div class="cap">Stacked</div></div>
<div><div class="tile"><img src="master/nine-smile-tile-blue.svg" style="height:13mm"></div><div class="cap">Icon</div></div></div></div>

<div class="box"><h2>Colour versions</h2>
<div class="row">
<div><div class="tile"><img src="lockups/sudoku-variants-horizontal-color.svg" style="height:10mm"></div><div class="cap">Full colour on light</div></div>
<div><div class="tile dark"><img src="lockups/sudoku-variants-horizontal-reversed.svg" style="height:10mm"></div><div class="cap">Full colour on dark</div></div>
<div><div class="tile"><img src="lockups/sudoku-variants-horizontal-black.svg" style="height:10mm"></div><div class="cap">One colour (black)</div></div>
<div><div class="tile blue"><img src="lockups/sudoku-variants-horizontal-white.svg" style="height:10mm"></div><div class="cap">One colour (white)</div></div>
</div>
<p style="margin:2mm 0 0">In one colour the blue tile becomes an outlined cell, so the face always sits in a cell.</p></div>

<div class="box"><h2>Colours</h2><div class="sws">{swatches}</div>
<div style="font-size:7.2pt;color:#5a5a6e">CMYK values are converted from RGB: proof before printing. Match Pantone with a swatch book.</div></div>

<div class="box"><h2>Clear space and minimum size</h2>
<div class="row" style="align-items:flex-start"><div class="tile" style="padding:5mm;border:1px dashed #2a4fff"><img src="lockups/sudoku-variants-horizontal-color.svg" style="height:11mm"></div>
<div style="flex:1;min-width:40mm">Keep clear space of <b>one eye</b> (the diameter of the left eye dot) on every side, at any size.</div></div>
<table style="margin-top:2mm"><tr><th>Version</th><th>Screen</th><th>Print</th></tr>
<tr><td>Horizontal lockup</td><td>120 px wide</td><td>30 mm wide</td></tr>
<tr><td>Stacked lockup</td><td>80 px wide</td><td>20 mm wide</td></tr>
<tr><td>Icon / symbol</td><td>16 px: use the <b>16 px pixel file</b></td><td>6 mm</td></tr></table></div>

<div class="box"><h2>Small sizes</h2>
<div class="row"><div><div class="tile"><img src="master/nine-smile-16px-blue.svg" style="height:16mm;image-rendering:pixelated"></div><div class="cap">16 px cut (enlarged)</div></div>
<div><div class="tile"><img src="master/nine-smile-tile-blue.svg" style="height:16mm"></div><div class="cap">32 px and up</div></div></div>
<p style="margin:2mm 0 0">At 16 px the vector 9 fills in, so a hand-drawn pixel version is used. The <code>.ico</code> files already
combine both: pixel art at 16 px, vector from 24 px up.</p></div>

<div class="box"><h2>Typography</h2>
<ul><li><b>Logo and headings:</b> DM Serif Display (the wordmark is drawn from it and outlined; never retype it).</li>
<li><b>Body and UI:</b> DM Sans.</li><li>Both are free under the SIL Open Font License (in the game's <code>fonts/</code>).</li></ul></div>

<div class="box"><h2>Do</h2>
<ul><li>Use the files as they are; scale them evenly.</li><li>Use the blue tile as the game, Steam and Windows icon.</li>
<li>On photos or busy art, use the tile icon or put the logo on a calm area.</li><li>Keep gold as an accent, never the main logo colour.</li></ul></div>

</div><div class="box full"><h2>Don't</h2><div class="dont">
<div><img src="master/nine-smile-tile-blue.svg" style="transform:scaleX(1.4)"><br><span class="x">✕</span> stretch</div>
<div><img src="master/nine-smile-tile-blue.svg" style="transform:rotate(18deg)"><br><span class="x">✕</span> rotate</div>
<div><img src="master/nine-smile-tile-blue.svg" style="filter:hue-rotate(120deg)"><br><span class="x">✕</span> recolour</div>
<div><img src="master/nine-smile-tile-blue.svg" style="filter:drop-shadow(2mm 2mm 1mm rgba(0,0,0,.6))"><br><span class="x">✕</span> add effects</div>
<div><img src="master/nine-smile-face.svg" style="transform:scaleX(-1)"><br><span class="x">✕</span> mirror (the 9 must stay a 9)</div>
<div><img src="master/nine-smile-tile-gold.svg"><br><span class="x">✕</span> gold as the main icon</div>
</div></div>

<div class="box full"><h2>Files</h2>
<code>master/</code> symbols (SVG) · <code>lockups/</code> horizontal, one-line, stacked, wordmark · <code>png/</code> ready-made PNGs ·
<code>godot/</code> <code>icon.svg</code> + Windows <code>.ico</code> · <code>steam/</code> store and library images + client/shortcut icons ·
<code>web/</code> favicon set · <code>board/</code> presentation. SVG for screens and print, PNG when a tool needs pixels.</div>
</div></body></html>"""
open(f"{K}/guide.html", "w", encoding="utf-8").write(html)
print("guide.html written")
