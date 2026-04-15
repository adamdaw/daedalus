---
description: Start a new proposal from scratch — scaffolding, material import, and guided elicitation
---

You are guiding a user through starting a new Daedalus proposal from scratch. This is
the recommended entry point for new users.

**Non-AI equivalent:**
```bash
make init NAME=my-proposal TITLE="My Title" AUTHOR="Name"
make gather-requirements PROPOSAL=my-proposal
make gather-brief PROPOSAL=my-proposal
make ready PROPOSAL=my-proposal
make assemble PROPOSAL=my-proposal
make all PROPOSAL=my-proposal
```

## Procedure

1. **Check for existing proposal:**
   Look for `brief.md` and `requirements.md` in the current directory. Also check if
   we are inside a `proposals/*/` directory.

   - If both files exist: say "It looks like a proposal is already in progress here.
     Run `/elicit` to continue where you left off."
   - If no proposal exists: proceed to step 2.

2. **Scaffold the proposal:**
   Ask: "What would you like to name this proposal? Use lowercase letters, numbers,
   and hyphens (e.g., 'api-gateway', 'mobile-app')."

   Then ask for a title and author name. Run:
   ```
   make init NAME=<name> TITLE="<title>" AUTHOR="<author>"
   ```

   Change to the proposal directory: `cd proposals/<name>`

3. **Check for existing material:**
   Ask: "Do you have any existing material to work from — meeting notes, an existing
   brief, emails, a requirements document, or a project charter?"

   - **If yes:** Explain: "You can paste or attach the material and I will extract a
     structured requirements specification from it, flagging gaps and contradictions.
     This uses Prompt 06 (Requirements Author). Alternatively, we can work through
     requirements interactively."
     Let the user choose between Prompt 06 synthesis or interactive `/req-01`.
   - **If no:** Proceed to step 4.

4. **Begin elicitation:**
   Explain: "We will now work through two phases:
   1. **Requirements** (5 steps) — captures what the system must do, for whom, and
      how you will know it is done. Follows ISO/IEC/IEEE 29148:2018.
   2. **Architecture** (11 steps) — captures how the system is structured, deployed,
      and governed. Follows arc42 with C4 Model diagrams.

   Each step takes 5–15 minutes. You can stop and resume at any point — run `/elicit`
   to pick up where you left off."

   Run `/elicit` to begin the guided workflow.

5. **At completion:**
   When `/elicit` reports both artifacts are complete:

   - Run `make ready PROPOSAL=<name>` to verify cross-document consistency.
   - If ready passes: suggest loading Prompt 01 (`prompts/01-arch-spec-author.md`) with
     both `requirements.md` and `brief.md` as input to begin spec authoring.
   - If ready has warnings: show the issues and suggest which `/req-*` or `/gather-*`
     commands to re-run to address them.

   Then present the build path:
   ```
   make assemble PROPOSAL=<name>    # (non-AI) Generate arc42 markdown from artifacts
   make all PROPOSAL=<name>         # Build PDF + HTML + DOCX
   make open PROPOSAL=<name>        # Open the PDF
   ```
