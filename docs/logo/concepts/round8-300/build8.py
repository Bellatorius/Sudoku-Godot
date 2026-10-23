"""Round 8: 60 new motifs (#128-#187), each in 5 styles = 300 logos.
Styles: a ink, b in a cell, c on an ink tile, d on the game's blue, e on a gold badge.
Usage: python build8.py <DMSerif.ttf> <out_dir> <version>"""
import math
from common import *  # noqa: F401,F403

ACCENT, GOLD, WHITE = "#2a4fff", "#e8a020", "#ffffff"
S3 = math.sqrt(3)


# ---------- helpers (f = foreground colour, b = background colour for cut-outs) ----------
def F(d, f, extra=""):
    return f'<path d="{d}" fill="{f}"{extra}/>'


def ST(d, w, f, cap="round", join="round", extra=""):
    return (f'<path d="{d}" fill="none" stroke="{f}" stroke-width="{w}" stroke-linecap="{cap}" '
            f'stroke-linejoin="{join}"{extra}/>')


def C(x, y, r, f):
    return f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{r}" fill="{f}"/>'


def RING(x, y, r, w, f, fill="none"):
    return f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{r}" fill="{fill}" stroke="{f}" stroke-width="{w}"/>'


def poly(pts):
    return "M" + "L".join(f"{x:.2f} {y:.2f}" for x, y in pts) + "Z"


def rr4(x, y, w, h, tl, tr, br, bl):
    def arc(r, ex, ey):
        return f"A{r} {r} 0 0 1 {ex:.2f} {ey:.2f}" if r else f"L{ex:.2f} {ey:.2f}"
    return (f"M{x + tl:.2f} {y:.2f}H{x + w - tr:.2f}{arc(tr, x + w, y + tr)}V{y + h - br:.2f}"
            f"{arc(br, x + w - br, y + h)}H{x + bl:.2f}{arc(bl, x, y + h - bl)}V{y + tl:.2f}{arc(tl, x + tl, y)}Z")


def cells(c=56, g=14, cols=3, rows=3, cx=128, cy=128):
    ox, oy = cx - (cols * c + (cols - 1) * g) / 2, cy - (rows * c + (rows - 1) * g) / 2
    return {(r, k): (ox + k * (c + g), oy + r * (c + g)) for r in range(rows) for k in range(cols)}


def tiles(c=56, g=14, r=12, skip=(), only=None, cols=3, rows=3, cx=128, cy=128):
    return "".join(rr(round(x, 2), round(y, 2), c, c, r) for key, (x, y) in cells(c, g, cols, rows, cx, cy).items()
                   if key not in skip and (only is None or key in only))


def pixel(pattern, f, c=36, g=6, r=7):
    rows = pattern.split("/")
    on = {(i, j) for i, row in enumerate(rows) for j, ch in enumerate(row) if ch == "1"}
    return F(tiles(c, g, r, only=on, cols=len(rows[0]), rows=len(rows)), f)


def G(ch, size, cx, cy, f):
    return F(glyph_centred(ch, size, cx, cy), f)


def grp(body, s=1.0, cx=128, cy=128, dx=0, dy=0, rot=0):
    return (f'<g transform="translate({128 + dx} {128 + dy}) scale({s}) rotate({rot}) translate({-cx} {-cy})">'
            f'{body}</g>')


def shrink(pts, k):
    mx, my = sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)
    return [(mx + (x - mx) * k, my + (y - my) * k) for x, y in pts]


L = []


def motif(name, note):
    def deco(fn):
        L.append((name, note, fn))
        return fn
    return deco


# ---------- characters ----------
def nine_face(f, b, left="dot", mouth="smile", w=14):
    out = ""
    if left == "dot":
        out += C(96, 94, 17, f)
    elif left == "wink":
        out += ST("M80 98Q96 80 112 98", 12, f)
    elif left == "square":
        out += F(rr(80, 78, 32, 32, 6), f)
    if left == "square":
        out += ST(rr(142, 76, 36, 36, 8), 12, f)
        out += ST("M178 94V150Q178 168 160 168H96Q78 168 78 150", 12, f)
        return out
    out += RING(160, 94, 20, w, f)
    if mouth == "smile":
        out += ST("M180 94V144A52 40 0 0 1 80.9 160.9", w, f)
    elif mouth == "grin":
        out += ST("M180 94V144", w, f) + F("M187 144A59 52 0 0 1 69 144Z", f)
    return out


