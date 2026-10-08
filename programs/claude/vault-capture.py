"""Copy Claude Code conversations and memory into the vault's .depth/.

Run by the SessionEnd and SessionStart hooks; no model is involved.

- Conversations of interactive sessions become one JSON line per event,
  appended to .depth/conversations/YYYY/MM/DD_<host>.jsonl. These files live
  in object storage, not git: each device uploads its own and downloads the
  others' through rclone (remote $VAULT_REMOTE, default vault-depth:).
- Every project's auto memory and every agent memory are mirrored to
  .depth/memory/<host>/.

Credentials are redacted on the way in, and over-long texts are cut down.
Nothing happens when the vault is missing. Problems are kept in the state
directory and reported by the next SessionStart; the hook always exits 0.

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
from pathlib import Path

VERSION = 1
MAX_TEXT = 10_000
KEEP_HEAD = 5_000
KEEP_TAIL = 2_000
TOOL_ARG = 200
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


def day_file(root: Path, ts: str, host: str) -> Path:
    t = datetime.datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone()
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
            by_file: dict[Path, list[str]] = {}
            for e in out:
                if e["ts"]:
                    by_file.setdefault(day_file(vault, e["ts"], host), []).append(json.dumps(e, ensure_ascii=False))
            for target, rows in by_file.items():
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


def run(mode: str, claude: Path, vault: Path, state_dir: Path, host: str,
        rclone: str | None = None, remote: str = "") -> str:
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
            if remote:
                sync(mode, vault, host, rclone, remote, problems)
        except Exception as e:  # noqa: BLE001 — a hook must not break the session
            problems.append(f"{type(e).__name__}: {e}")
        state_file.write_text(json.dumps(state))
        if problems:
            stamp = datetime.datetime.now().isoformat(timespec="seconds")
            with errors.open("a") as f:
                f.writelines(f"{stamp} {p}\n" for p in problems)
        if mode == "start" and errors.is_file() and errors.stat().st_size:
            report = errors.read_text()
            errors.write_text("")
            return report
    return ""


def self_test() -> None:
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
        assert "not set up" in run("start", claude, vault, state, "h", rclone, "nowhere:")
        run("end", claude, vault, state, "h", rclone, f"{remote}/")
        uploaded = remote / "conversations" / "2026" / "10" / files[0].name
        assert uploaded.read_text() == files[0].read_text()
        other = remote / "conversations" / "2026" / "10" / "08_g.jsonl"
        other.write_text("{}\n")
        uploaded.write_text("stale\n")
        assert run("start", claude, vault, state, "h", rclone, f"{remote}/") == ""
        assert (out / "08_g.jsonl").read_text() == "{}\n"
        assert files[0].read_text().splitlines() == again
        assert uploaded.read_text() == files[0].read_text()
    else:
        print("vault-capture: rclone not found, storage sync not tested")
    shutil.rmtree(tmp)
    print("vault-capture: self-test passed")


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    if mode == "self-test":
        self_test()
        return
    if mode not in ("end", "start"):
        sys.exit("usage: vault-capture end|start|self-test")
    sys.stdin.read() if not sys.stdin.isatty() else None
    home = Path.home()
    report = run(
        mode,
        Path(os.environ.get("CLAUDE_CONFIG_DIR") or home / ".claude"),
        Path(os.environ.get("VAULT_DIR") or home / "Repository/github.com/Hiro-mackay/vault"),
        Path(os.environ.get("XDG_STATE_HOME") or home / ".local/state") / "vault-capture",
        os.environ.get("VAULT_HOST") or socket.gethostname().split(".")[0].lower(),
        os.environ.get("VAULT_RCLONE") or shutil.which("rclone"),
        os.environ.get("VAULT_REMOTE", "vault-depth:"),
    )
    if report:
        print("vault-capture reported problems since the last session:\n" + report)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as e:  # noqa: BLE001
        print(f"vault-capture: {e}", file=sys.stderr)
