#!/usr/bin/env bash
# Requires bash 4.0+ (associative arrays, [[ ]], local, set -euo pipefail)
# progress.sh — Display elicitation progress dashboard for requirements.md and brief.md
#
# Usage:
#   bash scripts/progress.sh
#   bash scripts/progress.sh --proposal my-proposal
#   bash scripts/progress.sh --requirements FILE --brief FILE
#
# Parses <!-- Status: empty/in-progress/complete --> comments from both files
# and displays a visual progress dashboard with next-step recommendations.

set -uo pipefail

# ── Defaults ────────────────────────────────────────────────────────────────
REQ_FILE="requirements.md"
BRIEF_FILE="brief.md"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --proposal)     REQ_FILE="proposals/$2/requirements.md"
                        BRIEF_FILE="proposals/$2/brief.md"; shift 2 ;;
        --requirements) REQ_FILE="$2"; shift 2 ;;
        --brief)        BRIEF_FILE="$2"; shift 2 ;;
        -h|--help)      echo "Usage: bash scripts/progress.sh [--proposal NAME] [--requirements FILE] [--brief FILE]"
                        exit 0 ;;
        *)              echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ── Colour support ──────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'
    CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
else
    GREEN=''; YELLOW=''; RED=''; CYAN=''; BOLD=''; DIM=''; RESET=''
fi

# ── Get status of a section from a file ─────────────────────────────────────
# Usage: get_status FILE SECTION_NUM → prints "empty", "in-progress", or "complete"
get_status() {
    local file="$1" section_num="$2"
    if [[ ! -f "$file" ]]; then echo "missing"; return; fi
    # Find the section, then the first Status comment after it
    awk -v sect="## $section_num" '
        $0 ~ "^" sect " " { found=1 }
        found && /<!-- Status:/ {
            s = $0
            gsub(/.*Status: */, "", s)
            gsub(/ *-->.*/, "", s)
            print s
            exit
        }
        found && /^## [0-9][0-9] / && $0 !~ "^" sect " " { print "empty"; exit }
        END { if (!found) print "empty" }
    ' "$file"
}

