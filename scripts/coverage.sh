#!/usr/bin/env bash
# coverage.sh — Calculate test coverage for shell scripts using bashcov + bats
#
# Usage:
#   bash scripts/coverage.sh
#   bash scripts/coverage.sh --output DIR
#
# Runs bats tests under bashcov to measure line-level code coverage for all
# shell scripts. Produces HTML and Cobertura XML reports via SimpleCov.
#
# Standards:
#   bashcov — https://github.com/infertux/bashcov
#   bats-core — https://github.com/bats-core/bats-core
#   SimpleCov — https://github.com/simplecov-ruby/simplecov
#   Cobertura XML — https://cobertura.github.io/cobertura/
#
# Requirements:
#   Ruby, bashcov (gem install bashcov simplecov-cobertura), bats

set -uo pipefail

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    cat <<'HELPEOF'
Usage: bash scripts/coverage.sh [--output DIR]

Calculate test coverage for shell scripts using bashcov + bats-core.

Options:
  --output DIR    Coverage output directory (default: coverage/)

bashcov traces all bash execution during bats tests via PS4/BASH_XTRACEFD
and produces HTML + Cobertura XML reports. The .simplecov config file
controls filtering, grouping, and the 90% minimum coverage target.

Requirements:
  Ruby         — https://www.ruby-lang.org
  bashcov      — gem install bashcov (https://github.com/infertux/bashcov)
  bats         — https://github.com/bats-core/bats-core
  simplecov-cobertura — gem install simplecov-cobertura

Install all: bundle install (uses Gemfile)
HELPEOF
    exit 0
fi

COVERAGE_DIR="coverage"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --output) COVERAGE_DIR="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ── Dependency checks ───────────────────────────────────────────────────────
command -v ruby >/dev/null 2>&1 || { echo "Error: ruby not found." >&2; exit 1; }
command -v bashcov >/dev/null 2>&1 || { echo "Error: bashcov not found. Run: gem install bashcov simplecov-cobertura" >&2; exit 1; }
command -v bats >/dev/null 2>&1 || { echo "Error: bats not found. Run: apt-get install bats" >&2; exit 1; }

# ── Clean previous results ──────────────────────────────────────────────────
rm -rf "$COVERAGE_DIR"

echo "=== Shell Script Coverage (bashcov + bats) ==="
echo ""

# ── Run bats tests under bashcov ────────────────────────────────────────────
# bashcov traces all bash execution during the bats run, including scripts
# invoked by the tests. SimpleCov (.simplecov config) filters to scripts/ only.
COVERAGE_DIR="$COVERAGE_DIR" bashcov -- bats test/scripts/*.bats
status=$?

echo ""

# ── Summary ─────────────────────────────────────────────────────────────────
if [[ -f "$COVERAGE_DIR/coverage.xml" ]]; then
    echo "Cobertura XML: $COVERAGE_DIR/coverage.xml"
fi
if [[ -f "$COVERAGE_DIR/index.html" ]]; then
    echo "HTML report:   $COVERAGE_DIR/index.html"
fi

exit $status
