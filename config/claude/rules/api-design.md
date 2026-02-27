# API Design Principles

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
- Partial responses with `?fields=id,name,email` for bandwidth optimization

## Observability
- `X-Request-Id` header for distributed tracing -- generate server-side if not provided
- Rate limiting headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
- Health check: `GET /health` returning dependency status (DB, cache, external services)

## Evolution
- API contract first (OpenAPI spec), implement second
- Deprecation: `Sunset` header + minimum 2 release cycles notice
