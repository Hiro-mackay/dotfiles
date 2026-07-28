---
name: python-principles
description: Python design principles covering type hints, exceptions, dataclasses, async, packaging, and idiomatic style. Apply when reading, writing, or reviewing .py files.
user-invocable: false
paths:
  - "**/*.py"
---

# Python Design Principles

These are the calls you would otherwise get wrong. Idiomatic modern Python and anything `ruff` or `mypy` already flags is deliberately absent.

## Types
- Annotate params and returns on public functions. No `Any` without a stated reason
- Guard heavy imports with `if TYPE_CHECKING:` -- a type-only import must not cost anything at runtime

## Errors
- Catch specific exceptions. Never bare `except:`, never `except Exception:`
- `raise ... from e` -- dropping the chain makes the next failure unreadable
- Wrap only the lines that can raise. A `try` around the whole function hides which call failed
- Custom exceptions derive from a domain base class, not raw `Exception`

## Data and logging
- `dataclasses` with `frozen=True, slots=True`, or `pydantic` -- not plain dicts. `__slots__` on any data-heavy class instantiated in bulk
- `Protocol` over `ABC` when structural typing is enough
- `logging` or `structlog`, never a bare `print()`

## Async
- Never call blocking I/O inside `async def` without `asyncio.to_thread`
- `asyncio.TaskGroup` over `gather` -- it cancels siblings and propagates the first error for you

## Security
- `subprocess` takes a list, never `shell=True` with interpolated input. Where a shell is unavoidable, `shlex.quote()` every interpolated value
- `secrets`, never `random`, for tokens and anything cryptographic
