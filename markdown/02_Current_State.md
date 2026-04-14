# Current State

The existing system is a single-tier monolithic application deployed on-premises. All business logic, data access, and presentation concerns are bundled into one deployable unit.

## Pain Points

- **Deployment risk** — any change requires a full application restart, causing downtime
- **Scalability** — the entire application must be scaled even when only one component is under load
- **Development velocity** — teams cannot deploy independently, creating release bottlenecks

## Current Data Model

The following diagram shows the core entities and their relationships in the existing system.

```mermaid
erDiagram
    User ||--o{ Order : places
    Order ||--|{ LineItem : contains
    LineItem }o--|| Product : references
    User {
        string id
        string name
        string email
    }
    Order {
        string id
        string userId
        string status
        date createdAt
    }
    LineItem {
        string id
        string orderId
        string productId
        int quantity
    }
    Product {
        string id
        string name
        decimal price
    }
```

## Current Request Flow

```mermaid
sequenceDiagram
    participant Client
    participant Monolith
    participant Database

    Client->>Monolith: HTTP Request
    Monolith->>Database: Query
    Database-->>Monolith: Result set
    Monolith-->>Client: HTTP Response
```
