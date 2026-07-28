---
name: db-schema-design
description: Database schema design decisions, data modeling strategy, and relationship patterns. Applies when planning database schemas, choosing between normalization approaches, or designing data models. For SQL implementation rules (naming, queries, indexing, transactions), see the sql-implementation skill (auto-loaded for .sql files).
paths:
  - "**/*.sql"
  - "**/migrations/**"
  - "**/*.prisma"
  - "**/drizzle/**"
  - "**/drizzle.config.*"
  - "**/db/schema*"
  - "**/models.py"
  - "**/alembic/**"
  - "**/ent/schema/**"
  - "**/sqlc.*"
  - "**/repository/**"
  - "**/repositories/**"
---

# Database Design Principles

House conventions and the calls that go wrong. Standard relational modeling is deliberately absent.

## Conventions
- UUID for public-facing IDs, auto-increment for internal-only
- `created_at` and `updated_at` on every table
- Every foreign key states its `ON DELETE` deliberately: CASCADE when the child is meaningless without the parent (order items), SET NULL when it stands alone (assigned user on a task), RESTRICT when the deletion should be refused (user with active orders)
- Status and enum columns get a CHECK constraint or a reference table, never free text
- Hard delete by default. `deleted_at` needs a stated reason -- legal retention, undo, audit compliance. When you do add it, add a partial index on `deleted_at IS NULL` and make sure every query filters

## Normalization
- 3NF by default; denormalize only with the reason written down. Measured read bottlenecks, joins on a critical path, and precomputed dashboard aggregates qualify
- "Joins are slow" and "it's simpler" do not. Joins are fine with the right indexes, and denormalized data stops being simple the moment it drifts

## Relationships and domain mapping
- Polymorphic associations get separate FK columns (`commentable_post_id`, `commentable_photo_id`), not a type+id pair -- type+id gives up referential integrity
- One aggregate root maps to one primary table plus its owned child tables. Value objects embed as columns unless shared across aggregates
- History goes in a separate `_history` table fed by a trigger, not versioning inside the main table

## Scale
- Read-after-write goes to the primary. Replication lag makes any other routing a correctness bug, not a performance choice
- Estimate row counts at one year and five, and design indexes and partitioning for the five-year number. Past ~100M rows, consider range partitioning by date or hash by tenant, and archive cold data rather than deleting it
- `max_connections` must exceed the sum of every application instance's pool maximum, with headroom left for admin and migration connections
