"""Nine Smile logo kit: masters, lockups, pixel favicon, Steam art.
Usage: python kit.py <DMSerif.ttf> <kit_dir>"""
import sys, os, math
sys.argv = [sys.argv[0], sys.argv[1], sys.argv[2], "kit"]
from common import *  # noqa: F401,F403  (text_path, rr, gs, cmap, upm, OUT)
from fontTools.pens.boundsPen import BoundsPen

K = OUT
for d in ("master", "lockups", "steam", "godot"):
    os.makedirs(f"{K}/{d}", exist_ok=True)

INK, PAPER, WHITE, BLUE, GOLD = "#0e0e12", "#f8f7f2", "#ffffff", "#2a4fff", "#e8a020"

# ---------- the mark: outlined geometry ----------
# Drawn on the 256 design grid used in the concepts (face centred at x=128), then scaled 1.45 about (128, 133)
# so the face fills the canvas. Everything is a filled shape: no strokes, no transforms in the master.
S, CY = 1.45, 133


def P(x, y):
    return 128 + S * (x - 128), 128 + S * (y - CY)


def fmt(v):
    return f"{v:.2f}".rstrip("0").rstrip(".")


def circle_path(cx, cy, r):
    x, y = P(cx, cy)
    r = S * r
    return f"M{fmt(x - r)} {fmt(y)}A{fmt(r)} {fmt(r)} 0 1 0 {fmt(x + r)} {fmt(y)}A{fmt(r)} {fmt(r)} 0 1 0 {fmt(x - r)} {fmt(y)}Z"


def ring_path(cx, cy, ro, ri):
    return circle_path(cx, cy, ro) + circle_path(cx, cy, ri)   # used with fill-rule evenodd


def smile_path():
    """The 9's stem and the smile, as an outline: stroke 14 offset by 7 each side, round cap at the left end."""
    w = 7
    rx, ry, mx, my = 52, 40, 128, 144
    a = math.radians(25)
    ox, oy = mx - (rx + w) * math.cos(a), my + (ry + w) * math.sin(a)      # outer end
    ix, iy = mx - (rx - w) * math.cos(a), my + (ry - w) * math.sin(a)      # inner end
    pts = {k: P(*v) for k, v in {"s0": (180 + w, 94), "s1": (180 + w, 144), "oe": (ox, oy), "ie": (ix, iy),
                                  "i1": (180 - w, 144), "i0": (180 - w, 94)}.items()}
    f = lambda k: f"{fmt(pts[k][0])} {fmt(pts[k][1])}"
    return (f"M{f('s0')}L{f('s1')}A{fmt(S * (rx + w))} {fmt(S * (ry + w))} 0 0 1 {f('oe')}"
            f"A{fmt(S * w)} {fmt(S * w)} 0 0 1 {f('ie')}A{fmt(S * (rx - w))} {fmt(S * (ry - w))} 0 0 0 {f('i1')}"
            f"L{f('i0')}Z")


def face(c):
    return (f'<path fill="{c}" d="{circle_path(96, 94, 17)}{smile_path()}"/>'
            f'<path fill="{c}" fill-rule="evenodd" d="{ring_path(160, 94, 27, 13)}"/>')


def scaled(body, s, cx=128, cy=128, dx=0, dy=0):
    return f'<g transform="translate({fmt(cx + dx)} {fmt(cy + dy)}) scale({s}) translate(-128 -128)">{body}</g>'


def svg(w, h, body, title):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {fmt(w)} {fmt(h)}" width="{fmt(w)}" '
            f'height="{fmt(h)}" role="img" aria-labelledby="t"><title id="t">{title}</title>\n{body}\n</svg>\n')


CELL_R, CELL_W = 48, 14


