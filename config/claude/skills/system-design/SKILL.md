---
name: system-design
description: Distributed systems thinking covering CAP theorem, consistency models, replication, partitioning, failure domains, scaling strategies, stream processing, and migration patterns. Applies when designing system architecture, planning for scale, or reasoning about distributed behavior.
---

# System Design Principles

## CAP Theorem in Practice
- You choose between CP (consistent but unavailable during partition) and AP (available but eventually consistent)
- Most web applications: AP with eventual consistency is the right default
- Financial transactions, inventory counts: CP where correctness outweighs availability
- CAP applies per-operation, not per-system -- different endpoints can make different choices
- "Consistent enough, fast enough" -- define what consistency your users actually need

## Consistency Models
- **Strong consistency**: every read sees the latest write. Simple but expensive. Use for critical state
- **Eventual consistency**: reads may be stale but will converge. Use for non-critical, high-volume data
- **Causal consistency**: preserves cause-effect ordering. If user A posts, then user B comments, no reader sees the comment without the post. Cheaper than strong, stronger than eventual
- **Read-your-writes**: user always sees their own writes. Essential for UX -- implement by routing reads to primary after write, or by checking local write timestamp against replica lag
- **Monotonic reads**: user never sees older data after seeing newer data. Achieve by pinning user to a specific replica within a session
- Design for the inconsistency window: what happens if a user sees stale data? Define per use case

## Replication
- **Single-leader**: one primary accepts writes, replicas follow. Simple, strong consistency possible. Bottleneck: single write path
- **Multi-leader**: multiple primaries, each accepts writes. Use for multi-region. Risk: write conflicts (last-write-wins, or application-level merge)
- **Leaderless** (Dynamo-style): any node accepts reads/writes. Quorum: W + R > N for consistency. Flexible but complex conflict resolution
- Replication lag: design for it. Strong consistency requires synchronous replication (slower) or consensus protocol
- Failover: automatic promotion of replica to primary. Risk: split brain if old primary doesn't know it's demoted -- use fencing tokens or consensus-based leader election

## Partitioning (Sharding)
- **Range partitioning**: partition by value range (date, alphabet). Good for range queries. Risk: hot spots (e.g., all today's writes to one partition)
- **Hash partitioning**: partition by hash of key. Even distribution. Loses range query ability
- **Composite**: hash for distribution, range within partition (e.g., hash(tenant_id) + range(timestamp))
- Partition key choice is critical: must distribute load AND support access patterns
- Cross-partition queries are expensive -- design schema so common queries hit single partition
- Rebalancing: consistent hashing or virtual nodes to minimize data movement when adding/removing nodes
- Secondary indexes on partitioned data: local index (fast write, scatter-gather read) vs global index (slow write, fast read)

## Message Processing & Idempotency
- At-least-once delivery is the practical default -- design all consumers to be idempotent
- Exactly-once is a myth at the infrastructure level -- achieve it via idempotent handlers
- Deduplication: store processed message ID, reject duplicates. Use DB unique constraint, not in-memory cache
- Outbox pattern: write domain event to `outbox` table in same transaction as state change, then publish asynchronously. Guarantees no lost events without distributed transactions
- Saga pattern: sequence of local transactions with compensating actions for rollback
  - Each step is idempotent and has a corresponding compensation (e.g., `chargeCard` / `refundCard`)
  - Orchestrator tracks saga state and drives retries/compensations
  - Prefer choreography (event-driven) for simple flows, orchestration for complex multi-step
- Dead letter queue: after N failed processing attempts, route to DLQ for manual inspection. Never silently drop

## Stream Processing & CDC
- Change Data Capture (CDC): stream DB changes as events. Debezium (Kafka Connect), PostgreSQL logical replication
- Stream-table duality: a table is a snapshot of a stream at a point in time; a stream is the changelog of a table
- Event sourcing: store events as source of truth, derive current state. Powerful but complex -- use only when audit trail or temporal queries are core requirements
- Consumer lag monitoring: if consumers fall behind producers, data becomes stale. Alert on growing lag
- Backpressure: when consumer can't keep up, signal producer to slow down. Bounded queues reject at capacity, don't grow unbounded. Pull-based consumers (Kafka) handle this naturally

## Schema Evolution
- Data at rest outlives code. Schema changes MUST maintain backward AND forward compatibility
- Backward compatible: new code reads old data (add fields with defaults, never remove required fields)
- Forward compatible: old code reads new data (ignore unknown fields, never change field semantics)
- Encoding formats: Protobuf/Avro enforce compatibility via schema registry. JSON has no built-in schema evolution -- validate manually
- Never reuse field numbers/names with different semantics. Delete by marking as reserved

## Failure Domains & Blast Radius
- Design so that failure of component A does not cascade to component B
- Blast radius: how many users/features are affected when X fails?
- Isolate failure domains: separate databases, separate queues, separate deployments
- Degrade gracefully: if recommendations fail, show popular items, not an error page
- Test failure: chaos engineering mindset -- "what happens when X is unavailable?"
- Every external dependency is a potential failure point. Have a plan for each one
- Partial failure is the norm in distributed systems. Network calls can: succeed, fail, or hang indefinitely. Design for all three

## Scaling Strategy
- Vertical first: bigger machine is simpler than distributed coordination
- Horizontal when: single machine is insufficient, or availability requires redundancy
- Stateless services scale horizontally by default. State belongs in purpose-built stores
- Caching: add when measured need exists. Cache invalidation is the second hardest problem
- Read replicas for read-heavy workloads. Write scaling is harder -- partition carefully
- Scale the bottleneck, not everything. Measure first

## Sync vs Async
- Synchronous (request/response): simple, easy to reason about, latency adds up in chains
- Asynchronous (message queue): decouples sender/receiver, absorbs spikes, adds operational complexity
- Use async when: fire-and-forget is acceptable, load spikes need smoothing, producer and consumer should scale independently
- Use sync when: immediate response required, simple request/response, few participants
- Message ordering: don't depend on it unless the queue explicitly guarantees it. Partition-level ordering (Kafka) is practical; global ordering does not scale

## Data Gravity
- Data attracts computation. Moving data is expensive; moving code to data is cheaper
- The location of your data store shapes your architecture more than any other choice
- Minimize data movement across network boundaries
- When data must live in multiple places: single source of truth + derived views
- Schema changes in shared data stores have the highest coordination cost

## Migration & Evolution
- Strangler Fig: wrap the old system, incrementally route traffic to the new one
- Never big-bang rewrite -- incrementally replace, validate at each step
- Parallel run: new system runs alongside old, compare outputs, switch when confident
- Backward compatibility during migration: new code reads old AND new format, writes new format
- Feature flags for gradual rollout: 1% -> 10% -> 50% -> 100% with metrics at each stage
- Rollback plan MUST exist before any migration begins
