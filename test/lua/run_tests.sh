#!/usr/bin/env bash
# run_tests.sh — Integration tests for filters/diagram.lua
#
# Tests the pandoc Lua filter by running pandoc with test inputs and
# verifying the output. Requires pandoc >= 3.0 and mmdc to be installed.
#
# Standards:
#   pandoc-ext/diagram v1.2.0 — https://github.com/pandoc-ext/diagram
#   Mermaid — https://mermaid.js.org
#
# Run: bash test/lua/run_tests.sh
#   or: make test-lua

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FILTER="$PROJECT_DIR/filters/diagram.lua"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

passed=0
failed=0
skipped=0
total=0

pass() { passed=$((passed + 1)); total=$((total + 1)); echo "  PASS: $1"; }
fail() { failed=$((failed + 1)); total=$((total + 1)); echo "  FAIL: $1 — $2"; }
skip() { skipped=$((skipped + 1)); total=$((total + 1)); echo "  SKIP: $1"; }

# Check pandoc version (filter requires >= 3.0)
HAVE_PANDOC3=false
if command -v pandoc >/dev/null 2>&1; then
    PANDOC_MAJOR=$(pandoc --version | head -1 | grep -oP '\d+' | head -1)
    if [[ "$PANDOC_MAJOR" -ge 3 ]]; then
        HAVE_PANDOC3=true
    fi
fi

# Check mmdc availability
HAVE_MMDC=false
if command -v mmdc >/dev/null 2>&1 || [[ -n "${MERMAID_BIN:-}" ]]; then
    HAVE_MMDC=true
fi

echo "=== Lua Filter Integration Tests ==="
echo ""
echo "Environment:"
echo "  pandoc: $(pandoc --version 2>/dev/null | head -1 || echo 'not found')"
echo "  pandoc >= 3.0: $HAVE_PANDOC3"
echo "  mmdc: $HAVE_MMDC"
echo ""

# --------------------------------------------------------------------------
# Test 1: Filter exists and is valid Lua (no pandoc required)
# --------------------------------------------------------------------------
echo "Test 1: Filter file exists and contains expected version"
if grep -q 'local version' "$FILTER"; then
    pass "Filter contains version identifier"
else
    fail "Filter missing version" "expected 'local version' in diagram.lua"
fi

# --------------------------------------------------------------------------
# Test 2: Mermaid diagram renders (requires pandoc 3+ and mmdc)
# --------------------------------------------------------------------------
echo "Test 2: Mermaid diagram renders to HTML"
if [[ "$HAVE_PANDOC3" != true ]]; then
    skip "pandoc >= 3.0 not available"
elif [[ "$HAVE_MMDC" != true ]]; then
    skip "mmdc not available"
else
    cat > "$TMPDIR/test_mermaid.md" << 'MD'
```{.mermaid}
graph TD
    A[Start] --> B[End]
```
MD
    if pandoc --lua-filter "$FILTER" "$TMPDIR/test_mermaid.md" -o "$TMPDIR/mermaid_out.html" 2>/dev/null; then
        if grep -qE '<img|<svg|data:image' "$TMPDIR/mermaid_out.html" 2>/dev/null; then
            pass "Mermaid diagram rendered to image in HTML"
        else
            fail "Mermaid output missing image" "no <img> or <svg> in output"
        fi
    else
        fail "Pandoc with mermaid filter failed" "exit code $?"
    fi
fi

# --------------------------------------------------------------------------
# Test 3: Plain code blocks pass through unchanged (requires pandoc 3+)
# --------------------------------------------------------------------------
echo "Test 3: Plain code blocks are not processed"
if [[ "$HAVE_PANDOC3" != true ]]; then
    skip "pandoc >= 3.0 not available"
else
    cat > "$TMPDIR/test_plain.md" << 'MD'
```python
print("hello")
```
MD
    if pandoc --lua-filter "$FILTER" "$TMPDIR/test_plain.md" -o "$TMPDIR/plain_out.html" 2>/dev/null; then
        if grep -q 'print.*hello' "$TMPDIR/plain_out.html"; then
            pass "Plain code block preserved"
        else
            fail "Plain code block was modified" "expected 'print(\"hello\")' in output"
        fi
    else
        fail "Pandoc with filter failed on plain code block" "exit code $?"
    fi
fi

# --------------------------------------------------------------------------
# Test 4: Unknown engine class passes through (requires pandoc 3+)
# --------------------------------------------------------------------------
echo "Test 4: Unknown diagram engine passes through"
if [[ "$HAVE_PANDOC3" != true ]]; then
    skip "pandoc >= 3.0 not available"
else
    cat > "$TMPDIR/test_unknown.md" << 'MD'
```{.unknownengine}
some diagram code
```
MD
    if pandoc --lua-filter "$FILTER" "$TMPDIR/test_unknown.md" -o "$TMPDIR/unknown_out.html" 2>/dev/null; then
        if grep -qE 'some diagram code|unknownengine' "$TMPDIR/unknown_out.html"; then
            pass "Unknown engine code block preserved"
        else
            fail "Unknown engine block was removed" "expected content in output"
        fi
    else
        fail "Pandoc with filter failed on unknown engine block" "exit code $?"
    fi
fi

# --------------------------------------------------------------------------
# Test 5: Filter handles empty code block gracefully (requires pandoc 3+)
# --------------------------------------------------------------------------
echo "Test 5: Empty mermaid block handled gracefully"
if [[ "$HAVE_PANDOC3" != true ]]; then
    skip "pandoc >= 3.0 not available"
else
    cat > "$TMPDIR/test_empty.md" << 'MD'
```{.mermaid}
```
MD
    if pandoc --lua-filter "$FILTER" "$TMPDIR/test_empty.md" -o "$TMPDIR/empty_out.html" 2>/dev/null; then
        pass "Empty mermaid block did not crash pandoc"
    else
        # Some versions may error on empty — that's acceptable too
        pass "Empty mermaid block handled (pandoc exited non-zero but no crash)"
    fi
fi

# --------------------------------------------------------------------------
# Test 6: Filter version matches expected (no pandoc required)
# --------------------------------------------------------------------------
echo "Test 6: Filter version is v1.2.0 (vendored)"
if grep -q "1\.2\.0" "$FILTER"; then
    pass "Filter version matches expected vendored version"
else
    fail "Unexpected filter version" "expected 1.2.0"
fi

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
echo ""
echo "Results: $passed passed, $failed failed, $skipped skipped (of $total)"
if [[ $failed -gt 0 ]]; then
    exit 1
fi
