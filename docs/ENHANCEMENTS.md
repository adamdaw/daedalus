# Enhancement Roadmap

This document tracks planned enhancements for Daedalus. The pipeline is designed to be
framework-agnostic — arc42 is the current default template, not a permanent commitment.
Future enhancements will add support for additional documentation frameworks, requirements
standards, diagram engines, and output formats.

For the current implementation and its rationale, see
[`docs/pipeline-decisions.md`](pipeline-decisions.md).

---

## Documentation Frameworks

Currently: **arc42** (11-section template with C4 diagrams)

| Enhancement | Description | Standard/Reference | Status |
|---|---|---|---|
| TOGAF viewpoint templates | Enterprise architecture viewpoints (Business, Data, Application, Technology) | [TOGAF — opengroup.org](https://www.opengroup.org/togaf) | Planned |
| 4+1 View Model | Kruchten's logical, process, physical, development + scenario views | [4+1 — IEEE Software 1995](https://www.cs.ubc.ca/~gregor/teaching/papers/4+1view-architecture.pdf) | Planned |
| Rozanski & Woods viewpoints | Context, functional, information, concurrency, deployment, operational | [Software Systems Architecture — viewpoints](https://www.viewpoints-and-perspectives.info) | Planned |
| ISO/IEC/IEEE 42010 compliance | Formal architecture description with viewpoints, views, correspondences | [ISO 42010 — iso.org](https://www.iso.org/standard/74393.html) | Planned |
| C4-only lightweight mode | Diagrams + ADRs without surrounding prose sections | [C4 Model — c4model.com](https://c4model.com) | Planned |
| Custom user-defined templates | User provides their own section structure as a YAML/Markdown template | — | Planned |

## Requirements Standards

Currently: **ISO/IEC/IEEE 29148:2018** (9-section requirements specification)

| Enhancement | Description | Standard/Reference | Status |
|---|---|---|---|
| BABOK requirements template | Business Analysis Body of Knowledge aligned analysis | [BABOK — iiba.org](https://www.iiba.org/business-analysis-certifications/babok-guide/) | Planned |
| Volere requirements template | Robertson & Robertson alternative section structure | [Volere — volere.org](https://www.volere.org) | Planned |
| User stories-only mode | Lightweight Agile requirements (no formal document structure) | [User Stories — mountaingoatsoftware.com](https://www.mountaingoatsoftware.com/agile/user-stories) | Planned |
| WSJF prioritisation | Weighted Shortest Job First as alternative to MoSCoW | [WSJF — scaledagileframework.com](https://www.scaledagileframework.com/wsjf/) | Planned |
| Kano model | Customer satisfaction-based prioritisation | [Kano — wikipedia.org](https://en.wikipedia.org/wiki/Kano_model) | Planned |
| RICE scoring | Reach × Impact × Confidence / Effort numeric scoring | [RICE — intercom.com](https://www.intercom.com/blog/rice-simple-prioritization-for-product-managers/) | Planned |

## Diagram Engines

Currently: **Mermaid** (via @mermaid-js/mermaid-cli + pandoc-ext/diagram)

The vendored pandoc-ext/diagram filter (filters/diagram.lua) already supports PlantUML,
GraphViz, TikZ, Asymptote, and Cetz in addition to Mermaid. These engines need testing,
documentation, and CI validation.

| Enhancement | Description | Reference | Status |
|---|---|---|---|
| PlantUML support | UML-native diagrams (class, component, activity, state) — already in filter | [PlantUML — plantuml.com](https://plantuml.com) | Needs testing |
| GraphViz support | Graph visualisation (dot, neato, fdp) — already in filter | [GraphViz — graphviz.org](https://graphviz.org) | Needs testing |
| D2 diagrams | Modern text-to-diagram with auto-layout | [D2 — d2lang.com](https://d2lang.com) | Planned |
| Structurizr DSL | C4-specific diagram definition language | [Structurizr — structurizr.com](https://structurizr.com/dsl) | Planned |
| ArchiMate notation | Enterprise architecture modelling standard | [ArchiMate — opengroup.org](https://www.opengroup.org/archimate-forum) | Planned |

## Acceptance Criteria Formats

Currently: **BDD Given/When/Then** (Gherkin-style)

| Enhancement | Description | Reference | Status |
|---|---|---|---|
| ATDD scenarios | Acceptance Test-Driven Development format | [ATDD — pmi.org](https://www.pmi.org/disciplined-agile/how-to-start-with-acceptance-test-driven-development) | Planned |
| Specification by Example | Concrete data-driven examples (Gojko Adzic) | [SbE — specificationbyexample.com](https://specificationbyexample.com) | Planned |
| Decision tables | Combinatorial condition/action tables | [Decision Tables — wikipedia.org](https://en.wikipedia.org/wiki/Decision_table) | Planned |
| Rule-based criteria | Structured bullet list of business rules | — | Planned |

## Document Generation

Currently: **Pandoc** (Markdown → PDF via XeLaTeX, HTML5, DOCX)

| Enhancement | Description | Reference | Status |
|---|---|---|---|
| AsciiDoc input | Alternative to Markdown via Asciidoctor | [Asciidoctor — asciidoctor.org](https://asciidoctor.org) | Planned |
| Web output (MkDocs) | Static site from Markdown for online viewing | [MkDocs — mkdocs.org](https://www.mkdocs.org) | Planned |
| Web output (Docusaurus) | React-based documentation site | [Docusaurus — docusaurus.io](https://docusaurus.io) | Planned |
| LuaLaTeX engine | Alternative PDF engine with Lua scripting | [LuaLaTeX — luatex.org](https://www.luatex.org) | Planned |
| Typst engine | Modern typesetting system (faster than LaTeX) | [Typst — typst.app](https://typst.app) | Planned |

## Platform

| Enhancement | Description | Status |
|---|---|---|
| Web UI for elicitation | Browser-based alternative to CLI for interactive elicitation | Planned |
| VS Code extension | Guided elicitation within the IDE | Planned |
| Multi-language support | i18n for templates, prompts, and generated output | Planned |
| GitHub Actions reusable workflow | Publish as a reusable workflow for other repositories | Planned |

---

## Contributing

To propose a new enhancement, open a GitHub issue using the feature request template.
To implement an enhancement, see [CONTRIBUTING.md](../CONTRIBUTING.md) for the development
workflow.
