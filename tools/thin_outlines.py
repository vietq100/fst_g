"""Thins the silhouette outline of the D56 double-density pixel maps to one texel (D60).

After the EPX upscale every outline is two texels thick. An outline texel is removed (painted
with the fill it touches) when it is the *inner* layer of a silhouette outline: it touches no
transparent texel itself, but one of its 4-neighbours is an outline texel that does. Inner lines
(eyes, mouths, seams) touch no transparency and keep their thickness.

Usage: python3 tools/thin_outlines.py [--dry-run]
Rewrites actors/hunter/chibi/chibi_body.gd (BODY, OUTFITS, HAIR_STYLES),
actors/enemies/monster_bodies.gd (BODIES) and actors/common/weapon_sprites.gd (BITMAPS).
Outfits are thinned together with the head rows of BODY above them. Run once.
"""
import re
import sys
from collections import Counter

OUTLINE = "o"
EMPTY = "."
N4 = [(1, 0), (-1, 0), (0, 1), (0, -1)]
N8 = N4 + [(1, 1), (1, -1), (-1, 1), (-1, -1)]


def thin(rows, keep_rows=0):
    """Returns the thinned rows; the first `keep_rows` rows are context only (returned as is)."""
    h = len(rows)
    w = len(rows[0])
    grid = [list(r) for r in rows]

    def at(x, y):
        if 0 <= x < w and 0 <= y < h:
            return rows[y][x]
        return EMPTY

    def touches_empty(x, y, ring):
        return any(at(x + dx, y + dy) == EMPTY for dx, dy in ring)

    for y in range(keep_rows, h):
        for x in range(w):
            if rows[y][x] != OUTLINE or touches_empty(x, y, N8):
                continue
            outer = any(at(x + dx, y + dy) == OUTLINE and touches_empty(x + dx, y + dy, N4) for dx, dy in N4)
            if not outer:
                continue
            fills = Counter(at(x + dx, y + dy) for dx, dy in N4 if at(x + dx, y + dy) not in (OUTLINE, EMPTY))
            if fills:
                grid[y][x] = fills.most_common(1)[0][0]
    return ["".join(r) for r in grid]


ROW = re.compile(r'^(\s*)"([.\w]+)",\s*$')


def map_blocks(text, const):
    """(start, end) line spans of consecutive single-row lines inside `const NAME`."""
    lines = text.split("\n")
    spans = []
    active = False
    depth = 0
    i = 0
    while i < len(lines):
        line = lines[i]
        if not active:
            if line.startswith("const %s :=" % const):
                active = True
                depth = line.count("[") + line.count("{") - line.count("]") - line.count("}")
            i += 1
            continue
        if ROW.match(line):
            start = i
            while i < len(lines) and ROW.match(lines[i]):
                i += 1
            spans.append((start, i))
            continue
        depth += line.count("[") + line.count("{") - line.count("]") - line.count("}")
        if depth <= 0:
            active = False
        i += 1
    return lines, spans


def rows_of(lines, span):
    return [ROW.match(lines[k]).group(2) for k in range(*span)]


def write_rows(lines, span, rows):
    for k, row in zip(range(*span), rows):
        indent = ROW.match(lines[k]).group(1)
        lines[k] = '%s"%s",' % (indent, row)


def process_simple(path, const):
    text = open(path).read()
    lines, spans = map_blocks(text, const)
    changed = 0
    for span in spans:
        rows = rows_of(lines, span)
        if len(rows) < 2 or len({len(r) for r in rows}) != 1:
            continue
        new = thin(rows)
        changed += sum(a != b for ra, rb in zip(rows, new) for a, b in zip(ra, rb))
        write_rows(lines, span, new)
    return "\n".join(lines), changed


def process_chibi(path):
    text = open(path).read()
    lines, body_spans = map_blocks(text, "BODY")
    body_span = body_spans[0]
    body = rows_of(lines, body_span)
    torso_row = int(re.search(r"const TORSO_ROW := (\d+)", text).group(1))
    new_body = thin(body)
    changed = sum(a != b for ra, rb in zip(body, new_body) for a, b in zip(ra, rb))
    write_rows(lines, body_span, new_body)
    # Outfits: thinned below the (original) head rows.
    _, outfit_spans = map_blocks("\n".join(lines), "OUTFITS")
    head = body[:torso_row]
    for span in outfit_spans:
        rows = rows_of(lines, span)
        new = thin(head + rows, keep_rows=len(head))[len(head):]
        changed += sum(a != b for ra, rb in zip(rows, new) for a, b in zip(ra, rb))
        write_rows(lines, span, new)
    _, hair_spans = map_blocks("\n".join(lines), "HAIR_STYLES")
    for span in hair_spans:
        rows = rows_of(lines, span)
        new = thin(rows)
        changed += sum(a != b for ra, rb in zip(rows, new) for a, b in zip(ra, rb))
        write_rows(lines, span, new)
    return "\n".join(lines), changed


if __name__ == "__main__":
    dry = "--dry-run" in sys.argv
    jobs = [
        ("actors/hunter/chibi/chibi_body.gd", lambda p: process_chibi(p)),
        ("actors/enemies/monster_bodies.gd", lambda p: process_simple(p, "BODIES")),
        ("actors/common/weapon_sprites.gd", lambda p: process_simple(p, "BITMAPS")),
    ]
    for path, job in jobs:
        text, changed = job(path)
        print("%s: %d texels thinned" % (path, changed))
        if not dry:
            open(path, "w").write(text)
