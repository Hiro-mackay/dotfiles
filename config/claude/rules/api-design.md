# API Design Principles

## Resource Modeling
- Nouns for resources, HTTP verbs for actions: `POST /orders` not `POST /createOrder`
- Plural resource names: `/users`, `/orders`, `/products`
- Nest for ownership: `/users/{id}/orders` -- max 2 levels deep
- Use query parameters for filtering, sorting, searching: `/orders?status=pending&sort=-created_at`
- Avoid action endpoints -- if unavoidable, use verb sub-resources: `POST /orders/{id}/cancel`

## HTTP Methods & Status Codes
- `GET` (read), `POST` (create), `PUT` (full replace), `PATCH` (partial update), `DELETE` (remove)
- `201 Created` for POST with `Location` header
- `204 No Content` for successful DELETE
- `400` validation error, `401` unauthenticated, `403` unauthorized, `404` not found, `409` conflict, `422` unprocessable
- `500` only for unexpected server errors -- never leak internals

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
- Response includes: `data`, `pagination` (next_cursor or total_count + total_pages)
- Default limit with a max cap (e.g., default 20, max 100)

## Versioning
- URL path versioning for major breaking changes: `/v1/users`, `/v2/users`
- Additive changes (new fields, new endpoints) are NOT breaking -- no version bump
- Breaking changes: field removal, type change, semantic change, required field addition
- Support N-1 version minimum during migration period

## Request/Response Design
- Use `camelCase` for JSON fields (or match project convention consistently)
- Timestamps in ISO 8601 / RFC 3339: `2024-01-15T09:30:00Z`
- IDs as strings (UUID preferred over sequential integers for public APIs)
- Envelope responses: `{ "data": [...] }` for collections, `{ "data": {} }` for singles
- Partial responses with `?fields=id,name,email` for bandwidth optimization

## API Gateway Patterns
- Gateway as single entry point: routing, auth, rate limiting, request transformation
- Backend for Frontend (BFF): per-client gateway aggregating multiple services
- Rate limiting with clear headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
- Circuit breaker for downstream service failures

## Security
- Authentication at gateway, authorization at service
- API keys for service-to-service, OAuth 2.0 / JWT for user-facing
- Always validate and sanitize input at API boundary
- CORS: explicit origin allowlist, never `*` in production
- Idempotency keys for non-idempotent operations: `Idempotency-Key` header for POST

## Evolution & Documentation
- Design API contract first (OpenAPI spec), implement second
- Deprecation: `Sunset` header + minimum 2 release cycles notice
- Health check endpoint: `GET /health` returning service status