@motif("Nine Smile", "The face you liked: the right eye is a 9 and its tail is the smile.")
def _(f, b): return grp(nine_face(f, b), 1.45, 128, 133)


@motif("Nine Wink", "The same face, winking: the left eye closes.")
def _(f, b): return grp(nine_face(f, b, "wink"), 1.45, 128, 133)


@motif("Nine Grin", "A big open grin hanging from the 9.")
def _(f, b): return grp(nine_face(f, b, mouth="grin"), 1.4, 128, 135)


@motif("Nine Cat", "The Nine Smile with cat ears.")
def _(f, b):
    ears = F("M60 108L66 34L114 80ZM196 108L190 34L142 80Z", f, f' stroke="{f}" stroke-width="10" stroke-linejoin="round"')
    return ears + head(f) + grp(nine_face(f, b), 0.74, 128, 133, dy=20)


@motif("Nine Bot", "A robot: square eyes, the right one a square 9 whose tail is the mouth.")
def _(f, b): return grp(nine_face(f, b, "square") + ST("M128 62V44", 8, f) + C(128, 38, 8, f), 1.45, 128, 106)


@motif("Nine Bubble", "The Nine Smile inside a speech bubble: chat with your rival.")
def _(f, b):
    bub = ST(rr(30, 30, 196, 168, 44) + "M70 196L60 232L106 198", 12, f)
    return bub + grp(nine_face(f, b), 0.95, 128, 133, dy=-14)


@motif("Peek", "Two kropki-dot eyes peek over a wall of cells.")
def _(f, b):
    body = (F(tiles(60, 10, 12, cols=3, rows=1, cy=176), f) + C(100, 112, 18, f) + RING(156, 112, 15, 8, f)
            + C(64, 142, 12, f) + C(192, 142, 12, f))
    return grp(body, 1.25, 128, 150)


def head(f):
    return ST(rr(44, 76, 168, 140, 46), 14, f)


@motif("Sleepy Cat", "A cat-cell with closed eyes, dozing over a puzzle.")
def _(f, b):
    ears = F("M60 108L66 34L114 80ZM196 108L190 34L142 80Z", f, f' stroke="{f}" stroke-width="10" stroke-linejoin="round"')
    return ears + head(f) + ST("M82 140Q98 156 114 140M142 140Q158 156 174 140", 11, f) + C(128, 170, 8, f)


@motif("Bunny", "A cell with two long ears.")
def _(f, b):
    ears = ST(rr(78, 16, 32, 88, 16) + rr(146, 16, 32, 88, 16), 12, f)
    return (ears + ST(rr(48, 96, 160, 128, 46), 14, f) + C(100, 150, 11, f) + C(156, 150, 11, f)
            + F("M120 172H136L128 182Z", f, f' stroke="{f}" stroke-width="6" stroke-linejoin="round"'))


@motif("Owl", "Kropki eyes, one black, one white, on a wise owl.")
def _(f, b):
    tufts = F("M50 92L56 44L96 78ZM206 92L200 44L160 78Z", f, f' stroke="{f}" stroke-width="8" stroke-linejoin="round"')
    return (tufts + head(f) + RING(94, 136, 26, 10, f) + C(94, 136, 10, f) + RING(162, 136, 26, 10, f)
            + F("M118 164H138L128 186Z", f, f' stroke="{f}" stroke-width="6" stroke-linejoin="round"'))


@motif("Bear", "A bear-cell with round ears.")
def _(f, b):
    return (C(64, 80, 26, f) + C(192, 80, 26, f) + F(rr(40, 74, 176, 150, 60), f) + C(98, 138, 12, b)
            + C(158, 138, 12, b) + F("M100 178A28 22 0 0 1 156 178A28 22 0 0 1 100 178Z", b)
            + C(128, 172, 9, f))


