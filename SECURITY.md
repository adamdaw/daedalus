# Security Policy

## Supported Versions

| Version | Supported |
| --- | --- |
| Latest (`master`) | Yes |

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

This project follows [coordinated vulnerability disclosure](https://cheatsheetseries.owasp.org/cheatsheets/Vulnerability_Disclosure_Cheat_Sheet.html)
(OWASP Vulnerability Disclosure Cheat Sheet).

To report a security issue, email **security@bespokeinformatics.ca** with:

- A description of the vulnerability
- Steps to reproduce it
- The potential impact
- Any suggested mitigations, if known

You will receive an acknowledgement within 48 hours and a full response within 7 days.
If the issue is confirmed, we will coordinate a fix and disclosure timeline with you.

## Scope

This repository contains a document generation pipeline (Pandoc, XeLaTeX, @mermaid-js/mermaid-cli).
Security-relevant areas include:

- The Dockerfile and build environment (supply chain integrity)
- GitHub Actions workflows (Actions supply chain, secret handling)
- Any shell execution paths in the Makefile

Out of scope: the generated PDF/HTML/DOCX output content, which is entirely user-supplied.
