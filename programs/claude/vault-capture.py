"""Copy Claude Code conversations and memory into the vault's .depth/.

Run by the SessionEnd and SessionStart hooks. The hook itself only does the
local work and then hands the rest to a detached run, so it never holds up
the session:

- Conversations of interactive sessions become one JSON line per event,
  appended to .depth/conversations/YYYY/MM/DD_<host>.jsonl. These files live
  in object storage, not git: each device uploads its own and downloads the
  others' through rclone (remote $VAULT_REMOTE, default vault-depth:).
- Every project's auto memory and every agent memory are mirrored to
  .depth/memory/<host>/.

- The detached run (after-start / after-end) uploads this device's
  conversations and, after a start, downloads the others'; syncs the vault's
  git branch with the vault's own .claude/scripts/sync.py; and, at the first
  start of the day, runs the daily agents (see daily()).

Credentials are redacted on the way in, and over-long texts are cut down.
Nothing happens when the vault is missing. Problems are kept in the state
directory and reported by the next SessionStart; the hook always exits 0.
Claude Code sessions started by the daily agents carry VAULT_CAPTURE_CHILD,
and their hooks do nothing. A device with $XDG_CONFIG_HOME/vault/work is the
work Mac: nothing leaves it through object storage, and the daily agents do
not run there yet.

  vault-capture end|start|self-test
"""

from __future__ import annotations

import datetime
import fcntl
import json
import os
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

VERSION = 1
MAX_TEXT = 10_000
KEEP_HEAD = 5_000
KEEP_TAIL = 2_000
TOOL_ARG = 200
REPLY_TAIL = 600
MAX_DAYS = 14
AGENT_TIMEOUT = 1800
FIELDS = ("v", "ts", "sid", "id", "parent", "host", "cwd", "branch", "type", "name", "text", "q", "model")

SECRETS = [
    re.compile(p, re.MULTILINE)
    for p in (
        r"(?<![A-Za-z0-9])AKIA[0-9A-Z]{16}",
        r"(?<![A-Za-z0-9])gh[pousr]_[A-Za-z0-9]{36,}",
        r"(?<![A-Za-z0-9])github_pat_[A-Za-z0-9_]{22,}",
        r"(?<![A-Za-z0-9])sk-[A-Za-z0-9_-]{32,}",
        r"(?<![A-Za-z0-9])xox[baprs]-[A-Za-z0-9-]{10,}",
        r"(?<![A-Za-z0-9])SG\.[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}",
        r"(?<![A-Za-z0-9])eyJ[A-Za-z0-9_-]{20,}\.eyJ[A-Za-z0-9_-]{20,}[A-Za-z0-9._-]*",
        r"(?<![A-Za-z0-9])AIza[0-9A-Za-z_-]{35}",
        r"-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?(-----END [A-Z ]*PRIVATE KEY-----|\Z)",
        r"(?i)(?<=bearer )[A-Za-z0-9._~+/=-]{16,}",
        r"(?<=://)[^/\s:@]+:[^/\s@]+(?=@)",
        r"(?i)(?<=password=)\S+|(?<=passwd=)\S+|(?<=secret=)\S+|(?<=token=)\S+|(?<=api_key=)\S+",
        r"^[`\"']?[a-z]{4} [a-z]{4} [a-z]{4} [a-z]{4}[`\"']?\s*$",
    )
]
DENIED = ("has been denied", "doesn't want to proceed", "The user doesn't want")


def redact(text: str) -> str:
    for r in SECRETS:
        text = r.sub("[REDACTED]", text)
    return text


def shorten(text: str) -> str:
    raw = text.encode()
    if len(raw) <= MAX_TEXT:
        return text
    cut = len(raw) - KEEP_HEAD - KEEP_TAIL
    head = raw[:KEEP_HEAD].decode(errors="ignore")
    tail = raw[-KEEP_TAIL:].decode(errors="ignore")
    return f"{head}\n…（約 {round(cut / 1000)} KB 省略）…\n{tail}"


