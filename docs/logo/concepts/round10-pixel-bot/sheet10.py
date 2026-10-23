"""Sheets for round 8: one row per motif (number, name, idea) with its 5 styles, plus 32 px and 16 px copies.
Usage: python sheet8.py <dir> <ver> <out_prefix> <title>"""
import sys, re, html

D, VER, PRE, TITLE = sys.argv[1:5]
rows = [l.split("\t") for l in open(f"{D}/index.txt", encoding="utf-8").read().splitlines()]
STY = ["a", "b", "c", "d", "e"]
LABELS = ["ink", "in a cell", "ink tile", "blue tile", "gold badge"]
PER, RH, LW, TS, PAD, TOP = 10, 172, 300, 140, 24, 130
W = PAD * 2 + LW + 5 * (TS + 14) + 80


def inner(path):
    s = open(path, encoding="utf-8").read()
    s = re.sub(r"^.*?<svg[^>]*>", "", s, flags=re.S)
    s = re.sub(r"<title[^>]*>.*?</title>", "", s, flags=re.S)
    return s.replace("</svg>", "")


def wrap(note, n=34):
    out, line = [], ""
    for w in note.split():
        if len(line) + len(w) > n:
            out.append(line)
            line = w
        else:
            line = (line + " " + w).strip()
    return out + [line]


pages = (len(rows) + PER - 1) // PER
for p in range(pages):
    chunk = rows[p * PER:(p + 1) * PER]
    H = TOP + len(chunk) * RH + PAD
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">',
         f'<rect width="{W}" height="{H}" fill="#f8f7f2"/>',
         f'<text x="{PAD}" y="56" font-family="Segoe UI, Arial" font-size="32" font-weight="700" fill="#0e0e12">'
         f'{html.escape(TITLE)} ({p + 1}/{pages})</text>',
         f'<text x="{PAD}" y="86" font-family="Segoe UI, Arial" font-size="16" fill="#5a5a6e">'
         f'Each idea in 5 styles (a-e). Right: the sprite at 2x and at its true size (1 pixel = 1 pixel).</text>']
    for j, lab in enumerate(LABELS):
        x = PAD + LW + j * (TS + 14) + TS / 2
        o.append(f'<text x="{x}" y="118" text-anchor="middle" font-family="Segoe UI, Arial" font-size="15" '
                 f'fill="#5a5a6e">{STY[j]} · {lab}</text>')
    for i, (num, name, note, sw, sh) in enumerate(chunk):
        y = TOP + i * RH
        o.append(f'<rect x="{PAD - 8}" y="{y}" width="{W - 2 * PAD + 16}" height="{RH - 12}" rx="14" fill="#fff" stroke="#e6e4dc"/>')
        o.append(f'<text x="{PAD + 10}" y="{y + 40}" font-family="Segoe UI, Arial" font-size="21" font-weight="700" '
                 f'fill="#0e0e12">{num} · {html.escape(name)}</text>')
        for k, ln in enumerate(wrap(note)[:4]):
            o.append(f'<text x="{PAD + 10}" y="{y + 68 + k * 20}" font-family="Segoe UI, Arial" font-size="15" '
                     f'fill="#5a5a6e">{html.escape(ln)}</text>')
        for j, s in enumerate(STY):
            body = inner(f"{D}/{int(num):03d}{s}-{VER}.svg")
            x = PAD + LW + j * (TS + 14)
            o.append(f'<svg x="{x}" y="{y + 10}" width="{TS}" height="{TS}" viewBox="0 0 256 256">{body}</svg>')
        body = inner(f"{D}/{int(num):03d}n-{VER}.svg")
        x = PAD + LW + 5 * (TS + 14) + 10
        sw, sh = int(sw), int(sh)
        o.append(f'<svg x="{x}" y="{y + 30}" width="{sw * 2}" height="{sh * 2}" viewBox="0 0 {sw} {sh}" shape-rendering="crispEdges">{body}</svg>')
        o.append(f'<svg x="{x + 8}" y="{y + 40 + sh * 2}" width="{sw}" height="{sh}" viewBox="0 0 {sw} {sh}" shape-rendering="crispEdges">{body}</svg>')
    o.append("</svg>")
    fn = f"{PRE}-{p + 1}.svg"
    open(fn, "w", encoding="utf-8").write("\n".join(o))
    print(fn, W, H)
