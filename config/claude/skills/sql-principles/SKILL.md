---
name: sql-principles
description: SQL and database design principles. Use when designing schemas, writing queries, or reviewing database code. Covers normalization, indexing, N+1 prevention, and migration safety.
user-invocable: false
---

# SQL & Database Principles

## Schema Design
- Primary keys: UUID or ULID for public-facing IDs, auto-increment for internal-only
- Every table has `created_at` and `updated_at` timestamps
- Foreign keys with explicit `ON DELETE` behavior (CASCADE, SET NULL, RESTRICT)
- Soft delete (`deleted_at` column) only when audit trail is required -- prefer hard delete
- Normalize to 3NF by default; denormalize intentionally with documented reason

## Naming Conventions
- `snake_case` for tables and columns
- Plural table names: `users`, `orders`, `order_items`
- Foreign keys: `{referenced_table_singular}_id` (e.g., `user_id`, `order_id`)
- Boolean columns: `is_` or `has_` prefix (`is_active`, `has_verified_email`)
- Indexes: `idx_{table}_{columns}` (e.g., `idx_orders_user_id_created_at`)

## Indexing
- Index every foreign key column
- Index columns used in WHERE, ORDER BY, and JOIN conditions
- Composite indexes: put equality conditions first, range conditions last
- Covering indexes for frequent queries to avoid table lookups
- Do not over-index: each index slows writes. Monitor and remove unused indexes

## Query Patterns
- **N+1 prevention**: use JOINs or batch loading (IN clause), never loop queries
- SELECT only needed columns, never `SELECT *` in application code
- Use parameterized queries / prepared statements -- never string interpolation
- LIMIT results by default; unbounded queries are a production risk
- Use EXISTS over COUNT for existence checks: `WHERE EXISTS (...)` not `WHERE (SELECT COUNT ...) > 0`
- Prefer `UNION ALL` over `UNION` when duplicates are impossible

## Transactions
- Keep transactions short -- no network calls or user interaction inside a transaction
- Use appropriate isolation level (READ COMMITTED default; SERIALIZABLE for financial)
- Optimistic locking with version column for concurrent updates
- Retry on serialization failures with exponential backoff

## Migration Safety
- Additive migrations only in zero-downtime deployments: add column, add table, add index
- Breaking changes require multi-step: add new -> migrate data -> remove old
- Add columns as nullable or with defaults -- never add NOT NULL without default to existing table
- Create indexes CONCURRENTLY (PostgreSQL) to avoid table locks
- Every migration must be reversible (up + down)
- Test migrations against production-sized dataset before deploy