def clean(text: str | None) -> str | None:
    return None if text is None else shorten(redact(text))


def head_bytes(text: str, n: int = TOOL_ARG) -> str:
    return text.encode()[:n].decode(errors="ignore")


def tool_arg(inp: dict) -> str:
    for k in ("command", "file_path", "path", "pattern", "url", "query", "prompt", "description"):
        if isinstance(inp.get(k), str):
            return inp[k]
    return json.dumps(inp, ensure_ascii=False)


def events(d: dict, host: str, tools: dict) -> list[dict]:
    """Events for one transcript line, in the order they happened."""
    if d.get("isSidechain") or d.get("isMeta") or d.get("isCompactSummary"):
        return []
    kind = d.get("type")
    if kind not in ("user", "assistant"):
        return []
    base = {
        "v": VERSION,
        "ts": d.get("timestamp"),
        "sid": d.get("sessionId"),
        "id": d.get("uuid"),
        "parent": d.get("parentUuid"),
        "host": host,
        "cwd": d.get("cwd"),
        "branch": d.get("gitBranch"),
    }

    def ev(type_: str, text=None, name=None, q=None, model=None) -> dict:
        e = dict.fromkeys(FIELDS) | base | {"type": type_, "name": name, "q": clean(q), "model": model}
        e["text"] = clean(text)
        return e

    msg = d.get("message") or {}
    content = msg.get("content")
    out: list[dict] = []

    if kind == "assistant":
        for b in content if isinstance(content, list) else []:
            if b.get("type") == "text" and b.get("text"):
                out.append(ev("claude", b["text"], model=msg.get("model")))
            elif b.get("type") == "tool_use":
                tools[b.get("id")] = b.get("name")
                arg = redact(tool_arg(b.get("input") or {}))
                out.append(ev("tool", head_bytes(arg), name=b.get("name")))
        return out

    if isinstance(content, str):
        origin = (d.get("origin") or {}).get("kind")
        if origin not in (None, "human"):
            return []
        if content.startswith("[Request interrupted by user"):
            return [ev("refusal", "interrupted")]
        if content.startswith(("<command-message>", "<command-name>")):
            name = re.search(r"<command-name>(.*?)</command-name>", content, re.S)
            args = re.search(r"<command-args>(.*?)</command-args>", content, re.S)
            return [ev("command", args.group(1).strip() if args else "", name=name.group(1) if name else None)]
        if content.startswith("<bash-input>"):
            cmd = re.search(r"<bash-input>(.*?)</bash-input>", content, re.S)
            return [ev("command", cmd.group(1) if cmd else "", name="!")]
        if content.startswith("<"):
            return []
        return [ev("user", content)]

    result = d.get("toolUseResult")
    if isinstance(result, dict) and isinstance(result.get("answers"), dict):
        for q, a in result["answers"].items():
            out.append(ev("answer", ", ".join(a) if isinstance(a, list) else str(a), q=q))
    for b in content if isinstance(content, list) else []:
        if b.get("type") == "text" and b.get("text", "").startswith("[Request interrupted by user"):
            out.append(ev("refusal", "interrupted"))
        elif b.get("type") == "tool_result" and b.get("is_error"):
            body = b.get("content")
            body = body if isinstance(body, str) else json.dumps(body, ensure_ascii=False)
            if any(s in body for s in DENIED):
                out.append(ev("refusal", head_bytes(redact(body)), name=tools.get(b.get("tool_use_id"))))
    return out


def local_time(ts: str) -> datetime.datetime:
    return datetime.datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone()


def day_file(root: Path, ts: str, host: str) -> Path:
    t = local_time(ts)
    return root / ".depth" / "conversations" / f"{t:%Y}" / f"{t:%m}" / f"{t:%d}_{host}.jsonl"


