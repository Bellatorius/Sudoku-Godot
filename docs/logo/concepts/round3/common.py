"""Shared helpers (from round 2): six more Sudoku Variants logo concepts (D-I), symbols + horizontal lockups.
Usage: python build2.py <font.ttf> <out_dir> <version>"""
import sys, os, math
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.boundsPen import BoundsPen

FONT, OUT, VER = sys.argv[1], sys.argv[2], sys.argv[3]
INK, PAPER = "#0e0e12", "#ffffff"
os.makedirs(OUT, exist_ok=True)
font = TTFont(FONT)
gs = font.getGlyphSet()
cmap = font.getBestCmap()
upm = font["head"].unitsPerEm


def text_path(text, size, x, baseline, tracking=0):
    s = size / upm
    pen = SVGPathPen(gs)
    for ch in text:
        g = cmap[ord(ch)]
        gs[g].draw(TransformPen(pen, (s, 0, 0, -s, x, baseline)))
        x += gs[g].width * s + tracking
    return pen.getCommands(), x


def glyph_centred(ch, size, cx, cy):
    """One glyph, its ink box centred on (cx, cy)."""
    s = size / upm
    bp = BoundsPen(gs)
    gs[cmap[ord(ch)]].draw(bp)
    x0, y0, x1, y1 = bp.bounds
    return text_path(ch, size, cx - (x0 + x1) / 2 * s, cy + (y0 + y1) / 2 * s)[0]


def svg(view_w, body, title):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {view_w} 256" width="{view_w}" height="256" '
            f'role="img" aria-labelledby="t"><title id="t">{title}</title>\n{body}\n</svg>\n')


def rr(x, y, w, h, r):
    if r <= 0:
        return f"M{x} {y}H{x+w}V{y+h}H{x}Z"
    return (f"M{x+r} {y}H{x+w-r}A{r} {r} 0 0 1 {x+w} {y+r}V{y+h-r}A{r} {r} 0 0 1 {x+w-r} {y+h}"
            f"H{x+r}A{r} {r} 0 0 1 {x} {y+h-r}V{y+r}A{r} {r} 0 0 1 {x+r} {y}Z")


def frame(sw=20, lo=34, hi=222, r=30):
    return f'<path d="{rr(lo, lo, hi - lo, hi - lo, r)}" fill="none" stroke="{INK}" stroke-width="{sw}"/>'


