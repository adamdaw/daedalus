# Standards & Practices

Daedalus follows recognised industry standards throughout — in the document template, the
diagram notation, the decision record format, the quality model, and across the entire build
pipeline. Every significant implementation decision is documented with its rationale and
authoritative reference in [`pipeline-decisions.md`](pipeline-decisions.md).

---

## Document & Architecture

| Standard | Reference | Applied in |
|---|---|---|
| **arc42** | [arc42.org](https://arc42.org) | Document template structure — all 11 sections |
| **C4 Model** | [c4model.com](https://c4model.com) | Context, Container, and Deployment diagrams (Sections 3, 5, 7) |
| **Architecture Decision Records** | [adr.github.io](https://adr.github.io) | Section 9 ADR format (Nygard, 2011) |
| **ISO/IEC 25010** | [iso25000.com/iso-25010](https://iso25000.com/en/iso-25000-standards/iso-25010) | Software quality model — Section 10 quality scenarios, `/req-03` non-functional requirements |
| **ISO/IEC/IEEE 29148:2018** | [iso.org/standard/72089](https://www.iso.org/standard/72089.html) | Requirements specification structure — `requirements.md` template, `/req-*` commands |

---

## Pipeline & Tooling

| Standard | Reference | Applied in |
|---|---|---|
| **Conventional Commits** | [conventionalcommits.org](https://www.conventionalcommits.org) | Commit message format (`feat:`, `fix:`, `chore:`, `docs:`); enforced by pre-commit |
| **Semantic Versioning** | [semver.org](https://semver.org) | Release tags (`v1.0.0`) trigger `release.yml` |
| **OCI Image Spec** | [opencontainers.org — annotations](https://github.com/opencontainers/image-spec/blob/main/annotations.md) | Docker image labels: title, description, source, licenses |
| **OpenSSF Supply Chain Best Practices** | [best.openssf.org](https://best.openssf.org) | SHA-256 binary download verification (pandoc, pandoc-crossref) in Dockerfile and CI |
| **OpenSSF Scorecard** | [securityscorecards.dev](https://securityscorecards.dev) | SHA-pinned Actions, Dependabot, CodeQL, Trivy scanning, least-privilege permissions |
| **SLSA** | [slsa.dev](https://slsa.dev) | SLSA provenance attestation on Docker images pushed to GHCR |
| **EditorConfig** | [editorconfig.org](https://editorconfig.org) | Consistent formatting across editors and IDEs (`.editorconfig`) |
| **pre-commit framework** | [pre-commit.com](https://pre-commit.com) | Automated quality gates: linting, spellcheck, Conventional Commits |
| **GNU Make conventions** | [GNU Make manual](https://www.gnu.org/software/make/manual/make.html) | `.DEFAULT_GOAL := help`; self-documenting targets via `##` comments |
| **PEP 668** | [peps.python.org/pep-0668](https://peps.python.org/pep-0668/) | Python tools installed in an isolated venv, not system Python |
| **CommonMark** | [spec.commonmark.org](https://spec.commonmark.org/0.31.2/) | Trailing whitespace preserved in `.md` files (hard line break spec §2.2) |
| **GitHub community health** | [docs.github.com — community health](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions) | `CONTRIBUTING.md`, `SECURITY.md` |
