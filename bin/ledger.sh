#!/bin/sh
# ledger.sh — validate the ledger and emit its counts. The counts are GENERATED.
#
#   usage: ledger.sh <ledger-dir>
#   emits: the STATE.md ledger section, on stdout
#   exits: non-zero, loudly, on any violation
#
# WHY A LEDGER AT ALL
#
#   FAILURES.md was prose. You cannot threshold prose. A class recurred at three
#   sites before anyone noticed it was one class, and a fix landed at one site
#   and not the next one over, because nothing connected them. Recurrence has to
#   be a NUMBER or nobody escalates until it hurts.
#
# WHY IT IS GATED
#
#   A ledger that is not checked is FAILURES.md again. Every rule below is
#   enforced here and run by verify.sh, because a governance instrument nobody
#   runs is the A5 failure: a check for the exact defect, in writing, naming the
#   document and the failure mode, that cost nothing to add and did nothing.
#
# THE ESCALATION IS MECHANICAL, AND IT IS THE ONLY ONE
#
#   >= 2 OPEN sites and no mechanism  ->  the build is red.
#
#   Not a review, not a meeting, not a judgment about whether the class matters.
#   Two sites means the shape propagates; one site might be a quirk. The number
#   of open sites is derived from this file, so nobody has to remember to care.
#
#   Escalation requires a mechanism AND a search key. A machine that makes the
#   class unrepresentable, and a command that finds the other sites. Without the
#   key, "closed by a sweep rather than by a fix" is aspiration, not procedure.
#
# TWO STATES, PLUS TWO DECLARED TERMINALS
#
#   The middle zone -- "should", "best practice" -- is where bureaucracy grows,
#   because prose does not bind and everyone knows it. So: unregulated, or
#   impossible. But two honest terminal states are not a middle zone, because
#   each is an explicit claim that shows up in a diff and gets counted:
#
#     mechanism = unmechanizable   we looked, there is no machine
#     control   = uncontrolled     we know this gate has no negative control
#
#   `-` in either field means nobody looked, and that is the thing that fails.
#   The distinction being drawn is between an unanswered question and an
#   answered one whose answer is "no". Only the first is a defect.

set -u

BIN=$(dirname "$0")
dir=${1:-ledger}
[ -d "$dir" ] || { echo "ledger.sh: no such directory: $dir" >&2; exit 2; }
TAB=$(printf '\t')
fail=0

C="$dir/classes.tsv"; S="$dir/sites.tsv"; G="$dir/gates.tsv"
for f in "$C" "$S" "$G"; do
    [ -f "$f" ] || { echo "ledger.sh: ABORT -- missing $f" >&2; exit 1; }
done

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT INT TERM
strip() { grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null || :; }
strip "$C" > "$work/classes"; strip "$S" > "$work/sites"; strip "$G" > "$work/gates"

# Vacuous pass: the class this project hit five times. An empty ledger is not a
# clean ledger, and this gate must not report one as such.
for n in classes sites gates; do
    [ -s "$work/$n" ] || { echo "ledger.sh: ABORT -- $n.tsv has no entries. An empty ledger is not a clean one." >&2; fail=1; }
done
[ "$fail" -eq 0 ] || exit 1

err() { echo "ledger.sh: $*" >&2; fail=1; }

# ---- shape ----------------------------------------------------------------
# The expected field count is DERIVED from each file's own header row. There is
# no column count in this script, and there must never be one again: the literal
# 3 that used to be here covered all three files, gates.tsv grew a fourth
# column, and this check began rejecting the ledger it exists to validate.
# Widening the literal to a per-file number moved the same defect one file over,
# into verify.sh's fixtures. See bin/tsvhdr.sh.
#
# Counting is necessary and not sufficient. The loops below index columns BY
# POSITION, so each file's header is also asserted to START with the names this
# script depends on. Appending a column stays legal -- that is the entire point
# -- while renaming or reordering one is refused rather than silently misread.
#
# The silent misread is not hypothetical. `read -r gid closes control` against a
# four-column gates.tsv leaves the fourth field glued to the third: no row
# equals 'uncontrolled' any more, and STATE.md reports zero gates without a
# negative control while four of them have none. Nothing rings. Hence `rest`.
: > "$work/shape"
check_shape() {   # <file> <stripped copy> <columns this script reads by position>
    h=$(sh "$BIN/tsvhdr.sh" "$1" 2>&1) || { err "$h"; return; }
    want=${h%% *}; names=${h#* }
    case "$names " in
        "$3 "*) ;;
        *) err "$1 header is '$names', but ledger.sh reads '$3' by position. Appending a column is fine; renaming or reordering one is not." ;;
    esac
    awk -F"$TAB" -v want="$want" -v nm="$1" \
        'NF != want {print nm": line "FNR": header declares "want" tab-separated fields, found "NF}' \
        "$2" >> "$work/shape"
}
check_shape "$C" "$work/classes" "class_id mechanism search_key"
check_shape "$S" "$work/sites"   "class_id site state"
check_shape "$G" "$work/gates"   "gate_id closes control"
[ -s "$work/shape" ] && { sed 's/^/ledger.sh: /' "$work/shape" >&2; fail=1; }

# ---- classes --------------------------------------------------------------
cut -f1 "$work/classes" | sort | uniq -d > "$work/dupclass"
[ -s "$work/dupclass" ] && err "duplicate class ids:$(tr '\n' ' ' < "$work/dupclass")"