def capture(claude: Path, vault: Path, state: dict, host: str, problems: list[str]) -> None:
    files = state.setdefault("files", {})
    for path in sorted((claude / "projects").glob("*/*.jsonl")):
        key = str(path)
        seen = files.get(key, {"off": 0, "cli": None})
        size = path.stat().st_size
        if size < seen["off"]:
            seen = {"off": 0, "cli": None}
        if size == seen["off"]:
            continue
        with path.open("rb") as f:
            f.seek(seen["off"])
            chunk = f.read()
        end = chunk.rfind(b"\n") + 1
        if end == 0:
            continue
        lines = []
        for raw in chunk[:end].splitlines():
            try:
                lines.append(json.loads(raw))
            except ValueError:
                continue
        if seen["cli"] is None:
            entry = next((d["entrypoint"] for d in lines if d.get("entrypoint")), None)
            if entry is None and any(d.get("type") in ("user", "assistant") for d in lines):
                problems.append(f"no entrypoint in {path.name}; the transcript format may have changed")
            seen["cli"] = None if entry is None else entry == "cli"
        if seen["cli"]:
            tools: dict = {}
            out = [e for d in lines for e in events(d, host, tools)]
            typed = sum(1 for d in lines if d.get("type") == "user" and isinstance((d.get("message") or {}).get("content"), str))
            if typed and not out:
                problems.append(f"{typed} user lines but no events in {path.name}; the transcript format may have changed")
            by_file: dict[Path, list[dict]] = {}
            for e in out:
                if e["ts"]:
                    by_file.setdefault(day_file(vault, e["ts"], host), []).append(e)
            for target, evs in by_file.items():
                # A resumed session's transcript starts with copies of the earlier
                # session's lines, uuids unchanged; every event of a line shares its id.
                written = set()
                if target.is_file():
                    for raw in target.read_text(encoding="utf-8").splitlines():
                        try:
                            written.add(json.loads(raw).get("id"))
                        except ValueError:
                            pass
                rows = [json.dumps(e, ensure_ascii=False) for e in evs if not (e["id"] and e["id"] in written)]
                if not rows:
                    continue
                target.parent.mkdir(parents=True, exist_ok=True)
                with target.open("a", encoding="utf-8") as f:
                    f.write("\n".join(rows) + "\n")
        seen["off"] += end
        files[key] = seen


def mirror(claude: Path, vault: Path, host: str) -> None:
    dest = vault / ".depth" / "memory" / host
    sources = {f"projects/{p.parent.name}": p for p in (claude / "projects").glob("*/memory") if p.is_dir()}
    sources |= {f"agents/{p.name}": p for p in (claude / "agent-memory").glob("*") if p.is_dir()}
    for rel, src in sources.items():
        out = dest / rel
        wanted = {f.relative_to(src) for f in src.rglob("*") if f.is_file()}
        for f in wanted:
            text = redact((src / f).read_text(encoding="utf-8", errors="replace"))
            target = out / f
            if not target.is_file() or target.read_text(encoding="utf-8", errors="replace") != text:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(text, encoding="utf-8")
        for f in [f for f in out.rglob("*") if f.is_file() and f.relative_to(out) not in wanted]:
            f.unlink()
    for group in ("projects", "agents"):
        for d in (dest / group).glob("*") if (dest / group).is_dir() else []:
            if f"{group}/{d.name}" not in sources:
                shutil.rmtree(d)


