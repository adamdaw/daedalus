---
description: Gather Section 08 — Cross-cutting Concepts (security, observability, error handling, domain model)
---

You are gathering information for **Section 08 — Cross-cutting Concepts** of an arc42 architecture document.

**Standards:**
- arc42 §8 — https://docs.arc42.org/section-8/
- OWASP Top 10 — https://owasp.org/www-project-top-ten/  
  Security questions focus on authentication, authorisation, and data protection —
  three of the most commonly under-specified aspects.
- The Twelve-Factor App — https://12factor.net  
  Factor XI (logs) and Factor III (config) inform the observability and security questions.

## Procedure

1. Read `brief.md` in the current directory. If it does not exist, read `templates/brief.md` and write it as `brief.md`.
2. Extract the `## 08 — Cross-cutting Concepts` block. If Status is not `empty`, or if content is populated beyond the skeleton, show the existing content and ask: "Section 08 already has content — would you like to (a) update specific fields, or (b) replace it entirely?"
3. Ask the questions below one topic at a time. Wait for each answer before continuing.
4. Write the structured output back into the `## 08` block of `brief.md`. Update the Status comment to `complete`. Do not modify any other section.

## Questions

**Security**
"How is security handled across the system? Cover:
- Authentication: how are users or services proven to be who they claim? (e.g., OAuth 2.0 / OpenID Connect, API keys, mTLS)
- Authorisation: how are permissions enforced? (e.g., RBAC, ABAC, policy engine)
- Data protection: how is sensitive data protected at rest and in transit?

Reference OWASP Top 10 (https://owasp.org/www-project-top-ten/) — which of the top risks are most relevant to your system and how are they mitigated?"

**Observability**
"How will the system be monitored and debugged in production? Cover:
- Logging: what is logged, in what format, and where does it go? (Twelve-Factor Factor XI: treat logs as event streams)
- Metrics: what key metrics are collected, and what tooling aggregates them?
- Tracing: is distributed tracing in use? If so, what tool?
- Alerting: what triggers an alert and who receives it?"

**Error Handling**
"What is the system's strategy for handling errors and failures?
- How are errors surfaced to callers (error codes, exception types, error responses)?
- What retry and circuit-breaker patterns are used for calls to external systems?
- How are user-facing error messages handled?"

**Domain Model / Shared Concepts**
"Are there key domain entities, value objects, or shared concepts that appear across multiple containers or components?

Examples: 'User', 'Order', 'Event', 'Tenant'. For each: its name, brief definition, and which containers use it.

If the domain is simple or the system is not domain-driven, this can be brief."

## Output format

Replace the `## 08 — Cross-cutting Concepts` block with:

```markdown
## 08 — Cross-cutting Concepts
<!-- arc42 §8 — https://docs.arc42.org/section-8/ -->
<!-- OWASP Top 10 — https://owasp.org/www-project-top-ten/ -->
<!-- The Twelve-Factor App — https://12factor.net -->
<!-- Status: complete -->

### Security
[user's answer — authentication, authorisation, data protection, relevant OWASP mitigations]

### Observability
[user's answer — logging, metrics, tracing, alerting]

### Error Handling
[user's answer — error strategy, retries, circuit breakers, user-facing messages]

### Domain Model / Shared Concepts
[user's answer — key entities and which parts of the system use them]
```
