---
name: go-principles
description: Go design principles covering naming, error handling, goroutines and concurrency, interfaces, package layout, and idiomatic style. Apply when reading, writing, or reviewing .go files.
user-invocable: false
paths:
  - "**/*.go"
---

# Go Design Principles

These are the calls you would otherwise get wrong, not a summary of idiomatic Go. Anything `go vet` or the project linter already catches is deliberately absent.

## Comments
- Doc comments only on exported names of a package consumed outside its own module, starting with the declared name. Inside an app's internal packages, skip them -- a doc comment that echoes the signature (`// GetUser returns the user`) is noise. Package comment only when the name doesn't already say it

## Errors
- `%w` when callers should inspect with `errors.Is` / `errors.As` -- it becomes part of your API contract and you cannot remove it later. Use `%v` when the wrapped type is an internal detail
- Compare wrapped errors with `errors.Is` / `errors.As`, never `==`. Wrapping silently breaks equality, and neither `go vet` nor the standard `golangci-lint` set reports it

## Context
- `context.Context` is the first parameter and is never stored in a struct field. A context in a struct outlives the request it belongs to

## Interfaces
- Accept interfaces, return concrete types. Export the interface instead of the concrete type only when callers should never instantiate it directly (`http.ResponseWriter`, `io.Reader`)

## Goroutines and lifetime
- Every goroutine MUST have a termination path: context cancellation, channel close, or timeout
- No `init()` side effects -- initialize explicitly at the call site
- `resp.Body.Close()` / `rows.Close()` in `defer`, placed after the error check
- No `defer` inside a loop; wrap the body in a function literal when release has to happen per iteration

## Memory
- A slice taken from a large array retains the whole backing array -- `slices.Clone()` to release it
