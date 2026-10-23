"""Round 11: the centre box of a sudoku breaks into 5 variant pieces (thermo, killer cage, kropki, arrow, V).
6 compositions x 3 palettes. Usage: python build11.py <out_dir> <version>"""
import sys, os, math

OUT, VER = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
PAPER, WHITE = "#f8f7f2", "#ffffff"
PALETTES = {
    # name: grid ink, corner-box tints, the 5 piece colours, glyph colour on pieces
    "mono": dict(ink="#0e0e12", tints=[None] * 4, pieces=["#0e0e12"] * 5, glyph=WHITE),
    "brand": dict(ink="#0e0e12", tints=[None] * 4, pieces=["#2a4fff", "#e8a020", "#2a4fff", "#e8a020", "#0e0e12"], glyph=WHITE),
    "image": dict(ink="#2b3240", tints=["#8fdcb6", "#43a39d", "#a993dc", "#5ea4dc"],
                  pieces=["#43a39d", "#a993dc", "#8fdcb6", "#5ea4dc", "#2b3240"], glyph=WHITE),
}


def f(v):
    return f"{v:.2f}".rstrip("0").rstrip(".")


def rr(x, y, w, h, r):
    return (f"M{f(x + r)} {f(y)}H{f(x + w - r)}A{f(r)} {f(r)} 0 0 1 {f(x + w)} {f(y + r)}V{f(y + h - r)}"
            f"A{f(r)} {f(r)} 0 0 1 {f(x + w - r)} {f(y + h)}H{f(x + r)}A{f(r)} {f(r)} 0 0 1 {f(x)} {f(y + h - r)}"
            f"V{f(y + r)}A{f(r)} {f(r)} 0 0 1 {f(x + r)} {f(y)}Z")


def grid(x, y, S, pal, hole=True, tints=True):
    """A 9x9 sudoku: corner boxes tinted (palette), thin cell lines, thick box lines, frame. Centre box left empty."""
    b, c = S / 3, S / 9
    out = []
    corners = [(0, 0), (2, 0), (0, 2), (2, 2)]
    for (bx, by), t in zip(corners, pal["tints"]):
        if t and tints:
            out.append(f'<rect x="{f(x + bx * b)}" y="{f(y + by * b)}" width="{f(b)}" height="{f(b)}" fill="{t}"/>')
    thin, thick = "", ""
    for i in range(1, 9):
        if i % 3:
            thin += f"M{f(x + i * c)} {f(y)}V{f(y + S)}M{f(x)} {f(y + i * c)}H{f(x + S)}"
    for i in (1, 2):
        thick += f"M{f(x + i * b)} {f(y)}V{f(y + S)}M{f(x)} {f(y + i * b)}H{f(x + S)}"
    out.append(f'<path d="{thin}" stroke="{pal["ink"]}" stroke-width="{f(S * 0.011)}" opacity="0.28"/>')
    out.append(f'<path d="{thick}" stroke="{pal["ink"]}" stroke-width="{f(S * 0.034)}"/>')
    if hole:   # the centre box is empty: the pieces came from here
        k = S * 0.017
        out.append(f'<rect x="{f(x + b + k)}" y="{f(y + b + k)}" width="{f(b - 2 * k)}" height="{f(b - 2 * k)}" fill="{PAPER}"/>')
    out.append(f'<path d="{rr(x, y, S, S, S * 0.035)}" fill="none" stroke="{pal["ink"]}" stroke-width="{f(S * 0.045)}"/>')
    return "".join(out)