@motif("Frog", "A frog: two eye bumps and a wide smile.")
def _(f, b):
    return (F(rr(32, 100, 192, 118, 56) + "M84 64A32 32 0 1 1 84 128A32 32 0 1 1 84 64Z"
              "M172 64A32 32 0 1 1 172 128A32 32 0 1 1 172 64Z", f)
            + C(84, 96, 15, b) + C(172, 96, 15, b) + C(84, 96, 7, f) + C(172, 96, 7, f)
            + ST("M76 166Q128 204 180 166", 12, b))


@motif("V Fox", "A fox face whose shape is a V.")
def _(f, b):
    face = poly([(36, 40), (94, 82), (162, 82), (220, 40), (202, 122), (128, 222), (54, 122)])
    return F(face, f, f' stroke="{f}" stroke-width="12" stroke-linejoin="round"') + C(100, 122, 11, b) + C(156, 122, 11, b)


@motif("Pixel Smile", "A smiley face drawn in cells.")
def _(f, b): return pixel("01010/01010/00000/10001/01110", f)


@motif("Hatchling", "A chick breaking out of a cracked egg: a fresh puzzle.")
def _(f, b):
    shell = "M48 150L72 132L96 152L128 130L160 152L184 132L208 150V168A80 64 0 0 1 48 168Z"
    return (RING(128, 104, 56, 14, f) + C(144, 94, 9, f) + F("M180 104L204 112L180 120Z", f) + F(shell, f))


# ---------- digit characters ----------
@motif("Eight Glasses", "A sideways 8 becomes a pair of glasses.")
def _(f, b):
    return (RING(94, 112, 34, 16, f) + RING(162, 112, 34, 16, f) + ST("M60 112H40M196 112H216", 12, f)
            + ST("M98 172Q128 194 158 172", 12, f))


@motif("Three Cat", "A cat whose mouth is a sideways 3.")
def _(f, b):
    ears = F("M60 108L66 34L114 80ZM196 108L190 34L142 80Z", f, f' stroke="{f}" stroke-width="10" stroke-linejoin="round"')
    return (ears + head(f) + C(98, 138, 12, f) + C(158, 138, 12, f)
            + ST("M98 166Q100 186 113 186Q128 186 128 168Q128 186 143 186Q156 186 158 166", 10, f))


@motif("Four Boat", "The digit 4 is the sail and mast of a boat.")
def _(f, b):
    return ST("M146 32V176M146 32L74 138H182", 18, f) + F("M40 186H216L190 220H66Z", f, f' stroke="{f}" stroke-width="8" stroke-linejoin="round"')


@motif("Six Snail", "A snail whose shell is a 6: slow and steady.")
def _(f, b):
    return (RING(122, 140, 42, 18, f) + ST("M80 140C80 84 110 52 156 50", 18, f) + F(rr(28, 186, 200, 28, 14), f)
            + ST("M206 188L218 150M218 188L234 160", 8, f) + C(218, 148, 7, f) + C(234, 158, 7, f))


@motif("Two Swan", "The digit 2 is a swan on the water.")
def _(f, b):
    return (ST("M84 94A46 46 0 1 1 166 120L90 200H206", 18, f) + F("M84 86L58 100L84 106Z", f)
            + C(100, 82, 5, b) + ST("M40 226H216", 8, f, extra=' stroke-dasharray="22 12"'))


@motif("One Pencil", "The digit 1 is a pencil, for your notes.")
def _(f, b):
    return (F(rr(110, 56, 36, 136, 6) + "M110 196H146L128 234Z", f) + ST("M110 64L80 86", 18, f)
            + F("M110 82H146V90H110Z", b) + C(128, 222, 0, f))


@motif("Nine Balloon", "A 9 whose head is a balloon and whose tail is the string.")
def _(f, b):
    return (RING(120, 92, 50, 18, f) + F("M162 128L176 144L156 146Z", f)
            + ST("M166 146C176 180 146 196 156 236", 9, f))


@motif("Eight Snowman", "An 8 dressed as a snowman.")
def _(f, b):
    return (RING(128, 78, 36, 14, f) + RING(128, 168, 52, 14, f) + C(116, 72, 6, f) + C(140, 72, 6, f)
            + F("M126 84L150 90L126 94Z", f) + ST("M78 150L40 124M178 150L216 124", 9, f))


