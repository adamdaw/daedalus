#!/usr/bin/env bash
# assemble.sh — non-AI fallback for prompts/01-arch-spec-author.md
# Assembles arc42 markdown files from requirements.md + brief.md.
# Output is draft quality: structured content, no AI prose synthesis.
#
# Usage:
#   assemble.sh [--proposal NAME]
#   assemble.sh [--requirements FILE --brief FILE --output DIR]
#
# With --proposal NAME, looks for files in proposals/NAME/ and writes
# arc42 markdown to proposals/NAME/markdown/.
#
# Standards:
#   arc42 §1–11 — https://docs.arc42.org
#   ISO/IEC/IEEE 29148:2018 — requirements traceability

set -euo pipefail

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    cat <<'HELPEOF'
Usage: bash scripts/assemble.sh [--proposal NAME] [--requirements FILE] [--brief FILE] [--output DIR]

Assemble arc42 markdown files from requirements.md and brief.md elicitation
artifacts. Generates 12 files (sections 01–11 + 99_References).

Options:
  --proposal NAME          Use proposals/NAME/ as source and output
  --requirements FILE      Path to requirements.md (default: requirements.md)
  --brief FILE             Path to brief.md (default: brief.md)
  --output DIR             Output directory (default: markdown/)

Standards:
  arc42 — https://arc42.org (all 11 sections)
  ISO/IEC/IEEE 29148:2018 — requirements integration

Non-AI fallback for Prompt 01 (spec authoring).
HELPEOF
    exit 0
fi

REQUIREMENTS="requirements.md"
BRIEF="brief.md"
OUTDIR="markdown"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --proposal)
            BASE="proposals/$2"
            REQUIREMENTS="${BASE}/requirements.md"
            BRIEF="${BASE}/brief.md"
            OUTDIR="${BASE}/markdown"
            shift 2 ;;
        --requirements) REQUIREMENTS="$2"; shift 2 ;;
        --brief)        BRIEF="$2";        shift 2 ;;
        --output)       OUTDIR="$2";       shift 2 ;;
        *) echo "Usage: $0 [--proposal NAME | --requirements FILE --brief FILE --output DIR]" >&2
           exit 1 ;;
    esac
done

if [[ ! -f "$BRIEF" ]]; then
    echo "ERROR: ${BRIEF} not found — run 'make gather-brief' first" >&2
    exit 1
fi

mkdir -p "$OUTDIR"
HAS_REQ=false
[[ -f "$REQUIREMENTS" ]] && HAS_REQ=true

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Extract content of a brief.md section (between "## NN — Title" and next "---")
# Strips HTML comment lines. Shifts ### → ## and #### → ###.
extract_brief() {
    local num="$1"
    awk -v num="$num" '
        index($0, "## " num " —") == 1 { found=1; next }
        found && /^---$/              { exit }
        found && /^<!--/              { next }
        found && /^### /              { sub(/^### /, "## "); print; next }
        found && /^#### /             { sub(/^#### /, "### "); print; next }
        found                         { print }
    ' "$BRIEF"
}

# Extract content of a requirements.md section (between "## NN — Title" and next "---")
# Strips HTML comment lines. Strips MoSCoW reminder comments.
extract_req() {
    local num="$1"
    awk -v num="$num" '
        index($0, "## " num " —") == 1 { found=1; next }
        found && /^---$/              { exit }
        found && /^<!--/              { next }
        found                         { print }
    ' "$REQUIREMENTS"
}

