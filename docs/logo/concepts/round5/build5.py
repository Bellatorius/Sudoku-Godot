"""Round 5: 100 more Sudoku Variants symbol concepts (#28-#127) + contact sheets.
Usage: python build5.py <DMSerif.ttf> <out_dir> <version> <DMSans-Variable.ttf>"""
import math
from common import *  # noqa: F401,F403
from fontTools.ttLib import TTFont as _TT
from fontTools.varLib import instancer
from fontTools.pens.svgPathPen import SVGPathPen as _Pen
from fontTools.pens.transformPen import TransformPen as _TP
from fontTools.pens.boundsPen import BoundsPen as _BP

sans = instancer.instantiateVariableFont(_TT(sys.argv[4]), {"wght": 700, "opsz": 40})
sgs, scmap, supm = sans.getGlyphSet(), sans.getBestCmap(), sans["head"].unitsPerEm
S = math.sqrt(3)


# ---------- drawing helpers ----------
def F(d, c=INK, extra=""):
    return f'<path d="{d}" fill="{c}"{extra}/>'


def ST(d, w, c=INK, cap="round", join="round", extra=""):
    return (f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="{cap}" '
            f'stroke-linejoin="{join}"{extra}/>')


def C(x, y, r, c=INK):
    return f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{r}" fill="{c}"/>'


def RING(x, y, r, w, fill="none"):
    return f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{r}" fill="{fill}" stroke="{INK}" stroke-width="{w}"/>'


def rr4(x, y, w, h, tl, tr, br, bl):
    def arc(r, ex, ey):
        return f"A{r} {r} 0 0 1 {ex:.2f} {ey:.2f}" if r else f"L{ex:.2f} {ey:.2f}"
    return (f"M{x + tl:.2f} {y:.2f}H{x + w - tr:.2f}{arc(tr, x + w, y + tr)}V{y + h - br:.2f}"
            f"{arc(br, x + w - br, y + h)}H{x + bl:.2f}{arc(bl, x, y + h - bl)}V{y + tl:.2f}{arc(tl, x + tl, y)}Z")


def poly(pts):
    return "M" + "L".join(f"{x:.2f} {y:.2f}" for x, y in pts) + "Z"


def line(pts):
    return "M" + "L".join(f"{x:.2f} {y:.2f}" for x, y in pts)


def cells(c=56, g=14, cols=3, rows=3, cx=128, cy=128):
    """Top-left corners of a cols x rows block of c-sized cells, centred on (cx, cy)."""
    ox, oy = cx - (cols * c + (cols - 1) * g) / 2, cy - (rows * c + (rows - 1) * g) / 2
    return {(r, k): (ox + k * (c + g), oy + r * (c + g)) for r in range(rows) for k in range(cols)}


def tiles(c=56, g=14, r=12, skip=(), only=None, cols=3, rows=3, cx=128, cy=128):
    out = ""
    for key, (x, y) in cells(c, g, cols, rows, cx, cy).items():
        if key in skip or (only is not None and key not in only):
            continue
        out += rr(round(x, 2), round(y, 2), c, c, r)
    return out


def grid_lines(lo=34, hi=222, w=6):
    a, b = lo + (hi - lo) / 3, lo + 2 * (hi - lo) / 3
    return (f'<path d="M{a:.1f} {lo}V{hi}M{b:.1f} {lo}V{hi}M{lo} {a:.1f}H{hi}M{lo} {b:.1f}H{hi}" '
            f'stroke="{INK}" stroke-width="{w}"/>')


def FR(lo=34, hi=222, w=16, r=28):
    return ST(rr(lo, lo, hi - lo, hi - lo, r), w)


def G(ch, size, cx=128, cy=128, c=INK):
    return F(glyph_centred(ch, size, cx, cy), c)


def word_centred(text, size, cx, cy, c=INK, tracking=0, font="serif"):
    if font == "serif":
        glyphs, gmap, u = gs, cmap, upm
    else:
        glyphs, gmap, u = sgs, scmap, supm
    s = size / u
    pen = _Pen(glyphs)
    bp = _BP(glyphs)
    x = 0
    for ch in text:
        g = gmap[ord(ch)]
        glyphs[g].draw(_TP(bp, (1, 0, 0, 1, x / s, 0)))
        x += glyphs[g].width * s + tracking
    x0, y0, x1, y1 = bp.bounds
    ox = cx - (x0 + x1) / 2 * s
    oy = cy + (y0 + y1) / 2 * s
    x = ox
    for ch in text:
        g = gmap[ord(ch)]
        glyphs[g].draw(_TP(pen, (s, 0, 0, -s, x, oy)))
        x += glyphs[g].width * s + tracking
    return F(pen.getCommands(), c)


