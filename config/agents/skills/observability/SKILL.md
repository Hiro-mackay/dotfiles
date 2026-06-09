---
name: observability
description: Observability patterns for structured logging, distributed tracing, metrics design, and alerting. Applies when implementing logging, monitoring, tracing, metrics, or alert rules.
---

# Observability Principles

## Structured Logging
- JSON format in production, human-readable in development
- Log levels with clear semantics:
  - `ERROR`: requires human intervention, pages oncall
  - `WARN`: unexpected but handled, review in next business day
  - `INFO`: significant state changes (request served, job completed, config loaded)
  - `DEBUG`: diagnostic detail, disabled in production by default
- Every log entry MUST include: timestamp (ISO 8601), level, message, service name
- Include contextual fields: request_id, user_id, trace_id, operation name
- NEVER log: passwords, tokens, API keys, PII, credit card numbers, session IDs
- Mask sensitive fields: email -> `m***@example.com`, IP -> last octet redacted
- Log at boundaries: incoming request, outgoing response, external service call, error caught

## Distributed Tracing
- Propagate trace context through entire call chain (W3C Trace Context / OpenTelemetry)
- Generate trace_id at entry point, pass through all downstream calls
- Span naming: `{service}.{operation}` (e.g., `auth.validateToken`, `db.queryUsers`)
- Add span attributes for key parameters (user_id, order_id) -- NOT for high-cardinality values (request body)
- Record errors as span events with stack traces
- Set span status to ERROR on failures
- Sample strategically: 100% for errors, configurable rate for success (1-10%)

## Metrics Design
- RED method for request-driven services:
  - **R**ate: requests per second
  - **E**rrors: failed requests per second
  - **D**uration: request latency distribution (histogram, NOT average)
- USE method for resources (CPU, memory, connections, queues):
  - **U**tilization: percentage of capacity used
  - **S**aturation: work queued / waiting
  - **E**rrors: error count
- Histogram buckets for latency: align with SLO thresholds (e.g., 50ms, 100ms, 250ms, 500ms, 1s, 5s)
- Counter for totals, gauge for current state, histogram for distributions
- Label cardinality: keep under 10 unique values per label. High cardinality kills metric backends

## Alerting
- Alert on symptoms (error rate, latency), not causes (CPU, memory) -- unless resource-specific
- Every alert MUST be actionable: if there's no runbook action, it shouldn't page
- Include in alert: what's broken, impact, dashboard link, runbook link
- Severity levels:
  - **P1**: user-facing outage, page immediately
  - **P2**: degraded service, page during business hours
  - **P3**: non-urgent, ticket and review
- Avoid alert fatigue: tune thresholds to < 1 false positive per week per alert

## Health Checks
- `GET /health` or `GET /healthz`: return dependency status (DB, cache, external APIs)
- Distinguish liveness (process alive) from readiness (can serve traffic)
- Health check MUST NOT trigger side effects or heavy computation
- Include version/build info in health response for debugging
