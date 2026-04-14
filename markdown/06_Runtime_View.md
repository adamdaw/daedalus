# Runtime View

## Scenario: Place Order

The most critical user journey: a client submits an order, which is validated, paid,
and acknowledged before fulfillment processing continues asynchronously.

```mermaid
sequenceDiagram
    actor Client
    participant GW as API Gateway
    participant Auth as Auth Service
    participant Order as Order Service
    participant Product as Product Service
    participant Stripe as Payment Gateway
    participant SQS as SQS Queue

    Client->>GW: POST /orders (JWT)
    GW->>Auth: Validate JWT
    Auth-->>GW: Claims (userId)
    GW->>Order: Forward request + claims
    Order->>Product: Reserve stock (productId, qty)
    Product-->>Order: Reservation confirmed
    Order->>Stripe: Authorise payment
    Stripe-->>Order: Authorisation code
    Order->>Order: Persist order (status: ACCEPTED)
    Order->>SQS: Publish order.placed event
    Order-->>GW: 201 Created (orderId)
    GW-->>Client: 201 Created (orderId)
    Note over SQS: Fulfillment and notification\ncontinue asynchronously
```

## Scenario: Payment Failure

When Stripe declines authorisation, the order is rejected and the stock reservation
is released. The client receives a clear error without any charge.

```mermaid
sequenceDiagram
    actor Client
    participant Order as Order Service
    participant Product as Product Service
    participant Stripe as Payment Gateway

    Client->>Order: POST /orders
    Order->>Product: Reserve stock
    Product-->>Order: Reservation confirmed
    Order->>Stripe: Authorise payment
    Stripe-->>Order: Declined
    Order->>Product: Release reservation (compensating action)
    Product-->>Order: Released
    Order-->>Client: 402 Payment Required
```

## Scenario: Notification Delivery

The notification service consumes events from SQS independently of the order flow.
Failures in notification delivery do not affect order processing.

```mermaid
sequenceDiagram
    participant SQS as SQS Queue
    participant Notif as Notification Service
    participant Email as SendGrid

    SQS->>Notif: order.placed event (at-least-once)
    Notif->>Notif: Render email template
    Notif->>Email: Send transactional email
    Email-->>Notif: 202 Accepted
    Notif->>SQS: Delete message
    Note over SQS,Notif: On failure: message returns\nto queue after visibility timeout.\nDead-letter queue after 3 attempts.
```
