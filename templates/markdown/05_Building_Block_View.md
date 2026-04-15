# Building Block View

<!-- arc42 Section 5 — https://docs.arc42.org/section-5/
     C4 Model notation — https://c4model.com -->

## Level 1: Container Overview

<!-- Show the high-level decomposition into main building blocks (C4 Container level).
     Reference: https://c4model.com/#ContainerDiagram
     Each box should be independently deployable or a clearly bounded module. -->

```mermaid
flowchart TD
    User([User]) --> Gateway[API Gateway]
    subgraph System
        Gateway --> ServiceA[Service A]
        Gateway --> ServiceB[Service B]
        ServiceA --> StoreA[(Store A)]
        ServiceB --> StoreB[(Store B)]
    end
```

| Building Block | Responsibility |
| --- | --- |
| API Gateway | |
| Service A | |
| Service B | |

## Level 2: [Component Name] Internals

<!-- Zoom into building blocks that require further explanation (C4 Component level).
     Reference: https://c4model.com/#ComponentDiagram
     Duplicate this subsection for each component that needs decomposing. -->

| Component | Responsibility |
| --- | --- |
| | |
