---
name: concurrency-idempotency
description: Write-path concurrency and idempotency -- natural-key races, find-or-create convergence, row locking, publish-after-commit. Applies when implementing create/update paths, background workers, queue consumers, or transactional logic.
paths:
  - "**/usecase/**"
  - "**/usecases/**"
  - "**/application/**"
  - "**/repository/**"
  - "**/repositories/**"
  - "**/worker/**"
  - "**/workers/**"
  - "**/consumer/**"
  - "**/queue/**"
---

# Concurrency & Idempotency

Write paths must survive running twice -- concurrently, or again after a retry -- without corrupting state.

## The recurring race

Two requests create-or-update the same logical entity keyed by a natural key (email, slug, external id) while the table's primary key is a surrogate id. An id-only upsert does not serialize them: both read "absent", both insert, one duplicates or fails. Any "check then insert" in application code is this race.

## Rules

- Uniqueness lives in the database: declare a unique index on the natural key. An application-level existence check is a race window, not a guard
- Converge instead of failing: on unique violation in a semantically idempotent operation, reconcile to find-or-create -- fetch the winner and continue
- Serialize read-modify-write with a row lock (`SELECT ... FOR UPDATE`) inside the same transaction, or use an atomic conditional write (`ON CONFLICT` / compare-and-swap). Choose per contention: row lock for hot rows, unique-constraint-reconcile for inserts, advisory lock for cross-table invariants
- Publish after commit: events and messages leave only once the enclosing transaction commits. Publishing inside the transaction leaks phantom events on rollback
- Make consumers idempotent: at-least-once delivery is the norm. Key side effects by request/message id so duplicates become no-ops
- Test the race, not just the happy path: two concurrent invocations against the same natural key is the regression test for this whole class
