# API Advanced Patterns

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
