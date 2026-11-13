#!/usr/bin/env python3
"""Build the downloadable programs for each chapter from its listings.

Run from the repository root:  python3 code/build.py [chNN ...]

For every chapter it takes the complete programs out of the <pre><code>
listings, writes them to code/chNN/ (BASIC as .bas text and tokenized
.prg, assembly as .asm and assembled .prg), puts the PRGs on a D81 disk
image, code/chNN/chNN.d81, and updates the chapter page: download links
on each of those listings, a link to the disk image under the byline,
and the code.js script that adds a Copy button to every listing.

Needs petcat and c1541 (from VICE) and 64tass on the PATH.

A BASIC listing counts as a complete program when every line is
numbered, there is no "..." placeholder, the first line is 10 or lower
and every line it jumps to exists. Assembly counts when it sets its
origin with "* =". OVERRIDES handles everything else.
"""
import glob, html, os, re, shutil, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRE = re.compile(r'<pre(?: data-download="[^"]*")?><code>(.*?)</code></pre>', re.S)
HEADING = re.compile(r'<h[234] id="([^"]+)"')
BYLINE = re.compile(r'(<p>[^<]*· @Craig Taylor</p>\n)(<p class="downloads">.*?</p>\n)?', re.S)
SCRIPT = '  <script src="code.js" defer></script>\n'

# (chapter file, heading id, n-th listing under that heading) ->
#   name:  disk and file name (lower case, up to 16 characters)
#   merge: (heading id, n) of the listing whose lines this one changes
#   skip:  leave it out
OVERRIDES = {
    # BASIC that calls a routine no listing loads, and a header with no code
    ("ch06-advanced-basic65.html", "sys", 0): {"skip": True},
    ("ch07-45gs02-machine-language.html", "a-first-program", 2): {"name": "border"},
    ("ch08-ml-methods-specific-to-the-mega65.html", "saving-and-restoring-the-map", 1): {"name": "atticpeek"},
    ("ch08-ml-methods-specific-to-the-mega65.html", "a-split-screen-example", 0): {"name": "split"},
    ("ch08-ml-methods-specific-to-the-mega65.html", "cooperative-raster-interrupts", 0): {"name": "coraster"},
    ("ch08-ml-methods-specific-to-the-mega65.html", "example-loading-level-data-into-bank-4", 0): {"name": "hyppoload"},
    ("ch09-mixing-basic-with-machine-language.html", "bload", 0): {"skip": True},
    ("ch09-mixing-basic-with-machine-language.html", "strings", 0): {"name": "spaces"},
    ("ch09-mixing-basic-with-machine-language.html", "the-cost-of-usr", 0): {"name": "bitcount"},
    ("ch11-mega65-rom-guide.html", "example-saving-and-loading-a-file", 0): {"name": "kernalfile"},
    ("ch09-mixing-basic-with-machine-language.html", "a-basic-header", 0): {"skip": True},
    ("ch09-mixing-basic-with-machine-language.html", "building-it-byte-by-byte", 0): {"skip": True},
    ("ch09-mixing-basic-with-machine-language.html", "registers", 0): {"skip": True},
    ("ch09-mixing-basic-with-machine-language.html", "parameter-blocks", 0): {"skip": True},
    ("ch09-mixing-basic-with-machine-language.html", "pointer", 0): {"skip": True},
    ("ch09-mixing-basic-with-machine-language.html", "rreg", 1): {"skip": True},
    ("ch09-mixing-basic-with-machine-language.html", "reporting-success-or-failure", 0): {"skip": True},
    ("ch09-mixing-basic-with-machine-language.html", "parameter-blocks-and-arrays", 0): {"skip": True},
    ("ch09-mixing-basic-with-machine-language.html", "the-machine-language-routine", 0): {"name": "sumbytes"},
    ("ch12-graphics.html", "scaling-characters", 1): {"name": "tall text"},
    ("ch12-graphics.html", "a-seam-screen", 0): {"name": "seam"},
    ("ch12-graphics.html", "rows-of-any-length", 0): {"name": "seam rows", "merge": ("a-seam-screen", 0)},
    ("ch12-graphics.html", "a-full-colour-screen", 0): {"name": "fcm"},
    ("ch12-graphics.html", "an-ncm-screen", 0): {"name": "ncm"},
    ("ch12-graphics.html", "several-palettes", 0): {"name": "alt palette"},
    ("ch12-graphics.html", "a-16-colour-sprite", 0): {"name": "16 colour sprite"},
    ("ch12-graphics.html", "an-80-column-bitmap", 0): {"name": "80 column bitmap"},
    ("ch12-graphics.html", "a-bitplane-screen-by-hand", 0): {"name": "bitplanes"},
    ("ch12-graphics.html", "objects-from-basic", 0): {"name": "rrb objects"},
    ("ch12-graphics.html", "the-update-in-machine-language", 0): {"name": "rrbobj"},
    ("ch12-graphics.html", "calling-it-from-basic", 0): {"name": "rrb objects ml", "merge": ("objects-from-basic", 0)},
    ("ch12-graphics.html", "scaling-the-whole-display", 0): {"name": "rrb zoom", "merge": ("objects-from-basic", 0)},
    ("ch12-graphics.html", "scaling-an-object-with-dma", 0): {"name": "rrb scale", "merge": ("objects-from-basic", 0)},
}