# ---------- variant glyphs, drawn in a cell of size s centred on (0, 0) ----------
def glyph(kind, s, c):
    w = s * 0.11
    if kind == "thermo":
        return (f'<circle cx="{f(-s * .2)}" cy="{f(s * .2)}" r="{f(s * .17)}" fill="{c}"/>'
                f'<path d="M{f(-s * .2)} {f(s * .2)}L{f(s * .24)} {f(-s * .24)}" stroke="{c}" stroke-width="{f(w)}" stroke-linecap="round"/>')
    if kind == "cage":
        return (f'<path d="{rr(-s * .3, -s * .3, s * .6, s * .6, s * .06)}" fill="none" stroke="{c}" stroke-width="{f(s * .07)}" '
                f'stroke-dasharray="{f(s * .11)} {f(s * .07)}"/>')
    if kind == "kropki":
        return (f'<circle cx="{f(-s * .17)}" cy="0" r="{f(s * .14)}" fill="{c}"/>'
                f'<circle cx="{f(s * .19)}" cy="0" r="{f(s * .11)}" fill="none" stroke="{c}" stroke-width="{f(s * .07)}"/>')
    if kind == "arrow":
        h = s * .14
        return (f'<circle cx="{f(-s * .17)}" cy="{f(-s * .17)}" r="{f(s * .12)}" fill="none" stroke="{c}" stroke-width="{f(s * .07)}"/>'
                f'<path d="M{f(-s * .08)} {f(-s * .08)}L{f(s * .25)} {f(s * .25)}M{f(s * .25 - h)} {f(s * .25)}H{f(s * .25)}V{f(s * .25 - h)}" '
                f'fill="none" stroke="{c}" stroke-width="{f(s * .07)}" stroke-linecap="round" stroke-linejoin="round"/>')
    if kind == "v":
        return (f'<path d="M{f(-s * .22)} {f(-s * .18)}L0 {f(s * .22)}L{f(s * .22)} {f(-s * .18)}" fill="none" stroke="{c}" '
                f'stroke-width="{f(w)}" stroke-linecap="round" stroke-linejoin="round"/>')
    return ""


KINDS = ["thermo", "cage", "kropki", "arrow", "v"]


def piece(cx, cy, s, rot, colour, kind, pal, shape="tile", halo=True, w=None, h=None):
    """A piece: a rounded cell (or a jigsaw piece) with its variant glyph, outlined in paper so it reads over the grid."""
    w, h = w or s, h or s
    if shape == "jig":
        body_d = jigsaw(-s / 2, -s / 2, s)
    else:
        body_d = rr(-w / 2, -h / 2, w, h, min(w, h) * 0.16)
    halo_svg = f'<path d="{body_d}" fill="none" stroke="{PAPER}" stroke-width="{f(s * 0.16)}" stroke-linejoin="round"/>' if halo else ""
    g = glyph(kind, min(w, h), pal["glyph"])
    return (f'<g transform="translate({f(cx)} {f(cy)}) rotate({f(rot)})">{halo_svg}'
            f'<path d="{body_d}" fill="{colour}"/>{g}</g>')


def jigsaw(x, y, s):
    """Jigsaw piece: knobs out on the top and right, sockets in on the bottom and left."""
    k, a, b = s * 0.15, s * 0.36, s * 0.64
    return (f"M{f(x)} {f(y)}H{f(x + a)}A{f(k)} {f(k)} 0 1 1 {f(x + b)} {f(y)}H{f(x + s)}"
            f"V{f(y + a)}A{f(k)} {f(k)} 0 1 1 {f(x + s)} {f(y + b)}V{f(y + s)}"
            f"H{f(x + b)}A{f(k)} {f(k)} 0 1 0 {f(x + a)} {f(y + s)}H{f(x)}"
            f"V{f(y + b)}A{f(k)} {f(k)} 0 1 0 {f(x)} {f(y + a)}Z")


# ---------- compositions ----------
def burst(pal):
    """Pieces explode in place: the centre box as a pinwheel of 4 dominoes + 1 cell, pushed outward."""
    x = y = 24
    S = 208
    b, u = S / 3, S / 9
    ox, oy = x + b, y + b
    out = grid(x, y, S, pal)
    pcs = [(0, 0, 2, 1), (2, 0, 1, 2), (1, 2, 2, 1), (0, 1, 1, 2), (1, 1, 1, 1)]
    for i, (px, py, pw, ph) in enumerate(pcs):
        cx, cy = ox + (px + pw / 2) * u, oy + (py + ph / 2) * u
        dx, dy = cx - (ox + 1.5 * u), cy - (oy + 1.5 * u)
        d = math.hypot(dx, dy) or 1
        push = 0 if i == 4 else 20
        out += piece(cx + dx / d * push, cy + dy / d * push, min(pw, ph) * u - 3, [-9, 8, -9, 8, 0][i],
                     pal["pieces"][i], KINDS[i], pal, w=pw * u - 3, h=ph * u - 3)
    return out


