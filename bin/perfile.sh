#!/bin/sh

[ "${1:-}" = "--scope" ] && { echo "DOMAIN|perfile|every *.lean in the named directory, and every PERFILE record in the census"; exit 0; }
# perfile.sh — build the per-file table from the FILE LIST, not from prose.
#
#   usage: perfile.sh <lean-dir> <census-output-file>
#
# WHY THIS FILE EXISTS
#
#   report.sh used to build the per-file table with a regex over check.sh's
#   human-readable output:
#
#       sed -n 's/^  \([A-Za-z]*\.lean\) *\([0-9]*\) declarations.*/...'
#
#   `[A-Za-z]*` is the same anchor that killed the fifth version of check.sh's
#   declaration extractor. An underscore or a digit in a filename and the row
#   silently vanished, while `N_FILES` (from `find`) still counted it and
#   `N_DECL` still included its declarations. STATE.md would report 11 files
#   with 9 rows and verify.sh would pass, because check 3 only asserts that
#   regeneration is DETERMINISTIC -- and it was deterministically wrong.
#
#   The class was closed in check.sh (stop parsing source text, ask Lean) and
#   left open one file away, because nothing connected the two sites. That is
#   the defect this file closes, and the reason the counter is worth building.
#
# HOW THE ROWS ARE OBTAINED, AND WHY IT IS DIFFERENT IN KIND
#
#   The row set is ENUMERATED, not matched. `find` produces the files; each
#   name is then used as an exact literal lookup key against a machine record
#   that check.sh printed from its own loop variable. No pattern anywhere has
#   to anticipate what a future author may legally name a file.
#
#   Two properties follow, and they are the point:
#
#     * A file that yielded no census record cannot be dropped from the table.
#       There is no code path that omits a row. There is only a code path that
#       ABORTS, loudly, naming the file. Silence is unrepresentable.
#     * The row set and the file count come from the same enumeration, so they
#       cannot disagree. report.sh derives N_FILES from these rows rather than
#       counting separately; one enumeration, not two agreeing by luck.
#
#   This is a type-1 fix (remove the degree of freedom) rather than type-2 (add
#   a gate that rejects). The repo's history is 2-for-2 on type-1 holding and
#   6-for-6 on type-2 needing a patch. A better regex would have been type-2.

set -u

dir=${1:-}
census=${2:-}
[ -n "$dir" ] && [ -n "$census" ] || { echo "usage: perfile.sh <lean-dir> <census-file>" >&2; exit 2; }
[ -d "$dir" ] || { echo "perfile.sh: no such directory: $dir" >&2; exit 2; }
[ -f "$census" ] || { echo "perfile.sh: no such census file: $census" >&2; exit 2; }

files=$(find "$dir" -name '*.lean' | sort)

# Vacuous pass has occurred three times in this project (extractor matched
# nothing; census yielded no declarations; no probes found). It is the first
# real defect class here. An empty table is not a passing table.
if [ -z "$files" ]; then
    echo "perfile.sh: ABORT -- no .lean files under $dir. Refusing to emit an empty table." >&2
    exit 1
fi

missing=''
rows=''
for f in $files; do
    b=$(basename "$f")

    # The record is pipe-delimited and the lookup is an exact literal. A name
    # containing the delimiter would make the record ambiguous, so it is
    # rejected rather than parsed optimistically.
    case "$b" in
        *'|'*) echo "perfile.sh: ABORT -- filename contains '|', census record would be ambiguous: $b" >&2; exit 1 ;;
    esac

    rec=$(grep -F "PERFILE|$b|" "$census" | head -1)
    if [ -z "$rec" ]; then
        missing="${missing}${b}
"
        continue
    fi

    n=$(printf '%s' "$rec" | cut -d'|' -f3)
    a=$(printf '%s' "$rec" | cut -d'|' -f4)
    rows="${rows}| \`$b\` | $n | $a |
"
done

if [ -n "$missing" ]; then
    echo "perfile.sh: ABORT -- census produced no record for these files:" >&2
    printf '%s' "$missing" | sed 's/^/    /' >&2
    echo "  A file the census did not reach must not become a missing table row." >&2
    exit 1
fi

printf '%s' "$rows"
