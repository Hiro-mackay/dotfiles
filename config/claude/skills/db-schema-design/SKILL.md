---
name: db-schema-design
description: Database schema design decisions, data modeling strategy, and relationship patterns. Applies when planning database schemas, choosing between normalization approaches, or designing data models. For SQL implementation rules (naming, queries, indexing, transactions), see the sql-implementation rule (auto-loaded for .sql files).
---

# Database Design Principles

## Schema Decisions
- Primary keys: UUID for public-facing IDs, auto-increment for internal-only
- Every table has `created_at` and `updated_at` timestamps
- Foreign keys with explicit `ON DELETE` behavior -- choose intentionally:
  - CASCADE: child has no meaning without parent (order_items when order deleted)
  - SET NULL: child can exist independently (assigned_user on task)
  - RESTRICT: deletion should be blocked (user with active orders)

## Normalization Strategy
- Normalize to 3NF by default -- denormalize only with documented reason
- Valid denormalization reasons: measured read performance bottleneck, reducing complex joins for critical queries, pre-computed aggregates for dashboards
- Invalid reasons: "joins are slow" (they're not with proper indexes), "it's simpler" (it's not when data drifts)

## Relationship Patterns
- **1:1**: consider merging into one table unless access patterns differ significantly or one side is optional
- **1:N**: FK on the many side. If N is unbounded, plan for pagination
- **M:N**: junction table with composite PK or surrogate key. Add `created_at` if the relationship has temporal meaning
- **Polymorphic**: prefer separate FK columns (`commentable_post_id`, `commentable_photo_id`) over type+id pattern. Type+id breaks referential integrity

## Soft Delete
- Hard delete by default. Soft delete (`deleted_at`) requires documented justification:
  - Legal retention requirements
  - Undo/restore workflows
  - Audit compliance
- If soft delete: add partial index on `deleted_at IS NULL` for query performance. Ensure all queries filter by default

## Data Modeling from Domain
- One aggregate root = one primary table + owned child tables
- Value Objects: embed as columns (not separate table) unless shared across aggregates
- Enum/status fields: use CHECK constraint or reference table, not free-text
- Temporal data: if "when" matters, store timestamps. If history matters, use event log or history table
- Audit trail: separate `_history` table with trigger, not versioning in main table

## Read Replica Strategy
- Read replicas for read-heavy workloads (reporting, search, dashboards)
- Application-level routing: writes → primary, reads → replica. Framework support or explicit connection switching
- Replication lag awareness: critical reads (read-after-write) MUST go to primary
- Replica count: scale read capacity horizontally, but each replica adds replication load on primary

## Capacity Planning
- Estimate row count at 1 year and 5 years. Design indexes and partitioning for 5-year scale
- Tables exceeding 100M rows: consider range partitioning (by date) or hash partitioning (by tenant)
- Archive strategy: move cold data to separate table/store, not delete
- Connection pool sizing: plan for peak concurrent connections across all application instances. Set DB `max_connections` > sum of all pool `max_open` with headroom for admin/migration connections