while IFS="$TAB" read -r id mech key rest; do
    [ -n "${id:-}" ] || continue
    printf '%s\n' "$id" | grep -qE '^[A-Z][A-Z0-9-]*$' \
        || err "class id is not upper-kebab: '$id'"
    # A mechanism without a way to find the other sites cannot be swept, so
    # closing one site tells you nothing about exposure.
    if [ "$mech" != "-" ] && [ "$key" = "-" ]; then
        err "$id declares a mechanism but no search key. Escalation requires both."
    fi
done < "$work/classes"

# ---- sites ----------------------------------------------------------------
cut -f1,2 "$work/sites" | sort | uniq -d > "$work/dupsite"
[ -s "$work/dupsite" ] && { echo "ledger.sh: duplicate (class, site) rows:" >&2; sed 's/^/    /' "$work/dupsite" >&2; fail=1; }

while IFS="$TAB" read -r cid site state rest; do
    [ -n "${cid:-}" ] || continue
    cut -f1 "$work/classes" | grep -qxF "$cid" || err "site names unknown class '$cid': $site"
    case "$state" in
        open|closed) ;;
        *) err "site state must be open or closed, found '$state': $site" ;;
    esac
done < "$work/sites"

# A class nobody has recorded a site for is a category, not a class.
while IFS="$TAB" read -r id rest; do
    [ -n "${id:-}" ] || continue
    cut -f1 "$work/sites" | grep -qxF "$id" || err "class '$id' has no recorded site. A class with no site is a category."
done < "$work/classes"

# ---- gates ----------------------------------------------------------------
cut -f1 "$work/gates" | sort | uniq -d > "$work/dupgate"
[ -s "$work/dupgate" ] && err "duplicate gate ids:$(tr '\n' ' ' < "$work/dupgate")"

n_uncontrolled=0
# `rest` is load-bearing: without it `control` absorbs every column appended
# after it, and the two token comparisons below stop matching anything.
while IFS="$TAB" read -r gid closes control rest; do
    [ -n "${gid:-}" ] || continue
    cut -f1 "$work/classes" | grep -qxF "$closes" || err "gate '$gid' closes unknown class '$closes'"
    # '-' means nobody looked. 'uncontrolled' means someone did and the answer
    # was no. Only the first is a defect; the second is a counted fact.
    [ "$control" = "-" ] && err "gate '$gid' declares no control. Use a control, or the token 'uncontrolled'."
    [ "$control" = "uncontrolled" ] && n_uncontrolled=$((n_uncontrolled+1))
done < "$work/gates"

# ---- THE ESCALATION -------------------------------------------------------
rows=''; ripe=''
while IFS="$TAB" read -r id mech key rest; do
    [ -n "${id:-}" ] || continue
    open=$(awk -F"$TAB" -v c="$id" '$1==c && $3=="open"' "$work/sites" | wc -l | tr -d ' ')
    tot=$(awk -F"$TAB" -v c="$id" '$1==c' "$work/sites" | wc -l | tr -d ' ')
    case "$mech" in
        -)              state='**unmechanized**' ;;
        unmechanizable) state='unmechanizable' ;;
        *)              state='mechanized' ;;
    esac
    if [ "$mech" = "-" ] && [ "$open" -ge 2 ]; then
        ripe="${ripe}${id} (${open} open sites)
"
    fi
    esc=$(printf '%s' "$key" | sed 's/|/\\|/g')
    rows="${rows}| \`$id\` | $tot | $open | $state | \`$esc\` |
"
done < "$work/classes"

if [ -n "$ripe" ]; then
    echo "ledger.sh: ESCALATION -- these classes have >=2 open sites and no mechanism:" >&2
    printf '%s' "$ripe" | sed 's/^/    /' >&2
    echo "  Name a machine that makes the class unrepresentable, or declare it" >&2
    echo "  unmechanizable. A rule is not a mechanism. A warning is not a mechanism." >&2
    fail=1
fi

[ "$fail" -eq 0 ] || exit 1

# ---- emit -----------------------------------------------------------------
n_classes=$(wc -l < "$work/classes" | tr -d ' ')
n_sites=$(wc -l < "$work/sites" | tr -d ' ')
n_open=$(awk -F"$TAB" '$3=="open"' "$work/sites" | wc -l | tr -d ' ')
n_gates=$(wc -l < "$work/gates" | tr -d ' ')

cat <<LEDGER_EOF
## Ledger

Recurrence is a number here, not a narrative. A class with two or more **open**
sites and no mechanism turns this build red; see \`bin/ledger.sh\`. Every count
below is derived from \`ledger/\` by that script.

| | |
|---|---|
| Classes | $n_classes |
| Recorded sites | $n_sites |
| Open sites | $n_open |
| Gates | $n_gates |
| Gates with no negative control | $n_uncontrolled |

| class | sites | open | mechanism | search key |
|---|---|---|---|---|
$rows

The last column is what makes "a class is closed by a sweep, not a fix" a
procedure rather than an intention. A class with no way to enumerate its other
sites cannot be swept, so it stays local however real it is.

Gates with no negative control are counted rather than tolerated silently. A
gate whose only catch is its own control is either perfect or dead, and one with
no control at all cannot be told apart from either.
LEDGER_EOF
