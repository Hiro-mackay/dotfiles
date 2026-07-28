---
name: api-design
description: REST API design conventions for error responses, pagination, versioning, request/response patterns, and observability. Applies when designing or implementing HTTP APIs.
paths:
  - "**/api/**"
  - "**/apis/**"
  - "**/routes/**"
  - "**/router/**"
  - "**/routing/**"
  - "**/handler/**"
  - "**/handlers/**"
  - "**/controller/**"
  - "**/controllers/**"
  - "**/endpoint/**"
  - "**/endpoints/**"
  - "**/*openapi*"
  - "**/*swagger*"
---

# API Design Principles

House conventions and the calls that go wrong. Standard REST shape and HTTP semantics are deliberately absent.

## Shape
- Nest for ownership (`/users/{id}/orders`), stay flat when the resource exists independently (`/orders?user_id=`). Never nest beyond two levels -- flatten with a top-level resource instead
- Every response is enveloped: `{ "data": ... }` for both collections and single items
- Errors use one envelope everywhere: `{ "error": { "code": "VALIDATION_ERROR", "message": "human-readable", "details": [{ "field": ..., "reason": ... }] } }`. `code` is a machine-readable constant; `message` is for a person. Stack traces, SQL, and internal paths never appear in either
- IDs are strings (UUID). 422 for a well-formed request that is semantically wrong, 400 only for malformed

## Pagination
- Cursor-based (`?cursor=&limit=`) for anything real-time or large. Offset paging only for small static datasets
- Default limit 20, hard cap 100. Response carries `pagination` with `next_cursor`, or `total_count` + `total_pages` for offset

## Idempotency
- Non-idempotent operations accept an `Idempotency-Key` header. Store the key with its response, TTL 24-48 hours
- Same key, same body: return the stored response with 200, not 201
- Same key, different body: reject with 422 -- this is misuse, not a retry
- Same key still in flight: 409, or hold until the first request finishes

## Versioning
- Major breaking changes get a URL path version (`/v1/`). Support N-1 through the migration window
- Breaking means removing a field, changing its type or meaning, or adding a required one. New fields and new endpoints are additive -- no bump
- Contract first (OpenAPI), implementation second. Deprecate with a `Sunset` header and at least two release cycles of notice

## Rate limiting
- Scope per client (API key or user ID), never per IP -- shared NAT makes IP limits punish the wrong people
- Token bucket or sliding window. Fixed windows produce a thundering herd at the boundary
- Over limit: 429 with `Retry-After`, plus `X-RateLimit-Limit` / `-Remaining` / `-Reset` on normal responses

## Headers
- Cacheable reads carry a validator: `ETag` answered by `If-None-Match`, or `Last-Modified` answered by `If-Modified-Since`, returning 304 with no body. Without one, every conditional request pays for the full payload again
- `Vary` whenever the response depends on a request header (`Vary: Accept, Authorization`) -- omitting it is how proxies serve one user's data to another
- `Cache-Control: private, no-cache` on user-specific endpoints, `no-store` on sensitive ones
- `Authorization: Bearer <token>`, or `X-API-Key` for service-to-service. Never a credential in the URL
- Inbound webhooks are verified by HMAC-SHA256 over the raw body with a shared secret
- `X-Request-Id` for tracing, generated server-side when the client didn't send one

## See also
- Token lifetimes, session handling, and OAuth flow selection: `security-principles` skill. Health checks and metrics: `observability` skill
- Async operations, batch/bulk, file handling, content negotiation: [reference](reference/advanced-patterns.md)
