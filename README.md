# Daedalus

[![Build & Validate PDF](https://github.com/adamdaw/daedalus/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/adamdaw/daedalus/actions/workflows/build.yml?query=branch%3Amaster)

An architecture documentation pipeline with structured requirements elicitation. Write in Markdown, run `make all`, get professional PDF, HTML, and DOCX — with cover page, table of contents, Mermaid diagrams, cross-references, and bibliography. No AI required.

Daedalus guides you from blank proposal to finished document through two phases: **requirements gathering** ([ISO/IEC/IEEE 29148:2018](https://www.iso.org/standard/72089.html)) and **architecture elicitation** ([arc42](https://arc42.org) default template, with [C4 Model](https://c4model.com) diagrams). Interactive bash scripts walk you through each section at the terminal; [Claude Code](https://docs.anthropic.com/en/docs/claude-code) commands provide AI-assisted enrichment for teams that use it.

Built on [Pandoc](https://pandoc.org/), [XeLaTeX](https://www.latex-project.org/), [pandoc-ext/diagram](https://github.com/pandoc-ext/diagram) + [@mermaid-js/mermaid-cli](https://github.com/mermaid-js/mermaid-cli), and [pandoc-crossref](https://github.com/lierdakil/pandoc-crossref). The pipeline is framework-agnostic — arc42 is the current default, with additional templates [planned](docs/ENHANCEMENTS.md).

---

## 30-second quickstart

No local install required — pull the pre-built image from GitHub Container Registry and build the example document:

```bash
git clone https://github.com/adamdaw/daedalus.git
cd daedalus
make docker-pull-run        # → project.pdf, project.html, project.docx
```

To build your own proposal:

```bash
make init NAME=my-proposal
make gather-requirements PROPOSAL=my-proposal   # interactive, no AI required
make gather-brief PROPOSAL=my-proposal
make all PROPOSAL=my-proposal
```

For local installs, AI-assisted elicitation, and the full command surface, see the documentation below.

---

## Documentation

| Guide | Covers |
|---|---|
| **[Getting Started](docs/getting-started.md)** | Dependencies, install, build commands, testing, Docker, devcontainer, pre-commit, CI/CD, project structure |
| **[Authoring](docs/authoring.md)** | Elicitation workflow (AI + non-AI), managing proposals, content files, Mermaid diagrams, cross-references, customisation |
| **[Standards & Practices](docs/standards.md)** | Full reference for every standard the pipeline implements (arc42, C4, ISO 25010, ISO 29148, OpenSSF, SLSA, and more) |
| **[Troubleshooting](docs/troubleshooting.md)** | Common errors and their fixes (mmdc, pandoc-crossref, xelatex, Mermaid rendering) |
| **[Pipeline Decisions](docs/pipeline-decisions.md)** | Every significant implementation decision with rationale and authoritative reference |
| **[Roadmap](docs/ENHANCEMENTS.md)** | Planned framework, standard, and tooling additions |
| **[Contributing](CONTRIBUTING.md)** | Setup, workflow, PR process, release |
| **[Security](SECURITY.md)** | Coordinated vulnerability disclosure policy |

### VSDD knowledge base

For the underlying methodology (Verified Software Design Document — Daedalus produces the spec artifact layer):

- [`docs/mem-1-project-context.md`](docs/mem-1-project-context.md) — authority hierarchy, agent roles, phase gates
- [`docs/mem-2-vsdd-reference.md`](docs/mem-2-vsdd-reference.md) — pipeline, convergence signal, anti-patterns
- [`docs/mem-3-pipeline-standards.md`](docs/mem-3-pipeline-standards.md) — section standards, diagram conventions
- [`docs/mem-4-process-lessons.md`](docs/mem-4-process-lessons.md) — build and documentation lessons

---

## Standards at a glance

Daedalus follows recognised industry standards throughout. Highlights:

- **Document & architecture:** [arc42](https://arc42.org), [C4 Model](https://c4model.com), [ADR](https://adr.github.io), [ISO/IEC 25010](https://iso25000.com/en/iso-25000-standards/iso-25010), [ISO/IEC/IEEE 29148:2018](https://www.iso.org/standard/72089.html)
- **Supply chain:** [OpenSSF Scorecard](https://securityscorecards.dev), [SLSA](https://slsa.dev) provenance, SHA-pinned Actions, Trivy + CodeQL scanning
- **Process:** [Conventional Commits](https://www.conventionalcommits.org), [Semantic Versioning](https://semver.org), [pre-commit framework](https://pre-commit.com)

See [docs/standards.md](docs/standards.md) for the full table with rationale and references for each.

---

## Roadmap

Daedalus is designed to be framework-agnostic — arc42 is the current default, not a permanent
commitment. Planned additions span documentation frameworks (TOGAF, 4+1 View, ISO 42010),
requirements standards (BABOK, Volere), prioritisation methods (WSJF, Kano, RICE), diagram
engines (PlantUML, GraphViz, D2), and output formats (web via MkDocs, AsciiDoc input).

See [`docs/ENHANCEMENTS.md`](docs/ENHANCEMENTS.md) for the full roadmap and
[open issues](https://github.com/adamdaw/daedalus/issues) for tracked work.
