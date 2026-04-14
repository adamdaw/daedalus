# Quality Requirements

## Quality Tree

| Quality Category | Quality Goal | Priority |
| --- | --- | --- |
| Deployability | Independent service releases | High |
| Performance | Order throughput at peak | High |
| Reliability | Availability under partial failure | High |
| Security | Authenticated and authorised access | High |
| Maintainability | Testability of service boundaries | Medium |
| Scalability | Order service horizontal scaling | Medium |

## Quality Scenarios

| ID | Quality | Stimulus | System State | Response | Measure |
| --- | --- | --- | --- | --- | --- |
| QS-01 | Performance | 500 concurrent order submissions | Normal production load | Orders accepted and acknowledged | ≤ 300 ms p95 end-to-end latency |
| QS-02 | Reliability | One ECS task in AZ-A crashes | Production, multi-AZ deployed | ECS replaces task; load balancer drains | < 30 s customer impact |
| QS-03 | Reliability | Payment Gateway is unreachable for 60 s | Normal load | Orders rejected with 503; no data corruption | Circuit breaker opens within 5 failed attempts |
| QS-04 | Deployability | Order Service team deploys a new release | Other services unchanged | Order Service deploys without coordination | Zero downtime; no action required from other teams |
| QS-05 | Security | Unauthenticated request to a protected endpoint | Any state | Request rejected at gateway | 401 returned; no service invoked |
| QS-06 | Scalability | Flash sale: 5× normal order volume | Auto-scaling enabled | Order Service scales out | New tasks healthy within 90 s of scaling trigger |