@motif("One Candle", "The digit 1 as a candle, lighting up the puzzle.")
def _(f, b):
    return (F(rr(108, 96, 40, 132, 8), f) + ST("M108 104L84 120", 14, f)
            + F("M128 24C152 54 148 78 128 84C108 78 104 54 128 24Z", f))


# ---------- letters ----------
@motif("V Gull", "A V that is also a gull in flight.")
def _(f, b): return ST("M28 100Q78 66 128 140Q178 66 228 100", 24, f)


@motif("V Heart", "A heart whose point is a V.")
def _(f, b): return ST("M128 216L46 128A42 42 0 0 1 128 88A42 42 0 0 1 210 128Z", 20, f)


@motif("S Snake", "An S that is also a snake.")
def _(f, b):
    return (ST("M172 72H96A28 28 0 0 0 96 128H160A28 28 0 0 1 160 184H68", 30, f) + C(182, 72, 26, f)
            + C(190, 64, 5, b) + ST("M206 74L224 66M206 74L224 84", 5, f))


@motif("S Yin-Yang", "An S splits a circle; the two small dots are a black and a white kropki dot.")
def _(f, b):
    half = "M128 28A50 50 0 0 0 128 128A50 50 0 0 1 128 228A100 100 0 0 1 128 28Z"
    return RING(128, 128, 100, 10, f) + F(half, f) + C(128, 78, 15, f) + C(128, 178, 15, b)


# ---------- objects ----------
@motif("Grid House", "A house with a sudoku window: the home of puzzles.")
def _(f, b): return ST("M38 116L128 38L218 116V218H38Z", 14, f) + F(tiles(22, 7, 5, cy=166), f)


@motif("Grid Cookie", "A waffle cookie with a bite taken out.")
def _(f, b):
    return (C(124, 132, 98, f) + C(206, 56, 34, b) + C(228, 98, 24, b)
            + F(tiles(24, 12, 5, cx=118, cy=140), b))


@motif("Grid Gift", "A grid wrapped as a present: a new puzzle every day.")
def _(f, b):
    bow = (f'<ellipse cx="100" cy="56" rx="26" ry="15" transform="rotate(-25 100 56)" fill="none" stroke="{f}" stroke-width="11"/>'
           f'<ellipse cx="156" cy="56" rx="26" ry="15" transform="rotate(25 156 56)" fill="none" stroke="{f}" stroke-width="11"/>')
    return F(tiles(52, 10, 10, cy=156), f) + bow + C(128, 64, 11, f)


@motif("Chocolate", "A chocolate bar of cells with one piece broken off.")
def _(f, b):
    out = F(tiles(56, 8, 6, skip={(0, 2)}, cy=136), f)
    return out + grp(F(rr(-23, -23, 46, 46, 6), f), 1, 0, 0, dx=86, dy=-92, rot=20)


@motif("Fortress", "Cells stacked into a castle: the fortress variant.")
def _(f, b):
    merlons = "".join(rr(x, 44, 40, 44, 6) for x in (36, 108, 180))
    return F(merlons + rr(36, 80, 184, 148, 10), f) + F(rr4(104, 160, 48, 68, 24, 24, 0, 0), b) + F(rr(120, 108, 16, 26, 4), b)


@motif("Lollipop", "A thermometer that is also a lollipop.")
def _(f, b):
    return (C(128, 92, 58, f) + ST("M100 92A28 28 0 1 1 128 120A16 16 0 1 1 128 88", 9, b)
            + ST("M128 150V232", 16, f))


@motif("Kropki Paw", "A paw print whose toes are black and white kropki dots.")
def _(f, b):
    return (F("M80 176C80 132 104 124 128 124C152 124 176 132 176 176C176 210 146 212 128 202C110 212 80 210 80 176Z", f)
            + C(62, 104, 22, f) + RING(102, 66, 18, 9, f) + RING(154, 66, 18, 9, f) + C(194, 104, 22, f))


