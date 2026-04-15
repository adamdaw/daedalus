# Deployment View

## Infrastructure Overview

All services are deployed to AWS ECS (Fargate) across two availability zones within a
single AWS region. The API gateway is managed by AWS API Gateway. Each service has its
own RDS PostgreSQL instance. SQS is a regional managed service with no single point of failure.

```mermaid
flowchart TD
    Internet([Internet]) --> APIGW[API Gateway]

    subgraph VPC["AWS VPC (eu-west-1)"]
        subgraph AZ1["Availability Zone A"]
            AuthA[Auth]
            OrderA[Order]
            ProductA[Product]
            NotifA[Notification]
        end

        subgraph AZ2["Availability Zone B"]
            AuthB[Auth]
            OrderB[Order]
            ProductB[Product]
            NotifB[Notification]
        end

        subgraph Data["Data Layer (Multi-AZ)"]
            AuthDB[(Auth RDS)]
            OrderDB[(Order RDS)]
            ProductDB[(Product RDS)]
            SQS[[SQS Queue]]
        end
    end

    APIGW --> AuthA & AuthB
    APIGW --> OrderA & OrderB
    APIGW --> ProductA & ProductB
    OrderA & OrderB --> SQS
    SQS --> NotifA & NotifB
    AuthA & AuthB --> AuthDB
    OrderA & OrderB --> OrderDB
    ProductA & ProductB --> ProductDB
```

All services run on ECS Fargate. Each box above represents an ECS task; the two availability
zones provide redundancy.

## Deployment Environments

| Environment | Purpose | Notes |
| --- | --- | --- |
| Development | Local Docker Compose | All services run locally; external services are stubbed |
| Staging | AWS (eu-west-1, single AZ) | Full integration with Stripe test mode and SendGrid sandbox |
| Production | AWS (eu-west-1, multi-AZ) | Live traffic; auto-scaling enabled on Order Service |

## Deployment Process

Each service has an independent CI/CD pipeline:

1. Pull request triggers build, unit tests, and contract tests
2. Merge to `main` builds and pushes a Docker image tagged with the commit SHA
3. ECS rolling deployment updates tasks with zero downtime
4. Health check endpoint (`/health`) must return 200 before old tasks are drained
5. Rollback is triggered automatically if the health check fails within the deployment window
