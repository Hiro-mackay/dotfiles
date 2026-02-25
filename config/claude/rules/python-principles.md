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
- No `Any` without justification

## Error Handling
- Catch specific exceptions, never bare `except:` or `except Exception:`
- `raise ... from e` to preserve exception chains
- Context managers (`with`) for all resources
- No silent `pass` in except blocks

## Modern Python
- f-strings over `.format()` or `%`
- `pathlib.Path` over `os.path`
- `dataclasses` or `pydantic` over plain dicts for structured data
- `enum.Enum` for fixed sets of values
- `match` statement for complex branching (3.10+)

## Async
- `async/await` over `threading` for I/O-bound concurrency
- Never call blocking I/O inside `async def` without `asyncio.to_thread`
- `asyncio.TaskGroup` over `gather` (3.11+)
- Always cancel/cleanup tasks on error

## Project Structure
- Imports: stdlib -> third-party -> local
- No circular imports
- No mutable default arguments (`def f(x=[])`)
