"""Round 3: six more Sudoku Variants logo concepts (J-O).
Usage: python build3.py <font.ttf> <out_dir> <version>"""
import math
from common import *  # noqa: F401,F403  (text_path, glyph_centred, svg, rr, frame, INK, PAPER, OUT, VER)


# J — Seal: a round emblem; SUDOKU and VARIANTS run around the ring, a 3x3 block of cells in the middle.
def sym_j():
    size, track = 27, 3.5
    sc = size / upm
    body = (f'<circle cx="128" cy="128" r="117" fill="none" stroke="{INK}" stroke-width="8"/>'
            f'<circle cx="128" cy="128" r="76" fill="none" stroke="{INK}" stroke-width="5"/>')
    # top word: baseline r=89, caps point outward, clockwise. bottom word: baseline r=107, caps point inward,
    # running counter-clockwise so it reads left to right.
    for word, R, sign, base in (("SUDOKU", 89, 1, -89), ("VARIANTS", 107, -1, 107)):
        adv = [gs[cmap[ord(ch)]].width * sc for ch in word]
        total = sum(adv) + track * (len(adv) - 1)
        pos = -total / 2
        for ch, wd in zip(word, adv):
            th = math.degrees((pos + wd / 2) / R) * sign
            d, _ = text_path(ch, size, -wd / 2, base)
            body += f'<path d="{d}" fill="{INK}" transform="translate(128 128) rotate({th:.2f})"/>'
            pos += wd + track
    for th in (90, 270):
        body += (f'<path d="M0 -104L6 -98L0 -92L-6 -98Z" fill="{INK}" transform="translate(128 128) rotate({th})"/>')
    c, g = 26, 7
    o = 128 - (3 * c + 2 * g) / 2
    body += f'<path d="{"".join(rr(o + col * (c + g), o + row * (c + g), c, c, 6) for row in range(3) for col in range(3))}" fill="{INK}"/>'
    return body


# K — SV monogram: the serif S laid over the V's left arm, cut free by a paper outline.
def sym_k():
    v = glyph_centred("V", 186, 146, 124)
    s = glyph_centred("S", 150, 106, 134)
    return (f'<path d="{v}" fill="{INK}"/>'
            f'<path d="{s}" fill="{PAPER}" stroke="{PAPER}" stroke-width="12" stroke-linejoin="round"/>'
            f'<path d="{s}" fill="{INK}"/>')


# L — Box in Box: nine cells; the centre one is itself a 3x3 grid (boxes within the grid).
def sym_l():
    c, g, o, r = 56, 14, 30, 12
    parts = []
    for row in range(3):
        for col in range(3):
            x, y = o + col * (c + g), o + row * (c + g)
            if row == col == 1:
                t, tg = 16, 4
                parts += [rr(x + cc * (t + tg), y + rw * (t + tg), t, t, 4) for rw in range(3) for cc in range(3)]
            else:
                parts.append(rr(x, y, c, c, r))
    return f'<path d="{"".join(parts)}" fill="{INK}"/>'


# M — Letter Cells: SUDOKU set in a 3x2 block of cells, like givens in a grid (an emblem).
def sym_m():
    c, g, o = 64, 8, 24
    oy = 128 - (2 * c + g) / 2
    body = ""
    for i, ch in enumerate("SUDOKU"):
        col, row = i % 3, i // 3
        x, y = o + col * (c + g), oy + row * (c + g)
        body += f'<path d="{rr(x, y, c, c, 12)}" fill="none" stroke="{INK}" stroke-width="8"/>'
        body += f'<path d="{glyph_centred(ch, 56, x + c / 2, y + c / 2)}" fill="{INK}"/>'
    return body


# N — Jigsaw Pieces: a 3x3 box cut into three irregular regions (two L's and a bar), split by gaps.
def sym_n():
    u, g, o = 64, 12, 32           # cell, gap, origin -> 3*64 = 192 + gaps inside regions are filled
    def pt(cx, cy): return o + cx * u, o + cy * u
    def poly(pts):
        q = []
        for x, y in pts:
            q.append(f"{x} {y}")
        return "M" + "L".join(q) + "Z"
    h = g / 2 + 8                  # + half the rounding stroke
    # region outlines on the cell lattice, each inset by half the gap
    r1 = [(o + h, o + h), (o + 2 * u - h, o + h), (o + 2 * u - h, o + u - h), (o + u - h, o + u - h),
          (o + u - h, o + 2 * u - h), (o + h, o + 2 * u - h)]
    r2 = [(o + 2 * u + h, o + h), (o + 3 * u - h, o + h), (o + 3 * u - h, o + 2 * u - h), (o + u + h, o + 2 * u - h),
          (o + u + h, o + u + h), (o + 2 * u + h, o + u + h)]
    r3 = [(o + h, o + 2 * u + h), (o + 3 * u - h, o + 2 * u + h), (o + 3 * u - h, o + 3 * u - h), (o + h, o + 3 * u - h)]
    d = "".join(poly(r) for r in (r1, r2, r3))
    # rounded corners: fill + same-colour round-joined stroke, outline inset so the stroke grows back to size
    return f'<path d="{d}" fill="{INK}" stroke="{INK}" stroke-width="16" stroke-linejoin="round" transform="translate(0 0)"/>'


# O — Thermo-i: the i in "Variants" is a sudoku thermometer (bulb + line), the one sans letter in a serif word.
def sym_o():
    return (frame() + f'<path d="M128 112V190" stroke="{INK}" stroke-width="30" stroke-linecap="round"/>'
            f'<circle cx="128" cy="86" r="34" fill="{INK}"/>')


def word_thermo_i():
    size, base2 = 118, 230
    l1, x1 = text_path("Sudoku", size, 292, 120, 1)
    a, xa = text_path("Var", size, 292, base2, 1)
    s = size / 1000
    cx = xa + 140 * s
    xh = base2 - 481 * s
    i = (f'<path d="M{cx:.1f} {xh + 6:.1f}V{base2}" stroke="{INK}" stroke-width="15"/>'
         f'<circle cx="{cx:.1f}" cy="{xh - 14:.1f}" r="15" fill="{INK}"/>')
    b, x2 = text_path("ants", size, xa + 280 * s + 1, base2, 1)
    return f'<path d="{l1}{a}{b}" fill="{INK}"/>' + i, max(x1, x2)


def lockup(sym_body, word=None):
    if word:
        w_body, xm = word
    else:
        l1, x1 = text_path("Sudoku", 118, 292, 120, 1)
        l2, x2 = text_path("Variants", 118, 292, 230, 1)
        w_body, xm = f'<path d="{l1}{l2}" fill="{INK}"/>', max(x1, x2)
    return svg(int(xm + 16), sym_body + w_body, "Sudoku Variants logo")


for k, f in (("j", sym_j), ("k", sym_k), ("l", sym_l), ("m", sym_m), ("n", sym_n), ("o", sym_o)):
    open(f"{OUT}/{k}-symbol-{VER}.svg", "w").write(svg(256, f(), "Sudoku Variants symbol"))
    open(f"{OUT}/{k}-lockup-{VER}.svg", "w").write(lockup(f(), word_thermo_i() if k == "o" else None))
print("ok")
