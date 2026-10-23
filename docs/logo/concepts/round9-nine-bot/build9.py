"""Round 9: Nine Bot variations (#132-1 ... #132-24), each in the 5 round-8 styles.
The constant: the right eye is a square 9 whose tail becomes the mouth.
Usage: python build9.py <DMSerif.ttf> <out_dir> <version>"""
_src = open("build8.py", encoding="utf-8").read()
exec(_src[:_src.index("# ---------- characters")])   # helpers, motif(), L  # noqa: S102

L.clear()


def bot(f, b, left="square", right="square", mouth="box", ant="one", extra=""):
    """Nine Bot parts in a ~130 unit face centred near (128, 110)."""
    out = ""
    # left eye
    if left == "square":
        out += F(rr(80, 78, 32, 32, 6), f)
    elif left == "round":
        out += C(96, 94, 17, f)
    elif left == "wink":
        out += F(rr(78, 90, 36, 10, 5), f)
    elif left == "happy":
        out += ST("M80 102L96 84L112 102", 10, f)
    elif left == "ring":
        out += ST(rr(82, 80, 28, 28, 6), 9, f)
    elif left == "heart":
        out += F("M96 110L80 94A9 9 0 0 1 96 84A9 9 0 0 1 112 94Z", f, f' stroke="{f}" stroke-width="4" stroke-linejoin="round"')
    elif left == "x0":
        out += F(rr(80, 78, 32, 32, 6), f) + F(rr(90, 84, 8, 8, 2), b)
    # right eye = head of the 9, and its tail
    if right == "square":
        out += ST(rr(142, 76, 36, 36, 8), 12, f)
        sx, sy = 178, 94
    else:
        out += RING(160, 94, 19, 12, f)
        sx, sy = 179, 94
    if mouth == "box":
        out += ST(f"M{sx} {sy}V150Q{sx} 168 160 168H96Q78 168 78 150", 12, f)
    elif mouth == "flat":
        out += ST(f"M{sx} {sy}V160H82", 12, f)
    elif mouth == "round":
        out += ST(f"M{sx} {sy}V138A50 34 0 0 1 78 138", 12, f)
    elif mouth == "grin":
        out += ST(f"M{sx} {sy}V138", 12, f) + F(f"M{sx + 6} 136V150Q{sx + 6} 174 160 174H96Q72 174 72 150V136Z", f)
        out += F(rr(92, 142, 72, 8, 4), b)
    elif mouth == "grille":
        out += ST(f"M{sx} {sy}V150Q{sx} 168 160 168H96Q78 168 78 150", 12, f)
        out += ST("M104 146V168M128 146V168M152 146V168", 8, f, cap="butt")
    elif mouth == "zig":
        out += ST(f"M{sx} {sy}V146L160 166L142 146L124 166L106 146L88 166", 11, f)
    elif mouth == "o":
        out += ST(f"M{sx} {sy}V138Q{sx} 156 160 156H140", 12, f) + ST(rr(108, 140, 28, 28, 8), 10, f)
    # antenna
    if ant == "one":
        out += ST("M128 62V44", 8, f) + C(128, 38, 8, f)
    elif ant == "two":
        out += ST("M104 64L94 42M152 64L162 42", 8, f) + C(92, 38, 7, f) + C(164, 38, 7, f)
    elif ant == "bolt":
        out += ST("M128 64L120 52L136 46L126 30", 7, f)
    elif ant == "spring":
        out += ST("M128 66Q138 62 128 58Q118 54 128 50Q138 46 128 42", 6, f) + C(128, 34, 8, f)
    elif ant == "nine":
        out += RING(128, 38, 8, 6, f) + ST("M136 38V58", 6, f)
    return out + extra


def face(**kw):
    return lambda f, b: grp(bot(f, b, **kw), 1.42, 128, 106)


def with_head(shape="square", **kw):
    def draw(f, b):
        if shape == "square":           # antenna sits on top of the head, not inside it
            h = ST(rr(52, 62, 152, 130, 30), 12, f) + ST("M128 56V36", 8, f) + C(128, 30, 8, f)
        elif shape == "round":
            h = RING(128, 128, 82, 12, f) + ST("M128 40V24", 8, f) + C(128, 18, 8, f)
        elif shape == "tv":
            h = (ST(rr(48, 64, 160, 124, 22), 12, f) + ST("M92 188L80 210M164 188L176 210", 10, f)
                 + ST("M116 58L96 30M140 58L160 30", 8, f) + C(94, 26, 7, f) + C(162, 26, 7, f))
        kw.setdefault("ant", "none")
        return grp(h + grp(bot(f, b, **kw), 0.8, 128, 124, dy=4 if shape != "round" else 6), 1.08, 128, 128)
    return draw


