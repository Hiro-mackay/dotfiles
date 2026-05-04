---
name: sql-implementation
description: SQL implementation rules covering query correctness, indexing, joins, transactions, NULL semantics, and migration safety. Apply when reading, writing, or reviewing .sql files or database migration code.
paths:
  - "**/*.sql"
  - "**/migrations/**"
  - "**/migrate/**"
---

# SQL Implementation Rules
<!-- For schema design decisions and data modeling, use /db-schema-design skill -->

## Naming Conventions
- `snake_case` for tables and columns
- Plural table names: `users`, `orders`, `order_items`
- Foreign keys: `{referenced_table_singular}_id` (e.g., `user_id`, `order_id`)
- Boolean columns: `is_` or `has_` prefix (`is_active`, `has_verified_email`)
- Indexes: `idx_{table}_{columns}` (e.g., `idx_orders_user_id_created_at`)

## Query Patterns
- **N+1 prevention**: use JOINs or batch loading (IN clause), never loop queries
- SELECT only needed columns, never `SELECT *` in application code
- Use parameterized queries / prepared statements -- never string interpolation
- LIMIT results by default; unbounded queries are a production risk
- Use EXISTS over COUNT for existence checks: `WHERE EXISTS (...)` not `WHERE (SELECT COUNT ...) > 0`
- Prefer `UNION ALL` over `UNION` when duplicates are impossible

## Indexing
- Index every foreign key column
- Index columns used in WHERE, ORDER BY, and JOIN conditions
- Composite indexes: put equality conditions first, range conditions last
- Covering indexes for frequent queries to avoid table lookups
- Do not over-index: each index slows writes. Monitor and remove unused indexes

## Transactions & Locking
- Keep transactions short -- no network calls or user interaction inside a transaction
- Use appropriate isolation level (READ COMMITTED default; SERIALIZABLE for financial)
- Optimistic locking with version column for concurrent updates
- Retry on serialization failures with exponential backoff
- Deadlock prevention: acquire locks in consistent order across all code paths
- Deadlock detection: set `lock_timeout` (PostgreSQL) or `innodb_lock_wait_timeout` (MySQL). Catch and retry
- Avoid `SELECT ... FOR UPDATE` on large result sets -- lock only the rows you need

## Connection Pool
- Size: start with `(2 * CPU cores) + effective_spindle_count`. Measure and adjust
- Set `max_idle` close to `max_open` to avoid connection churn
- `max_lifetime`: 5-10 minutes. Rotate before infrastructure-level timeout (load balancer, PgBouncer)
- `connect_timeout`: 3-5 seconds. Fail fast, don't queue indefinitely
- Health check: `SELECT 1` or driver-level ping on checkout from pool
- One pool per database role. Separate pools for read replicas

## Query Performance
- `EXPLAIN ANALYZE` before deploying new queries touching large tables
- Watch for: sequential scans on large tables, nested loops on unindexed joins, high row estimates vs actuals
- Slow query logging: set threshold (100ms-500ms), review weekly
- Avoid functions in WHERE on indexed columns (`WHERE LOWER(email) = ?`) -- use functional index or generated column
- Pagination: keyset (`WHERE id > ?`) over offset (`OFFSET 1000`) for large datasets

## Bulk Operations
- Batch INSERT: 100-1000 rows per statement. Too small = overhead, too large = lock contention
- PostgreSQL `COPY` for initial data loads -- orders of magnitude faster than INSERT
- Bulk UPDATE/DELETE in chunks with `LIMIT` to avoid long-running transactions and lock escalation
- Use `ON CONFLICT` (PostgreSQL) / `ON DUPLICATE KEY` (MySQL) for upserts

## Tracing
- Propagate request_id / trace_id as query comment: `/* trace_id=abc123 */ SELECT ...`
- Tag queries with caller context for slow query attribution
- Log query duration at application level with bound parameters (not interpolated values)

## Migration Safety
- Additive migrations only in zero-downtime deployments: add column, add table, add index
- Breaking changes require multi-step: add new -> migrate data -> remove old
- Add columns as nullable or with defaults -- never add NOT NULL without default to existing table
- Create indexes CONCURRENTLY (PostgreSQL) to avoid table locks
- Every migration must be reversible (up + down)
- Test migrations against production-sized dataset before deploy
