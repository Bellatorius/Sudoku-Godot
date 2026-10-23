"""Contact sheets: 25 symbols per sheet (5x5), each with its number, name, a 32px and a 16px copy.
Usage: python sheet.py <dir with NNN-symbol-<ver>.svg + index.txt> <ver> <out_prefix> <title>"""
import sys, re, html

D, VER, PRE, TITLE = sys.argv[1:5]
rows = [l.split("\t") for l in open(f"{D}/index.txt", encoding="utf-8").read().splitlines()]
COLS, PER, CW, CH, PAD, TOP = 5, 25, 300, 290, 24, 110


def inner(path):
    s = open(path, encoding="utf-8").read()
    s = re.sub(r"^.*?<svg[^>]*>", "", s, flags=re.S)
    s = re.sub(r"<title[^>]*>.*?</title>", "", s, flags=re.S)
    return s.replace("</svg>", "")


for p in range(0, len(rows), PER):
    chunk = rows[p:p + PER]
    nrows = (len(chunk) + COLS - 1) // COLS
    W, H = PAD * 2 + COLS * CW, TOP + nrows * CH + PAD
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">',
           f'<rect width="{W}" height="{H}" fill="#f8f7f2"/>',
           f'<text x="{PAD}" y="58" font-family="Segoe UI, Arial" font-size="34" font-weight="700" fill="#0e0e12">'
           f'{html.escape(TITLE)} ({p // PER + 1}/{(len(rows) + PER - 1) // PER})</text>',
           f'<text x="{PAD}" y="90" font-family="Segoe UI, Arial" font-size="17" fill="#5a5a6e">'
           f'Symbols only; each pairs with the Sudoku Variants wordmark. Small copies at true 32 px and 16 px.</text>']
    for i, (num, name, note) in enumerate(chunk):
        x, y = PAD + (i % COLS) * CW, TOP + (i // COLS) * CH
        body = inner(f"{D}/{int(num):03d}-symbol-{VER}.svg")
        out.append(f'<rect x="{x + 8}" y="{y}" width="{CW - 16}" height="{CH - 14}" rx="14" fill="#fff" stroke="#e6e4dc"/>')
        out.append(f'<svg x="{x + 30}" y="{y + 18}" width="170" height="170" viewBox="0 0 256 256">{body}</svg>')
        out.append(f'<svg x="{x + 222}" y="{y + 60}" width="32" height="32" viewBox="0 0 256 256">{body}</svg>')
        out.append(f'<svg x="{x + 230}" y="{y + 120}" width="16" height="16" viewBox="0 0 256 256">{body}</svg>')
        out.append(f'<text x="{x + 26}" y="{y + 222}" font-family="Segoe UI, Arial" font-size="19" font-weight="700" '
                   f'fill="#0e0e12">{num} · {html.escape(name)}</text>')
        words, line, lines = note.split(), "", []
        for w in words:
            if len(line) + len(w) > 34:
                lines.append(line)
                line = w
            else:
                line = (line + " " + w).strip()
        lines.append(line)
        for j, ln in enumerate(lines[:2]):
            out.append(f'<text x="{x + 26}" y="{y + 246 + j * 19}" font-family="Segoe UI, Arial" font-size="14.5" '
                       f'fill="#5a5a6e">{html.escape(ln)}</text>')
    out.append("</svg>")
    fn = f"{PRE}-{p // PER + 1}.svg"
    open(fn, "w", encoding="utf-8").write("\n".join(out))
    print(fn, W, H)