NUMBERED = re.compile(r"^\s*(\d+)\s+[A-Z?]")  # a statement, not printed output
JUMPS = re.compile(r"\b(?:GOTO|GO TO|GOSUB|THEN|ELSE|TRAP|RESUME|RESTORE)\s*(\d+(?:\s*,\s*\d+)*)")


def listings(page):
    """Yield (match, heading id, index under heading, text) for each listing."""
    seen = {}
    for m in PRE.finditer(page):
        heads = HEADING.findall(page, 0, m.start())
        head = heads[-1] if heads else "top"
        n = seen.get(head, 0)
        seen[head] = n + 1
        yield m, head, n, html.unescape(m.group(1)).rstrip("\n")


def basic_lines(text):
    """Return {line number: line} if every line is numbered, else None."""
    lines = {}
    for line in text.split("\n"):
        if not line.strip():
            continue
        m = NUMBERED.match(line)
        if not m or "..." in line:
            return None
        lines[int(m.group(1))] = line.strip()
    return lines or None


def complete_basic(lines):
    if min(lines) > 10:
        return False
    for line in lines.values():
        for group in JUMPS.findall(line):
            if any(int(n) not in lines for n in re.split(r"\s*,\s*", group)):
                return False
    return True


def unique_name(base, used):
    base = re.sub(r"[^a-z0-9]+", " ", base.lower()).strip()[:16].strip()
    name, k = base, 2
    while name in used:
        suffix = " %d" % k
        name, k = base[:16 - len(suffix)].strip() + suffix, k + 1
    used.add(name)
    return name


def run(*cmd):
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)


def find_programs(fname, page):
    """Return [(match start, disk name, file stem, kind, text)] for the complete programs."""
    found = list(listings(page))
    by_key = {(h, n): t for _, h, n, t in found}
    programs, stems, used = [], set(), set(o["name"] for (f, _, _), o in OVERRIDES.items()
                             if f == fname and "name" in o)
    for m, head, n, text in found:
        opt = OVERRIDES.get((fname, head, n), {})
        if opt.get("skip"):
            continue
        kind = None
        if "merge" in opt:
            lines = basic_lines(by_key[opt["merge"]])
            lines.update(basic_lines(text))
            kind = "bas"
        elif re.search(r"^\s*\*\s*=", text, re.M):
            kind = "asm"
        else:
            lines = basic_lines(text)
            if lines and complete_basic(lines):
                kind = "bas"
        if kind == "bas":
            text = "\n".join(lines[k] for k in sorted(lines))
        if kind:
            name = opt.get("name") or unique_name(head, used)
            stem = opt.get("name", head).replace(" ", "-")
            k = 2
            while stem in stems:
                stem, k = "%s-%d" % (opt.get("name", head).replace(" ", "-"), k), k + 1
            stems.add(stem)
            programs.append((m.start(), name, stem, kind, text))
    return programs


