---
name: observability
description: Observability patterns for structured logging, distributed tracing, metrics design, and alerting. Applies when implementing logging, monitoring, tracing, metrics, or alert rules.
---

# Observability Principles

House conventions and the choices that go wrong. Standard telemetry vocabulary is deliberately absent.

## Logging
- JSON in production, human-readable in development
- Levels are defined by the response they demand, not by how bad the event feels: `ERROR` pages someone, `WARN` gets reviewed next business day, `INFO` marks a significant state change, `DEBUG` is off in production
- Every entry carries timestamp, level, message, service name, plus `request_id`, `trace_id`, `user_id`, and the operation
- Log at boundaries -- request in, response out, external call, error caught. Logging inside the logic is how a service produces volume without producing signal
- Never a password, token, API key, session ID, card number, or PII. Mask at the logging boundary: `m***@example.com`, IP with the last octet dropped

## Tracing
- Propagate context through the whole chain (W3C Trace Context / OpenTelemetry), with the trace ID generated at the entry point
- Spans named `{service}.{operation}`: `auth.validateToken`, `db.queryUsers`
- Span attributes take identifiers (`user_id`, `order_id`), never high-cardinality payloads like a request body
- Failures set span status to ERROR and record the error as a span event
- Sample 100% of errors and 1-10% of successes

## Metrics
- Request-driven services: rate, error rate, and a latency **histogram**. An average latency hides exactly the tail you are looking for
- Resources: utilization, saturation (work queued and waiting), errors
- Histogram buckets align to the SLO thresholds you actually promise, not round numbers
- Under 10 distinct values per label. High cardinality is what takes down the metrics backend, usually before it takes down the service

## Alerting
- Alert on symptoms -- error rate, latency -- not on CPU and memory, unless the resource itself is the contract
- If there is no action to take, it is not an alert. Every page has a runbook
- The alert body says what broke, who it affects, and links the dashboard and the runbook
- P1 pages immediately for a user-facing outage, P2 pages in business hours for degradation, P3 becomes a ticket
- Tune until each alert produces under one false positive a week. Past that, people stop reading them and the real one gets missed too

## Health checks
- `GET /healthz` reports dependency status, and liveness (process is up) is a different endpoint from readiness (can serve traffic). Conflating them makes Kubernetes restart a process that was only waiting on a dependency
- No side effects, no heavy work. Include version and build info
