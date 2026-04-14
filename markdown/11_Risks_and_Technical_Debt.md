# Risks and Technical Debt

## Architecture Risks

| ID | Risk | Probability | Impact | Mitigation |
| --- | --- | --- | --- | --- |
| R-01 | Distributed transaction failure: payment authorised but order not persisted | Low | High | Idempotency keys on Stripe calls; reconciliation job detects and compensates orphaned authorisations within 5 minutes |
| R-02 | SQS dead-letter queue grows unmonitored | Medium | Medium | CloudWatch alarm on DLQ depth > 0; on-call runbook for DLQ replay |
| R-03 | Monolith and new services drift out of sync during migration | Medium | High | Contract tests run on every pull request; feature-flagged traffic routing prevents partial state |
| R-04 | WMS XML adapter becomes a bottleneck | Low | Medium | Async dispatch via SQS if synchronous WMS calls exceed 500 ms; monitored with p99 latency alarm |

## Technical Debt

| Item | Description | Plan to Address |
| --- | --- | --- |
| TD-01 | Auth Service issues JWTs without a key rotation mechanism | Add JWKS endpoint and key rotation before GA; tracked in Identity Squad backlog |
| TD-02 | Product Service reads directly from monolith database during migration phase | Remove direct DB access once Product Service API reaches feature parity; target: end of Q2 |
| TD-03 | No contract tests between Order Service and WMS XML adapter | Introduce Pact-style contract tests in Q3; currently covered only by staging integration tests |
