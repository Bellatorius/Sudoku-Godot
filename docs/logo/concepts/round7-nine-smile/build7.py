"""Round 7: the Nine Smile. A face in a cell: left eye a kropki dot, right eye the head of a 9 whose tail
runs down into the smile. Usage: python build7.py <DMSerif.ttf> <out_dir> <version> [mouth ry] [left-end angle]"""
import math
from common import *  # noqa: F401,F403

RY = float(sys.argv[4]) if len(sys.argv) > 4 else 40      # mouth depth
END = float(sys.argv[5]) if len(sys.argv) > 5 else 25     # where the left end stops, degrees above the mouth line


def ST(d, w, c=INK):
    return f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'


def C(x, y, r, c=INK):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}"/>'


# The face is symmetric about x=128: left eye at 128-32, the 9's ring at 128+32, so the 9's stem (ring centre + r)
# is x=180 and the mouth is a half ellipse centred on 128 whose right end is exactly the stem: the stem meets the
# mouth with a vertical tangent (no kink). The left end stops END degrees short of vertical so it doesn't read as a U.
EY, ER, MY, RX = 94, 20, 144, 52


def nine_smile(w=14, c=INK):
    sx = 128 + 32 + ER                                     # = 128 + RX: stem line = right end of the mouth
    a = math.radians(END)
    lx, ly = 128 - RX * math.cos(a), MY + RY * math.sin(a)
    return (f'<circle cx="{128 + 32}" cy="{EY}" r="{ER}" fill="none" stroke="{c}" stroke-width="{w}"/>'
            + ST(f"M{sx} {EY}V{MY}A{RX} {RY:g} 0 0 1 {lx:.1f} {ly:.1f}", w, c))


def eye(c=INK):
    return C(96, EY, 17, c)


# A — in a cell, black kropki left eye
def a():
    return frame() + eye() + nine_smile()


# B — no cell, the face alone, larger
def b():
    return f'<g transform="translate(128 128) scale(1.3) translate(-128 -134)">' + eye() + nine_smile(15) + '</g>'


# C — in a cell, white kropki left eye (echoes the ring of the 9)
def c():
    return frame() + f'<circle cx="96" cy="{EY}" r="16" fill="none" stroke="{INK}" stroke-width="10"/>' + nine_smile()


# D — solid tile, face in paper (app-icon style)
def d():
    return f'<path d="{rr(24, 24, 208, 208, 50)}" fill="{INK}"/>' + eye(PAPER) + nine_smile(c=PAPER)


def lockup(sym_body):
    l1, x1 = text_path("Sudoku", 118, 292, 120, 1)
    l2, x2 = text_path("Variants", 118, 292, 230, 1)
    return svg(int(max(x1, x2) + 16), f'{sym_body}<path d="{l1}{l2}" fill="{INK}"/>', "Sudoku Variants logo")


for k, f in (("n1", a), ("n2", b), ("n3", c), ("n4", d)):
    open(f"{OUT}/{k}-symbol-{VER}.svg", "w").write(svg(256, f(), "Sudoku Variants symbol"))
    open(f"{OUT}/{k}-lockup-{VER}.svg", "w").write(lockup(f()))
print("ok")