def cell_outline(c):
    """The cell: a rounded square outline, as a filled ring (no stroke)."""
    o = rr(18 - CELL_W / 2, 18 - CELL_W / 2, 220 + CELL_W, 220 + CELL_W, CELL_R + CELL_W / 2)
    i = rr(18 + CELL_W / 2, 18 + CELL_W / 2, 220 - CELL_W, 220 - CELL_W, CELL_R - CELL_W / 2)
    return f'<path fill="{c}" fill-rule="evenodd" d="{o}{i}"/>'


def tile(c):
    return f'<path fill="{c}" d="{rr(12, 12, 232, 232, 56)}"/>'


def sym_face(c):          return face(c)
def sym_cell(c):          return cell_outline(c) + scaled(face(c), 0.68)
def sym_tile(bg, fg):     return tile(bg) + scaled(face(fg), 0.68)


# ---------- the 16 px cut: hand-drawn pixels ----------
PIX16 = """
................
................
................
..........##....
...###...#..#...
...###...#..#...
...###....###...
............#...
............#...
............#...
...#........#...
....#......#....
.....######.....
................
................
................"""


def pixel_tile(bg, fg, rounded=True):
    rows = PIX16.strip("\n").split("\n")
    out = [f'<rect width="16" height="16" rx="3.5" fill="{bg}"/>' if bg else ""]
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "#":
                out.append(f'<rect x="{x}" y="{y}" width="1" height="1" fill="{fg}"/>')
    return f'<g shape-rendering="crispEdges">{"".join(out)}</g>'


# ---------- type ----------
def text_bounds(text, size, tracking=1):
    s = size / upm
    bp = BoundsPen(gs)
    x = 0
    from fontTools.pens.transformPen import TransformPen
    for ch in text:
        g = cmap[ord(ch)]
        gs[g].draw(TransformPen(bp, (s, 0, 0, -s, x, 0)))
        x += gs[g].width * s + tracking
    return bp.bounds   # x0, y0, x1, y1 relative to (0, baseline)


def word_lines(lines, size, x, top, c, align="left", width=None, lead=0.93, tracking=1):
    """Wordmark lines; `top` = top of the first line's capitals. Returns (svg, right edge, bottom)."""
    cap = -text_bounds("S", size)[1]
    body, right = "", x
    base = top + cap
    for i, ln in enumerate(lines):
        x0, _, x1, _ = text_bounds(ln, size, tracking)
        lx = x - x0 if align == "left" else x + (width - (x1 - x0)) / 2 - x0
        d, adv = text_path(ln, size, lx, base + i * size * lead, tracking)
        body += f'<path fill="{c}" d="{d}"/>'
        right = max(right, lx + x1)
    bottom = base + (len(lines) - 1) * size * lead + text_bounds("p", size)[3] * 0
    return body, right, bottom


# ink bounds of the face in the 256 canvas (for spacing): eye left edge .. stem right edge
FACE_X0, FACE_X1 = P(96 - 17, 0)[0], P(187, 0)[0]
FACE_Y0, FACE_Y1 = P(0, 94 - 27)[1], P(0, 144 + 47)[1]
U = 2 * 17 * S        # spacing unit = diameter of the eye dot (49 units on the 256 symbol)

# ---------- write masters ----------
def write(path, w, h, body, title):
    open(f"{K}/{path}", "w", encoding="utf-8").write(svg(w, h, body, title))


write("master/nine-smile-face.svg", 256, 256, sym_face(INK), "Sudoku Variants - Nine Smile")
write("master/nine-smile-cell.svg", 256, 256, sym_cell(INK), "Sudoku Variants - Nine Smile in a cell")
write("master/nine-smile-tile-blue.svg", 256, 256, sym_tile(BLUE, WHITE), "Sudoku Variants icon (blue)")
write("master/nine-smile-tile-ink.svg", 256, 256, sym_tile(INK, WHITE), "Sudoku Variants icon (ink)")
write("master/nine-smile-tile-gold.svg", 256, 256, sym_tile(GOLD, INK), "Sudoku Variants icon (gold)")
write("master/nine-smile-16px-blue.svg", 16, 16, pixel_tile(BLUE, WHITE), "Sudoku Variants 16 px icon")
write("master/nine-smile-16px-ink.svg", 16, 16, pixel_tile(INK, WHITE), "Sudoku Variants 16 px icon (ink)")
write("master/nine-smile-16px-face.svg", 16, 16, pixel_tile(None, INK), "Sudoku Variants 16 px face")

