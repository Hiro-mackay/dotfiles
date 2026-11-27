"""Terminal helpers for herdr-diff-view: delta colors to curses, ESC input, boxes and buttons."""
import curses
import re
import shutil
import unicodedata


DELTA = shutil.which("delta")
SGR = re.compile(r"\x1b\[([0-9;]*)m")
OTHER_ESC = re.compile(r"\x1b\][^\x07\x1b]*(\x07|\x1b\\)|\x1b\[[0-9;?]*[A-Za-ln-z]")


def rgb_to_256(r, g, b):
    if r == g == b:
        return 16 if r < 8 else 231 if r > 248 else 232 + round((r - 8) / 247 * 23)
    return 16 + 36 * round(r / 255 * 5) + 6 * round(g / 255 * 5) + round(b / 255 * 5)


class Palette:
    """Map delta's SGR colors to curses color pairs, adding a pair the first time a color is used."""

    def __init__(self):
        self.pairs = {}
        self.next = 10

    def attr(self, fg, bg, flags):
        key = (fg, bg)
        if key not in self.pairs:
            if self.next >= curses.COLOR_PAIRS:
                self.pairs[key] = 0
            else:
                curses.init_pair(self.next, fg, bg)
                self.pairs[key] = curses.color_pair(self.next)
                self.next += 1
        return self.pairs[key] | flags


def parse_ansi(line, palette):
    """Split one line of delta output into (text, curses attribute) segments."""
    line = OTHER_ESC.sub("", line)
    segs, fg, bg, flags, pos = [], -1, -1, 0, 0
    for m in SGR.finditer(line):
        if m.start() > pos:
            segs.append((line[pos:m.start()], palette.attr(fg, bg, flags)))
        codes = [int(c) if c else 0 for c in m.group(1).split(";")]
        i = 0
        while i < len(codes):
            c = codes[i]
            if c == 0:
                fg, bg, flags = -1, -1, 0
            elif c == 1:
                flags |= curses.A_BOLD
            elif c == 2:
                flags |= curses.A_DIM
            elif c == 3:
                flags |= getattr(curses, "A_ITALIC", 0)
            elif c == 4:
                flags |= curses.A_UNDERLINE
            elif c == 7:
                flags |= curses.A_REVERSE
            elif c == 22:
                flags &= ~(curses.A_BOLD | curses.A_DIM)
            elif c == 23:
                flags &= ~getattr(curses, "A_ITALIC", 0)
            elif c == 24:
                flags &= ~curses.A_UNDERLINE
            elif c == 27:
                flags &= ~curses.A_REVERSE
            elif 30 <= c <= 37:
                fg = c - 30
            elif 90 <= c <= 97:
                fg = c - 90 + 8
            elif c == 39:
                fg = -1
            elif 40 <= c <= 47:
                bg = c - 40
            elif 100 <= c <= 107:
                bg = c - 100 + 8
            elif c == 49:
                bg = -1
            elif c in (38, 48) and i + 1 < len(codes):
                if codes[i + 1] == 5 and i + 2 < len(codes):
                    color, i = codes[i + 2], i + 2
                elif codes[i + 1] == 2 and i + 4 < len(codes):
                    color, i = rgb_to_256(*codes[i + 2:i + 5]), i + 4
                else:
                    color = -1
                if c == 38:
                    fg = color
                else:
                    bg = color
            i += 1
        pos = m.end()
    if pos < len(line):
        segs.append((line[pos:], palette.attr(fg, bg, flags)))
    return segs


ESCAPES = {
    "[A": curses.KEY_UP, "OA": curses.KEY_UP, "[B": curses.KEY_DOWN, "OB": curses.KEY_DOWN,
    "[C": curses.KEY_RIGHT, "OC": curses.KEY_RIGHT, "[D": curses.KEY_LEFT, "OD": curses.KEY_LEFT,
    "[5~": curses.KEY_PPAGE, "[6~": curses.KEY_NPAGE, "[H": curses.KEY_HOME, "OH": curses.KEY_HOME,
    "[F": curses.KEY_END, "OF": curses.KEY_END, "[Z": curses.KEY_BTAB,
}


def read_escape(win):
    """Read the rest of an escape sequence curses left undecoded: the Esc key when nothing follows,
    None for a sequence not in ESCAPES."""
    win.nodelay(True)
    seq = ""
    try:
        for _ in range(8):
            try:
                c = win.get_wch()
            except curses.error:
                break
            if not isinstance(c, str):
                break
            seq += c
            if seq in ESCAPES:
                break
    finally:
        win.nodelay(False)
    if not seq:
        return "\x1b"
    return ESCAPES.get(seq)


def width(s):
    return sum(2 if unicodedata.east_asian_width(ch) in "WF" else 1 for ch in s)


def clip(s, w):
    out, used = "", 0
    for ch in s.replace("\t", "    "):
        cw = 2 if unicodedata.east_asian_width(ch) in "WF" else 1
        if used + cw > w:
            break
        out += ch
        used += cw
    return out


def box(win, y, x, h, w, title, active):
    attr = curses.color_pair(5) | curses.A_BOLD if active else curses.color_pair(6)
    win.attron(attr)
    win.addstr(y, x, "┌" + "─" * (w - 2) + "┐")
    for i in range(1, h - 1):
        win.addstr(y + i, x, "│")
        win.addstr(y + i, x + w - 1, "│")
    win.addstr(y + h - 1, x, "└" + "─" * (w - 2) + "┘")
    win.addstr(y, x + 2, clip(f" {title} ", w - 4))
    win.attroff(attr)
    for i in range(1, h - 1):
        win.addstr(y + i, x + 1, " " * (w - 2))


def button(win, y, x, w, label, value, active):
    text = clip(f" {label}: {value or '-'} ", w - 4) + " ▼ "
    attr = curses.A_REVERSE | curses.A_BOLD if active else curses.A_BOLD
    win.addstr(y, x, "[", curses.color_pair(6))
    win.addstr(y, x + 1, text, attr)
    win.addstr(y, x + 1 + width(text), "]", curses.color_pair(6))
    return width(text) + 2


def diff_attr(line):
    if line.startswith("+") and not line.startswith("+++"):
        return curses.color_pair(1)
    if line.startswith("-") and not line.startswith("---"):
        return curses.color_pair(2)
    if line.startswith("@@"):
        return curses.color_pair(3)
    if line.startswith(("diff ", "index ", "+++", "---")):
        return curses.color_pair(4) | curses.A_BOLD
    return 0


def draw_dropdown(win, app, x, W, H):
    picker = app.dropdown
    w = min(max(60, W // 2), W - x)
    h = min(22, H - 2)
    y = 1
    app.drop_rect = (y, x, h, w)
    box(win, y, x, h, w, f"{picker.title} を選ぶ（打つと絞り込み / Enter・クリックで決定 / Esc でやめる）", True)
    win.addstr(y + 1, x + 2, clip(f"検索: {picker.query}▏", w - 4), curses.A_BOLD)
    shown = picker.shown()
    rows = h - 3
    picker.top = max(0, picker.cursor - rows + 1)
    for i, name in enumerate(shown[picker.top:picker.top + rows]):
        idx = picker.top + i
        mark = "✓ " if name == picker.value else "  "
        attr = curses.A_REVERSE if idx == picker.cursor else 0
        win.addstr(y + 2 + i, x + 2, clip(mark + name, w - 4).ljust(w - 4), attr)
    if not shown:
        win.addstr(y + 2, x + 2, "一致するブランチがありません", curses.color_pair(6))