def rot(body, a, cx=128, cy=128):
    return f'<g transform="rotate({a} {cx} {cy})">{body}</g>'


def tile_at(x, y, c, r, a=0):
    body = F(rr(round(x - c / 2, 2), round(y - c / 2, 2), c, c, r))
    return rot(body, a, x, y) if a else body


def pixel(pattern, c=36, g=6, r=7):
    rows = pattern.split("/")
    h, w = len(rows), len(rows[0])
    on = {(i, j) for i, row in enumerate(rows) for j, ch in enumerate(row) if ch == "1"}
    return F(tiles(c, g, r, only=on, cols=w, rows=h))


def hexagon(cx, cy, R, a0=-90):
    return poly([(cx + R * math.cos(math.radians(a0 + 60 * k)), cy + R * math.sin(math.radians(a0 + 60 * k)))
                 for k in range(6)])


def shrink(pts, f):
    mx, my = sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)
    return [(mx + (x - mx) * f, my + (y - my) * f) for x, y in pts]


# ---------- the 100 concepts: (name, one-liner, draw) ----------
L = []


def concept(name, note):
    def deco(f):
        L.append((name, note, f))
        return f
    return deco


# --- grid ideas ---
@concept("Missing Tile", "Eight cells and one gap: the cell you're about to solve.")
def _(): return F(tiles(skip={(0, 2)}))


@concept("Lifted Tile", "One cell lifts out of the grid, like a digit being placed.")
def _(): return F(tiles(skip={(0, 2)})) + tile_at(30 + 2 * 70 + 28 + 10, 30 + 28 - 10, 56, 12)


@concept("Slide Row", "The middle row slides half a cell: same grid, shifted rule.")
def _():
    t = tiles(only={(0, 0), (0, 1), (0, 2), (2, 0), (2, 1), (2, 2)}, c=50, g=12, cx=128)
    m = tiles(only={(1, 0), (1, 1), (1, 2)}, c=50, g=12, cx=128 + 31)
    return F(t + m)


@concept("Growing Tiles", "Cells grow from small to large across the block.")
def _():
    out = ""
    for (r, k), (x, y) in cells().items():
        s = 30 + 6.5 * (r + k)
        out += tile_at(x + 28, y + 28, s, s * 0.22)
    return out


@concept("Squircle Split", "One rounded square cut into nine cells.")
def _():
    out, R, ri = "", 46, 6
    for (r, k), (x, y) in cells(60, 10).items():
        tl = R if (r, k) == (0, 0) else ri
        tr = R if (r, k) == (0, 2) else ri
        br = R if (r, k) == (2, 2) else ri
        bl = R if (r, k) == (2, 0) else ri
        out += rr4(x, y, 60, 60, tl, tr, br, bl)
    return F(out)


@concept("Disc Grid", "A circle cut into nine cells by the grid lines.")
def _():
    return (C(128, 128, 104) + F("M91 20H101V236H91ZM155 20H165V236H155ZM20 91H236V101H20ZM20 155H236V165H20Z", PAPER))


@concept("Ring Centre", "Eight cells around a ring: the centre is the open question.")
def _(): return F(tiles(skip={(1, 1)})) + RING(128, 128, 22, 12)


@concept("Checker Outline", "Solid and open cells alternate, givens and blanks.")
def _():
    on = {(r, k) for r in range(3) for k in range(3) if (r + k) % 2 == 0}
    off = {(r, k) for r in range(3) for k in range(3)} - on
    return F(tiles(only=on)) + ST(tiles(c=44, g=26, only=off, r=8), 12)


@concept("L Selection", "An L of selected cells, like a multi-select in the game.")
def _():
    on = {(0, 0), (1, 0), (2, 0), (2, 1), (2, 2)}
    off = {(r, k) for r in range(3) for k in range(3)} - on
    return F(tiles(only=on)) + ST(tiles(c=44, g=26, only=off, r=8), 10)


