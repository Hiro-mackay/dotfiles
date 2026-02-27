---
paths:
  - "**/*.py"
---

# Python Design Principles

## Type Hints
- All public functions must have type annotations (params + return)
- `X | None` over `Optional[X]` (3.10+)
- `list[str]`, `dict[str, int]` over `List[str]`, `Dict[str, int]` (3.9+)
- `TypeAlias` (3.10+) or `type` statement (3.12+) -- calibrate to project version
- `Self` return type for fluent interfaces and classmethods (3.11+)
- `@override` decorator for explicit method overrides (3.12+)
- No `Any` without justification
- Guard heavy imports with `if TYPE_CHECKING:` to avoid runtime cost

## Error Handling
- Catch specific exceptions, never bare `except:` or `except Exception:`
- `raise ... from e` to preserve exception chains
- Context managers (`with`) for all resources
- `contextlib.suppress(SpecificError)` over empty except blocks
- Derive custom exceptions from domain-specific base, not raw `Exception`
- Minimize `try` scope -- only wrap the line(s) that can raise

## Modern Python
- f-strings over `.format()` or `%`
- `pathlib.Path` over `os.path`
- `dataclasses` (prefer `frozen=True, slots=True`) or `pydantic` over plain dicts
- `enum.Enum` for fixed sets of values
- `match` statement for complex branching (3.10+)
- `removeprefix()` / `removesuffix()` (3.9+)
- `dict1 | dict2` merge syntax (3.9+)
- `tomllib` for TOML config parsing (3.11+)
- Prefer stdlib: `itertools`, `functools`, `collections`, `contextlib`

## Design Patterns
- `Protocol` over `ABC` when only structural typing is needed -- duck typing with type safety
- `__slots__` on data-heavy classes instantiated in bulk
- `functools.cache` / `lru_cache` for pure function memoization
- Structured logging: `logging` with structured format or `structlog` -- no bare `print()`

## Async
- `async/await` over `threading` for I/O-bound concurrency
- Never call blocking I/O inside `async def` without `asyncio.to_thread`
- `asyncio.TaskGroup` over `gather` (3.11+)
- Always cancel/cleanup tasks on error
- Handle `KeyboardInterrupt` / signals for graceful shutdown

## Security
- Never `eval()` / `exec()` on untrusted input
- `subprocess`: always pass `list` args, never `shell=True` with user input
- `yaml.safe_load()` over `yaml.load()` -- arbitrary code execution risk
- Never `pickle.loads()` on untrusted data -- use JSON or msgpack
- `shlex.quote()` when interpolating into shell commands
- `secrets` module over `random` for tokens and cryptographic values

## Project Structure
- No circular imports
- No mutable default arguments (`def f(x=[])`)
- `__all__` in `__init__.py` to control public surface
