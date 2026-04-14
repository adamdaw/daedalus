# Architecture Decisions

## ADR-001: Services-with-Gateway Over Service Mesh

**Status:** Accepted

**Date:** 2026-01-15

**Context:**

The team evaluated two patterns for inter-service communication: a service mesh (Istio/Envoy
sidecars) and a simpler services-with-gateway pattern using REST over HTTPS. A service mesh
provides traffic management, mTLS, and observability out of the box, but adds significant
operational complexity and requires sidecar expertise the team does not currently have.

**Decision:**

We will use AWS API Gateway as the external entry point and direct HTTPS calls between
services internally (no service mesh). Distributed tracing will be handled by AWS X-Ray.
mTLS between services will be deferred until a concrete security requirement demands it.

**Consequences:**

- Teams can deploy and operate services without learning sidecar configuration
- We lose automatic mTLS between internal services; mitigated by VPC network segmentation
- If traffic management complexity grows (e.g., canary releases per service), revisiting a
  service mesh will be necessary

## ADR-002: One Database Per Service

**Status:** Accepted

**Date:** 2026-01-15

**Context:**

Sharing a single PostgreSQL database across services was proposed as a cost reduction
measure. The team assessed the risk: shared schemas create implicit coupling, make
independent deployments unsafe (schema changes affect all services), and have been
a primary cause of failures in the existing monolith.

**Decision:**

Each service will own a dedicated RDS PostgreSQL instance. Cross-service data access
is exclusively via the owning service's API. No service may read or write another
service's database.

**Consequences:**

- Independent schema evolution and deployment without coordination
- Higher RDS cost (estimated +$180/month for three additional instances)
- Queries that previously joined across domains now require API calls; accepted as
  necessary for decoupling

## ADR-003: Amazon SQS Over an Event Streaming Platform

**Status:** Accepted

**Date:** 2026-01-22

**Context:**

The notification service needs to consume order events asynchronously. Apache Kafka and
Amazon SNS/SQS were the primary candidates. Kafka provides event replay and a durable log,
but requires a managed cluster (MSK) and operational expertise the SRE team does not have.
The notification use case does not require event replay.

**Decision:**

We will use Amazon SQS (standard queue with a dead-letter queue). The Order Service
publishes to SQS; the Notification Service polls and processes messages.

**Consequences:**

- Simple operational model; SQS is fully managed
- No event replay capability; if the Notification Service needs to re-process past events,
  it must query the Order Service API
- If future use cases require event sourcing or multiple independent consumers, migration
  to SNS fan-out or Amazon EventBridge will be required
