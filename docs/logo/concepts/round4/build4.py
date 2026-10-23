"""Round 4: twelve more Sudoku Variants logo concepts (P1-P12).
Usage: python build4.py <DMSerif.ttf> <out_dir> <version> <DMSans-Variable.ttf>"""
import math
from common import *  # noqa: F401,F403
from fontTools.ttLib import TTFont as _TT
from fontTools.varLib import instancer
from fontTools.pens.svgPathPen import SVGPathPen as _Pen
from fontTools.pens.transformPen import TransformPen as _TP
from fontTools.pens.boundsPen import BoundsPen as _BP

sans = instancer.instantiateVariableFont(_TT(sys.argv[4]), {"wght": 700, "opsz": 40})
sgs, scmap, supm = sans.getGlyphSet(), sans.getBestCmap(), sans["head"].unitsPerEm


def sans_path(text, size, x, baseline, tracking=0, skip_i_dot=False):
    s = size / supm
    pen = _Pen(sgs)
    marks = []
    for ch in text:
        g = scmap[ord(ch)]
        if ch == "i" and skip_i_dot:
            g = scmap.get(0x131, g)          # dotless i, dot drawn separately
            marks.append((x + sgs[g].width * s / 2, s))
        sgs[g].draw(_TP(pen, (s, 0, 0, -s, x, baseline)))
        x += sgs[g].width * s + tracking
    return pen.getCommands(), x, marks


def tiles(c, g, o, r, skip=()):
    return "".join(rr(o + col * (c + g), o + row * (c + g), c, c, r)
                   for row in range(3) for col in range(3) if (row, col) not in skip)


def word2():
    l1, x1 = text_path("Sudoku", 118, 292, 120, 1)
    l2, x2 = text_path("Variants", 118, 292, 230, 1)
    return f'<path d="{l1}{l2}" fill="{INK}"/>', max(x1, x2)


# P1 Even & Odd: the even/odd variant's squares and circles in a checkerboard.
def p1():
    c, g, o = 56, 14, 30
    body = ""
    for row in range(3):
        for col in range(3):
            x, y = o + col * (c + g), o + row * (c + g)
            if (row + col) % 2 == 0:
                body += f'<circle cx="{x + c/2}" cy="{y + c/2}" r="{c/2}" fill="{INK}"/>'
            else:
                body += f'<path d="{rr(x, y, c, c, 8)}" fill="{INK}"/>'
    return body


# P2 Sandwich: solid outer columns hold an open middle column: the sandwich, and what you solve is in between.
def p2():
    c, g, o = 56, 14, 30
    solid = "".join(rr(o + col * (c + g), o + row * (c + g), c, c, 12) for row in range(3) for col in (0, 2))
    hollow = "".join(rr(o + (c + g) + 6, o + row * (c + g) + 6, c - 12, c - 12, 8) for row in range(3))
    return (f'<path d="{solid}" fill="{INK}"/>'
            f'<path d="{hollow}" fill="none" stroke="{INK}" stroke-width="12"/>')


# P3 Kropki Cat: a cat's head whose eyes are a white and a black kropki dot (mascot).
def p3():
    head = rr(44, 92, 168, 128, 44)
    ears = "M56 133L64 40L120 96ZM200 133L136 96L192 40Z"   # both wound like the head (no holes)
    return (f'<path d="{head}{ears}" fill="{INK}" stroke="{INK}" stroke-width="12" stroke-linejoin="round"/>'
            f'<circle cx="98" cy="156" r="19" fill="{PAPER}"/>'
            f'<circle cx="158" cy="156" r="19" fill="{PAPER}"/><circle cx="158" cy="156" r="12" fill="{INK}"/>')