# Extract a named subsection from requirements.md (between "### Name" and next "##" or "---")
extract_req_subsection() {
    local header="$1"
    awk -v hdr="$header" '
        index($0, "### " hdr) == 1 { found=1; print; next }
        found && /^(## |---$)/     { exit }
        found && /^<!--/           { next }
        found                      { print }
    ' "$REQUIREMENTS"
}

arc42_header() {
    local title="$1"
    local ref="$2"
    printf '# %s\n\n<!-- arc42 Section — %s -->\n\n' "$title" "$ref"
}

write_file() {
    local name="$1"
    local content="$2"
    printf '%s\n' "$content" > "${OUTDIR}/${name}"
    echo "  wrote ${OUTDIR}/${name}"
}

# ---------------------------------------------------------------------------
# §01 — Introduction and Goals
# ---------------------------------------------------------------------------

{
    arc42_header "Introduction and Goals" "https://docs.arc42.org/section-1/"

    # System overview from brief.md
    overview=$(extract_brief "01" | awk '/^## System Overview/{found=1; next} found && /^## /{exit} found{print}')
    if [[ -n "$overview" ]]; then
        echo "## System Overview"
        echo ""
        echo "$overview"
        echo ""
    fi

    if $HAS_REQ; then
        # Requirements from requirements.md §03 (business) + §04 (functional)
        echo "## Requirements Overview"
        echo ""
        extract_req_subsection "Business Requirements" 2>/dev/null | tail -n +2 || true
        echo ""
        extract_brief "01" | awk '/^## Requirements/{found=1; next} found && /^## /{exit} found{print}' || true
        echo ""

        # Quality Goals from requirements.md §05 NFRs (top entries)
        echo "## Quality Goals"
        echo ""
        echo "| Priority | Quality Goal | Motivation |"
        echo "| --- | --- | --- |"
        extract_req "05" | grep "^| NFR-" | head -5 | \
            awk -F'|' 'NR==1{p=1} {printf "| %s | %s (%s) | %s |\n", NR, $3, $2, $4}' || true
        echo ""

        # Stakeholders from requirements.md §02
        echo "## Stakeholders"
        echo ""
        extract_req "02"
        echo ""
    else
        extract_brief "01" | awk '/^## Requirements/{found=1} found{print}'
    fi
} | write_file "01_Introduction_and_Goals.md" "$(cat)"

# ---------------------------------------------------------------------------
# §02 — Architecture Constraints
# ---------------------------------------------------------------------------

{
    arc42_header "Architecture Constraints" "https://docs.arc42.org/section-2/"

    if $HAS_REQ; then
        echo "## Technical Constraints"
        echo ""
        extract_req_subsection "Technical Constraints" 2>/dev/null | tail -n +2 || true
        echo ""

        echo "## Organisational Constraints"
        echo ""
        extract_req_subsection "Organisational Constraints" 2>/dev/null | tail -n +2 || true
        echo ""
    fi

    # Conventions from brief.md §02
    conventions=$(extract_brief "02" | awk '/^## Conventions/{found=1; next} found && /^## /{exit} found{print}')
    if [[ -n "$conventions" ]]; then
        echo "## Conventions"
        echo ""
        echo "$conventions"
        echo ""
    fi

    # Any additional constraint content from brief.md §02
    extra=$(extract_brief "02" | awk '
        /^## (Technical|Organisational) Constraints/{skip=1}
        skip && /^## /{skip=0}
        /^## Conventions/{skip=1}
        skip && /^## /{skip=0}
        !skip{print}
    ')
    [[ -n "$extra" ]] && echo "$extra"
} | write_file "02_Constraints.md" "$(cat)"

# ---------------------------------------------------------------------------
# §03–§11 — direct from brief.md (heading-shifted, comments stripped)
# ---------------------------------------------------------------------------

declare -A SECTIONS=(
    ["03"]="03_Context_and_Scope.md|Context and Scope|https://docs.arc42.org/section-3/"
    ["04"]="04_Solution_Strategy.md|Solution Strategy|https://docs.arc42.org/section-4/"
    ["05"]="05_Building_Block_View.md|Building Block View|https://docs.arc42.org/section-5/"
    ["06"]="06_Runtime_View.md|Runtime View|https://docs.arc42.org/section-6/"
    ["07"]="07_Deployment_View.md|Deployment View|https://docs.arc42.org/section-7/"
    ["08"]="08_Crosscutting_Concepts.md|Cross-cutting Concepts|https://docs.arc42.org/section-8/"
    ["09"]="09_Architecture_Decisions.md|Architecture Decisions|https://docs.arc42.org/section-9/"
    ["10"]="10_Quality_Requirements.md|Quality Requirements|https://docs.arc42.org/section-10/"
    ["11"]="11_Risks_and_Technical_Debt.md|Risks and Technical Debt|https://docs.arc42.org/section-11/"
)

for num in 03 04 05 06 07 08 09 10 11; do
    IFS='|' read -r filename title ref <<< "${SECTIONS[$num]}"
    content=$(extract_brief "$num")
    {
        arc42_header "$title" "$ref"
        echo "$content"
    } | write_file "$filename" "$(cat)"
done

# ---------------------------------------------------------------------------
# §99 — References (stub)
# ---------------------------------------------------------------------------

{
    printf '# References\n\n'
    printf '<!-- Add bibliography entries to project.bib and cite inline with [@Key].\n'
    printf '     pandoc --citeproc appends the formatted reference list here automatically. -->\n'
} | write_file "99_References.md" "$(cat)"

echo ""
file_count=$(find "${OUTDIR}" -maxdepth 1 -name '*.md' | wc -l)
echo "Assembled ${file_count} files into ${OUTDIR}/"
echo "Output is draft quality — review and refine before publishing."