@motif("Patchwork", "Nine cells, nine different patterns: one grid, many variants.")
def _(f, b):
    out = ""
    for i, ((r, k), (x, y)) in enumerate(sorted(cells(60, 10).items())):
        cx, cy = x + 30, y + 30
        box = rr(x, y, 60, 60, 10)
        if i == 0:
            out += F(box, f)
        elif i == 1:
            out += ST(rr(x + 5, y + 5, 50, 50, 8), 10, f)
        elif i == 2:
            out += C(cx, cy, 30, f)
        elif i == 3:
            out += ST(rr(x + 5, y + 5, 50, 50, 8), 10, f) + C(cx, cy, 9, f)
        elif i == 4:
            out += F(poly([(cx, y), (x + 60, cy), (cx, y + 60), (x, cy)]), f)
        elif i == 5:
            out += ST(f"M{x + 6} {y + 12}H{x + 54}M{x + 6} {y + 30}H{x + 54}M{x + 6} {y + 48}H{x + 54}", 9, f)
        elif i == 6:
            out += F(f"M{x} {y + 60}V{y + 10}A10 10 0 0 1 {x + 10} {y}L{x + 60} {y + 60}Z", f)
        elif i == 7:
            out += RING(cx, cy, 24, 10, f)
        else:
            out += F(tiles(16, 6, 3, cx=cx, cy=cy), f)
    return out


@motif("Steam S Mug", "A mug whose steam curls into an S: a puzzle with your morning coffee.")
def _(f, b):
    return (F(rr(50, 118, 124, 100, 18), f) + RING(184, 160, 24, 14, f)
            + ST("M98 100C78 84 118 72 98 54C88 44 100 34 106 28M138 100C118 84 158 72 138 54C128 44 140 34 146 28", 10, f))


@motif("Grid Glasses", "Glasses with a sudoku grid in each lens.")
def _(f, b):
    lens = ""
    for x in (34, 142):
        lens += ST(rr(x, 92, 80, 72, 20), 13, f)
        lens += ST(f"M{x + 27} 96V160M{x + 53} 96V160M{x + 4} 116H{x + 76}M{x + 4} 140H{x + 76}", 4, f, cap="butt")
    return lens + ST("M114 112Q128 100 142 112", 10, f) + ST("M34 108L18 100M222 108L238 100", 10, f)


@motif("Trophy", "A trophy with a grid on its cup: achievements.")
def _(f, b):
    return (F("M74 44H182V92A54 54 0 0 1 74 92Z", f) + ST("M74 64H52Q46 100 80 112M182 64H204Q210 100 176 112", 12, f)
            + F(rr(116, 144, 24, 40, 4) + rr(80, 184, 96, 28, 8), f) + F(tiles(12, 5, 2, cy=84), b))


@motif("Grid Turtle", "A turtle with a sudoku grid on its shell.")
def _(f, b):
    return (F("M26 170A88 88 0 0 1 202 170Z", f) + C(220, 156, 18, f) + F(rr(50, 164, 28, 34, 10) + rr(150, 164, 28, 34, 10), f)
            + ST("M85 92V170M143 92V170M34 128H194", 6, b, cap="butt"))


@motif("Kropki Ladybug", "A ladybug whose spots are kropki dots.")
def _(f, b):
    return (C(128, 62, 30, f) + C(128, 146, 84, f) + ST("M128 66V230", 6, b, cap="butt")
            + C(90, 120, 15, b) + RING(166, 120, 13, 6, b) + RING(92, 182, 13, 6, b) + C(164, 182, 15, b)
            + ST("M114 36L98 16M142 36L158 16", 6, f))


@motif("Rocket", "A rocket with cell windows: blast through the levels.")
def _(f, b):
    body = "M128 20C168 56 176 110 166 176H90C80 110 88 56 128 20Z"
    return (F(body + "M90 140L58 184L92 178ZM166 140L198 184L164 178Z", f) + F(tiles(18, 6, 4, cols=1, rows=3, cy=104), b)
            + F("M106 182H150L128 230Z", f))


@motif("Grid Balloon", "A hot-air balloon painted with a grid.")
def _(f, b):
    env = "M128 22A82 82 0 0 1 196 150L150 186H106L60 150A82 82 0 0 1 128 22Z"
    return (F(env, f) + ST("M100 30Q84 110 108 184M156 30Q172 110 148 184M50 104H206", 6, b, cap="butt")
            + F(rr(106, 202, 44, 32, 6), f) + ST("M110 186V202M146 186V202", 5, f))


