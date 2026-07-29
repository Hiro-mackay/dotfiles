---
name: system-design
description: Distributed systems thinking covering CAP theorem, consistency models, replication, partitioning, failure domains, scaling strategies, stream processing, and migration patterns. Applies when designing system architecture, planning for scale, or reasoning about distributed behavior.
---

# System Design Principles

The judgment calls, not the pattern catalogue. Standard distributed-systems vocabulary is deliberately absent.

## Consistency
- Availability with eventual consistency is the right default for most web applications. Reach for strong consistency where correctness genuinely outweighs uptime -- money, inventory counts
- The choice is per operation, not per system. Different endpoints in the same service can decide differently
- Read-your-writes is a UX requirement, not an optimization: route a user's reads to the primary after their write, or compare their write timestamp against replica lag. Pin a user to one replica within a session so they never see time run backwards
- Name the inconsistency window and say what happens inside it. "Eventually consistent" without that number is not a design

## Replication and partitioning
- Failover creates split brain unless the demoted primary can be stopped from accepting writes. Fencing tokens or consensus-based election, not a health check
- Range partitioning gives you range queries and a hot spot -- everything written today lands on one partition. Hash partitioning distributes evenly and takes range queries away. Composite (`hash(tenant_id)` then range by time) buys both
- The partition key has to satisfy two things at once: even load distribution and the access patterns you actually run. Cross-partition queries cost enough that the schema should keep common queries inside one
- Secondary indexes: local means fast writes and scatter-gather reads, global means slow writes and fast reads. Pick against the read/write ratio

## Messaging
- At-least-once is what you get. Exactly-once exists only as an idempotent handler, never as an infrastructure guarantee
- Deduplicate on a stored message ID with a unique constraint. An in-memory cache loses its memory exactly when you need it
- Outbox: write the event to an `outbox` table in the same transaction as the state change, publish asynchronously from there. This is how you get no lost events without distributed transactions
- Multi-step flows pair every action with its compensation (`chargeCard` / `refundCard`) and make both idempotent. Event choreography for simple flows, an orchestrator once the state gets hard to follow
- After N failures, a message goes to a dead letter queue. Never dropped silently
- Do not depend on message ordering unless the broker guarantees it. Partition-level ordering is practical; global ordering does not scale

## Failure
- A network call can succeed, fail, or hang forever. Code that handles two of those three is broken in production
- Ask the blast radius question before building: when this fails, how many users and which features go with it? Then separate the databases, queues, and deployments that answer is too large for
- Degrade to something, not to an error page. Recommendations down means show popular items

## Scale
- Vertical first. A bigger machine is cheaper than distributed coordination, and the coordination is permanent
- Scale the measured bottleneck, not the system. Add caching when there is a number saying to, since the invalidation is yours forever afterward
- Read replicas handle read-heavy load. Write scaling means partitioning, which is a schema decision, not a capacity decision
- Async when it buys spike absorption or independent scaling; sync when a caller genuinely needs the answer. Async is not free -- it moves the complexity into operations

## Data gravity
- Moving data is expensive; move the computation to it. Where the data lives shapes the architecture more than any other single decision
- When it must exist in several places: one source of truth, everything else a derived view
- A schema change in a shared store has the highest coordination cost of anything you can do. Plan it as a migration, not an edit

## Migration
- Never a big-bang rewrite. Wrap the old system and route traffic across incrementally, validating each step
- During the transition, new code reads both the old and new format and writes only the new one
- Run both systems in parallel and compare outputs before switching
- Roll out behind a flag at 1%, 10%, 50%, 100%, with metrics gating each step
- The rollback plan exists before the migration starts, not after it goes wrong

## Reference
- Stream processing, CDC, event sourcing, schema evolution: [reference](${CLAUDE_SKILL_DIR}/reference/data-patterns.md)
