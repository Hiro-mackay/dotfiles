---
paths:
  - "**/*.go"
---

# Go Design Principles

## Error Handling
- `errors.Is` / `errors.As` -- never `==` for wrapped errors
- `%w` only when underlying error is public API; `%v` for opaque errors
- No ignored error returns; no `panic` in library code

## Slices & Modern Go
- Pre-allocate with `make([]T, 0, n)` when size is known
- `slices.Clone()` / `copy()` for small slices from large arrays
- No `defer` inside loops
- Go 1.22+: remove redundant `v := v`; use `slices`, `maps`, `cmp` packages
- `log/slog` over `log.Printf`

## Concurrency & Resources
- `context.Context` first param, never stored in structs
- Unbuffered channels need clear goroutine coordination
- `sync.WaitGroup` Add/Done must match
- `resp.Body.Close()` / `rows.Close()` in `defer` after error check
- No `init()` side effects -- prefer explicit initialization

## Idiomatic Patterns
- Doc comments on exported names
- Short, consistent receiver names (not `this`/`self`)
- Accept interfaces, return structs
- Context propagation through entire call chain
