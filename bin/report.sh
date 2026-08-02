#!/bin/sh

[ "${1:-}" = "--scope" ] && exit 3   # composes other instruments; enumerates nothing itself
# report.sh — GENERATE STATE.md from live runs.
#
# There is not a single hand-typed number in the output. Every count, every exit
# status, every timing is substituted from a command executed by this script.
#
# WHY THIS EXISTS
#   An audit document written by hand contained four wrong numbers: a summary
#   that said "five" where its own table showed four, an instrument inventory
#   missing four entries, a heading that said "6 instruments" where two were
#   executables, and a timing of "8s" for a command that takes 75-160s. All four
#   were found by an outside reader. All four were typed by a model into prose.
#
#   Adding a rule ("a count is a claim, check it") does not work: that rule was
#   already written down, in the same document, and was violated four times
#   inside it. The rule requires a reader who remembers and heeds it, and that
#   reader is not reliably present.
#
#   So the numbers are not written. They are computed. There is no longer a
#   place in the pipeline where a wrong count can be typed.
#
# PAIRED WITH verify.sh, which regenerates and diffs against the committed copy.
# Editing STATE.md by hand fails that gate.

set -u
export PATH="/root/.elan/bin:$PATH"
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 2
command -v lean >/dev/null 2>&1 || { echo "no lean on PATH" >&2; exit 2; }

# ---- measure ---------------------------------------------------------------
LEAN_VER=$(lean --version 2>&1 | head -1)
# Neither N_FILES nor N_PROBES is computed here. Both are derived from the tables
# below, so that each count and its rows come from one enumeration and cannot
# disagree.

T0=$(date +%s)
CENSUS=$(cd lean && sh ../bin/check.sh 2>&1); CENSUS_RC=$?
T1=$(date +%s); CENSUS_SECS=$((T1-T0))

TOTAL_LINE=$(printf '%s\n' "$CENSUS" | grep 'TOTAL:')
N_DECL=$(printf '%s' "$TOTAL_LINE" | sed -n 's/.*TOTAL: \([0-9]*\) declarations.*/\1/p')
N_AUD=$(printf '%s' "$TOTAL_LINE" | sed -n 's/.*declarations, \([0-9]*\) audited.*/\1/p')
N_FORBID=$(printf '%s\n' "$CENSUS" | grep -c 'FORBIDDEN AXIOMS')
N_SORRYWARN=$(printf '%s\n' "$CENSUS" | sed -n 's/.*sorry-warnings=\([0-9]*\).*/\1/p' | awk '{s+=$1} END{print s+0}')

# Negative controls. Each probe must fail, AND fail for the reason it declares
# in its .expect sidecar. The exit code alone is one bit, and every wrong answer
# has one -- a probe swapped for something that fails differently used to print
# "rejected PASS" and regenerate this file byte-identically. See bin/probes.sh.
if ! PROBE_ROWS=$(sh "$ROOT/bin/probes.sh" probes 2>/dev/null); then
    echo "report.sh: ABORT -- a negative control did not fail for its declared reason." >&2
    echo "           Run: sh bin/probes.sh probes >/dev/null" >&2
    exit 4
fi
# One enumeration. The count IS the table.
N_PROBES=$(printf '%s\n' "$PROBE_ROWS" | grep -c '^| `')

# The ledger's counts are generated for the same reason every other number here
# is: a recurrence count that can be typed is a recurrence count that will drift,
# and this one is what escalation triggers on.
if ! LEDGER=$(sh "$ROOT/bin/ledger.sh" ledger 2>/dev/null); then
    echo "report.sh: ABORT -- the ledger is invalid or something is ripe for escalation." >&2
    echo "           Run: sh bin/ledger.sh ledger >/dev/null" >&2
    exit 5
fi

# The map. Four instruments, each computing its own section rather than stating
# it, each aborting this report rather than emitting a section it could not
# derive. The genus in particular is recomputed every run: it is a fact about
# ledger/translations.tsv, not a background constant, and writing it down
# anywhere would make it a number that can be typed wrong.
for m in atlas:ATLAS absence:ABSENCE laps:LAPS center:CENTER; do
    inst=${m%%:*}; var=${m#*:}
    case "$inst" in
        laps|center) arg="$ROOT" ;;
        *)           arg="$ROOT/ledger" ;;
    esac
    if ! out=$(sh "$ROOT/bin/$inst.sh" "$arg" --md 2>/dev/null); then
        echo "report.sh: ABORT -- bin/$inst.sh failed. Run: sh bin/$inst.sh $arg" >&2
        exit 6
    fi
    # The SCOPE line is the instrument's manifest, checked by verify.sh check 11
    # against a live run. It is not prose for a document, so it is stripped here.
    eval "$var=\$(printf '%s\\n' \"\$out\" | grep -v '^SCOPE|')"