def sync(mode: str, vault: Path, host: str, rclone: str | None, remote: str, problems: list[str]) -> None:
    """Each file has one writer and only grows, so a copy each way never conflicts."""
    if not rclone:
        problems.append("rclone not found; conversations stay on this device")
        return
    if remote.endswith(":"):
        names = subprocess.run([rclone, "listremotes"], capture_output=True, text=True).stdout.split()
        if remote not in names:
            problems.append(f"rclone remote {remote} is not set up; conversations stay on this device")
            return
    local, dest, own = str(vault / ".depth" / "conversations"), remote + "conversations", f"**/*_{host}.jsonl"
    steps = [["copy", local, dest, "--include", own]]
    if mode == "start":
        steps.append(["copy", dest, local, "--exclude", own])
    for args in steps:
        r = subprocess.run([rclone, *args, "--contimeout", "10s", "--timeout", "60s"], capture_output=True, text=True)
        if r.returncode:
            problems.append(f"rclone {args[0]} failed: {(r.stderr.strip().splitlines() or ['?'])[-1]}")


def run(mode: str, claude: Path, vault: Path, state_dir: Path, host: str) -> str:
    """Capture and mirror; on start, return the problems to report."""
    if not vault.is_dir():
        return ""
    state_dir.mkdir(parents=True, exist_ok=True)
    errors = state_dir / "errors.log"
    with (state_dir / "lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state_file = state_dir / "state.json"
        state = json.loads(state_file.read_text()) if state_file.is_file() else {}
        problems: list[str] = []
        try:
            capture(claude, vault, state, host, problems)
            mirror(claude, vault, host)
        except Exception as e:  # noqa: BLE001 — a hook must not break the session
            problems.append(f"{type(e).__name__}: {e}")
        state_file.write_text(json.dumps(state))
        log_problems(state_dir, problems)
        if mode == "start" and errors.is_file() and errors.stat().st_size:
            report = errors.read_text()
            errors.write_text("")
            return report
    return ""


def log_problems(state_dir: Path, problems: list[str]) -> None:
    if problems:
        stamp = datetime.datetime.now().isoformat(timespec="seconds")
        with (state_dir / "errors.log").open("a") as f:
            f.writelines(f"{stamp} {p}\n" for p in problems)


def digest(files: list[Path]) -> str:
    """The user's side of the records, each user line with the end of the reply it answers."""
    out, prev = [], None
    for path in files:
        for raw in path.read_text(encoding="utf-8").splitlines():
            try:
                e = json.loads(raw)
            except ValueError:
                continue
            kind = e.get("type")
            if kind == "claude":
                prev = e.get("text")
                continue
            if kind not in ("user", "answer", "refusal", "command"):
                continue
            if kind == "user" and prev:
                tail = prev.encode()[-REPLY_TAIL:].decode(errors="ignore")
                out.append("  (直前の Claude の返答の末尾) " + tail.replace("\n", " "))
                prev = None
            when = f"{local_time(e['ts']):%Y-%m-%d %H:%M}" if e.get("ts") else ""
            head = f"[{when} {(e.get('sid') or '')[:8]} {e.get('cwd')}] {kind}"
            if e.get("name"):
                head += f" {e['name']}"
            body = e.get("text") or ""
            if e.get("q"):
                body = f"Q: {e['q']} A: {body}"
            out.append(f"{head}: {body}")
    return "\n".join(out) + "\n" if out else ""


def days_to_read(last: datetime.date | None, today: datetime.date) -> list[datetime.date]:
    first = today - datetime.timedelta(days=MAX_DAYS)
    if last and last + datetime.timedelta(days=1) > first:
        first = last + datetime.timedelta(days=1)
    return [first + datetime.timedelta(days=i) for i in range((today - first).days)]


def agent(claude_bin: str, name: str, prompt: str, vault: Path, dirs: list[Path], log: Path) -> int:
    # A session started from inside another one runs with auto memory off, so the
    # parent session's variables are dropped.
    env = {k: v for k, v in os.environ.items() if not k.startswith(("CLAUDECODE", "CLAUDE_CODE_"))}
    env["VAULT_CAPTURE_CHILD"] = "1"
    args = [claude_bin, "-p", "--agent", name, "--permission-mode", "acceptEdits"]
    for d in dirs:
        args += ["--add-dir", str(d)]
    with log.open("a") as f:
        f.write(f"--- {datetime.datetime.now().isoformat(timespec='seconds')} {name}\n")
        f.flush()
        # The prompt goes in on stdin because --add-dir takes every argument after it.
        return subprocess.run(args, input=prompt, cwd=vault, env=env, stdout=f, stderr=subprocess.STDOUT,
                              text=True, timeout=AGENT_TIMEOUT).returncode


def daily(claude: Path, vault: Path, state_dir: Path, host: str, claude_bin: str | None,
          problems: list[str], today: datetime.date | None = None) -> None:
    """Once a day per device: the observer and the minutes agent read this device's records.

    They read the days after the last one read, up to yesterday, at most MAX_DAYS
    back. A day counts as read only when both agents finished; a failed day is
    read again at the next day's first start.
    """
    today = today or datetime.date.today()
    ran, last_file = state_dir / "daily-ran", state_dir / "daily-last"
    if ran.is_file() and ran.read_text().strip() == today.isoformat():
        return
    ran.write_text(today.isoformat())
    if not claude_bin:
        problems.append("claude not found; the daily agents did not run")
        return
    last = datetime.date.fromisoformat(last_file.read_text().strip()) if last_file.is_file() else None
    conv = vault / ".depth" / "conversations"
    files = [f for d in days_to_read(last, today)
             if (f := conv / f"{d:%Y}" / f"{d:%m}" / f"{d:%d}_{host}.jsonl").is_file()]
    text = digest(files)
    yesterday = (today - datetime.timedelta(days=1)).isoformat()
    if not text:
        last_file.write_text(yesterday)
        return
    material = state_dir / "daily-input.txt"
    material.write_text(text, encoding="utf-8")
    log = state_dir / "daily.log"
    prompt = f"Read {material} (this device's conversation records, {len(files)} day(s)) and do your job."
    failed = [name for name, dirs in (("observer", [state_dir, claude / "agent-memory"]), ("minutes", [state_dir]))
              if agent(claude_bin, name, prompt, vault, dirs, log)]
    if failed:
        problems.append(f"daily agents failed: {', '.join(failed)} (see {log})")
    else:
        last_file.write_text(yesterday)


def git_sync(vault: Path, problems: list[str]) -> None:
    script = vault / ".claude" / "scripts" / "sync.py"
    if script.is_file():
        r = subprocess.run([sys.executable, str(script), "run"], capture_output=True, text=True)
        if r.returncode:
            problems.append(f"git sync: {(r.stdout.strip() or r.stderr.strip() or '?').splitlines()[-1]}")


def after(mode: str, claude: Path, vault: Path, state_dir: Path, host: str, rclone: str | None, remote: str,
          claude_bin: str | None, work: bool) -> None:
    """The slow half of a hook, run detached."""
    if not vault.is_dir():
        return
    problems: list[str] = []
    with (state_dir / "after.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            if remote and not work:
                sync(mode, vault, host, rclone, remote, problems)
            git_sync(vault, problems)
            if mode == "start" and not work:
                daily(claude, vault, state_dir, host, claude_bin, problems)
                with (state_dir / "lock").open("w") as main_lock:
                    fcntl.flock(main_lock, fcntl.LOCK_EX)
                    mirror(claude, vault, host)
                git_sync(vault, problems)
        except Exception as e:  # noqa: BLE001 — record and report next session
            problems.append(f"{type(e).__name__}: {e}")
    with (state_dir / "lock").open("w") as main_lock:
        fcntl.flock(main_lock, fcntl.LOCK_EX)
        log_problems(state_dir, problems)


def detach(mode: str, state_dir: Path) -> None:
    with (state_dir / "after.log").open("a") as log:
        subprocess.Popen([sys.executable, os.path.abspath(__file__), f"after-{mode}"], stdin=subprocess.DEVNULL,
                         stdout=log, stderr=subprocess.STDOUT, start_new_session=True,
                         env=os.environ | {"VAULT_CAPTURE_CHILD": "1"})


def self_test() -> None:
    os.environ["TZ"] = "Asia/Tokyo"
    time.tzset()
    tmp = Path(tempfile.mkdtemp())
    claude, vault, state = tmp / "claude", tmp / "vault", tmp / "state"
    vault.mkdir()
    proj = claude / "projects" / "-p"
    (proj / "memory").mkdir(parents=True)
    (proj / "memory" / "MEMORY.md").write_text("- [a](a.md)\n")
    (proj / "memory" / "old.md").write_text("old\n")
    (claude / "agent-memory" / "observer").mkdir(parents=True)
    (claude / "agent-memory" / "observer" / "MEMORY.md").write_text("token=abc123\n")
    common = {"entrypoint": "cli", "sessionId": "s1", "cwd": "/w", "gitBranch": "main"}

    def line(i, **kw):
        return json.dumps(common | {"uuid": f"u{i}", "parentUuid": f"u{i-1}", "timestamp": "2026-10-08T01:00:00Z"} | kw)

    user = lambda c, **kw: {"type": "user", "message": {"role": "user", "content": c}, **kw}  # noqa: E731
    rows = [
        line(1, **user("hello", origin={"kind": "human"})),
        line(2, type="assistant", message={"model": "m", "content": [
            {"type": "thinking", "thinking": "x"},
            {"type": "text", "text": "hi"},
            {"type": "tool_use", "id": "t1", "name": "Bash", "input": {"command": "echo ghp_" + "a" * 36 + " " + "x" * 300}},
        ]}),
        line(3, **user([{"type": "tool_result", "tool_use_id": "t1", "content": "out"}])),
        line(4, **user([{"type": "tool_result", "tool_use_id": "t1", "is_error": True,
                         "content": "Permission to use Bash has been denied."}])),
        line(5, **user([{"type": "tool_result", "tool_use_id": "t9", "content": "answered"}],
                       toolUseResult={"questions": [], "answers": {"Q?": "A", "M?": ["x", "y"]}})),
        line(6, **user("<command-message>ship</command-message>\n<command-name>/ship</command-name>\n<command-args>42</command-args>",
                       origin={"kind": "human"})),
        line(7, **user([{"type": "text", "text": "[Request interrupted by user]"}])),
        line(8, **user("<task-notification>done</task-notification>", origin={"kind": "task-notification"})),
        line(9, **user("meta", isMeta=True)),
        line(10, **user("summary", isCompactSummary=True)),
        line(11, **user("side", isSidechain=True)),
        line(12, **user("あ" * 4000, origin={"kind": "human"})),
    ]
    (proj / "s1.jsonl").write_text("\n".join(rows) + "\n" + '{"partial": ')
    (proj / "s2.jsonl").write_text(json.dumps({"entrypoint": "sdk-cli", "type": "user", "timestamp": "2026-10-08T01:00:00Z",
                                               "message": {"content": "auto"}}) + "\n")

    run("end", claude, vault, state, "h")
    out = vault / ".depth" / "conversations" / "2026" / "10"
    files = list(out.glob("*_h.jsonl"))
    assert len(files) == 1, files
    got = [json.loads(r) for r in files[0].read_text().splitlines()]
    assert [e["type"] for e in got] == ["user", "claude", "tool", "refusal", "answer", "answer", "command", "refusal", "user"], [e["type"] for e in got]
    assert all(set(e) == set(FIELDS) and e["v"] == VERSION and e["host"] == "h" for e in got)
    assert got[2]["name"] == "Bash" and "[REDACTED]" in got[2]["text"] and len(got[2]["text"].encode()) <= TOOL_ARG
    assert got[3]["name"] == "Bash" and got[5]["text"] == "x, y" and got[5]["q"] == "M?"
    assert got[6]["name"] == "/ship" and got[6]["text"] == "42" and got[1]["model"] == "m"
    assert "KB 省略" in got[8]["text"] and len(got[8]["text"].encode()) < MAX_TEXT
    assert got[0]["parent"] == "u0" and got[1]["id"] == "u2"

    with (proj / "s1.jsonl").open("a") as f:  # the partial line completes later
        f.write('"x"}\n' + line(13, **user("again", origin={"kind": "human"})) + "\n")
    (proj / "memory" / "old.md").unlink()
    run("end", claude, vault, state, "h")
    again = files[0].read_text().splitlines()
    assert len(again) == len(got) + 1 and json.loads(again[-1])["text"] == "again"

    (proj / "s4.jsonl").write_text("\n".join(rows[:2]) + "\n")  # a resumed session copies s1's lines
    run("end", claude, vault, state, "h")
    assert files[0].read_text().splitlines() == again

    mem = vault / ".depth" / "memory" / "h"
    assert (mem / "projects" / "-p" / "MEMORY.md").is_file()
    assert not (mem / "projects" / "-p" / "old.md").exists()
    assert "[REDACTED]" in (mem / "agents" / "observer" / "MEMORY.md").read_text()

    (proj / "s3.jsonl").write_text(json.dumps({"type": "user", "message": {"content": "x"}}) + "\n")
    assert "no entrypoint" in run("start", claude, vault, state, "h")
    assert run("start", claude, vault, state, "h") == ""
    assert run("end", claude, tmp / "missing", state, "h") == ""

    rclone = os.environ.get("VAULT_RCLONE") or shutil.which("rclone")
    if rclone:
        os.environ["RCLONE_CONFIG"] = str(tmp / "rclone.conf")
        remote = tmp / "remote"
        problems: list[str] = []
        sync("start", vault, "h", rclone, "nowhere:", problems)
        assert "not set up" in problems[0]
        sync("end", vault, "h", rclone, f"{remote}/", problems)
        uploaded = remote / "conversations" / "2026" / "10" / files[0].name
        assert uploaded.read_text() == files[0].read_text()
        other = remote / "conversations" / "2026" / "10" / "08_g.jsonl"
        other.write_text("{}\n")
        uploaded.write_text("stale\n")
        sync("start", vault, "h", rclone, f"{remote}/", problems)
        assert len(problems) == 1, problems
        assert (out / "08_g.jsonl").read_text() == "{}\n"
        assert files[0].read_text().splitlines() == again
        assert uploaded.read_text() == files[0].read_text()
        (out / "08_g.jsonl").unlink()
    else:
        print("vault-capture: rclone not found, storage sync not tested")

    # digest: the user's side, each user line with the end of the reply before it
    text = digest([files[0]])
    assert "[2026-10-08 10:00 s1 /w] user: hello" in text and "Q: M? A: x, y" in text and "command /ship: 42" in text
    assert "(直前の Claude の返答の末尾) hi\n" in text and text.count("直前の Claude") == 1
    assert "echo" not in text

    d = datetime.date
    assert len(days_to_read(None, d(2026, 10, 18))) == MAX_DAYS
    assert days_to_read(d(2026, 10, 17), d(2026, 10, 18)) == []
    assert days_to_read(d(2026, 10, 15), d(2026, 10, 18)) == [d(2026, 10, 16), d(2026, 10, 17)]

    # daily: both agents get the material on stdin; a day counts as read only when both finish
    calls = tmp / "calls"
    fake = tmp / "fake-claude"
    fake.write_text(f"#!/bin/sh\necho \"$* | $VAULT_CAPTURE_CHILD | $(cat)\" >> {calls}\nexit ${{FAKE_RC:-0}}\n")
    fake.chmod(0o755)
    os.environ["CLAUDECODE"] = "1"
    problems = []
    daily(claude, vault, state, "h", str(fake), problems, today=d(2026, 10, 9))
    got_calls = calls.read_text().splitlines()
    assert problems == [] and len(got_calls) == 2, (problems, got_calls)
    assert "--agent observer" in got_calls[0] and "--agent minutes" in got_calls[1]
    assert all("| 1 | Read " in c and "daily-input.txt" in c for c in got_calls)
    assert "user: hello" in (state / "daily-input.txt").read_text()
    assert (state / "daily-last").read_text() == "2026-10-08"
    daily(claude, vault, state, "h", str(fake), problems, today=d(2026, 10, 9))
    assert len(calls.read_text().splitlines()) == 2  # once a day
    os.environ["FAKE_RC"] = "1"
    (state / "daily-last").write_text("2026-10-01")
    daily(claude, vault, state, "h", str(fake), problems, today=d(2026, 10, 10))
    assert "observer, minutes" in problems[0] and (state / "daily-last").read_text() == "2026-10-01"
    del os.environ["FAKE_RC"], os.environ["CLAUDECODE"]

    # the hook detaches the slow half, and the child's hooks do nothing
    script = vault / ".claude" / "scripts"
    script.mkdir(parents=True)
    marker = tmp / "synced"
    (script / "sync.py").write_text(f"import time, pathlib\ntime.sleep(1)\npathlib.Path({str(marker)!r}).write_text('ok')\n")
    env = os.environ | {"CLAUDE_CONFIG_DIR": str(claude), "VAULT_DIR": str(vault), "XDG_STATE_HOME": str(tmp),
                        "XDG_CONFIG_HOME": str(tmp / "config"), "VAULT_HOST": "h", "VAULT_REMOTE": ""}
    me = [sys.executable, os.path.abspath(__file__)]
    t0 = time.monotonic()
    subprocess.run(me + ["end"], input="{}", text=True, env=env, check=True)
    assert time.monotonic() - t0 < 1 and not marker.exists()
    for _ in range(50):
        if marker.exists():
            break
        time.sleep(0.1)
    assert marker.read_text() == "ok"
    marker.unlink()
    before = files[0].read_text()
    with (proj / "s1.jsonl").open("a") as f:
        f.write(line(14, **user("child", origin={"kind": "human"})) + "\n")
    subprocess.run(me + ["end"], input="{}", text=True, env=env | {"VAULT_CAPTURE_CHILD": "1"}, check=True)
    time.sleep(1.5)
    assert files[0].read_text() == before and not marker.exists()
    shutil.rmtree(tmp)
    print("vault-capture: self-test passed")


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    if mode == "self-test":
        self_test()
        return
    if mode not in ("end", "start", "after-end", "after-start"):
        sys.exit("usage: vault-capture end|start|self-test")
    sys.stdin.read() if not sys.stdin.isatty() else None
    if mode in ("end", "start") and os.environ.get("VAULT_CAPTURE_CHILD"):
        return
    home = Path.home()
    claude = Path(os.environ.get("CLAUDE_CONFIG_DIR") or home / ".claude")
    vault = Path(os.environ.get("VAULT_DIR") or home / "Repository/github.com/Hiro-mackay/vault")
    state = Path(os.environ.get("XDG_STATE_HOME") or home / ".local/state") / "vault-capture"
    host = os.environ.get("VAULT_HOST") or socket.gethostname().split(".")[0].lower()
    if mode.startswith("after-"):
        work = (Path(os.environ.get("XDG_CONFIG_HOME") or home / ".config") / "vault" / "work").is_file()
        after(mode.removeprefix("after-"), claude, vault, state, host,
              os.environ.get("VAULT_RCLONE") or shutil.which("rclone"), os.environ.get("VAULT_REMOTE", "vault-depth:"),
              os.environ.get("VAULT_CLAUDE") or shutil.which("claude"), work)
        return
    report = run(mode, claude, vault, state, host)
    if vault.is_dir():
        detach(mode, state)
    if report:
        print("vault-capture reported problems since the last session:\n" + report)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as e:  # noqa: BLE001
        print(f"vault-capture: {e}", file=sys.stderr)