# P4 Puzzle Page: a sheet of paper with a folded corner and a small grid, like a printed puzzle.
def p4():
    l, t, r_, b, f, k = 50, 30, 206, 226, 50, 20
    page = (f"M{l + k} {t}H{r_ - f}L{r_} {t + f}V{b - k}A{k} {k} 0 0 1 {r_ - k} {b}H{l + k}"
            f"A{k} {k} 0 0 1 {l} {b - k}V{t + k}A{k} {k} 0 0 1 {l + k} {t}Z")
    fold = f"M{r_ - f} {t}V{t + f}H{r_}"
    c, g = 26, 8
    o = 128 - (3 * c + 2 * g) / 2
    grid = "".join(rr(o + col * (c + g), o + 12 + row * (c + g), c, c, 5) for row in range(3) for col in range(3))
    return (f'<path d="{page}{fold}" fill="none" stroke="{INK}" stroke-width="16" stroke-linejoin="round"/>'
            f'<path d="{grid}" fill="{INK}"/>')


# P5 Little Killer: an outside arrow points down the diagonal of the box, through three cells.
def p5():
    lo, hi = 62, 228
    a, b = lo + (hi - lo) / 3, lo + 2 * (hi - lo) / 3
    body = (f'<path d="M{a:.1f} {lo}V{hi}M{b:.1f} {lo}V{hi}M{lo} {a:.1f}H{hi}M{lo} {b:.1f}H{hi}" stroke="{INK}" stroke-width="6"/>'
            f'<path d="{rr(lo, lo, hi - lo, hi - lo, 28)}" fill="none" stroke="{INK}" stroke-width="18"/>')
    body += (f'<path d="M22 22L54 54M54 28V54H28" fill="none" stroke="{INK}" stroke-width="12" '
             f'stroke-linecap="round" stroke-linejoin="round"/>')
    for v in (lo + (hi - lo) / 6, (lo + hi) / 2, hi - (hi - lo) / 6):
        body += f'<circle cx="{v}" cy="{v}" r="15" fill="{INK}"/>'
    return body


# P6 Kropki Dots: a 3x3 cell grid with one black and one white kropki dot on its borders.
def p6():
    lo, hi = 34, 222
    a, b = lo + (hi - lo) / 3, lo + 2 * (hi - lo) / 3
    lines = f"M{a:.1f} {lo}V{hi}M{b:.1f} {lo}V{hi}M{lo} {a:.1f}H{hi}M{lo} {b:.1f}H{hi}"
    return (f'<path d="{lines}" stroke="{INK}" stroke-width="6"/>'
            f'<path d="{rr(lo, lo, hi - lo, hi - lo, 28)}" fill="none" stroke="{INK}" stroke-width="16"/>'
            f'<circle cx="{a:.1f}" cy="{(lo + a) / 2:.1f}" r="19" fill="{INK}"/>'
            f'<circle cx="{(b + hi) / 2:.1f}" cy="{b:.1f}" r="16" fill="{PAPER}" stroke="{INK}" stroke-width="7"/>')


# P7 O-Cell: the o of Sudoku is a cell: a rounded square with serif contrast (thick sides, thin top/bottom).
def p7():
    return f'<path d="{rr(48, 44, 160, 168, 50)}{rr(94, 66, 68, 124, 22)}" fill="{INK}" fill-rule="evenodd"/>'


def word_ocell():
    size, s = 118, 118 / 1000
    a, xa = text_path("Sud", size, 292, 120, 1)
    xh = 481 * s
    w, h = 58, xh + 4
    ox, oy = xa + 3, 120 - h + 1
    sc = w / 160
    cell = f'<path d="{rr(0, 0, 160, 168, 50)}{rr(46, 22, 68, 124, 22)}" fill="{INK}" fill-rule="evenodd" ' \
           f'transform="translate({ox:.1f} {oy:.1f}) scale({sc:.3f} {h / 168:.3f})"/>'
    b, x1 = text_path("ku", size, ox + w + 4, 120, 1)
    l2, x2 = text_path("Variants", size, 292, 230, 1)
    return f'<path d="{a}{b}{l2}" fill="{INK}"/>' + cell, max(x1, x2)


