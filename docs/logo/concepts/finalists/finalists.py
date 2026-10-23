"""Finalists board: Smile Cell, Nine Smile, Nine Bot side by side, in the same styles and in real places
(true 32/16 px icon, horizontal lockup, Steam library capsule). Usage: python finalists.py <DMSerif.ttf> <out.svg>"""
import sys
sys.argv = [sys.argv[0], sys.argv[1], ".", "fin", *sys.argv[2:]]
_src = open("build8.py", encoding="utf-8").read()
exec(_src[:_src.index("@motif(\"Nine Smile\"")])   # helpers + nine_face  # noqa: S102
OUTFILE = sys.argv[4]


def smile_cell(f, b):
    return grp(C(98, 108, 17, f) + RING(158, 108, 14, 7, f) + ST("M86 156Q128 198 170 156", 14, f), 1.45, 128, 140)


def nine_smile(f, b):
    return grp(nine_face(f, b), 1.45, 128, 133)


def nine_bot(f, b):
    return grp(nine_face(f, b, "square") + ST("M128 62V44", 8, f) + C(128, 38, 8, f), 1.45, 128, 106)


FIN = [("Smile Cell", "Kropki eyes (black + white), a whisper-line smile.", smile_cell),
       ("Nine Smile", "Right eye is a 9; its tail is the smile.", nine_smile),
       ("Nine Bot", "Square eyes; the right one a square 9 whose tail is the mouth.", nine_bot)]


def cell(m):  return ST(rr(18, 18, 220, 220, 48), 14, INK) + grp(m(INK, WHITE), 0.68)
def ink(m):   return F(rr(12, 12, 232, 232, 56), INK) + grp(m(WHITE, INK), 0.68)
def blue(m):  return F(rr(12, 12, 232, 232, 56), ACCENT) + grp(m(WHITE, ACCENT), 0.68)
def gold(m):  return C(128, 128, 118, GOLD) + grp(m(INK, GOLD), 0.62)


def word(x, base, size, fill):
    l1, x1 = text_path("Sudoku", size, x, base, 1)
    l2, x2 = text_path("Variants", size, x, base + size * 0.93, 1)
    return f'<path d="{l1}{l2}" fill="{fill}"/>', max(x1, x2)


def nest(body, x, y, s):
    return f'<svg x="{x}" y="{y}" width="{s}" height="{s}" viewBox="0 0 256 256">{body}</svg>'


W, RH, TOP = 1900, 300, 150
H = TOP + 3 * RH + 30
o = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">',
     f'<rect width="{W}" height="{H}" fill="#f8f7f2"/>',
     '<text x="30" y="62" font-family="Segoe UI, Arial" font-size="36" font-weight="700" fill="#0e0e12">'
     'Sudoku Variants - the three finalists</text>',
     '<text x="30" y="96" font-family="Segoe UI, Arial" font-size="18" fill="#5a5a6e">'
     'Same styles for all three, then where they would really be used: the icon at true size, the logo with the name, and a Steam library capsule.</text>']
heads = [("in a cell", 330), ("ink tile", 500), ("blue tile", 670), ("gold", 840), ("32 / 16 px", 990),
         ("logo with the name", 1090), ("Steam capsule", 1520)]
for t, x in heads:
    o.append(f'<text x="{x}" y="{TOP - 14}" font-family="Segoe UI, Arial" font-size="16" fill="#5a5a6e">{t}</text>')
for i, (name, note, m) in enumerate(FIN):
    y = TOP + i * RH
    o.append(f'<rect x="16" y="{y}" width="{W - 32}" height="{RH - 18}" rx="16" fill="#fff" stroke="#e6e4dc"/>')
    o.append(f'<text x="40" y="{y + 54}" font-family="Segoe UI, Arial" font-size="28" font-weight="700" fill="#0e0e12">{name}</text>')
    words, line, k = note.split(), "", 0
    for w in words + [None]:
        if w is None or len(line) + len(w) > 24:
            o.append(f'<text x="40" y="{y + 90 + k * 22}" font-family="Segoe UI, Arial" font-size="16" fill="#5a5a6e">{line}</text>')
            k += 1
            line = w or ""
        else:
            line = (line + " " + w).strip()
    for j, st in enumerate((cell, ink, blue, gold)):
        o.append(nest(st(m), 320 + j * 170, y + 50, 150))
    o.append(nest(ink(m), 1000, y + 90, 32) + nest(ink(m), 1048, y + 98, 16))
    wb, xm = word(290, 120, 112, INK)
    lock = cell(m) + wb
    o.append(f'<svg x="1090" y="{y + 70}" width="{(xm + 16) * 124 / 256:.0f}" height="124" viewBox="0 0 {xm + 16:.0f} 256">{lock}</svg>')
    cap_w, cap_h = 330, 154
    wb2, xm2 = word(0, 0, 100, WHITE)
    cap = (f'<rect width="460" height="215" rx="10" fill="{ACCENT}"/>'
           f'<svg x="28" y="38" width="140" height="140" viewBox="0 0 256 256">{ink(m)}</svg>'
           f'<g transform="translate(192 100) scale(0.42)">{wb2}</g>')
    o.append(f'<svg x="1520" y="{y + 52}" width="{cap_w}" height="{cap_h}" viewBox="0 0 460 215">{cap}</svg>')
o.append("</svg>")
open(OUTFILE, "w", encoding="utf-8").write("\n".join(o))
print("ok", W, H)