# ---------- lockups (height 256, symbol = the cell or tile on the 256 square) ----------
def lockup_h(sym, word_c, lines=("Sudoku", "Variants"), size=118):
    gap = 0.75 * U
    cap = -text_bounds("S", size)[1]
    block = cap + (len(lines) - 1) * size * 0.93
    top = 128 - block / 2
    body, right, _ = word_lines(lines, size, 256 + gap - 12, top, word_c)
    return sym + body, right + 12


def lockup_stack(sym, word_c, size=74):
    x0, _, x1, _ = text_bounds("Sudoku Variants", size)
    w = max(256, x1 - x0 + 24)
    body, _, _ = word_lines(["Sudoku Variants"], size, 0, 256 + 0.5 * U, word_c, align="center", width=w)
    h = 256 + 0.5 * U - text_bounds("S", size)[1] + 22
    return f'<g transform="translate({fmt((w - 256) / 2)} 0)">{sym}</g>' + body, w, h


def lockup_stack2(sym, word_c, size=104):
    """Symbol over a two-line wordmark, all centred: for tall spaces (vertical capsules, splash)."""
    w = max(256, max(text_bounds(t, size)[2] - text_bounds(t, size)[0] for t in ("Sudoku", "Variants")) + 24)
    body2 = ""
    cap = -text_bounds("S", size)[1]
    for i, t in enumerate(("Sudoku", "Variants")):
        x0, _, x1, _ = text_bounds(t, size)
        d, _ = text_path(t, size, (w - (x1 - x0)) / 2 - x0, 256 + 0.5 * U + cap + i * size * 0.93, 1)
        body2 += f'<path fill="{word_c}" d="{d}"/>'
    h = 256 + 0.5 * U + cap + size * 0.93 + 24
    return f'<g transform="translate({fmt((w - 256) / 2)} 0)">{sym}</g>' + body2, w, h


SETS = {
    "color": (sym_tile(BLUE, WHITE), INK),        # on paper / white
    "reversed": (sym_tile(BLUE, WHITE), WHITE),   # on ink / dark
    "black": (sym_cell(INK), INK),                # one colour
    "white": (sym_cell(WHITE), WHITE),            # one colour, reversed
}
for k, (sym, wc) in SETS.items():
    body, w = lockup_h(sym, wc)
    write(f"lockups/sudoku-variants-horizontal-{k}.svg", w, 256, body, "Sudoku Variants logo")
    body, w = lockup_h(sym, wc, ("Sudoku Variants",), 104)
    write(f"lockups/sudoku-variants-oneline-{k}.svg", w, 256, body, "Sudoku Variants logo")
    body, w, h = lockup_stack(sym, wc)
    write(f"lockups/sudoku-variants-stacked-{k}.svg", w, h, body, "Sudoku Variants logo")
    body, w, h = lockup_stack2(sym, wc)
    write(f"lockups/sudoku-variants-stacked-2line-{k}.svg", w, h, body, "Sudoku Variants logo")
for k, c in (("black", INK), ("white", WHITE), ("blue", BLUE)):
    body, right, _ = word_lines(["Sudoku", "Variants"], 118, 12, 20, c)
    write(f"lockups/sudoku-variants-wordmark-{k}.svg", right + 12, 256, body, "Sudoku Variants wordmark")

