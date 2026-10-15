"""Doubles the pixel density of the text bitmaps in the given GDScript files (D56) with the EPX /
Scale2x rule, so every map gets a 2x grid with rounded diagonals ready for more detail.

Usage: python3 tools/upscale_pixel_maps.py <file.gd> [...]
Only quoted rows made of map symbols (letters, digits, '.') inside `const` blocks listed in
MAPS are rewritten; everything else is left untouched. Icon files (ICON_MAPS) keep several rows
per line: each `&"name": [ ... ],` entry is upscaled as one map and rewritten four rows per line.
Run once per file (it doubles whatever it finds) and review the git diff.
"""
import re
import sys

# Per file: the const names whose string rows are pixel maps.
MAPS = {
    "chibi_body.gd": ["BODY", "OUTFITS", "HAIR_STYLES"],
    "monster_bodies.gd": ["BODIES"],
    "weapon_sprites.gd": ["BITMAPS"],
}
# Icon tables: entries `&"name": [` followed by lines of several quoted rows, closed by `],`.
ICON_MAPS = {
    "pixel_icons.gd": "BITMAPS",
    "item_icons.gd": "BITMAPS",
}


def epx(rows):
    h = len(rows)
    w = len(rows[0])
    out = [[""] * (w * 2) for _ in range(h * 2)]

    def at(x, y):
        if 0 <= x < w and 0 <= y < h:
            return rows[y][x]
        return "."

    for y in range(h):
        for x in range(w):
            p = at(x, y)
            a, b, c, d = at(x, y - 1), at(x + 1, y), at(x - 1, y), at(x, y + 1)
            e1 = e2 = e3 = e4 = p
            if c == a and c != d and a != b:
                e1 = a
            if a == b and a != c and b != d:
                e2 = b
            if d == c and d != a and c != b:
                e3 = c
            if b == d and b != a and d != c:
                e4 = b
            out[y * 2][x * 2] = e1
            out[y * 2][x * 2 + 1] = e2
            out[y * 2 + 1][x * 2] = e3
            out[y * 2 + 1][x * 2 + 1] = e4
    return ["".join(r) for r in out]


ROW = re.compile(r'^(\s*)"([.\w]+)",\s*$')


def process_icons(path, const):
    text = open(path).read()
    start = text.index("const %s := {" % const)
    end = text.index("\n}", start)
    block = text[start:end]
    entry = re.compile(r'(\t&"\w+": \[)\n(.*?)\n(\t\],)', re.S)

    def rewrite(m):
        rows = re.findall(r'"([.\w]+)"', m.group(2))
        big = epx(rows)
        lines = []
        for i in range(0, len(big), 4):
            lines.append("\t\t" + ", ".join('"%s"' % r for r in big[i:i + 4]) + ",")
        return m.group(1) + "\n" + "\n".join(lines) + "\n" + m.group(3)

    new_block, count = entry.subn(rewrite, block)
    open(path, "w").write(text[:start] + new_block + text[end:])
    print("upscaled", count, "icons in", path)


def process(path):
    name = path.split("/")[-1]
    if name in ICON_MAPS:
        process_icons(path, ICON_MAPS[name])
        return
    consts = MAPS.get(name)
    if not consts:
        print("skip", path)
        return
    lines = open(path).read().split("\n")
    out = []
    i = 0
    active = False
    depth = 0
    while i < len(lines):
        line = lines[i]
        if not active:
            for c in consts:
                if line.startswith("const %s :=" % c):
                    active = True
                    depth = 0
            out.append(line)
            depth += line.count("[") + line.count("{") - line.count("]") - line.count("}")
            i += 1
            continue
        m = ROW.match(line)
        if m:
            # Collect a run of rows (one map) and upscale it together.
            indent = m.group(1)
            block = []
            while i < len(lines) and ROW.match(lines[i]):
                block.append(ROW.match(lines[i]).group(2))
                i += 1
            width = len(block[0])
            if all(len(r) == width for r in block) and len(block) > 1:
                for r in epx(block):
                    out.append('%s"%s",' % (indent, r))
            else:
                for r in block:
                    out.append('%s"%s",' % (indent, r))
            continue
        depth += line.count("[") + line.count("{") - line.count("]") - line.count("}")
        if depth <= 0:
            active = False
        out.append(line)
        i += 1
    open(path, "w").write("\n".join(out))
    print("upscaled", path)


if __name__ == "__main__":
    for p in sys.argv[1:]:
        process(p)
