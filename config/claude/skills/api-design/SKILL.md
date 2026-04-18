---
name: api-design
description: REST API design conventions for error responses, pagination, versioning, request/response patterns, and observability. Applies when designing or implementing HTTP APIs.
---

# API Design Principles

## Resource Design
- Resources are nouns, not verbs: `/users`, `/orders` -- not `/getUsers`, `/createOrder`
- Hierarchy for ownership: `/users/{id}/orders` when orders belong to a user
- Flat when independent: `/orders?user_id={id}` when orders exist outside user context
- Collection (plural) and item (singular ID): `GET /users` vs `GET /users/{id}`
- Avoid nesting beyond 2 levels: `/users/{id}/orders` is fine, `/users/{id}/orders/{id}/items/{id}/notes` is not -- flatten with top-level resources

## HTTP Methods & Status Codes
- `GET`: read, cacheable, idempotent. 200 with body, 304 if not modified
- `POST`: create or action, NOT idempotent (use `Idempotency-Key` header). 201 + `Location` header for creation, 200 for actions
- `PUT`: full replace, idempotent. 200 or 204
- `PATCH`: partial update, NOT idempotent. 200 with updated resource
- `DELETE`: remove, idempotent. 204 (no body) or 200 (with deleted resource)
- Client errors: 400 (malformed), 401 (unauthenticated), 403 (unauthorized), 404 (not found), 409 (conflict), 422 (valid syntax but semantic error)
- Server errors: 500 (unexpected), 502 (upstream failure), 503 (overloaded/maintenance), 504 (upstream timeout)

## Error Responses
- Consistent error envelope across all endpoints:
  ```json
  { "error": { "code": "VALIDATION_ERROR", "message": "human-readable", "details": [...] } }
  ```
- Machine-readable `code` (constant string), human-readable `message`
- `details` array for field-level validation errors with `field`, `reason`
- Never expose stack traces, SQL, or internal paths

## Pagination
- Cursor-based for real-time data or large datasets: `?cursor=abc&limit=20`
- Offset-based only for static, small datasets: `?page=1&per_page=20`
- Response: `data` + `pagination` (next_cursor or total_count + total_pages)
- Default limit: 20, max cap: 100

## Versioning
- URL path versioning for major breaking changes: `/v1/`, `/v2/`
- Additive changes (new fields, new endpoints) are NOT breaking -- no version bump
- Breaking: field removal, type change, semantic change, required field addition
- Support N-1 version minimum during migration period

## Request/Response Design
- Timestamps in ISO 8601 / RFC 3339
- IDs as strings (UUID)
- Envelope responses: `{ "data": [...] }` for collections, `{ "data": {} }` for singles
- Idempotency keys for non-idempotent operations: `Idempotency-Key` header for POST
  - Store key + response in DB. TTL: 24-48 hours
  - Same key + same request body = return cached response (200, not 201)
  - Same key + different body = reject with 422 (prevent misuse)
  - In-flight duplicate: return 409 or hold until first request completes
- Partial responses with `?fields=id,name,email` for bandwidth optimization

## Authentication at API Layer
- See `security-principles` skill for auth architecture, token design, and implementation details
- API layer specifics: `Authorization: Bearer <token>` header, `X-API-Key` for service-to-service (never in URL)
- Webhook signatures: HMAC-SHA256 with shared secret for inbound webhooks

## Rate Limiting
- Scope: per-client (API key / user ID), not per-IP (shared NAT breaks this)
- Algorithm: token bucket or sliding window. Fixed window causes thundering herd at boundary
- Differentiate by tier: free (60/min), paid (600/min), internal (no limit)
- Response: 429 Too Many Requests + `Retry-After` header (seconds until reset)
- Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

## Caching
- `ETag` + `If-None-Match` for content-based cache validation (304 Not Modified)
- `Cache-Control: max-age=N` for time-based caching. `no-store` for sensitive data
- `Last-Modified` + `If-Modified-Since` for timestamp-based validation
- `Vary` header when response differs by request header (e.g., `Vary: Accept, Authorization`)
- Private endpoints: `Cache-Control: private, no-cache` -- prevent proxy caching of user-specific data

## Async Operations
- Long-running tasks: return 202 Accepted + `Location` header pointing to status resource
- Status resource: `GET /jobs/{id}` returning `{ "status": "pending|running|completed|failed", "result_url": "..." }`
- Completion notification: webhook callback preferred over client polling
- Timeout: set and communicate maximum processing time. Fail with clear error if exceeded

## Batch Operations
- Bulk endpoint: `POST /users/batch` with array body, max 100 items
- Response: per-item status `{ "results": [{ "id": "...", "status": 201 }, { "id": "...", "status": 422, "error": {...} }] }`
- Partial success is valid -- return 200 with mixed item statuses, not 500
- Prefer batch over sequential calls when client needs > 5 operations

## File Handling
- Upload: presigned URL (S3/GCS) for large files. Direct `multipart/form-data` only for small files (< 10MB)
- Download: presigned URL with expiration, or stream with `Content-Disposition` header
- Progress: chunked upload with resumable protocol for large files
- Validation: enforce file size limits and content type checks server-side

## Content Negotiation
- `Content-Type` on request, `Accept` on response preference
- Default to `application/json`. Support other formats only when explicitly needed
- `406 Not Acceptable` when requested format is unsupported

## Observability Headers
- `X-Request-Id` header for distributed tracing -- generate server-side if not provided
- Health checks and application-level observability: see `observability` skill

## Evolution
- API contract first (OpenAPI spec), implement second
- Deprecation: `Sunset` header + minimum 2 release cycles notice
