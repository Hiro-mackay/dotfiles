---
name: error-handling
description: Cross-language resilience patterns for retry, timeout, circuit breaker, fallback, and graceful degradation. Applies when implementing retry logic, timeout handling, circuit breakers, or fault tolerance.
---

# Error Handling & Resilience Patterns

## Retry Strategy
- Exponential backoff with jitter: `base * 2^attempt + random(0, base)`
- Max attempts: 3-5 for idempotent operations. NEVER retry non-idempotent without idempotency key
- Retryable: network timeout, 429, 503, connection reset, DNS failure
- NOT retryable: 400, 401, 403, 404, 409, 422 -- these won't succeed on retry
- Cap max backoff (e.g., 30s) to prevent unbounded waits
- Log each retry with attempt number and reason

## Timeout Design
- Set timeouts on EVERY external call -- no unbounded waits
- Separate connect timeout (short, 1-5s) from read timeout (longer, varies by operation)
- Cascade prevention: downstream timeout < upstream timeout. If API has 30s timeout, DB call MUST be < 30s
- Pass deadline/context through the call chain -- don't create new timeouts at each layer
- Timeout error MUST include: which operation, configured timeout value, target service

## Circuit Breaker
- States: CLOSED (normal) -> OPEN (failing) -> HALF-OPEN (testing recovery)
- Open threshold: N failures in M seconds (e.g., 5 failures in 60s)
- Open duration: start at 30s, increase on repeated failures
- Half-open: allow 1 request through. Success -> CLOSED, failure -> OPEN
- Circuit breaker per dependency, not global
- When open: fail fast with clear error, use fallback if available
- Expose circuit state as a metric for monitoring

## Fallback Patterns
- Graceful degradation: serve stale cache, default values, or reduced functionality
- Fallback MUST be simpler and more reliable than the primary path
- Never chain fallbacks to other fallbacks -- one level only
- Cache-aside for read-heavy: try cache -> miss -> fetch -> populate cache
- Static fallback: pre-computed response when real-time computation fails
- Feature flags: disable non-critical features under load

## Bulkhead (Resource Isolation)
- Separate connection pools per downstream service
- Separate thread/goroutine pools for critical vs. non-critical work
- Queue with bounded size -- reject when full, don't block indefinitely
- Prevent one slow dependency from exhausting all resources

## Idempotency
- All retryable operations MUST be idempotent or use idempotency keys
- Natural idempotency: DB unique constraint, upsert, state machine transitions
- Side effects: record "executed" flag in same transaction, check before re-executing on retry
- For API-level idempotency key design, see `api-design` skill
- For message processing idempotency and outbox pattern, see `system-design` skill

## Error Propagation
- Wrap errors with context at each layer: `"payment failed: charge card: timeout after 5s"`
- Preserve original error for programmatic handling (`errors.Is`/`errors.As`, `cause` chain)
- At API boundary: translate internal errors to appropriate HTTP status + error code
- Never expose internal details (stack traces, SQL, file paths) to external callers
- Structured error response: machine-readable code + human-readable message

## Language-Specific
- Go: `context.WithTimeout` for deadlines. `errgroup` for concurrent error collection. Wrap with `fmt.Errorf("context: %w", err)`
- Python: `tenacity` for retry. `asyncio.wait_for` for async timeout. `contextlib.suppress` sparingly
- TypeScript: `AbortSignal.timeout()` for fetch. `p-retry` for retry. `Promise.race` for timeout fallback
