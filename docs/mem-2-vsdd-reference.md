# mem-2 — VSDD Reference for Architecture Documentation

**Maintained by:** Adam Daw (Bespoke Informatics)
**Load at:** Start of every Spec Author or Adversary session.

---

## VSDD Pipeline Summary

Verified Spec-Driven Development (VSDD) fuses Spec-Driven Development (SDD),
Test-Driven Development (TDD), and Verification-Driven Development (VDD) into a single
AI-orchestrated pipeline. In the context of architectural documentation:

- **SDD:** The arc42 document is the contract. It is written before any implementation
  begins. The spec is the highest authority below the human Architect.
- **TDD analogue:** Quality scenarios (Section 10) are the "tests" for the architecture.
  They must be written before implementation begins, and they must be measurable and
  falsifiable.
- **VDD:** The Adversary (Sarcasmotron) reviews the spec adversarially. No soft feedback.
  Every critique is a concrete flaw with a location and a proposed correction.

---

## Phase 1 — Spec Crystallization (Architecture Documentation)

The Spec Author produces the arc42 document. Critically, the spec defines not just what
the architecture is, but **what must be provable about it**:

**Step 1a — Behavioral Specification**
- Section 1: requirements, quality goals, stakeholders
- Section 2: constraints that bound the solution space
- Section 3: system boundary, external interfaces, data flows
- Section 4: fundamental technology and structural decisions

**Step 1b — Verification Architecture**
- Section 5: building block decomposition with clear service boundaries
- Section 9: ADRs — each significant decision with context, decision statement, consequences
- Section 10: quality scenarios with **measurable response measures** — not "fast" but
  "≤ 200 ms at p95 under 1,000 concurrent users"
- Section 6: runtime scenarios including **failure paths**, not just happy paths

**Step 1c — Spec Review Gate**
The complete arc42 document is reviewed by the Adversary before any implementation begins.
See Phase 3.

---

## Phase 3 — Adversarial Refinement (Architecture Review)

The Adversary receives the complete arc42 document with **fresh context** (no prior
relationship with the document). The review covers:

1. **Completeness** — Are all 11 sections substantively filled? Every Section 1 quality goal
   must have a Section 10 scenario. Every Section 4 technology decision must have a Section 9
   ADR.
2. **Consistency** — Do the sections contradict each other? Does Section 7 (Deployment)
   describe infrastructure that Section 4 (Solution Strategy) doesn't mention?
3. **Specificity** — Are quality scenarios measurable? "The system shall be fast" is
   not a quality scenario. "≤ 300 ms p95 latency under normal load" is.
4. **Assumption visibility** — Are implicit assumptions stated? If the architecture assumes
   a particular cloud provider or runtime, is it in Section 2 (Constraints)?
5. **Failure coverage** — Does Section 6 cover failure and error scenarios, or only happy
   paths?
6. **ADR completeness** — Does every ADR have a clear decision statement ("We will …")?
   Are the consequences honest about the trade-offs?
7. **Risk realism** — Does Section 11 reflect the actual risks of this architecture, or is
   it a list of generic software risks?

**Adversarial output format:**
- No preamble. No "overall this is good." Start with the first flaw.
- Each finding: `[Section N — Topic]: <concrete flaw> → <proposed correction>`
- If no genuine flaws exist, state: "Forced to manufacture flaws. Document meets standard."

---

## Phase 4 — Feedback Integration

| Finding type | Return to |
| --- | --- |
| Missing section content | Phase 1a — fill the section |
| Unmeasurable quality scenario | Phase 1b — add response measure |
| Missing ADR for a decision | Phase 1b — add ADR to Section 9 |
| Internal contradiction | Phase 1a — resolve in whichever section is wrong |
| New risk discovered by adversary | Section 11 — add to risk register |

---

## Convergence Signal

An architecture document has converged when **all** of the following hold:

- The Adversary's critiques are about wording, not missing substance or missing decisions.
- Every quality goal has a measurable scenario.
- Every significant decision in the system has an ADR.
- All phase gate rules from `mem-1` are satisfied.
- The document builds cleanly (`make build PROPOSAL=<name>` exits 0, `make validate` exits 0).

---

## VSDD Anti-Patterns in Architecture Documentation

| Anti-pattern | Why it fails |
| --- | --- |
| Quality goals without scenarios | Untestable architecture — you can't verify you've met them |
| ADRs without consequences | Decisions without trade-off analysis — the document lies by omission |
| Section 6 with only happy paths | Failure modes are the most important thing to design for |
| Constraints omitted because they're "obvious" | Future agents and reviewers won't know the implied constraints |
| "TBD" left in published documents | TBD is not a spec; it's a gap |
| Copying from the template without replacing placeholders | Placeholder architecture — worse than no document |