# P8 Classic Caps: SUDOKU in spaced capitals over VARIANTS, a small 3x3 mark between two rules (stacked wordmark).
def caps_block(w):
    """Stacked caps wordmark centred in a box of width w, height 256."""
    s1, s2 = 74, 38
    t1, t2 = 16, 13
    def width(word, size, tr):
        return sum(gs[cmap[ord(ch)]].width for ch in word) * size / upm + tr * (len(word) - 1)
    w1, w2 = width("SUDOKU", s1, t1), width("VARIANTS", s2, t2)
    l1, _ = text_path("SUDOKU", s1, (w - w1) / 2, 112, t1)
    l2, _ = text_path("VARIANTS", s2, (w - w2) / 2, 214, t2)
    cx, cy, c, g = w / 2, 152, 9, 3
    mark = "".join(rr(cx - 1.5 * c - g + col * (c + g), cy - 1.5 * c - g + row * (c + g), c, c, 2)
                   for row in range(3) for col in range(3))
    rule = f"M{(w - w1) / 2:.1f} {cy}H{cx - 30:.1f}M{cx + 30:.1f} {cy}H{(w + w1) / 2:.1f}"
    return (f'<path d="{l1}{l2}{mark}" fill="{INK}"/>'
            f'<path d="{rule}" stroke="{INK}" stroke-width="3"/>'), w1


def p8():
    body, w1 = caps_block(400)
    k = 236 / 400
    return f'<g transform="translate(10 {128 - 128 * k:.1f}) scale({k:.4f})">{body}</g>'


# P9 Modern Sans: lowercase DM Sans Bold, the i's dot turned into a diamond; icon = "sv" on a tile.
def p9():
    d, x, _ = sans_path("sv", 150, 0, 0)
    bp = _BP(sgs)
    w = x
    d2, _, _ = sans_path("sv", 150, 128 - w / 2, 164)
    return (f'<path d="{rr(20, 20, 216, 216, 52)}" fill="{INK}"/>'
            f'<path d="{d2}" fill="{PAPER}"/>')


def word_sans():
    l1, x1, _ = sans_path("sudoku", 118, 292, 120, -2)
    l2, x2, marks = sans_path("variants", 118, 292, 230, -2, skip_i_dot=True)
    dots = ""
    for cx, s in marks:
        cy, r = 230 - 700 * s, 11
        dots += f'<path d="M{cx:.1f} {cy - r:.1f}L{cx + r:.1f} {cy:.1f}L{cx:.1f} {cy + r:.1f}L{cx - r:.1f} {cy:.1f}Z" fill="{INK}"/>'
    return f'<path d="{l1}{l2}" fill="{INK}"/>' + dots, max(x1, x2)


# P10 Spiral Thermo: a thermometer that starts in the centre cell and spirals out through all nine.
def p10():
    pts = [(128, 128), (184, 128), (184, 72), (72, 72), (72, 184), (190, 184)]
    d = "M" + "L".join(f"{x} {y}" for x, y in pts)
    return (f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="28" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<circle cx="128" cy="128" r="30" fill="{INK}"/>')


# P11 Diamond: the 3x3 block turned 45deg; sudoku seen from a new angle.
def p11():
    return f'<path d="{tiles(46, 10, 128 - 74, 9)}" fill="{INK}" transform="rotate(45 128 128)"/>'


# P12 Overlap: two cells overlap; the shared square is cut out (a cell belongs to its row, column and box at once).
def p12():
    return f'<path d="{rr(36, 36, 124, 124, 26)}{rr(96, 96, 124, 124, 26)}" fill="{INK}" fill-rule="evenodd"/>'


CONCEPTS = [("p01", p1, None), ("p02", p2, None), ("p03", p3, None), ("p04", p4, None), ("p05", p5, None),
            ("p06", p6, None), ("p07", p7, word_ocell), ("p08", p8, "caps"), ("p09", p9, word_sans),
            ("p10", p10, None), ("p11", p11, None), ("p12", p12, None)]
for k, f, word in CONCEPTS:
    open(f"{OUT}/{k}-symbol-{VER}.svg", "w").write(svg(256, f(), "Sudoku Variants symbol"))
    if word == "caps":
        body, _ = caps_block(560)
        open(f"{OUT}/{k}-lockup-{VER}.svg", "w").write(svg(560, body, "Sudoku Variants logo"))
        continue
    wb, xm = (word or word2)()
    open(f"{OUT}/{k}-lockup-{VER}.svg", "w").write(svg(int(xm + 16), f() + wb, "Sudoku Variants logo"))
print("ok")