@concept("One to Nine", "Nine dots sized 1 to 9 in reading order.")
def _():
    out = ""
    for i, ((r, k), (x, y)) in enumerate(sorted(cells(48, 24).items())):
        out += C(x + 24, y + 24, 5 + 2.9 * i)
    return out


@concept("Tally Nine", "Nine tally strokes in three groups of three.")
def _():
    out = ""
    for gi in range(3):
        for b in range(3):
            x = 36 + gi * 82 + b * 20
            out += f"M{x} 64V192"
    return ST(out, 14)


@concept("Raised Cell", "Open cells, one solid cell raised with its outline left behind.")
def _():
    return (ST(tiles(c=46, g=24, r=9, skip={(1, 1)}), 10) + ST(rr(105, 105, 46, 46, 9), 6) + C(128, 128, 0) + tile_at(116, 116, 46, 9))


@concept("Turning Tiles", "Each cell turns a little more: nine steps of a variation.")
def _():
    out = ""
    for i, ((r, k), (x, y)) in enumerate(sorted(cells(50, 22).items())):
        out += tile_at(x + 25, y + 25, 50, 10, 5 * i)
    return out


@concept("Stencil Grid", "A solid plate with nine cell windows punched out.")
def _():
    holes = "".join(rr(round(x, 2), round(y, 2), 44, 44, 9) for (x, y) in cells(44, 16).values())
    return F(rr(28, 28, 200, 200, 40) + holes, extra=' fill-rule="evenodd"')


@concept("Punch Card", "Nine windows in a plate; the centre one is round.")
def _():
    holes = "".join(rr(round(x, 2), round(y, 2), 44, 44, 9) for k, (x, y) in cells(44, 16).items() if k != (1, 1))
    return F(rr(28, 28, 200, 200, 40) + holes + "M150 128A22 22 0 1 0 106 128A22 22 0 1 0 150 128Z",
             extra=' fill-rule="evenodd"')


@concept("Linked Cells", "Nine cells joined by bridges along the path of an S.")
def _():
    route = [(0, 2), (0, 1), (0, 0), (1, 0), (1, 1), (1, 2), (2, 2), (2, 1), (2, 0)]
    pos = cells(52, 18)
    out = tiles(52, 18, 12)
    for a, b in zip(route, route[1:]):
        (x1, y1), (x2, y2) = pos[a], pos[b]
        x, y = min(x1, x2), min(y1, y2)
        if y1 == y2:
            out += f"M{x + 40:.1f} {y + 14:.1f}h{30}v24h-30Z"
        else:
            out += f"M{x + 14:.1f} {y + 40:.1f}h24v30h-24Z"
    return F(out)


@concept("Pixel 9", "The digit 9 drawn in cells, like a scoreboard.")
def _(): return pixel("111/101/111/001/111")


@concept("Pixel S", "The letter S drawn in cells.")
def _(): return pixel("111/100/111/001/111")


@concept("Pixel V", "The letter V drawn in cells.")
def _(): return pixel("101/101/101/101/010")


@concept("Diagonal Fill", "The main diagonal is solid: the diagonal-sudoku rule.")
def _():
    on = {(0, 0), (1, 1), (2, 2)}
    off = {(r, k) for r in range(3) for k in range(3)} - on
    return F(tiles(only=on)) + ST(tiles(c=44, g=26, only=off, r=8), 10)


@concept("Porthole", "The grid seen through a round window.")
def _():
    h = math.sqrt(91 ** 2 - 32 ** 2)
    return RING(128, 128, 100, 18) + ST(f"M96 {128 - h:.1f}V{128 + h:.1f}M160 {128 - h:.1f}V{128 + h:.1f}"
                                        f"M{128 - h:.1f} 96H{128 + h:.1f}M{128 - h:.1f} 160H{128 + h:.1f}", 8, cap="butt")


@concept("Tri-Grid", "A triangle cut into nine smaller triangles.")
def _():
    s, h, top = 70, 70 * S / 2, 128 - 3 * 70 * S / 4
    out = ""
    for r in range(3):
        y0 = top + r * h
        for i in range(r + 1):
            ax = 128 + (i - r / 2) * s
            out += poly(shrink([(ax, y0), (ax + s / 2, y0 + h), (ax - s / 2, y0 + h)], 0.82))
        for i in range(r):
            ax1, ax2 = 128 + (i - r / 2) * s, 128 + (i + 1 - r / 2) * s
            out += poly(shrink([(ax1, y0), (ax2, y0), ((ax1 + ax2) / 2, y0 + h)], 0.82))
    return F(out)


