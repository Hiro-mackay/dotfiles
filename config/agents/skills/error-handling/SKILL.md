---
name: error-handling
description: Cross-language resilience patterns for retry, timeout, circuit breaker, fallback, and graceful degradation. Applies when implementing retry logic, timeout handling, circuit breakers, or fault tolerance.
---

# Error Handling & Resilience Patterns

The calls that go wrong under failure. The pattern catalogue itself is deliberately absent.

## Retry
- Exponential backoff **with jitter** (`base * 2^attempt + random(0, base)`), capped around 30s. Without jitter, every client retries in lockstep and the recovering service falls over again
- 3-5 attempts for idempotent operations. Never retry a non-idempotent one without an idempotency key
- Retry timeouts, connection resets, DNS failures, 429, and 503. Nothing in the 4xx range except 429 will succeed on a second try
- Log the attempt number and the reason each time, or the retry loop is invisible in production

## Timeouts
- Every external call has one. An unbounded wait is a slow outage
- Connect timeout (1-5s) and read timeout are separate settings with different jobs
- Downstream timeouts must be shorter than upstream ones. A 30s API budget with a 30s DB call leaves nothing for the rest of the request
- Pass the deadline down the call chain. Creating a fresh timeout at each layer silently multiplies the total wait
- A timeout error names the operation, the configured value, and the target

## Circuit breakers and bulkheads
- One breaker per dependency, never a global one -- otherwise a single failing service opens the circuit for everything
- Open after roughly 5 failures in 60s, stay open ~30s and back off further on repeat, then let exactly one request through to test
- While open, fail fast and expose the state as a metric
- Separate connection pools per downstream service, and separate worker pools for critical versus best-effort work, so one slow dependency cannot consume every thread
- Bounded queues that reject when full. An unbounded queue converts a throughput problem into a memory problem

## Fallbacks
- A fallback must be simpler and more reliable than the path it replaces. A fallback with its own dependencies is just a second way to fail
- One level only. Never fall back to something that itself falls back
- Stale cache, a precomputed response, or reduced functionality -- decided in advance, not improvised at the failure site

## Idempotency
- Anything retryable is either naturally idempotent (unique constraint, upsert, state transition) or carries an idempotency key
- Record the "executed" marker in the same transaction as the side effect. Separate writes reintroduce the race you were trying to close
- Write-path races and publish-after-commit: `concurrency-idempotency` skill. API-level key design: `api-design` skill. Outbox and message processing: `system-design` skill

## Propagation
- Wrap with context at each layer so the message reads as a path: `payment failed: charge card: timeout after 5s`
- Keep the original error reachable for `errors.Is` / `errors.As` or an equivalent cause chain
- Translate to a status code and error code once, at the API boundary -- not at every layer on the way out

## By language
- Go: `context.WithTimeout` for deadlines, `errgroup` for concurrent error collection, `fmt.Errorf("context: %w", err)` to wrap
- Python: `tenacity` for retry, `asyncio.wait_for` for async timeouts
- TypeScript: `AbortSignal.timeout()` for fetch, `p-retry` for retry
