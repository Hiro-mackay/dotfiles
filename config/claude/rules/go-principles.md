---
paths:
  - "**/*.go"
---

# Go Design Principles

## Naming
- Package names: short, lowercase, single-word, no underscores, no mixedCaps
- No `Get` prefix for getters -- `Owner()` not `GetOwner()`; setters use `Set` prefix
- Single-method interfaces: name with -er suffix (`Reader`, `Writer`, `Formatter`)
- `MixedCaps` / `mixedCaps` -- never underscores in names
- All-caps for acronyms: `HTTP`, `URL`, `ID` -- not `Http`, `Url`, `Id`
- Short receiver names (1-2 chars), consistent across methods (not `this`/`self`)

## Commentary
- Doc comments on exported names, starting with the declared name: `// Foo does...`
- Package comments required for non-trivial packages
- Error strings: lowercase, no trailing punctuation, prefix with origin (`pkg: message`)

## Control Structures
- No unnecessary `else` after `return` -- keep happy path unindented
- Use if-init: `if err := fn(); err != nil { ... }`
- Type switch for interface dispatch: `switch v := x.(type) { ... }`
- `for range ch` to receive until channel closes

## Functions & Defer
- Error as last return value
- Named returns for godoc clarity; use sparingly -- can hurt readability in long functions
- Pointer receiver when method mutates or struct is large; value receiver for small immutable types
- `defer` runs LIFO; arguments evaluated at defer site, not execution
- Avoid `defer` inside loops; wrap in anonymous function if needed to ensure timely execution

## Data
- `new(T)` returns zeroed `*T`; `make` for slices, maps, channels (initialized, not zeroed)
- Design types so the zero value is useful (`bytes.Buffer`, `sync.Mutex` work at zero value)
- Use field names in composite literals: `Point{X: 1, Y: 2}` not `Point{1, 2}`
- Pre-allocate slices with `make([]T, 0, n)` and maps with `make(map[K]V, n)` when capacity is known
- `slices.Clone()` / `copy()` for small slices from large arrays
- Go 1.20+: `errors.Join` for combining multiple errors
- Go 1.21+: `min()`/`max()` built-in, `sync.OnceFunc`/`sync.OnceValue`, `log/slog`
- Go 1.22+: remove redundant `v := v`; use `slices`, `maps`, `cmp` packages

## Interfaces & Embedding
- Accept interfaces, return concrete types
- Export the interface (not the concrete type) only when callers should never instantiate directly (e.g. `http.ResponseWriter`, `io.Reader`)
- Compile-time interface check: `var _ Interface = (*Type)(nil)`
- Prefer embedding over manual method forwarding

## Error Handling
- `errors.Is` / `errors.As` -- never `==` for wrapped errors
- `%w` when callers should inspect with `errors.Is`/`errors.As` -- becomes part of your API contract; omit `%w` (use `%v`) when the wrapped type is an internal detail
- No ignored error returns
- Custom error types implement `Error() string` -- use for typed error handling
- Implement `Unwrap() error` on custom error types that wrap an underlying error
- `panic` only for unrecoverable invariant violations; libraries MUST recover or document panic conditions
- `recover` belongs in deferred functions; convert panic to error at API boundary

## Concurrency
- "Don't communicate by sharing memory; share memory by communicating"
- `context.Context` first param, never stored in structs
- Context propagation through entire call chain
- Always `defer cancel()` when creating derived contexts (`WithCancel`, `WithTimeout`, `WithDeadline`)
- Unbuffered channels need clear goroutine coordination
- Buffered channels as semaphores for limiting concurrency
- `select` with `default` for non-blocking channel operations
- Worker pool: fixed goroutines consuming from shared channel
- `sync.WaitGroup` Add/Done must match
- `resp.Body.Close()` / `rows.Close()` in `defer` after error check
- No `init()` side effects -- prefer explicit initialization
- Concurrency is about structure; parallelism is about execution
