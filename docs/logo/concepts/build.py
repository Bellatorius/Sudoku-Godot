"""Build Sudoku Variants logo concepts (symbols + horizontal lockups) as SVG.
Usage: python build.py <font.ttf> <out_dir> <version>"""
import sys, os
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

FONT, OUT, VER = sys.argv[1], sys.argv[2], sys.argv[3]
INK = "#0e0e12"
os.makedirs(OUT, exist_ok=True)
font = TTFont(FONT)
gs = font.getGlyphSet()
cmap = font.getBestCmap()
upm = font["head"].unitsPerEm
kern = {}
# DM Serif kerning lives in GPOS; plain advances + manual tracking are good enough for concepts.


def text_path(text, size, x, baseline, tracking=0):
    s = size / upm
    pen = SVGPathPen(gs)
    for ch in text:
        g = cmap[ord(ch)]
        tp = TransformPen(pen, (s, 0, 0, -s, x, baseline))
        gs[g].draw(tp)
        x += gs[g].width * s + tracking
    return pen.getCommands(), x


def svg(view_w, body, title):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {view_w} 256" width="{view_w}" height="256" '
            f'role="img" aria-labelledby="t"><title id="t">{title}</title>\n{body}\n</svg>\n')


def rr(x, y, w, h, r):
    """Rounded rect as path (clockwise)."""
    return (f"M{x+r} {y}H{x+w-r}A{r} {r} 0 0 1 {x+w} {y+r}V{y+h-r}A{r} {r} 0 0 1 {x+w-r} {y+h}"
            f"H{x+r}A{r} {r} 0 0 1 {x} {y+h-r}V{y+r}A{r} {r} 0 0 1 {x+r} {y}Z")


# A — S-Thermo: a sudoku thermometer that writes an S through the 3x3 cell centres.
# Centres 72/128/184 (56 grid), stroke 34, corner radius 28 (= half the run, so turns are full semicircles),
# bulb r=38 at the start (top right), whole mark nudged left so the bulb doesn't pull it off-centre.
def sym_a():
    l, r, t, m, b, k = 72, 176, 72, 128, 184, 22
    d = (f"M{r} {t}H{l+k}A{k} {k} 0 0 0 {l} {t+k}V{m-k}A{k} {k} 0 0 0 {l+k} {m}"
         f"H{r-k}A{k} {k} 0 0 1 {r} {m+k}V{b-k}A{k} {k} 0 0 1 {r-k} {b}H{l}")
    # optical centring: the bulb pulls the mass up and right
    return (f'<g transform="translate(128 128) scale(1.12) translate(-135 -118)"><path d="{d}" fill="none" stroke="{INK}" stroke-width="32" '
            f'stroke-linecap="round" stroke-linejoin="round"/><circle cx="{r}" cy="{t}" r="38" fill="{INK}"/></g>')


# B — Twist: a 3x3 block of cells; the centre cell is turned 45 degrees (the variant rule).
def sym_b(accent=INK):
    c, g, o, r = 56, 14, 30, 12
    parts = []
    for row in range(3):
        for col in range(3):
            if row == col == 1:
                continue
            parts.append(rr(o + col * (c + g), o + row * (c + g), c, c, r))
    body = f'<path d="{"".join(parts)}" fill="{INK}"/>'
    # centre diamond: same 56 cell rotated 45deg about (128,128), slightly smaller (50) so the tips keep a gap.
    s = 50
    body += (f'<rect x="{128 - s/2}" y="{128 - s/2}" width="{s}" height="{s}" rx="{r - 2}" '
             f'transform="rotate(45 128 128)" fill="{accent}"/>')
    return body


# C — Regions: a bold frame whose inner box border steps like a jigsaw region; thin cell lines underneath.
def sym_c():
    lo, hi = 34, 222
    q0, q1 = 66, 190
    nine, _ = text_path("9", 92, 54, 130)
    dash = f"M120 {q0}H{q1}V{q1}H{q0}V146"
    return (f'<path d="{rr(lo, lo, hi - lo, hi - lo, 30)}" fill="none" stroke="{INK}" stroke-width="20"/>'
            f'<path d="{dash}" fill="none" stroke="{INK}" stroke-width="10" stroke-linecap="round" '
            f'stroke-linejoin="round" stroke-dasharray="14 14"/>'
            f'<path d="{nine}" fill="{INK}"/>')


def lockup(sym_body):
    l1, x1 = text_path("Sudoku", 118, 292, 120, 1)
    l2, x2 = text_path("Variants", 118, 292, 230, 1)
    w = int(max(x1, x2) + 16)
    return svg(w, f'{sym_body}<path d="{l1}{l2}" fill="{INK}"/>', "Sudoku Variants logo")


for k, f in (("a", sym_a), ("b", sym_b), ("c", sym_c)):
    open(f"{OUT}/{k}-symbol-{VER}.svg", "w").write(svg(256, f(), "Sudoku Variants symbol"))
    open(f"{OUT}/{k}-lockup-{VER}.svg", "w").write(lockup(f()))
print("ok")