def fly(pal, shape="tile"):
    """The centre box is empty; its 5 pieces fly out to the top right, growing as they go."""
    x, y, S = 16, 72, 168
    out = grid(x, y, S, pal)
    path = [(108, 140, 20, -10), (134, 112, 26, 12), (166, 88, 32, -14), (204, 62, 36, 10), (222, 116, 30, -8)]
    if shape == "jig":
        path = [(110, 140, 22, -10), (138, 108, 28, 14), (172, 82, 34, -12), (210, 50, 38, 8), (214, 120, 32, -16)]
    for i, (cx, cy, s, r) in enumerate(path):
        out += piece(cx, cy, s, r, pal["pieces"][i], KINDS[i], pal, shape=shape)
    return out


def lift(pal):
    """The centre box pops up out of the grid as a stack of 5 variant cards."""
    x = y = 24
    S = 208
    b = S / 3
    out = grid(x, y, S, pal)
    for i in range(5):
        cx = x + 1.5 * b + i * 9
        cy = y + 1.5 * b - i * 9
        out += piece(cx, cy, b - 8, 0, pal["pieces"][4 - i], "thermo" if i == 4 else "", pal)
    return out


def slices(pal):
    """The centre box slides out as 5 strips, stepping down like a staircase: 5 rules from one box."""
    x = y = 24
    S = 208
    b = S / 3
    out = grid(x, y, S, pal)
    sw = (b - 6) / 5
    for i in range(5):
        cx = x + b + 3 + sw * (i + 0.5)
        cy = y + 1.5 * b + i * 9 - 18
        out += piece(cx, cy, sw, 0, pal["pieces"][i], "", pal, w=sw - 2, h=b - 8)
    return out


def radial(pal):
    """The centre box bursts out in every direction: 5 pieces land on the boxes around it."""
    x = y = 24
    S = 208
    out = grid(x, y, S, pal)
    for i in range(5):
        a = math.radians(-90 + i * 72)
        cx, cy = 128 + 58 * math.cos(a), 128 + 58 * math.sin(a)
        out += piece(cx, cy, 40, (i * 37) % 30 - 15, pal["pieces"][i], KINDS[i], pal)
    return out


CONCEPTS = [
    ("Burst", "The centre box explodes in place into 4 dominoes and a cell, one variant each.", burst),
    ("Fly Out", "The centre box is empty: its 5 variant pieces fly out to the top right, like your image.", fly),
    ("Jigsaw Fly", "The same, with jigsaw pieces: the puzzle comes apart into variants.", lambda p: fly(p, "jig")),
    ("Lift", "The centre box lifts out of the grid as a stack of 5 variant cards.", lift),
    ("Slices", "The centre box slides out as 5 coloured strips: 5 rules from one box.", slices),
    ("Radial", "The centre box bursts in every direction; its 5 pieces land on the boxes around it.", radial),
]

idx = []
for i, (name, note, fn) in enumerate(CONCEPTS):
    for j, pn in enumerate(("mono", "brand", "image")):
        body = fn(PALETTES[pn])
        open(f"{OUT}/{i + 1:03d}{'abc'[j]}-{VER}.svg", "w", encoding="utf-8").write(
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">'
            f'<title>{name} ({pn})</title>{body}</svg>\n')
    idx.append(f"{i + 1}\t{name}\t{note}")
open(f"{OUT}/index.txt", "w", encoding="utf-8").write("\n".join(idx))
print(len(CONCEPTS), "compositions x 3 palettes")
