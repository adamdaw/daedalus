# Risks

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Data consistency issues during migration | Medium | High | Use dual-write pattern during transition; validate with reconciliation job |
| Team unfamiliarity with distributed systems | Medium | Medium | Knowledge-sharing sessions; pair experienced engineers with new joiners |
| Latency increase from network hops | Low | Medium | Benchmark before and after each phase; co-locate services in same region |
| Message queue becomes single point of failure | Low | High | Deploy queue in HA mode with replication; implement dead-letter queue |
| Scope creep extending timeline | High | Low | Strict phase gates; defer non-critical improvements to post-migration backlog |