VARIANTS = [
    ("Nine Bot", "The original: square eyes, the right one a square 9 whose tail is the mouth.", face()),
    ("Round Bot", "Softer: round eyes and a round 9.", face(left="round", right="round")),
    ("Wink Bot", "Winking: the left eye is a short bar.", face(left="wink")),
    ("Happy Bot", "Happy: the left eye closes into a ^.", face(left="happy")),
    ("Grin Bot", "A wide open grin with a row of teeth.", face(mouth="grin")),
    ("Calm Bot", "A flat, calm mouth.", face(mouth="flat")),
    ("Smile Bot", "A rounder smile under square eyes.", face(mouth="round")),
    ("Grille Bot", "A speaker-grille mouth: very robot.", face(mouth="grille")),
    ("Zigzag Bot", "A zigzag mouth, like a German-whispers line.", face(mouth="zig")),
    ("Surprised Bot", "An O mouth: did I just solve that?", face(mouth="o")),
    ("Two Antennas", "Two antennas, like ears.", face(ant="two")),
    ("Bolt Bot", "A lightning antenna: fast solving.", face(ant="bolt")),
    ("Spring Bot", "A springy antenna, bouncy and playful.", face(ant="spring")),
    ("No Antenna", "Just the face, cleanest at small sizes.", face(ant="none")),
    ("Nine Antenna", "The antenna is a tiny 9 too.", face(ant="nine")),
    ("Ring Eye Bot", "The left eye is an open square, matching the 9.", face(left="ring")),
    ("Pupil Bot", "A pupil in the left eye: it's looking at you.", face(left="x0")),
    ("Love Bot", "A heart left eye: loves puzzles.", face(left="heart", mouth="round")),
    ("Head Bot", "The face inside a square robot head.", with_head("square")),
    ("Round Head Bot", "The face inside a round head.", with_head("round", left="round", right="round")),
    ("TV Bot", "The face on an old TV with legs.", with_head("tv")),
    ("Ear Bolt Bot", "Bolts on the sides of the head.",
     lambda f, b: grp(ST(rr(52, 62, 152, 130, 30), 12, f) + F(rr(34, 106, 18, 40, 6) + rr(204, 106, 18, 40, 6), f)
                      + ST("M128 56V36", 8, f) + C(128, 30, 8, f)
                      + grp(bot(f, b, ant="none"), 0.8, 128, 124, dy=4), 1.05, 128, 128)),
    ("Headphones Bot", "Headphones on: ready for a multiplayer race.",
     lambda f, b: grp(ST("M50 120A78 78 0 0 1 206 120", 12, f) + F(rr(34, 108, 30, 60, 12) + rr(192, 108, 30, 60, 12), f)
                      + grp(bot(f, b, ant="none"), 0.8, 128, 122, dy=8), 1.05, 128, 128)),
    ("Cat Bot", "A robot cat: square ears on the head.",
     lambda f, b: grp(ST(rr(52, 72, 152, 124, 30), 12, f) + F("M60 84L64 40L102 72ZM196 84L192 40L154 72Z", f,
                      f' stroke="{f}" stroke-width="8" stroke-linejoin="round"') + grp(bot(f, b, ant="none"), 0.72, 128, 120, dy=6), 1.05, 128, 128)),
]

for name, note, fn in VARIANTS:
    L.append((name, note, fn))

STYLES = [
    ("a", lambda m: m(INK, WHITE)),
    ("b", lambda m: ST(rr(18, 18, 220, 220, 48), 14, INK) + grp(m(INK, WHITE), 0.68)),
    ("c", lambda m: F(rr(12, 12, 232, 232, 56), INK) + grp(m(WHITE, INK), 0.68)),
    ("d", lambda m: F(rr(12, 12, 232, 232, 56), ACCENT) + grp(m(WHITE, ACCENT), 0.68)),
    ("e", lambda m: C(128, 128, 118, GOLD) + grp(m(INK, GOLD), 0.62)),
]
rows = []
for i, (name, note, fn) in enumerate(L):
    num = 1 + i
    for code, st in STYLES:
        open(f"{OUT}/{num:03d}{code}-{VER}.svg", "w").write(svg(256, st(fn), f"Nine Bot {num}{code}"))
    rows.append(f"{num}\t{name}\t{note}")
open(f"{OUT}/index.txt", "w", encoding="utf-8").write("\n".join(rows))
print(len(L), "variations,", len(L) * 5, "logos")