def build_chapter(path, tmp):
    fname = os.path.basename(path)
    chap = re.match(r"ch(\d+)", fname).group(1)
    outdir = os.path.join(ROOT, "code", "ch" + chap)
    rel = "code/ch%s/" % chap

    page = open(path).read()
    page = re.sub(r'<pre data-download="[^"]*">', "<pre>", page)
    if SCRIPT not in page:
        page = page.replace('  <link rel="stylesheet" href="style.css" />\n',
                            '  <link rel="stylesheet" href="style.css" />\n' + SCRIPT, 1)
    programs = find_programs(fname, page)

    if os.path.isdir(outdir):
        shutil.rmtree(outdir)
    links = {}
    if programs:
        os.makedirs(outdir)
        d81 = "ch%s.d81" % chap
        disk = ["c1541", "-format", "ch%s programs,%s" % (chap, chap), "d81",
                os.path.join(outdir, d81)]
        for start, name, stem, kind, text in programs:
            src = os.path.join(outdir, stem + "." + kind)
            prg = os.path.join(outdir, stem + ".prg")
            open(src, "w").write(text + "\n")
            if kind == "bas":
                lower = os.path.join(tmp, stem + ".txt")
                open(lower, "w").write(text.lower().replace("π", "~") + "\n")
                run("petcat", "-w65", "-l", "2001", "-o", prg, "--", lower)
            else:
                run("64tass", "--m45gs02", "-q", "-a", src, "-o", prg)
            disk += ["-write", prg, name]
            links[start] = "%s%s.%s %s%s.prg" % (rel, stem, kind, rel, stem)
        run(*disk)

    # download links on the listings
    out, pos = [], 0
    for m in PRE.finditer(page):
        out.append(page[pos:m.start()])
        if m.start() in links:
            out.append('<pre data-download="%s">' % links[m.start()] + m.group(0)[5:])
        else:
            out.append(m.group(0))
        pos = m.end()
    page = "".join(out) + page[pos:]

    # the disk image under the byline
    note = ""
    if programs:
        n = len(programs)
        what = ("this chapter's complete program. It can also be downloaded from the "
                "links above its listing" if n == 1 else
                "this chapter's %d complete programs. Each can also be downloaded from "
                "the links above its listing" % n)
        note = ('<p class="downloads">Disk image: <a href="%sch%s.d81">ch%s.d81</a> '
                'holds %s, and every listing has a Copy button.</p>\n'
                % (rel, chap, chap, what))
    page = BYLINE.sub(lambda m: m.group(1) + note, page, count=1)
    open(path, "w").write(page)
    return programs


def main():
    args = sys.argv[1:]
    if any(a.startswith("-") for a in args):
        sys.exit(__doc__.strip() + "\n\nTo build only some chapters, name them:  "
                 "python3 code/build.py ch07 ch12")
    missing = [t for t in ("petcat", "c1541", "64tass") if not shutil.which(t)]
    if missing:  # check before build_chapter deletes anything
        sys.exit("build.py: not on the PATH: " + ", ".join(missing))
    paths = sorted(glob.glob(os.path.join(ROOT, "ch[0-9][0-9]-*.html")))
    if args:
        paths = [p for p in paths if os.path.basename(p)[:4] in args]
        if len(paths) != len(set(args)):
            sys.exit("build.py: no such chapter among: " + " ".join(args))
    with tempfile.TemporaryDirectory() as tmp:
        for path in paths:
            progs = build_chapter(path, tmp)
            print("%-48s %3d programs" % (os.path.basename(path), len(progs)))


if __name__ == "__main__":
    main()
