#!/bin/sh
# feedback.sh — the DOWNWARD arrow, and the only flow that shrinks |G|.
#
# sites.tsv reports defects in the corpus and pushes mechanisms UP.
# friction.tsv reports defects in the mechanisms and pushes deletions DOWN.
# Without the second, escalation is a ratchet: |G| only ever rises, and a gate
# that is wrong in practice is permanent because complaining about it is prose.
#
# The two thresholds are deliberately the same shape, opposite directions:
#   escalate:  >= 2 open SITES  and no mechanism   -> build one
#   delete:    >= 2 FRICTION    and no field-catch -> the gate is a candidate
#
# A gate whose entire lifetime record is control-only has never caught anything
# a person was actually trying to do. Paired with friction, that is not a
# suspicion, it is a measurement.
#
# ENFORCES: schema on friction.tsv and events.tsv, gate_id resolvable against
# gates.tsv, kind/outcome from a closed vocabulary. Then computes yield.
set -u
L=${1:-ledger}
fail=0
strip() { grep -v '^#' "$1" 2>/dev/null | grep -v '^[[:space:]]*$'; }

for f in friction events gates; do
    [ -f "$L/$f.tsv" ] || { echo "  ABORT: $L/$f.tsv missing"; exit 1; }
done
GATES=$(strip "$L/gates.tsv" | cut -f1 | sort -u)
[ -n "$GATES" ] || { echo "  ABORT: no gates declared - refusing a vacuous pass"; exit 1; }

echo "  -- friction (local -> mechanism) --"
strip "$L/friction.tsv" | while IFS='	' read -r g s k rest; do
    [ -n "${rest:-}" ] && { echo "  ABORT: too many fields: $g"; exit 1; }
    [ -n "$g" ] && [ -n "$s" ] && [ -n "$k" ] || { echo "  ABORT: empty field: $g $s $k"; exit 1; }
    printf '%s\n' "$GATES" | grep -qx "$g" || { echo "  ABORT: friction names unknown gate '$g'"; exit 1; }
    case "$k" in
        false-positive|unclear-verdict|cost|blocked|bypassed) ;;
        *) echo "  ABORT: unknown kind '$k' on gate '$g'"; exit 1 ;;
    esac
done || fail=1

strip "$L/events.tsv" | while IFS='	' read -r g o rest; do
    [ -n "${rest:-}" ] && { echo "  ABORT: too many fields: $g"; exit 1; }
    printf '%s\n' "$GATES" | grep -qx "$g" || { echo "  ABORT: event names unknown gate '$g'"; exit 1; }
    case "$o" in field-catch|control-only) ;; *) echo "  ABORT: unknown outcome '$o'"; exit 1 ;; esac
done || fail=1
[ "$fail" -eq 0 ] || exit 1

# EXPIRY. A gate stays alive by catching something. Age is derived from git --
# commits since the row was declared -- never typed. `never` is a declared
# terminal: an explicit claim that this gate should outlive evidence, visible in
# a diff and counted. `-` means nobody decided, and that fails.
echo "  -- expiry (a gate earns its life by catching) --"
HEADN=$(git rev-list --count HEAD 2>/dev/null || echo 0)

# yield, per gate. computed, never typed.
for g in $GATES; do
    fr=$(strip "$L/friction.tsv" | cut -f1 | grep -cx "$g")
    fc=$(strip "$L/events.tsv" | awk -F'\t' -v G="$g" '$1==G && $2=="field-catch"' | wc -l | tr -d ' ')
    exp=$(strip "$L/gates.tsv" | awk -F'\t' -v G="$g" '$1==G{print $4}')
    case "$exp" in
        '' ) echo "  ABORT: gate '$g' declares no expires_after. '-' is not a decision."; fail=1; continue ;;
        '-') echo "  ABORT: gate '$g' has expires_after='-'. Decide, or write 'never'."; fail=1; continue ;;
    esac

    # AGE. Derived from git, never typed. An UNRESOLVABLE age is not age 0 --
    # that silent coercion is exactly the vacuous-pass class, and the first
    # version of this block committed it: the lookup failed in a temp tree, age
    # became 0, `0 > 0` was false, and a gate with zero catches and
    # expires_after=0 reported healthy. Unknown must refuse, not pass.
    age=0
    if [ "$exp" != "never" ]; then
        born=$(git -C "$(dirname "$L")" log --format=%H -S"$g" -- "$(basename "$L")/gates.tsv" 2>/dev/null | tail -1)
        if [ -z "$born" ]; then
            echo "  ABORT: cannot determine age of '$g' from git. An unknown age is not"
            echo "         age zero. Run from a checkout, or declare expires_after=never."
            fail=1; continue
        fi
        age=$(git -C "$(dirname "$L")" rev-list --count "$born"..HEAD 2>/dev/null) || age=""
        [ -n "$age" ] || { echo "  ABORT: age of '$g' unresolvable"; fail=1; continue; }
    fi

    if [ "$fr" -ge 2 ] && [ "$fc" -eq 0 ]; then
        printf '  DELETION CANDIDATE  %-12s friction=%s field-catches=%s\n' "$g" "$fr" "$fc"
        fail=1
    elif [ "$exp" != "never" ] && [ "$fc" -eq 0 ] && [ "$age" -gt "$exp" ]; then
        printf '  EXPIRED             %-12s age=%s > expires_after=%s, field-catches=0\n' "$g" "$age" "$exp"
        echo   '                      Delete it, or log a field-catch it actually made.'
        fail=1
    else
        printf '  %-20s friction=%s field-catches=%s age=%s/%s\n' "$g" "$fr" "$fc" "$age" "$exp"
    fi
done
exit $fail
