---
paths:
  - "**/*.py"
---

# Python Design Principles

## Naming (PEP 8)
- `snake_case` for functions, methods, variables, and modules
- `CapWords` for classes and type aliases; `Error` suffix for custom exceptions
- `UPPER_CASE` for module-level constants
- `_leading_underscore` for internal/non-public names
- Never single-char `l`, `O`, `I` -- ambiguous in many fonts
- First param: `self` for instance methods, `cls` for class methods
- Package names: short, lowercase, no underscores

## Code Layout
- 4 spaces per indent, no tabs
- 79 chars max for code, 72 for docstrings and comments
- Break before binary operators (PEP 8 W504)
- Two blank lines around top-level definitions, one around methods
- Implicit line continuation via `()` `[]` `{}` over backslash `\`

## Imports
- One import per line
- Absolute imports over relative imports
- Never wildcard `from x import *`
- `from __future__` first, then stdlib -> third-party -> local (blank line between groups)
- Define `__all__` to declare public API in modules

## Whitespace
- No spaces inside brackets: `func(arg)` not `func( arg )`
- No space before call/index parens: `f(x)`, `d[key]`
- No space around `=` in keyword args: `func(key=val)`
- Space around `=` in default values with annotations: `def f(x: int = 0)`
- Space after `:` in annotations: `name: str`

## Documentation (PEP 257)
- Docstrings on all public modules, classes, functions, and methods
- Triple double quotes `"""` always
- One-liner: `"""Return the user's display name."""` on one line
- Multi-line: summary line, blank line, then elaboration
- Imperative mood: "Return" not "Returns"

## Comparisons & Idioms
- `is` / `is not` for singletons (`None`, `True`, `False`)
- `isinstance(x, T)` over `type(x) == T`
- Truthiness for empty checks: `if items:` not `if len(items) > 0`
- `.startswith()` / `.endswith()` over string slicing
- `def f():` over `f = lambda:` -- no lambda assignment
- All return paths must return a value or all must be bare
- No control flow (`return`, `break`, `continue`) in `finally` blocks

## Type Hints
- All public functions must have type annotations (params + return)
- `X | None` over `Optional[X]` (3.10+)
- `list[str]`, `dict[str, int]` over `List[str]`, `Dict[str, int]` (3.9+)
- `TypeAlias` (3.10+) or `type` statement (3.12+) -- calibrate to project version
- No `Any` without justification
- Guard heavy imports with `if TYPE_CHECKING:` to avoid runtime cost

## Error Handling
- Catch specific exceptions, never bare `except:` or `except Exception:`
- `raise ... from e` to preserve exception chains
- Context managers (`with`) for all resources
- No silent `pass` in except blocks
- Derive custom exceptions from domain-specific base, not raw `Exception`
- Minimize `try` scope -- only wrap the line(s) that can raise

## Modern Python
- f-strings over `.format()` or `%`
- `pathlib.Path` over `os.path`
- `dataclasses` or `pydantic` over plain dicts for structured data
- `enum.Enum` for fixed sets of values
- `match` statement for complex branching (3.10+)
- `removeprefix()` / `removesuffix()` over slicing (3.9+)
- `dict1 | dict2` merge syntax (3.9+)
- Prefer stdlib: `itertools`, `functools`, `collections`, `contextlib`

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
