"""Non-drawing helpers for herdr-diff-view: git, line numbers, the clipboard, swap requests."""
import base64
import json
import os
import re
import subprocess
import sys

# Generated API clients (kingston-static): listed last and marked, and left out of one total.
GENERATED = "src/clients/"
# The " old ⋮ new │" gutter delta --line-numbers puts at the start of each line.
DELTA_NUMBERS = re.compile(r"\s*(\d*)\s*⋮\s*(\d*)\s*│")
HUNK = re.compile(r"@@ -(\d+)(?:,\d+)? \+(\d+)")

REQUEST_DIR = os.path.join(os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state"),
                           "herdr-diff-view")


def git(*args):
    r = subprocess.run(["git", *args], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else ""


def refs():
    """Local branches, then remote ones, each newest first"""
    out = []
    for kind in ("refs/heads", "refs/remotes"):
        for line in git("for-each-ref", "--sort=-committerdate", "--format=%(refname:short) %(symref)", kind).splitlines():
            name, _, symref = line.partition(" ")
            if not symref:
                out.append(name)
    return out


def default_branch():
    return git("symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD").strip()


def branch_base(target):
    """The branch target most likely started from: walking target's first-parent line, the first
    commit that is another branch's tip, or the default branch once the walk reaches the point
    where target left it (diffs use base...target, so the default branch is exact from there on,
    even after it has moved)."""
    default = default_branch()
    fork = git("merge-base", "--end-of-options", default, target).strip() if default else ""
    remotes = git("remote").split()

    def name_of(ref):
        head, _, rest = ref.partition("/")
        return rest if head in remotes else ref

    cmd = ["git", "log", "--first-parent", "--decorate=short", "--decorate-refs=refs/heads",
           "--decorate-refs=refs/remotes", "--decorate-refs-exclude=refs/remotes/*/HEAD", "--format=%H %D",
           "--end-of-options", target]
    with subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True) as p:
        for line in p.stdout:
            commit, _, refs_ = line.partition(" ")
            # target's own remote copy (pushed earlier) is not where it started.
            names = [n.removeprefix("HEAD -> ").strip() for n in refs_.split(",")]
            names = [n for n in names if n and n != "HEAD" and name_of(n) != name_of(target)]
            if commit == fork or names:
                p.kill()
                return default if commit == fork or default in names else names[0]
    return default


def numstat(base, target):
    rows = []
    for line in git("diff", "--no-renames", "--numstat", "--end-of-options", f"{base}...{target}").splitlines():
        a, d, path = line.split("\t", 2)
        rows.append((int(a) if a.isdigit() else 0, int(d) if d.isdigit() else 0, path))
    return sorted(rows, key=lambda r: r[2].startswith(GENERATED))


def summary(rows):
    a = sum(r[0] for r in rows)
    d = sum(r[1] for r in rows)
    own = [r for r in rows if not r[2].startswith(GENERATED)]
    text = f"{len(rows)} files +{a} -{d}"
    if len(own) != len(rows):
        text += f"（生成を除く {len(own)} files +{sum(r[0] for r in own)} -{sum(r[1] for r in own)}）"
    return text


def delta_line_numbers(index, rows):
    """(file, old line, new line) for each line of delta output; a wrapped line repeats the one before"""
    out, prev = [], (index, None, None)
    for segs in rows:
        m = DELTA_NUMBERS.match("".join(t for t, _ in segs))
        if not m:
            out.append((index, None, None))
            continue
        old, new = (int(g) if g else None for g in m.groups())
        prev = (index, old, new) if old or new else prev
        out.append(prev)
    return out


def raw_line_numbers(index, block):
    """(file, old line, new line) for each line of plain git diff output, used without delta"""
    out, old, new = [], None, None
    for line in block.splitlines():
        m = HUNK.match(line)
        if m:
            old, new = int(m[1]), int(m[2])
            out.append((index, None, None))
        elif old is None or line.startswith("\\"):
            out.append((index, None, None))
        elif line.startswith("+"):
            out.append((index, None, new))
            new += 1
        elif line.startswith("-"):
            out.append((index, old, None))
            old += 1
        else:
            out.append((index, old, new))
            old, new = old + 1, new + 1
    return out


def copy_to_clipboard(text):
    """Put text on the clipboard with OSC 52, which herdr passes on to the outer terminal"""
    data = base64.b64encode(text.encode()).decode()
    os.write(sys.stdout.fileno(), f"\x1b]52;c;{data}\x07".encode())
    dump = os.environ.get("HERDR_DIFF_VIEW_DUMP")
    if dump:
        with open(dump + ".clip", "w") as f:
            f.write(text)


class Picker:
    def __init__(self, title, items, selected):
        self.title, self.items, self.query = title, items, ""
        self.value = selected
        self.cursor = 0
        self.top = 0

    def shown(self):
        q = self.query.lower()
        return [i for i in self.items if q in i.lower()]


def read_request():
    """Read and remove the request herdr-diff-pane wrote for this process"""
    path = os.path.join(REQUEST_DIR, f"{os.getpid()}.json")
    try:
        with open(path) as f:
            req = json.load(f)
    except (OSError, ValueError):
        req = None
    try:
        os.remove(path)
    except OSError:
        pass
    return req
