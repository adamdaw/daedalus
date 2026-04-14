# Solution Strategy

The platform will be decomposed incrementally using the strangler fig pattern [@Newman2019]:
new services are extracted from the monolith one at a time, with an API gateway routing
traffic to either the new service or the monolith. The monolith is retired one domain at
a time rather than in a single migration event.

## Technology Decisions

| Goal / Constraint | Technology / Approach | Rationale |
| --- | --- | --- |
| Independent deployability | Containerised services on AWS ECS | Each service is a separate task definition with its own deployment lifecycle |
| Peak load scaling | Horizontal auto-scaling per service | Order service scales independently during promotions without scaling auth or product services |
| Async order processing | Amazon SQS message queue | Decouples order intake from fulfillment; enables at-least-once delivery with dead-letter queue |
| Auth reuse | Dedicated auth service issuing JWTs | Stateless tokens; downstream services validate without calling auth on each request |
| Incremental migration | API gateway (AWS API Gateway) | Enables traffic routing to either the monolith or a new service without client changes |

## Structural Approach

The architecture adopts a **services-with-gateway** pattern: an API gateway is the single
entry point for all clients. Behind it, bounded-context services each own their data store.
Synchronous communication uses REST; cross-service events use an async message queue.
This avoids the operational overhead of a service mesh while still achieving independent
deployability.

## Approach to Quality Goals

| Quality Goal | How the Architecture Achieves It |
| --- | --- |
| Deployability | Each service has its own CI/CD pipeline and is deployed to ECS independently |
| Performance | Order service scales to N replicas via ECS auto-scaling; SQS buffers burst demand |
| Reliability | Services are deployed across two availability zones; ECS replaces failed tasks automatically |
