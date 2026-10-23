"""Round 6: double-meaning concepts (each mark reads two or three ways).
Usage: python build6.py <DMSerif.ttf> <out_dir> <version>"""
from common import *  # noqa: F401,F403


def ST(d, w, c=INK, cap="round", join="round"):
    return (f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="{cap}" '
            f'stroke-linejoin="{join}"/>')


def C(x, y, r, c=INK):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}"/>'


# 1 Arrow-9: an arrow-sudoku clue (hollow sum circle + arrow) bent into the digit 9.
def arrow9():
    return (f'<circle cx="122" cy="82" r="50" fill="none" stroke="{INK}" stroke-width="24"/>'
            + ST("M172 82V170A44 44 0 0 1 128 214H92M114 192L92 214L114 236", 24))


# 2 Check-V: a serif V (thick left arm, thin right arm) whose right arm runs on up: V for Variants and a tick.
def check_v():
    return (f'<path d="M43.5 86H104L142 196L206 34H224L150 222H122Z" fill="{INK}" stroke="{INK}" stroke-width="6" '
            f'stroke-linejoin="round"/><path d="M33 86H114" stroke="{INK}" stroke-width="10"/>')


# 3 Nine-Key: a 9 whose head is a cell and whose tail has key teeth.
def nine_key():
    return (f'<g transform="translate(-10 -6)">'
            + f'<path d="{rr(74, 34, 104, 100, 30)}" fill="none" stroke="{INK}" stroke-width="30"/>'
            + f'<path d="M163 100H193V236H163ZM193 172H221V190H193ZM193 206H213V224H193Z" fill="{INK}"/></g>')


# 4 Question Thermo: a question mark whose hook is a thermometer (bulb at its start); the dot is a kropki dot.
def question():
    return (C(84, 86, 36) + ST("M84 86A46 46 0 1 1 152 126Q130 138 130 162", 20) + C(130, 212, 17))


# 5 S-Cage: a killer cage drawn round an S of cells (3x5): the letter S and a cage at once.
def s_cage():
    u, k = 40, 7                              # cell, inset
    ox, oy = 128 - 1.5 * u, 128 - 2.5 * u
    pts = [(0, 0), (3, 0), (3, 1), (1, 1), (1, 2), (3, 2), (3, 5), (0, 5), (0, 4), (2, 4), (2, 3), (0, 3)]
    out = []
    n = len(pts)
    for i in range(n):                        # clockwise: inward normal of edge (dx, dy) is (-dy, dx)
        (x0, y0), (x1, y1), (x2, y2) = pts[i - 1], pts[i], pts[(i + 1) % n]
        a = ((x1 > x0) - (x1 < x0), (y1 > y0) - (y1 < y0))
        b = ((x2 > x1) - (x2 < x1), (y2 > y1) - (y2 < y1))
        nx, ny = -a[1] - b[1], a[0] + b[0]
        out.append((ox + x1 * u + nx * k, oy + y1 * u + ny * k))
    d = "M" + "L".join(f"{x:.1f} {y:.1f}" for x, y in out) + "Z"
    return (f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="10" stroke-linejoin="round" '
            f'stroke-dasharray="12 9"/>')


# 6 Smile Cell: a cell whose eyes are a black and a white kropki dot and whose smile is a whisper line.
def smile():
    return (frame() + C(98, 108, 17)
            + f'<circle cx="158" cy="108" r="14" fill="none" stroke="{INK}" stroke-width="7"/>'
            + ST("M86 156Q128 198 170 156", 14))


def lockup(sym_body):
    l1, x1 = text_path("Sudoku", 118, 292, 120, 1)
    l2, x2 = text_path("Variants", 118, 292, 230, 1)
    return svg(int(max(x1, x2) + 16), f'{sym_body}<path d="{l1}{l2}" fill="{INK}"/>', "Sudoku Variants logo")


for k, f in (("d1", arrow9), ("d2", check_v), ("d3", nine_key), ("d4", question), ("d5", s_cage), ("d6", smile)):
    open(f"{OUT}/{k}-symbol-{VER}.svg", "w").write(svg(256, f(), "Sudoku Variants symbol"))
    open(f"{OUT}/{k}-lockup-{VER}.svg", "w").write(lockup(f()))
print("ok")
