# Distributed Data Patterns

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
