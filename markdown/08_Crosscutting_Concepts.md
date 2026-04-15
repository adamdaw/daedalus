# Cross-cutting Concepts

## Security and Authentication

All external API traffic passes through the API Gateway, which enforces TLS 1.2+ and
validates JWT bearer tokens on protected routes. JWTs are issued by the Auth Service
with a 15-minute access token TTL and a 7-day refresh token TTL. Services treat JWTs
as opaque unless they need to inspect claims (e.g., the Order Service reads `userId`).

Secrets (database credentials, API keys) are stored in AWS Secrets Manager and injected
at container startup via ECS task definitions. No secrets are stored in environment
variables or container images.

## Logging and Observability

All services emit structured JSON logs to stdout. ECS forwards logs to CloudWatch Logs.
Log entries include at minimum: `timestamp`, `level`, `service`, `traceId`, `message`.

Distributed traces are collected via AWS X-Ray. Each inbound HTTP request creates a trace
that propagates through downstream service calls and SQS messages via trace context headers.

Each service exposes a `/metrics` endpoint (Prometheus format) scraped by a shared
CloudWatch agent. Key metrics per service: request rate, error rate, p95 latency, queue
depth (Notification Service).

## Error Handling

Services classify errors into two categories:

- **Client errors (4xx):** returned directly with a structured JSON body (`code`, `message`)
- **Server errors (5xx):** logged with full stack trace and `traceId`; generic message returned to caller

Downstream service calls use exponential backoff with jitter (initial 100 ms, max 5 retries).
A circuit breaker (half-open after 30 s) prevents cascading failures when a dependency is
degraded. Failed SQS messages are retried up to 3 times before being moved to a dead-letter
queue and triggering a CloudWatch alarm.

## Configuration Management

Environment-specific configuration (database endpoints, feature flags, external API URLs)
is stored in AWS Systems Manager Parameter Store. Services read configuration at startup;
a restart is required for configuration changes to take effect.

Feature flags are managed via Parameter Store with a naming convention of:

    /acme/{service}/{env}/feature/{flag-name}

## Data Management

Each service owns its PostgreSQL schema. Cross-service data access is only permitted
via the owning service's API. No service reads another service's database directly.

Databases use AWS RDS with automated daily snapshots retained for 35 days. Point-in-time
recovery is enabled. Data at rest is encrypted using AWS-managed KMS keys. PII fields
(email, name, address) are documented in a data dictionary maintained by the Identity Squad.