@concept("Honeycomb", "Nine hexagon cells: sudoku on a honeycomb.")
def _():
    R, sp = 30, 34
    w, v = S * sp, 1.5 * sp
    out = ""
    for r in range(3):
        for k in range(3):
            x = 128 + (k - 1) * w + (r - 1) * w / 2
            y = 128 + (r - 1) * v
            out += hexagon(x, y, R)
    return F(out)


@concept("Isometric Board", "The 3x3 board seen in perspective, lying on a table.")
def _():
    return f'<g transform="matrix(0.866 0.5 -0.866 0.5 128 61)">{F(tiles(40, 7, 8, cx=67, cy=67))}</g>'


@concept("Pinwheel", "Four dominoes spin around a centre cell.")
def _():
    u, o, i = 64, 32, 6
    pieces = [(0, 0, 2, 1), (2, 0, 1, 2), (1, 2, 2, 1), (0, 1, 1, 2), (1, 1, 1, 1)]
    return F("".join(rr(o + x * u + i, o + y * u + i, w * u - 2 * i, h * u - 2 * i, 12) for x, y, w, h in pieces))


@concept("Truchet", "Quarter circles in nine cells form a woven pattern.")
def _():
    rots = [[0, 1, 0], [3, 2, 3], [0, 1, 0]]
    out = ""
    for (r, k), (x, y) in cells(60, 8).items():
        q = rots[r][k]
        c = [(x, y), (x + 60, y), (x + 60, y + 60), (x, y + 60)][q]
        a = [(x + 60, y), (x + 60, y + 60), (x, y + 60), (x, y)][q]
        b = [(x, y + 60), (x, y), (x + 60, y), (x + 60, y + 60)][q]
        out += f"M{c[0]:.1f} {c[1]:.1f}L{a[0]:.1f} {a[1]:.1f}A60 60 0 0 1 {b[0]:.1f} {b[1]:.1f}Z"
    return F(out)


# --- clue ideas ---
@concept("Thermo Line", "A sudoku thermometer climbs across the cell.")
def _(): return FR() + C(86, 170, 26) + ST("M86 170L174 82", 18)


@concept("Bent Thermo", "A thermometer turns a corner inside the cell.")
def _(): return FR() + C(84, 172, 26) + ST("M84 172V84H174", 18)


@concept("Arrow Clue", "An arrow-sudoku circle with its arrow.")
def _(): return FR() + RING(88, 88, 24, 12) + ST("M105 105L176 176M150 176H176V150", 12)


@concept("Twin Cages", "Two killer cages side by side, each with its total.")
def _():
    return (ST(rr(26, 64, 96, 128, 16), 8, extra=' stroke-dasharray="12 9"') +
            ST(rr(134, 64, 96, 128, 16), 8, extra=' stroke-dasharray="12 9"') +
            G("7", 40, 50, 92) + word_centred("12", 40, 168, 92))


@concept("V Between", "Two cells with a V clue on their shared edge.")
def _():
    return F(rr(22, 78, 100, 100, 20) + rr(134, 78, 100, 100, 20)) + C(128, 128, 34, PAPER) + G("V", 64)


@concept("Kropki Pair", "A black and a white kropki dot side by side.")
def _(): return C(78, 128, 50) + RING(178, 128, 43, 14)


@concept("Kropki Chain", "Black, white, black dots strung on a line.")
def _(): return ST("M24 128H232", 8) + C(56, 128, 24) + RING(128, 128, 20, 8, PAPER) + C(200, 128, 24)


@concept("Whisper Wave", "A German-whispers line waves through the cell.")
def _(): return FR() + ST("M60 128C84 64 108 64 128 128S172 192 196 128", 18)


@concept("Renban Pill", "A renban pill lies across three cells.")
def _(): return grid_lines() + FR() + F(rr(52, 108, 152, 40, 20))


@concept("Between Line", "A line with a circle at each end: the between-line clue.")
def _(): return FR() + ST("M96 160L160 96", 12) + RING(84, 172, 22, 10, PAPER) + RING(172, 84, 22, 10, PAPER)


