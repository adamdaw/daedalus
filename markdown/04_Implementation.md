# Implementation Plan

The migration is staged across three phases to minimise risk. The monolith remains in production throughout until each service is proven in production.

## Phases

```mermaid
gantt
    title Implementation Timeline
    dateFormat  YYYY-MM-DD
    section Phase 1
    API Gateway setup          :p1a, 2026-05-01, 14d
    User Service               :p1b, after p1a, 21d
    section Phase 2
    Product Service            :p2a, after p1b, 21d
    Order Service              :p2b, after p2a, 28d
    section Phase 3
    Traffic migration          :p3a, after p2b, 14d
    Monolith decommission      :p3b, after p3a, 7d
```

## Phase 1 — Foundation

Deploy the API gateway and extract the User Service. Route authentication traffic to the new service while the monolith handles all other requests.

**Exit criteria:** User Service handles 100% of auth traffic with no increase in error rate.

## Phase 2 — Core Services

Extract Product and Order services. Run each in parallel with the monolith using a strangler-fig pattern, progressively shifting traffic.

**Exit criteria:** All three services handle production traffic; monolith receives no requests.

## Phase 3 — Cut-Over

Complete traffic migration, validate observability coverage, and decommission the monolith.

**Exit criteria:** Monolith infrastructure terminated; all services monitored and alerting.
