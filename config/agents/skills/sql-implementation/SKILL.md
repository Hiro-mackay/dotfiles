---
name: sql-implementation
description: SQL implementation rules covering query correctness, indexing, joins, transactions, NULL semantics, and migration safety. Apply when reading, writing, or reviewing .sql files or database migration code.
user-invocable: false
paths:
  - "**/*.sql"
  - "**/migrations/**"
  - "**/migrate/**"
---

# SQL Implementation Rules

House conventions and the calls that go wrong. Schema design decisions live in the `db-schema-design` skill.

## Naming
- `snake_case`, plural table names (`users`, `order_items`), foreign keys as `{singular_table}_id`, booleans prefixed `is_` / `has_`, indexes as `idx_{table}_{columns}`

## Queries
- No query inside a loop. JOIN or batch with `IN`
- Name the columns; `SELECT *` does not belong in application code
- `LIMIT` by default -- an unbounded query is a production incident waiting for the table to grow
- `WHERE EXISTS (...)` for existence checks, not `COUNT(...) > 0`. `UNION ALL` when duplicates are impossible
- A function on an indexed column in `WHERE` (`LOWER(email) = ?`) discards the index. Use a functional index or a generated column
- Keyset pagination (`WHERE id > ?`) rather than `OFFSET` once the table is large
- `EXPLAIN ANALYZE` any new query that touches a large table. Watch for sequential scans, nested loops over unindexed joins, and estimated rows far from actual

## Indexing
- Index every foreign key column -- most engines do not do this for you
- Composite indexes put equality conditions first and the range condition last
- Every index slows writes. Remove ones nothing uses

## Transactions and locking
- Short transactions. No network call, no user interaction, nothing that can block inside one
- Acquire locks in the same order on every code path, set `lock_timeout` / `innodb_lock_wait_timeout`, and retry serialization failures with backoff
- Optimistic locking with a version column for concurrent updates
- `SELECT ... FOR UPDATE` locks only the rows you actually need, never a large result set

## Connection pool
- Start at `(2 * CPU cores) + effective_spindle_count` and measure. `max_idle` close to `max_open` to avoid churn
- `max_lifetime` 5-10 minutes so connections rotate before a load balancer or PgBouncer kills them mid-query. `connect_timeout` 3-5 seconds -- fail fast instead of queueing
- One pool per database role, and a separate pool for read replicas

## Bulk work
- 100-1000 rows per batched INSERT. `COPY` for initial loads in PostgreSQL
- Bulk UPDATE and DELETE run in `LIMIT`ed chunks, so no single transaction holds locks long enough to escalate

## Tracing
- Carry the trace ID into the query as a comment (`/* trace_id=abc123 */ SELECT ...`) so slow queries can be attributed to a caller
- Log duration with bound parameters, never the interpolated string

## Migration safety
- Zero-downtime means additive only: add column, add table, add index. Anything breaking becomes add new, backfill, then remove old, across separate deploys
- New columns are nullable or carry a default. `NOT NULL` without a default on an existing table locks and fails
- `CREATE INDEX CONCURRENTLY` in PostgreSQL. Every migration has a working down, and gets tested against a production-sized dataset first