@concept("Quad Clue", "A quadruple circle holding four small candidates.")
def _():
    return (RING(128, 128, 88, 16) + C(102, 102, 15) + C(154, 102, 15) + C(102, 154, 15) + C(154, 154, 15))


@concept("Skyline", "Skyscraper sudoku: towers of one, two and three cells.")
def _():
    on = {(2, 0), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)}
    return F(tiles(only=on))


@concept("Zipper", "A zipper line folds through the cell around its centre dot.")
def _(): return FR() + ST("M72 80V128H184V176", 16) + C(128, 128, 18)


@concept("Clone", "Two identical shapes, one solid, one open: the clone rule.")
def _():
    def Lp(x, y, u):
        return poly([(x, y), (x + u, y), (x + u, y + u), (x + 2 * u, y + u), (x + 2 * u, y + 2 * u), (x, y + 2 * u)])
    return (F(Lp(30, 30, 48), extra=f' stroke="{INK}" stroke-width="12" stroke-linejoin="round"') +
            ST(Lp(128, 128, 48), 12))


@concept("Fifteen", "A magic square's total, 15, in the centre of the grid.")
def _(): return grid_lines(w=5) + FR() + C(128, 128, 30, PAPER) + word_centred("15", 54, 128, 128)


@concept("Sandwich Clue", "A clue outside the row: the sandwich total.")
def _():
    return word_centred("10", 58, 50, 128) + ST(tiles(42, 8, 8, cols=3, rows=1, cx=166), 8)


@concept("Margins", "Clue dots outside the grid, like outside-clue variants.")
def _():
    lo, hi = 62, 226
    a = (hi - lo) / 3
    dots = "".join(C(lo + a * (i + .5), 32, 10) + C(32, lo + a * (i + .5), 10) for i in range(3))
    return grid_lines(lo, hi, 5) + FR(lo, hi, 14, 24) + dots


@concept("Entropic", "One line in three moods: solid, dashed and dotted.")
def _():
    return (FR() + ST("M60 128H96", 18) + ST("M114 128H150", 18, extra=' stroke-dasharray="1 15"') +
            ST("M168 128H196", 18, cap="butt") + C(168, 128, 0))


@concept("Parity Beads", "A line of beads that alternate circle, square: parity.")
def _():
    return (ST("M30 128H226", 8) + C(52, 128, 22) + F(rr(84, 106, 44, 44, 8)) + C(154, 128, 22) +
            F(rr(184, 106, 44, 44, 8)))


@concept("Lockout", "A lockout line with diamonds at both ends.")
def _():
    def dia(x, y, r): return poly([(x, y - r), (x + r, y), (x, y + r), (x - r, y)])
    return FR() + ST("M84 172L172 84", 12) + F(dia(80, 176, 28)) + F(dia(176, 80, 28))


@concept("Four Quads", "Quad circles on all four inner corners of the grid.")
def _():
    a, b = 34 + 188 / 3, 34 + 2 * 188 / 3
    return grid_lines(w=5) + FR() + "".join(RING(x, y, 15, 7, PAPER) for x in (a, b) for y in (a, b))


@concept("Killer Tile", "A solid cell with a killer cage cut into it.")
def _():
    return F(rr(28, 28, 200, 200, 40)) + ST(rr(60, 60, 136, 136, 16), 10, PAPER, extra=' stroke-dasharray="16 12"')


@concept("Wavy Region", "A jigsaw region border that curves instead of stepping.")
def _(): return grid_lines(w=5) + FR() + ST("M34 128C90 64 166 192 222 128", 16)


@concept("Mini Box", "Six cells, two by three: the Mini 6x6 box.")
def _(): return F(tiles(56, 14, 12, cols=3, rows=2))


# --- type ideas ---
@concept("S Dot", "A serif S on a black kropki dot.")
def _(): return C(128, 128, 106) + G("S", 150, c=PAPER)


@concept("Nine Tile", "A serif 9 on a solid cell.")
def _(): return F(rr(24, 24, 208, 208, 46)) + G("9", 160, c=PAPER)


