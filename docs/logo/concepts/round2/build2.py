"""Round 2: six more Sudoku Variants logo concepts (D-I), symbols + horizontal lockups.
Usage: python build2.py <font.ttf> <out_dir> <version>"""
import sys, os, math
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.boundsPen import BoundsPen

FONT, OUT, VER = sys.argv[1], sys.argv[2], sys.argv[3]
INK, PAPER = "#0e0e12", "#ffffff"
os.makedirs(OUT, exist_ok=True)
font = TTFont(FONT)
gs = font.getGlyphSet()
cmap = font.getBestCmap()
upm = font["head"].unitsPerEm


def text_path(text, size, x, baseline, tracking=0):
    s = size / upm
    pen = SVGPathPen(gs)
    for ch in text:
        g = cmap[ord(ch)]
        gs[g].draw(TransformPen(pen, (s, 0, 0, -s, x, baseline)))
        x += gs[g].width * s + tracking
    return pen.getCommands(), x


def glyph_centred(ch, size, cx, cy):
    """One glyph, its ink box centred on (cx, cy)."""
    s = size / upm
    bp = BoundsPen(gs)
    gs[cmap[ord(ch)]].draw(bp)
    x0, y0, x1, y1 = bp.bounds
    return text_path(ch, size, cx - (x0 + x1) / 2 * s, cy + (y0 + y1) / 2 * s)[0]


def svg(view_w, body, title):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {view_w} 256" width="{view_w}" height="256" '
            f'role="img" aria-labelledby="t"><title id="t">{title}</title>\n{body}\n</svg>\n')


def rr(x, y, w, h, r):
    if r <= 0:
        return f"M{x} {y}H{x+w}V{y+h}H{x}Z"
    return (f"M{x+r} {y}H{x+w-r}A{r} {r} 0 0 1 {x+w} {y+r}V{y+h-r}A{r} {r} 0 0 1 {x+w-r} {y+h}"
            f"H{x+r}A{r} {r} 0 0 1 {x} {y+h-r}V{y+r}A{r} {r} 0 0 1 {x+r} {y}Z")


def frame(sw=20, lo=34, hi=222, r=30):
    return f'<path d="{rr(lo, lo, hi - lo, hi - lo, r)}" fill="none" stroke="{INK}" stroke-width="{sw}"/>'


# D — V-Clue: two cells; the serif V of "Variants" sits on their shared border like an XV-sudoku clue.
def sym_d():
    v = glyph_centred("V", 128, 128, 128)
    return (frame() + f'<path d="M128 34V66M128 190V222" stroke="{INK}" stroke-width="12"/>'
            f'<path d="{v}" fill="{INK}"/>')


# E — Candidates: a cell of nine pencil-mark dots; the 9 spot has grown into the answer.
def sym_e():
    body = frame(18)
    for r in range(3):
        for c in range(3):
            x, y = 84 + c * 44, 84 + r * 44
            body += f'<circle cx="{x}" cy="{y}" r="{24 if (r, c) == (2, 2) else 9}" fill="{INK}"/>'
    return body


# F — Nine Rules: nine different clue marks in a 3x3 block, one per variant family.
def sym_f():
    p, s = [], 50
    cx = [56, 128, 200]
    def at(i): return cx[i % 3], cx[i // 3]
    x, y = at(0); p.append(f'<circle cx="{x}" cy="{y}" r="{s/2}" fill="{INK}"/>')                      # kropki dot
    x, y = at(1); p.append(f'<path d="{rr(x-s/2, y-s/2, s, s, 10)}" fill="{INK}"/>')                    # given cell
    x, y = at(2); p.append(f'<circle cx="{x}" cy="{y}" r="{s/2-6}" fill="none" stroke="{INK}" stroke-width="12"/>')  # arrow circle
    x, y = at(3); p.append(f'<path d="M{x-25} {y-21.65}L{x} {y+21.65}L{x+25} {y-21.65}" fill="none" stroke="{INK}" stroke-width="13" stroke-linecap="round" stroke-linejoin="round"/>')  # V
    x, y = at(4); d = s/2 + 4; p.append(f'<path d="M{x} {y-d}L{x+d} {y}L{x} {y+d}L{x-d} {y}Z" fill="{INK}"/>')  # diamond
    x, y = at(5); p.append(f'<path d="M{x-25} {y+25}A50 50 0 0 1 {x+25} {y-25}" fill="none" stroke="{INK}" stroke-width="13" stroke-linecap="round"/>')  # line
    x, y = at(6); p.append(f'<circle cx="{x-8}" cy="{y+8}" r="16" fill="{INK}"/><path d="M{x-8} {y+8}L{x+20} {y-20}" stroke="{INK}" stroke-width="13" stroke-linecap="round"/>')  # thermo
    x, y = at(7); p.append(f'<path d="M{x} {y-23}L{x+26} {y+22.03}H{x-26}Z" fill="{INK}" stroke="{INK}" stroke-width="6" stroke-linejoin="round"/>')  # triangle
    x, y = at(8); p.append(f'<path d="{rr(x-s/2+5, y-s/2+5, s-10, s-10, 6)}" fill="none" stroke="{INK}" stroke-width="7" stroke-dasharray="9 7"/>')  # cage
    return "".join(p)


# G — Nine-Cell: a 9 whose head is a sudoku cell (rounded square bowl) with a serif ball terminal.
def sym_g():
    # bowl 104x100 (stroke 30, corner 30); the tail continues the bowl's right side (x=178) down and left.
    sw = 30
    bowl = rr(74, 38, 104, 100, 30)
    tail = "M178 110V178A44 44 0 0 1 134 222H114"
    return (f'<g transform="translate(-4 -7)"><path d="{bowl}" fill="none" stroke="{INK}" stroke-width="{sw}"/>'
            f'<path d="{tail}" fill="none" stroke="{INK}" stroke-width="{sw}"/>'
            f'<circle cx="104" cy="214" r="23" fill="{INK}"/></g>')


# H — Morph: nine cells that turn from square to circle; one cell, nine variations.
def sym_h():
    c, g, o = 56, 14, 30
    parts = [rr(o + col * (c + g), o + row * (c + g), c, c, 7 * (row + col)) for row in range(3) for col in range(3)]
    return f'<path d="{"".join(parts)}" fill="{INK}"/>'


# I — Given S: one sudoku cell holding a serif S as its given digit, with pencil marks in three corners.
def sym_i():
    s = glyph_centred("S", 150, 128, 132)
    dots = "".join(f'<circle cx="{x}" cy="{y}" r="8" fill="{INK}"/>' for x, y in ((68, 68), (188, 68), (68, 188)))
    return frame() + f'<path d="{s}" fill="{INK}"/>' + dots


def lockup(sym_body):
    l1, x1 = text_path("Sudoku", 118, 292, 120, 1)
    l2, x2 = text_path("Variants", 118, 292, 230, 1)
    w = int(max(x1, x2) + 16)
    return svg(w, f'{sym_body}<path d="{l1}{l2}" fill="{INK}"/>', "Sudoku Variants logo")


for k, f in (("d", sym_d), ("e", sym_e), ("f", sym_f), ("g", sym_g), ("h", sym_h), ("i", sym_i)):
    open(f"{OUT}/{k}-symbol-{VER}.svg", "w").write(svg(256, f(), "Sudoku Variants symbol"))
    open(f"{OUT}/{k}-lockup-{VER}.svg", "w").write(lockup(f()))
print("ok")