@motif("V Cone", "An ice-cream cone (a V) with a kropki-dot scoop.")
def _(f, b):
    return (F("M60 112H196L128 234Z", f) + C(128, 90, 46, f) + C(128, 30, 14, f)
            + ST("M84 136L150 192M120 136L168 176", 6, b, cap="butt"))


# ---------- geometry ----------
@motif("Whirl", "Nested squares turning inward: a puzzle that pulls you in.")
def _(f, b):
    out, s = "", 196
    for k in range(5):
        out += grp(ST(rr(-s / 2, -s / 2, s, s, s * 0.14), 10, f), 1, 0, 0, rot=k * 11)
        s *= 0.76
    return out


@motif("Rings", "Nine linked rings in a 3x3: every cell connects.")
def _(f, b):
    return "".join(RING(64 + 64 * k, 64 + 64 * r, 36, 9, f) for r in range(3) for k in range(3))


@motif("Puzzle Box", "A box whose lid is a 3x3 grid.")
def _(f, b):
    top = [(128, 34), (214, 84), (128, 134), (42, 84)]
    out = F(poly([(42, 84), (128, 134), (128, 230), (42, 180)]), f)
    out += ST(poly([(128, 134), (214, 84), (214, 180), (128, 230)]), 10, f)
    out += ST(poly(top), 10, f)
    for t in (1 / 3, 2 / 3):
        a = (128 + 86 * t, 34 + 50 * t)
        bb = (42 + 86 * t, 84 + 50 * t)
        c2 = (42 + 86 * t, 84 - 50 * t)
        d2 = (128 + 86 * t, 134 - 50 * t)
        out += ST(f"M{a[0]:.1f} {a[1]:.1f}L{bb[0]:.1f} {bb[1]:.1f}M{c2[0]:.1f} {c2[1]:.1f}L{d2[0]:.1f} {d2[1]:.1f}", 5, f)
    return out


@motif("Lock Ls", "Two pieces lock into one square: an L and a box.")
def _(f, b):
    u, o, i = 64, 32, 6
    Lp = poly([(o + i, o + i), (o + u - i, o + i), (o + u - i, o + 2 * u + i), (o + 3 * u - i, o + 2 * u + i),
               (o + 3 * u - i, o + 3 * u - i), (o + i, o + 3 * u - i)])
    return F(Lp, f, f' stroke="{f}" stroke-width="10" stroke-linejoin="round"') + ST(rr(o + u + 14, o + 14, 2 * u - 28, 2 * u - 28, 10), 12, f)


@motif("Mondrian", "A square cut into uneven regions, solid and open: jigsaw regions.")
def _(f, b):
    return (F(rr(32, 32, 100, 118, 10) + rr(142, 102, 82, 48, 10) + rr(100, 160, 124, 64, 10), f)
            + ST(rr(147, 37, 72, 50, 8), 10, f) + ST(rr(37, 165, 48, 54, 8), 10, f))


@motif("Bricks", "Cells laid like bricks: build the solution one digit at a time.")
def _(f, b):
    out = ""
    for r in range(4):
        off = 0 if r % 2 == 0 else -36
        for k in range(4):
            x = 28 + off + k * 72
            x0, x1 = max(x, 28), min(x + 64, 228)
            if x1 - x0 > 20:
                out += rr(x0, 40 + r * 46, x1 - x0, 38, 8)
    return F(out, f)


@motif("Card Fan", "Three puzzle cards fanned out: pick your variant.")
def _(f, b):
    card = rr(84, 44, 88, 128, 14)
    out = grp(ST(card, 10, f), 1, 128, 208, dy=80, rot=-20) + grp(ST(card, 10, f), 1, 128, 208, dy=80, rot=20)
    return out + grp(F(card, f) + F(tiles(18, 7, 4, cy=108), b), 1, 128, 208, dy=80)


@motif("Stack", "A stack of three cells: many puzzles, one after another.")
def _(f, b):
    return ST(rr(84, 30, 130, 130, 26), 12, f) + ST(rr(63, 63, 130, 130, 26), 12, f) + F(rr(42, 96, 130, 130, 26), f)