@concept("Keypad", "The digits 1 to 9 in a 3x3, set in the game's serif.")
def _():
    return "".join(G(str(i + 1), 56, 56 + 72 * (i % 3), 56 + 72 * (i // 3)) for i in range(9))


@concept("Segment S", "An S built from display segments; it also reads as 5.")
def _():
    t, l, r_, m, b = 40, 52, 204, 128, 216
    segs = [rr(l + 20, t, r_ - l - 40, 28, 14), rr(l, t + 18, 28, m - t - 28, 14), rr(l + 20, m - 14, r_ - l - 40, 28, 14),
            rr(r_ - 28, m + 10, 28, b - m - 28, 14), rr(l + 20, b - 28, r_ - l - 40, 28, 14)]
    return F("".join(segs))


@concept("Tile V", "A V made of five cells.")
def _(): return pixel("10001/01010/00100", c=40, g=8, r=9)


@concept("Stencil SV", "Bold SV with a stencil cut through the middle.")
def _(): return word_centred("SV", 150, 128, 128, font="sans") + F("M10 124H246V132H10Z", PAPER)


@concept("V Holds", "The serif V holds a kropki dot in its arms.")
def _(): return G("V", 210, 128, 140) + C(128, 50, 20)


@concept("Eighty-One", "81: the number of cells in a sudoku.")
def _(): return word_centred("81", 160, 128, 128)


@concept("One-Nine Pill", "The digits you play, 1-9, in a pill.")
def _(): return F(rr(20, 80, 216, 96, 48)) + word_centred("1-9", 70, 128, 128, PAPER)


@concept("s Cell", "A lowercase serif s inside a cell.")
def _(): return FR() + G("s", 190, 128, 128)


@concept("Badge", "SUDOKU and VARIANTS stacked in a rounded badge.")
def _():
    return (F(rr(16, 64, 224, 128, 24)) + word_centred("SUDOKU", 46, 128, 110, PAPER, 4, font="sans") +
            word_centred("VARIANTS", 26, 128, 154, PAPER, 5, font="sans"))


@concept("S9", "S and 9 side by side: Sudoku, nine by nine.")
def _(): return word_centred("S9", 150, 128, 128)


@concept("Pencil 9", "A big given 9 with small pencil marks in the corner.")
def _():
    return FR() + G("9", 150, 140, 140) + word_centred("123", 30, 88, 66, tracking=3)


@concept("Two Givens", "Two cells holding 1 and 9: first and last digit.")
def _():
    return (F(rr(20, 70, 104, 116, 22) + rr(132, 70, 104, 116, 22)) + G("1", 84, 72, 128, PAPER) +
            G("9", 84, 184, 128, PAPER))


@concept("SV Stack", "S stacked over V, tight and narrow.")
def _(): return G("S", 112, 128, 70) + G("V", 112, 128, 186)


@concept("Element Su", "Su as a periodic-table element, atomic number 81.")
def _():
    return ST(rr(36, 36, 184, 184, 18), 10) + word_centred("Su", 110, 128, 140) + word_centred("81", 28, 70, 70)


# --- object ideas ---
@concept("Grid Key", "A key whose bow is a 3x3 grid: unlock the puzzle.")
def _():
    return (F(tiles(20, 6, 5, cx=70, cy=128)) + F("M108 120H226V136H108Z") +
            F("M186 136H202V164H186ZM212 136H226V156H212Z"))


@concept("Grid Lock", "A padlock with a 3x3 grid for a body.")
def _():
    holes = "".join(rr(round(x, 2), round(y, 2), 22, 22, 5) for x, y in cells(22, 10, cy=170).values())
    return ST("M88 116V86A40 40 0 0 1 168 86V116", 20, cap="butt") + F(rr(52, 112, 152, 116, 22) + holes,
                                                                         extra=' fill-rule="evenodd"')


@concept("Crown", "A crown for the anti-king rule.")
def _():
    return (F("M52 196L44 92L94 138L128 70L162 138L212 92L204 196Z",
              extra=f' stroke="{INK}" stroke-width="12" stroke-linejoin="round"') +
            C(44, 80, 14) + C(128, 56, 14) + C(212, 80, 14))


@concept("Puzzle Book", "An open book of puzzles, a grid on the right page.")
def _():
    pages = "M128 76L30 62V190L128 204ZM128 76L226 62V190L128 204Z"
    return ST(pages, 12) + F(tiles(16, 6, 3, cx=177, cy=133))


@concept("Pyramid", "Cells stacked one, two, three: build up from the givens.")
def _():
    out = ""
    for r, n in enumerate((1, 2, 3)):
        for k in range(n):
            out += rr(128 - (n * 56 + (n - 1) * 10) / 2 + k * 66, 30 + r * 66, 56, 56, 12)
    return F(out)


@concept("Rosette", "Eight cells around a centre cell, like a rosette.")
def _():
    out = tile_at(128, 128, 44, 10)
    for k in range(8):
        a = math.radians(k * 45)
        out += tile_at(128 + 82 * math.cos(a), 128 + 82 * math.sin(a), 40, 9, k * 45)
    return out


@concept("Bookmark", "A bookmark with a small grid: pick up where you left off.")
def _(): return F("M76 26H180V230L128 188L76 230Z") + F(tiles(18, 6, 4, cx=128, cy=92), PAPER)


@concept("Chat Grid", "A speech bubble holding a grid: multiplayer chat.")
def _():
    return F(rr(26, 38, 204, 152, 36) + "M76 186L116 186L64 230Z") + F(tiles(28, 8, 6, cx=128, cy=114), PAPER)


@concept("Hex Badge", "A hexagonal badge around a small grid.")
def _(): return ST(hexagon(128, 128, 108), 16) + F(tiles(32, 8, 7))


@concept("Calendar", "A calendar page with a grid: the daily puzzle.")
def _():
    return (ST(rr(40, 54, 176, 168, 24), 14) + ST("M88 36V70M168 36V70", 14) + ST("M40 98H216", 12) +
            F(tiles(24, 10, 5, cx=128, cy=160)))


@concept("Kite", "A diamond grid flying as a kite.")
def _():
    return rot(F(tiles(30, 8, 6, cx=128, cy=104)), 45, 128, 104) + ST("M128 178C108 196 150 208 130 236", 7)


@concept("Ticket", "A ticket stub with a grid: admit one puzzle.")
def _():
    return (F(rr(20, 72, 216, 112, 16)) + C(20, 128, 18, PAPER) + C(236, 128, 18, PAPER) +
            ST("M84 84V172", 5, PAPER, extra=' stroke-dasharray="8 8"') + F(tiles(20, 6, 4, cx=160), PAPER))


@concept("Stamp", "A postage stamp with a serif S.")
def _():
    out = F(rr(40, 40, 176, 176, 4))
    for i in range(9):
        t = 50 + i * 19.5
        out += C(t, 40, 7, PAPER) + C(t, 216, 7, PAPER) + C(40, t, 7, PAPER) + C(216, t, 7, PAPER)
    return out + G("S", 110, c=PAPER)


@concept("Grid Cat", "A 3x3 grid with two ears: the grid is a cat.")
def _():
    return (F(tiles(52, 12, 11, cy=150)) + F("M40 92L46 30L94 70Z M216 92L210 30L162 70Z",
                                             extra=f' stroke="{INK}" stroke-width="10" stroke-linejoin="round"'))


@concept("Tile Bird", "A cell with a beak and an eye becomes a bird.")
def _(): return F(rr(30, 58, 150, 150, 42) + "M176 108L230 130L176 152Z") + C(132, 112, 13, PAPER)


@concept("Hourglass", "Cells in a 3-1-3 hourglass: time to solve.")
def _(): return F(tiles(skip={(1, 0), (1, 2)}))


# --- abstract ideas ---
@concept("Nested", "Square, circle, square: a cell inside a cell.")
def _(): return ST(rr(28, 28, 200, 200, 40), 14) + RING(128, 128, 68, 14) + F(rr(100, 100, 56, 56, 10))


@concept("One Sharp Corner", "A rounded cell with one sharp corner, where the cage total sits.")
def _(): return F(rr4(36, 36, 184, 184, 0, 64, 64, 64))


@concept("Layers", "Three nested cells: grid, box, cell.")
def _(): return ST(rr(28, 28, 200, 200, 44), 14) + ST(rr(62, 62, 132, 132, 28), 14) + F(rr(98, 98, 60, 60, 12))


@concept("Bite", "A cell with a bite out of one corner, and the dot that took it.")
def _():
    d = ("M60 36H140A80 80 0 0 0 220 116V196A24 24 0 0 1 196 220H60A24 24 0 0 1 36 196V60A24 24 0 0 1 60 36Z")
    return F(d) + C(204, 52, 18)


@concept("Half and Half", "Half square, half round: two rules in one cell.")
def _(): return F("M36 36H128A92 92 0 0 1 128 220H36Z")


@concept("Split Cell", "A cell split on the diagonal, half given, half open.")
def _(): return ST(rr(36, 36, 184, 184, 30), 16) + F("M62 66V194H190Z")


@concept("Tilted Board", "The grid tilted a few degrees, a board set down at an angle.")
def _(): return rot(grid_lines(46, 210, 6) + FR(46, 210, 16, 26), -12)


@concept("Maze", "Two walls turn the 3x3 into a path: solve your way through.")
def _():
    a, b = 34 + 188 / 3, 34 + 2 * 188 / 3
    return FR() + ST(f"M{a:.1f} 34V{b + 10:.1f}M{b:.1f} 222V{a - 10:.1f}", 16, cap="butt") + C(190, 66, 16)


@concept("Square and Diamond", "A square cell with a diamond: the rule turned 45 degrees.")
def _():
    return ST(rr(44, 44, 168, 168, 26), 16) + F(poly([(128, 76), (180, 128), (128, 180), (76, 128)]))


@concept("Orbit", "A dot circles the cell: a rule moving around the grid.")
def _(): return F(rr(88, 88, 80, 80, 16)) + RING(128, 128, 98, 6) + C(197.3, 58.7, 22, PAPER) + C(197.3, 58.7, 15)


@concept("Leaf Grid", "Nine cells, each rounded on two corners like a leaf.")
def _():
    out = ""
    for x, y in cells().values():
        out += rr4(x, y, 56, 56, 26, 4, 26, 4)
    return F(out)


@concept("Notches", "Each cell has one sharp corner, turning round the block.")
def _():
    out = ""
    for i, ((r, k), (x, y)) in enumerate(sorted(cells().items())):
        rad = [16, 16, 16, 16]
        rad[i % 4] = 0
        out += rr4(x, y, 56, 56, *rad)
    return F(out)


@concept("Shaded Cell", "A cell shaded with pencil hatching.")
def _():
    lo, hi, segs = 50, 206, ""
    for k in range(-150, 151, 22):
        pts = []
        for x in (lo, hi):
            y = x - k
            if lo <= y <= hi:
                pts.append((x, y))
        for y in (lo, hi):
            x = y + k
            if lo < x < hi:
                pts.append((x, y))
        if len(pts) >= 2:
            (x1, y1), (x2, y2) = pts[0], pts[1]
            segs += f"M{x1:.1f} {y1:.1f}L{x2:.1f} {y2:.1f}"
    return ST(segs, 6, cap="butt") + FR()


@concept("Samurai", "Two grids overlapping at a shared box, like Samurai sudoku.")
def _():
    out = ""
    for o in (22, 94):
        hi = o + 140
        a, b = o + 140 / 3, o + 280 / 3
        out += f'<path d="M{a:.1f} {o}V{hi}M{b:.1f} {o}V{hi}M{o} {a:.1f}H{hi}M{o} {b:.1f}H{hi}" stroke="{INK}" stroke-width="5"/>'
        out += ST(rr(o, o, 140, 140, 18), 12)
    return out


@concept("Big and Small", "A big cell and a small one: 9 and 1.")
def _(): return F(rr(28, 76, 140, 140, 28) + rr(176, 40, 52, 52, 12))


@concept("Frame of Eight", "Eight cells frame an empty centre.")
def _(): return F(tiles(skip={(1, 1)}))


@concept("Row Unit", "The middle row joins into one bar: a unit of nine.")
def _():
    return F(tiles(only={(0, 0), (0, 1), (0, 2), (2, 0), (2, 1), (2, 2)}) + rr(30, 100, 196, 56, 12))


@concept("Corner Mark", "A cell with one mark in its corner, where a cage total goes.")
def _(): return ST(rr(36, 36, 184, 184, 32), 16) + C(80, 80, 20)


# ---------- output ----------
FIRST = 28
names = []
for i, (name, note, f) in enumerate(L):
    num = FIRST + i
    slug = f"{num:03d}"
    open(f"{OUT}/{slug}-symbol-{VER}.svg", "w").write(svg(256, f(), f"Sudoku Variants symbol {num}"))
    names.append((num, name, note))
open(f"{OUT}/index.txt", "w", encoding="utf-8").write("\n".join(f"{n}\t{a}\t{b}" for n, a, b in names))
print(len(L), "concepts")
