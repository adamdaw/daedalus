# Architecture Constraints

## Technical Constraints

| Constraint | Background / Motivation |
| --- | --- |
| AWS cloud only | Existing infrastructure and vendor agreements are AWS-exclusive; no multi-cloud |
| PostgreSQL for relational stores | Existing DBA expertise and tooling; migration cost to another engine is not justified |
| REST over HTTPS for external-facing APIs | Mobile clients and third-party integrators require a stable, widely-supported protocol |
| Node.js 20 LTS runtime | Standardised runtime across Acme engineering; reduces platform support burden |

## Organisational Constraints

| Constraint | Background / Motivation |
| --- | --- |
| Migration must be incremental (strangler fig) | A big-bang rewrite is not acceptable; the existing monolith must remain live throughout [@Newman2019] |
| Two-pizza team ownership per service | Conway's Law alignment: each service is owned by a team small enough to be fed by two pizzas |
| No new vendor licences without architecture review | Budget and procurement governance requirement |

## Conventions

| Convention | Motivation |
| --- | --- |
| OpenAPI 3.0 specs for all service contracts | Enables automated contract testing and client generation |
| Semantic versioning for all service APIs | Consumers must be able to detect breaking changes |
| Structured JSON logging (key-value pairs) | Required by the central log aggregation pipeline |