# ── Progress bar ────────────────────────────────────────────────────────────
progress_bar() {
    local complete="$1" total="$2"
    local filled=$(( complete * 10 / total ))
    local empty=$(( 10 - filled ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="#"; done
    for ((i=0; i<empty; i++)); do bar+="-"; done
    echo "$bar"
}

# ── Globals for next-step tracking ──────────────────────────────────────────
NEXT_NUM=""
NEXT_TYPE=""

# ── Requirements sections ───────────────────────────────────────────────────
REQ_NUMS=(01 02 03 04 05 06 07 08 09)
REQ_NAMES=(
    "Purpose and Scope"
    "Stakeholders"
    "Business Requirements"
    "Functional Requirements"
    "Non-Functional Requirements"
    "Constraints"
    "Assumptions and Dependencies"
    "Acceptance Criteria"
    "Requirements Traceability Matrix"
)
REQ_CMDS=(/req-01 /req-01 /req-02 /req-02 /req-03 /req-04 /req-04 /req-05 /req-05)

# ── Brief sections ──────────────────────────────────────────────────────────
BRIEF_NUMS=(01 02 03 04 05 06 07 08 09 10 11)
BRIEF_NAMES=(
    "Introduction and Goals"
    "Constraints"
    "Context and Scope"
    "Solution Strategy"
    "Building Block View"
    "Runtime View"
    "Deployment View"
    "Cross-cutting Concepts"
    "Architecture Decisions"
    "Quality Requirements"
    "Risks and Technical Debt"
)

# ── Render one artifact ─────────────────────────────────────────────────────
render_artifact() {
    local label="$1" file="$2"
    shift 2
    local -a nums=()
    local -a names=()

    # Split remaining args: first half is nums, second half is names
    local count="$1"; shift
    for ((i=0; i<count; i++)); do nums+=("$1"); shift; done
    for ((i=0; i<count; i++)); do names+=("$1"); shift; done

    local total=${#nums[@]}

    if [[ ! -f "$file" ]]; then
        printf '%s%s%s (%s):  %sNot started%s\n\n' "$BOLD" "$label" "$RESET" "$(basename "$file")" "$DIM" "$RESET"
        if [[ -z "$NEXT_NUM" ]]; then
            NEXT_NUM="${nums[0]}"
            NEXT_TYPE="$label"
        fi
        return
    fi

    # Collect statuses
    local complete=0
    local statuses=()
    for ((i=0; i<total; i++)); do
        local st
        st=$(get_status "$file" "${nums[$i]}")
        statuses+=("$st")
        if [[ "$st" == "complete" ]]; then ((complete++)); fi
        # Track first incomplete for next-step
        if [[ -z "$NEXT_NUM" && "$st" != "complete" ]]; then
            NEXT_NUM="${nums[$i]}"
            NEXT_TYPE="$label"
        fi
    done

    # Header with bar
    local bar
    bar=$(progress_bar "$complete" "$total")
    local colour="$RED"
    [[ $complete -eq $total ]] && colour="$GREEN"
    [[ $complete -gt 0 && $complete -lt $total ]] && colour="$YELLOW"

    printf '%s%s%s (%s):  %s%d/%d complete%s  [%s]\n' \
        "$BOLD" "$label" "$RESET" "$(basename "$file")" "$colour" "$complete" "$total" "$RESET" "$bar"

    # Section grid (2 columns)
    local col=0
    for ((i=0; i<total; i++)); do
        local st="${statuses[$i]}"
        local icon marker
        case "$st" in
            complete)    marker="$GREEN"; icon="+" ;;
            in-progress) marker="$YELLOW"; icon="~" ;;
            *)           marker="$DIM"; icon="-" ;;
        esac

        local entry_text
        entry_text=$(printf "%s %s %s" "$icon" "${nums[$i]}" "${names[$i]}")
        printf '  %s%s%s' "$marker" "$entry_text" "$RESET"

        ((col++)) || true
        if (( col % 2 == 0 )); then
            printf "\n"
        else
            local padlen=$(( 40 - ${#entry_text} ))
            (( padlen < 1 )) && padlen=1
            printf "%*s" "$padlen" ""
        fi
    done
    (( col % 2 != 0 )) && printf "\n"
    printf "\n"
}

# ── Main ────────────────────────────────────────────────────────────────────
printf "\n"

render_artifact "Requirements" "$REQ_FILE" \
    ${#REQ_NUMS[@]} "${REQ_NUMS[@]}" "${REQ_NAMES[@]}"

render_artifact "Architecture" "$BRIEF_FILE" \
    ${#BRIEF_NUMS[@]} "${BRIEF_NUMS[@]}" "${BRIEF_NAMES[@]}"

# ── Next step recommendation ────────────────────────────────────────────────
if [[ -z "$NEXT_NUM" ]]; then
    printf '%s%sElicitation complete!%s\n' "$GREEN" "$BOLD" "$RESET"
    printf '  Next: %smake ready%s to validate consistency, then Prompt 01 for spec authoring.\n' "$CYAN" "$RESET"
else
    printf '%sNext step:%s\n' "$BOLD" "$RESET"

    if [[ "$NEXT_TYPE" == "Requirements" ]]; then
        # Look up the command and name for this section
        next_cmd="" next_name=""
        for ((i=0; i<${#REQ_NUMS[@]}; i++)); do
            if [[ "${REQ_NUMS[$i]}" == "$NEXT_NUM" ]]; then
                next_cmd="${REQ_CMDS[$i]}"
                next_name="${REQ_NAMES[$i]}"
                break
            fi
        done
        printf '  AI:     %s%s%s  %s\n' "$CYAN" "$next_cmd" "$RESET" "$next_name"
        printf '  Non-AI: %smake gather-requirements%s\n' "$CYAN" "$RESET"
    else
        next_name=""
        for ((i=0; i<${#BRIEF_NUMS[@]}; i++)); do
            if [[ "${BRIEF_NUMS[$i]}" == "$NEXT_NUM" ]]; then
                next_name="${BRIEF_NAMES[$i]}"
                break
            fi
        done
        printf '  AI:     %s/gather-%s%s  %s\n' "$CYAN" "$NEXT_NUM" "$RESET" "$next_name"
        printf '  Non-AI: %smake gather-brief%s\n' "$CYAN" "$RESET"
    fi
fi

printf "\n"
