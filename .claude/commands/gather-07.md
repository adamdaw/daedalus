---
description: Gather Section 07 — Deployment View (environments, infrastructure, deployment process)
---

You are gathering information for **Section 07 — Deployment View** of an arc42 architecture document.

**Standards:**
- arc42 §7 — https://docs.arc42.org/section-7/
- C4 Model — Deployment diagram — https://c4model.com
- The Twelve-Factor App — https://12factor.net  
  Factor I (codebase), Factor II (dependencies), Factor III (config), Factor X (dev/prod parity)
  are directly relevant to deployment environment design.

## Procedure

1. Read `brief.md` in the current directory. If it does not exist, read `templates/brief.md` and write it as `brief.md`.
2. Extract the `## 07 — Deployment View` block. If Status is not `empty`, or if content is populated beyond the skeleton, show the existing content and ask: "Section 07 already has content — would you like to (a) update specific fields, or (b) replace it entirely?"
3. Ask the questions below one topic at a time. Wait for each answer before continuing.
4. Write the structured output back into the `## 07` block of `brief.md`. Update the Status comment to `complete`. Do not modify any other section.

## Questions

**Environments**
"What environments does the system run in?

Common environments: development, CI/test, staging/UAT, production — but yours may differ. For each:
- Its name and purpose
- Any significant differences from production (e.g., reduced data, mocked services, different scaling)

Per Twelve-Factor App Factor X (dev/prod parity), note where dev and prod intentionally diverge and why."

**Infrastructure**
"What infrastructure does the production environment run on?

Describe: cloud provider (AWS, Azure, GCP, on-prem), compute platform (Kubernetes, ECS, VMs, serverless), data stores and their locations, networking topology if relevant (VPC, CDN, load balancers).

Include any infrastructure-as-code tools in use (Terraform, Pulumi, CDK)."

**Deployment Process**
"How does code move from a developer's commit to running in production?

Describe the pipeline: source control → CI build → test → artefact → deployment → production. Include:
- What triggers a deployment
- How configuration is managed (Twelve-Factor Factor III: config in the environment, not code)
- Any approval gates or manual steps
- Rollback strategy"

## Output format

Replace the `## 07 — Deployment View` block with:

```markdown
## 07 — Deployment View
<!-- arc42 §7 — https://docs.arc42.org/section-7/ -->
<!-- C4 Model — Deployment — https://c4model.com -->
<!-- The Twelve-Factor App — https://12factor.net -->
<!-- Status: complete -->

### Environments
| Environment | Purpose | Notable Differences from Production |
| --- | --- | --- |
| [env] | [purpose] | [differences] |

### Infrastructure
[user's answer — cloud/platform/compute/networking]

### Deployment Process
[user's answer — pipeline, config management, rollback]
```