done

N_PROBE_CAUGHT=$(printf '%s\n' "$PROBE_ROWS" | grep -c '| CAUGHT | matched |')

# lean's own opinion of each probe, to show exit code is not a gate
LEAN_ON_PROBES=""
for p in probes/*.lean; do
    b=$(basename "$p")
    out=$(lean "$p" 2>&1); lrc=$?
    w=$(printf '%s' "$out" | grep -c "uses 'sorry'")
    LEAN_ON_PROBES="${LEAN_ON_PROBES}| \`$b\` | $lrc | $w |
"
done

# Per-file rows: enumerated by `find`, looked up by exact literal. The previous
# version matched `[A-Za-z]*\.lean` against check.sh's human output, so a file
# named with an underscore or a digit lost its row while still being counted --
# hole #5's class, surviving one file away from where it was closed. See
# bin/perfile.sh. A missing record now aborts the whole report rather than
# quietly shortening the table.
CENSUS_FILE=$(mktemp)
printf '%s\n' "$CENSUS" > "$CENSUS_FILE"
if ! PER_FILE=$(sh "$ROOT/bin/perfile.sh" lean "$CENSUS_FILE"); then
    rm -f "$CENSUS_FILE"
    echo "report.sh: ABORT -- refusing to emit a STATE.md whose table undercounts the corpus." >&2
    exit 3
fi
rm -f "$CENSUS_FILE"

# One enumeration, not two. N_FILES cannot disagree with the table because it is
# the table.
N_FILES=$(printf '%s\n' "$PER_FILE" | grep -c '^|')

STAMP=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
# NOTE: no commit SHA here. A file cannot contain the SHA of the commit that
# adds it, so embedding one guarantees verify.sh fails on the next clone -- as
# it did on this bundle's first independent run. Git records provenance already.

# ---- emit ------------------------------------------------------------------
cat <<EOF
# STATE

<!-- GENERATED BY bin/report.sh. DO NOT EDIT.
     Every number below was computed by a command in this run.
     bin/verify.sh regenerates this file and fails if it differs. -->

Generated: $STAMP
Toolchain: $LEAN_VER

## Corpus

| | |
|---|---|
| Lean files in \`lean/\` | $N_FILES |
| Declarations | $N_DECL |
| Declarations audited | $N_AUD |
| Files with forbidden axioms | $N_FORBID |
| \`sorry\` warnings | $N_SORRYWARN |
| Census exit status | $CENSUS_RC |
| Census wall clock | ${CENSUS_SECS}s |

Permitted axioms are exactly \`propext\`, \`Classical.choice\`, \`Quot.sound\`.
Anything else fails the run. This is an allowlist: an axiom nobody thought to
name cannot pass.

### Per file

| file | declarations | audited |
|---|---|---|
$PER_FILE

## Negative controls

These files exist to be rejected. **A passing probe means the gate is broken**,
which is the failure this project keeps hitting. $N_PROBE_CAUGHT of $N_PROBES caught.

Rejection is not enough. Each probe declares the failure signature it claims to
produce, in a \`.expect\` sidecar, and the signature is checked. A probe that
fails for some other reason is not testing what its name says, and used to pass
this gate while regenerating this table byte-identically.

| probe | check.sh exit | verdict | declared signature |
|---|---|---|---|
$PROBE_ROWS

### What \`lean\` alone says about the same files

Exit status is not a gate. \`sorry\` is a warning, and a planted axiom is not an
error at all.

| probe | lean exit | sorry warnings |
|---|---|---|
$LEAN_ON_PROBES

$LEDGER
$ATLAS
$ABSENCE
$LAPS
$CENTER

## How to check this yourself

    sh bin/check.sh      # from lean/ — must exit 0
    sh bin/verify.sh     # regenerates this file and diffs; must exit 0

The four sections above the last one need **no toolchain and no trusted party**.
\`bin/atlas.sh\` in particular decides whether a translation is sound by closing
the loop, not by consulting anyone:

    sh bin/schema.sh ledger
    sh bin/atlas.sh ledger
    sh bin/absence.sh ledger
    sh bin/laps.sh .
    sh bin/center.sh .

\`verify.sh\` failing means either the corpus changed or someone edited this
file by hand. Both should fail.
EOF
