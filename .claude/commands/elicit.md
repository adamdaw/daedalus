---
description: Orchestrate the full elicitation workflow — requirements then architecture, with progress tracking
---

You are orchestrating the full Daedalus elicitation workflow. This command guides
the user through all elicitation steps (5 requirements + 11 architecture) in the
correct order, tracking progress between steps.

**Non-AI equivalent:** `make progress` shows the dashboard; `make gather-requirements`
and `make gather-brief` handle the full elicitation in non-AI mode.

## Procedure

1. Read `requirements.md` and `brief.md` in the current directory. If neither exists,
   check whether we are inside a `proposals/*/` directory. If no proposal exists, tell the
   user: "No proposal found. Run `make init NAME=my-proposal` first, or use `/start-proposal`
   to set up a new proposal from scratch."

2. Parse the `<!-- Status: empty/in-progress/complete -->` comments in both files to
   determine the completion state of each section:
   - requirements.md: sections 01 through 09
   - brief.md: sections 01 through 11

3. Display a progress summary showing each file's completion fraction, a visual indicator
   per section (+ for complete, ~ for in-progress, - for empty), and the overall percentage.

4. Determine the next step using the mapping below:
   - If any requirements.md section is incomplete, the next step is the corresponding
     `/req-NN` command.
   - If all requirements.md sections are complete (or the user chooses to skip requirements)
     and any brief.md section is incomplete, the next step is `/gather-NN` for the first
     incomplete section.
   - If both files are fully complete: report "Elicitation complete!" and suggest
     `make ready` to validate consistency, then Prompt 01 for spec authoring.

5. Tell the user: "Next step: `/[command]` — [section description]. Shall I run it now?"
   - If yes: run the command by telling the user to invoke it (e.g., "Please run `/req-02` now.")
   - If no: show what remains and exit gracefully.

6. After the user returns from the sub-command, re-read both files, update the progress
   display, and repeat from step 4.

## Section-to-command mapping

### requirements.md

| Sections | Command | Description |
| --- | --- | --- |
| 01, 02 | /req-01 | Purpose, scope, and stakeholders |
| 03, 04 | /req-02 | Business and functional requirements |
| 05 | /req-03 | Non-functional requirements (ISO 25010) |
| 06, 07 | /req-04 | Constraints, assumptions, and dependencies |
| 08, 09 | /req-05 | Acceptance criteria (BDD) and traceability matrix |

### brief.md

| Section | Command | Description |
| --- | --- | --- |
| 01 | /gather-01 | Introduction and Goals |
| 02 | /gather-02 | Constraints |
| 03 | /gather-03 | Context and Scope |
| 04 | /gather-04 | Solution Strategy |
| 05 | /gather-05 | Building Block View |
| 06 | /gather-06 | Runtime View |
| 07 | /gather-07 | Deployment View |
| 08 | /gather-08 | Cross-cutting Concepts |
| 09 | /gather-09 | Architecture Decisions |
| 10 | /gather-10 | Quality Requirements |
| 11 | /gather-11 | Risks and Technical Debt |

## Handling edge cases

- **requirements.md does not exist:** Ask: "Would you like to start with requirements
  (/req-01) or go directly to architecture (/gather-01)? Requirements first gives a
  richer foundation — the architecture commands will cross-reference them."

- **User wants to skip a section:** Allow it — note: "Skipped. You can return to it later
  by running the command directly."

- **User wants to stop mid-way:** Show remaining sections and total progress. Remind them
  they can resume by running `/elicit` again — it picks up where they left off.