# ---------- Steam art ----------
def grid_pattern(w, h, cell, colour, opacity, ox=0, oy=0):
    """Sudoku grid lines: thin every cell, thick every 3 cells."""
    out = []
    n0x, n1x = int(-ox // cell) - 1, int((w - ox) // cell) + 2
    n0y, n1y = int(-oy // cell) - 1, int((h - oy) // cell) + 2
    for i in range(n0x, n1x):
        x = ox + i * cell
        out.append(f'<rect x="{fmt(x - (2 if i % 3 == 0 else 0.75))}" y="0" width="{4 if i % 3 == 0 else 1.5}" height="{h}"/>')
    for j in range(n0y, n1y):
        y = oy + j * cell
        out.append(f'<rect x="0" y="{fmt(y - (2 if j % 3 == 0 else 0.75))}" width="{w}" height="{4 if j % 3 == 0 else 1.5}"/>')
    return f'<g fill="{colour}" opacity="{opacity}">{"".join(out)}</g>'


def steam_bg(w, h, cell=None):
    cell = cell or h / 6
    return f'<rect width="{w}" height="{h}" fill="{BLUE}"/>' + grid_pattern(w, h, cell, WHITE, 0.10, w / 2 - cell * 4.5, h / 2 - cell * 4.5)


def place(svg_body, vw, vh, x, y, scale):
    return f'<g transform="translate({fmt(x)} {fmt(y)}) scale({fmt(scale)})">{svg_body}</g>'


hz_body, hz_w = lockup_h(sym_tile(INK, WHITE), WHITE)
st_body, st_w, st_h = lockup_stack2(sym_tile(INK, WHITE), WHITE)


def capsule(name, w, h, kind="h", fill=0.78):
    if kind == "h":
        sc = min(w * fill / hz_w, h * fill / 256)
        body = place(hz_body, hz_w, 256, (w - hz_w * sc) / 2, (h - 256 * sc) / 2, sc)
    else:
        sc = min(w * 0.72 / st_w, h * 0.66 / st_h)
        body = place(st_body, st_w, st_h, (w - st_w * sc) / 2, (h - st_h * sc) / 2, sc)
    write(f"steam/{name}.svg", w, h, steam_bg(w, h) + body, f"Sudoku Variants - {name}")


capsule("header-capsule-920x430", 920, 430)
capsule("small-capsule-462x174", 462, 174, fill=0.86)
capsule("main-capsule-1232x706", 1232, 706)
capsule("vertical-capsule-748x896", 748, 896, "v")
capsule("library-capsule-600x900", 600, 900, "v")
capsule("library-header-920x430", 920, 430)
write("steam/library-hero-3840x1240.svg", 3840, 1240, steam_bg(3840, 1240, 1240 / 7), "Sudoku Variants - library hero")
sc = min(1280 * 0.9 / hz_w, 720 * 0.9 / 256)
write("steam/library-logo-1280x720.svg", 1280, 720, place(hz_body, hz_w, 256, (1280 - hz_w * sc) / 2, (720 - 256 * sc) / 2, sc),
      "Sudoku Variants - library logo")
write("steam/community-icon-184x184.svg", 184, 184, f'<rect width="184" height="184" fill="{BLUE}"/>' + scaled(face(WHITE), 0.62, 92, 92),
      "Sudoku Variants - community icon")

# ---------- web icon sources (rasterised by kit_raster.py) ----------
os.makedirs(f"{K}/web", exist_ok=True)
write("web/_square.svg", 256, 256, f'<rect width="256" height="256" fill="{BLUE}"/>' + scaled(face(WHITE), 0.66),
      "Sudoku Variants")                          # iOS rounds the corners itself
write("web/_maskable.svg", 256, 256, f'<rect width="256" height="256" fill="{BLUE}"/>' + scaled(face(WHITE), 0.52),
      "Sudoku Variants")                          # face inside the 80 % safe circle

# ---------- Godot project icon ----------
write("godot/icon.svg", 256, 256, sym_tile(BLUE, WHITE), "Sudoku Variants")
print("kit written to", K)