@motif("Pixel Heart", "A heart drawn in cells.")
def _(f, b): return pixel("0110110/1111111/1111111/0111110/0011100/0001000", f, 26, 4, 5)


@motif("Shift", "A circle cut into three bands; the middle one slides: a variant.")
def _(f, b):
    top = "M42 96A100 100 0 0 1 214 96Z"
    mid = "M28 106H228V150H28Z"
    bot = "M42 160H214A100 100 0 0 1 42 160Z"
    return F(top + bot, f) + grp(F(mid, f) + "", 1, 128, 128, dx=22)


# ---------- clue ideas ----------
@motif("Thermo Sprout", "A branching thermometer that grows like a sprout.")
def _(f, b): return C(128, 200, 30, f) + ST("M128 200V128M128 128L84 80M128 128L172 80", 18, f)


@motif("Palindrome", "A line that mirrors itself across the middle.")
def _(f, b):
    return (ST("M128 30V226", 5, f, extra=' stroke-dasharray="10 10"')
            + ST("M44 176Q72 52 106 120Q118 146 128 146Q138 146 150 120Q184 52 212 176", 16, f))


@motif("Sandwich Bun", "Sandwich sudoku, drawn as an actual sandwich.")
def _(f, b):
    return (F("M44 112A84 68 0 0 1 212 112Z", f) + C(100, 84, 5, b) + C(128, 72, 5, b) + C(156, 84, 5, b)
            + F(tiles(46, 8, 8, cols=3, rows=1, cy=146), f) + F(rr(44, 180, 168, 34, 17), f))


@motif("Cage Chat", "A speech bubble drawn as a killer cage, total in its corner.")
def _(f, b):
    return (ST(rr(30, 40, 196, 142, 34) + "M70 182L62 224L108 182", 11, f, extra=' stroke-dasharray="16 11"')
            + G("9", 46, 66, 78, f))


@motif("V O'Clock", "A clock whose hands make a V: the timer.")
def _(f, b):
    ticks = "".join(C(128 + 84 * math.cos(math.radians(a)), 128 + 84 * math.sin(math.radians(a)), 6, f)
                    for a in range(0, 360, 30))
    return (RING(128, 128, 104, 12, f) + ticks
            + ST(f"M{128 - 62 * S3 / 2:.1f} {128 - 31:.1f}L128 128L{128 + 62 * S3 / 2:.1f} {128 - 31:.1f}", 16, f)
            + C(128, 128, 12, f))


@motif("Zipper", "A zipper: the zipper-line variant, closing the puzzle.")
def _(f, b):
    teeth = "".join(rr(98 if i % 2 else 128, 22 + i * 18, 30, 12, 4) for i in range(8))
    return F(teeth, f) + F(rr(100, 166, 56, 36, 10), f) + RING(128, 218, 16, 9, f)


# ---------- styles ----------
STYLES = [
    ("a", "ink", lambda m: m(INK, WHITE)),
    ("b", "cell", lambda m: ST(rr(18, 18, 220, 220, 48), 14, INK) + grp(m(INK, WHITE), 0.68)),
    ("c", "ink tile", lambda m: F(rr(12, 12, 232, 232, 56), INK) + grp(m(WHITE, INK), 0.68)),
    ("d", "blue tile", lambda m: F(rr(12, 12, 232, 232, 56), ACCENT) + grp(m(WHITE, ACCENT), 0.68)),
    ("e", "gold badge", lambda m: C(128, 128, 118, GOLD) + grp(m(INK, GOLD), 0.62)),
]

FIRST = 128
rows = []
for i, (name, note, fn) in enumerate(L):
    num = FIRST + i
    for code, label, st in STYLES:
        open(f"{OUT}/{num:03d}{code}-{VER}.svg", "w").write(svg(256, st(fn), f"Sudoku Variants {num}{code}"))
    rows.append(f"{num}\t{name}\t{note}")
open(f"{OUT}/index.txt", "w", encoding="utf-8").write("\n".join(rows))
print(len(L), "motifs,", len(L) * len(STYLES), "logos")
