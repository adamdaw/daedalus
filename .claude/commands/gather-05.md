---
description: Gather Section 05 — Building Block View (containers, components, responsibilities)
---

You are gathering information for **Section 05 — Building Block View** of an arc42 architecture document.

**Standards:**
- arc42 §5 — https://docs.arc42.org/section-5/
- C4 Model — Container (Level 2) and Component (Level 3) — https://c4model.com  
  Level 1 (system context) is covered in §03. This section covers Level 2 containers
  (independently deployable units) and optionally Level 3 components within them.

## Procedure

1. Read `brief.md` in the current directory. If it does not exist, read `templates/brief.md` and write it as `brief.md`.
2. Extract the `## 05 — Building Block View` block. If Status is not `empty`, or if tables are populated beyond the header, show the existing content and ask: "Section 05 already has content — would you like to (a) update specific fields, or (b) replace it entirely?"
3. Ask the questions below one topic at a time. Wait for each answer before continuing.
4. Write the structured output back into the `## 05` block of `brief.md`. Update the Status comment to `complete`. Do not modify any other section.

## Questions

**Level 1 — Containers**
"What are the major containers (independently deployable units) that make up the system?

In C4 terms, a container is anything that runs separately: a web application, a mobile app, a server-side API, a database, a message queue, a background job. For each:
- Its name
- The technology it uses
- Its primary responsibility in one sentence"

**Interactions**
"How do these containers communicate with each other? Describe the key interactions — which container calls or sends messages to which, and what protocol or mechanism is used (REST, gRPC, async message queue, database read, etc.)."

**Level 2 — Components (optional)**
"Are any containers complex enough to warrant zooming in to show their internal components?

If yes, for those containers: what are the main internal components and what is each responsible for? If the containers are straightforward, skip this."

## Output format

Replace the `## 05 — Building Block View` block with:

```markdown
## 05 — Building Block View
<!-- arc42 §5 — https://docs.arc42.org/section-5/ -->
<!-- C4 Model — Container (Level 2), Component (Level 3) — https://c4model.com -->
<!-- Status: complete -->

### Level 1 — Containers
| Container | Technology | Responsibility |
| --- | --- | --- |
| [container] | [tech] | [responsibility] |

### Container Interactions
[user's answer — key communication paths between containers]

### Level 2 — Components (for complex containers)
| Container | Component | Responsibility |
| --- | --- | --- |
| [container] | [component] | [responsibility] |
```

Omit the Level 2 table if the user indicated it is not needed.
