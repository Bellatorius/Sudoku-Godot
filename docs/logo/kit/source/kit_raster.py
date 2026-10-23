"""Raster outputs for the Nine Smile kit: PNGs of masters/lockups/Steam art, Windows .ico files, web icon set.
16 px icons use the hand-drawn pixel cut; 32 px and up use the vector master.
Usage: python kit_raster.py <kit_dir> <render_png.py>"""
import sys, os, subprocess, struct

K, RENDER = sys.argv[1], sys.argv[2]


def png(src, out, w, h=None, bg=None):
    os.makedirs(os.path.dirname(out), exist_ok=True)
    cmd = [sys.executable, RENDER, src, "-o", out, "--width", str(w), "--height", str(h or w)]
    if bg:
        cmd += ["--bg", bg]
    subprocess.run(cmd, check=True, capture_output=True)


def ico(out, pngs):
    """Write an .ico that embeds PNG images (supported since Windows Vista)."""
    data = [open(p, "rb").read() for _, p in pngs]
    head = struct.pack("<HHH", 0, 1, len(pngs))
    off = 6 + 16 * len(pngs)
    dirs = b""
    for (size, _), d in zip(pngs, data):
        dirs += struct.pack("<BBBBHHII", size % 256, size % 256, 0, 0, 1, 32, len(d), off)
        off += len(d)
    open(out, "wb").write(head + dirs + b"".join(data))


m = f"{K}/master"
# PNG masters
for name in ("nine-smile-face", "nine-smile-cell", "nine-smile-tile-blue", "nine-smile-tile-ink", "nine-smile-tile-gold"):
    for s in (64, 256, 512, 1024):
        png(f"{m}/{name}.svg", f"{K}/png/{name}-{s}.png", s)
for name in ("nine-smile-16px-blue", "nine-smile-16px-ink"):
    png(f"{m}/{name}.svg", f"{K}/png/{name}.png", 16)
# lockups at 1200 px wide (height follows the file's own proportions)
import re
for f in sorted(os.listdir(f"{K}/lockups")):
    s = open(f"{K}/lockups/{f}", encoding="utf-8").read(400)
    vw, vh = map(float, re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)"', s).groups())
    png(f"{K}/lockups/{f}", f"{K}/png/lockups/{f[:-4]}-1200.png", 1200, round(1200 * vh / vw))
# Steam art at exact sizes
for f in sorted(os.listdir(f"{K}/steam")):
    if not f.endswith(".svg"):
        continue
    w, h = map(int, re.search(r"(\d+)x(\d+)", f).groups())
    png(f"{K}/steam/{f}", f"{K}/steam/{f[:-4]}.png", w, h)

# icon files: 16 = pixel cut, the rest = vector
tmp = f"{K}/png/ico"
os.makedirs(tmp, exist_ok=True)
for variant in ("blue", "ink"):
    parts = [(16, f"{K}/png/nine-smile-16px-{variant}.png")]
    for s in (24, 32, 48, 64, 128, 256):
        p = f"{tmp}/{variant}-{s}.png"
        png(f"{m}/nine-smile-tile-{variant}.svg", p, s)
        parts.append((s, p))
    ico(f"{K}/godot/icon-{variant}.ico", parts)
# Steam client icon (32) and shortcut icon (256)
ico(f"{K}/steam/client-icon-32.ico", [(16, f"{K}/png/nine-smile-16px-blue.png"), (32, f"{tmp}/blue-32.png")])
ico(f"{K}/steam/shortcut-icon-256.ico", [(16, f"{K}/png/nine-smile-16px-blue.png"), (32, f"{tmp}/blue-32.png"),
                                        (48, f"{tmp}/blue-48.png"), (256, f"{tmp}/blue-256.png")])
png(f"{m}/nine-smile-tile-blue.svg", f"{K}/godot/icon-128.png", 128)

# web icon set
w = f"{K}/web"
os.makedirs(w, exist_ok=True)
ico(f"{w}/favicon.ico", [(16, f"{K}/png/nine-smile-16px-blue.png"), (32, f"{tmp}/blue-32.png"), (48, f"{tmp}/blue-48.png")])
open(f"{w}/favicon.svg", "w", encoding="utf-8").write(open(f"{m}/nine-smile-tile-blue.svg", encoding="utf-8").read())
png(f"{m}/nine-smile-16px-blue.svg", f"{w}/favicon-16.png", 16)
png(f"{m}/nine-smile-tile-blue.svg", f"{w}/favicon-32.png", 32)
png(f"{K}/web/_square.svg", f"{w}/apple-touch-icon.png", 180)
for s in (192, 512):
    png(f"{m}/nine-smile-tile-blue.svg", f"{w}/icon-{s}.png", s)
png(f"{K}/web/_maskable.svg", f"{w}/maskable-512.png", 512)
open(f"{w}/site.webmanifest", "w").write('{\n  "name": "Sudoku Variants",\n  "short_name": "Sudoku Variants",\n'
    '  "icons": [\n    {"src": "icon-192.png", "sizes": "192x192", "type": "image/png"},\n'
    '    {"src": "icon-512.png", "sizes": "512x512", "type": "image/png"},\n'
    '    {"src": "maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"}\n  ],\n'
    '  "theme_color": "#2a4fff",\n  "background_color": "#f8f7f2",\n  "display": "standalone"\n}\n')
open(f"{w}/head-snippet.html", "w").write(
    '<link rel="icon" href="/favicon.ico" sizes="any">\n<link rel="icon" href="/favicon.svg" type="image/svg+xml">\n'
    '<link rel="apple-touch-icon" href="/apple-touch-icon.png">\n<link rel="manifest" href="/site.webmanifest">\n'
    '<meta name="theme-color" content="#2a4fff">\n')
import shutil
shutil.rmtree(tmp)
print("raster done")
