#!/bin/sh
# laps.sh — how many laps until the instrument is the object.
#
#   usage: laps.sh <repo-root> [--md]
#          laps.sh --scope
#
# THE SURFACE IS ONE-SIDED, AND WE HAVE THE MEASUREMENTS
#
#   The most repeated fact in this repository is that instruments become the
#   things they check, usually within one lap:
#
#     bin/check.sh     the instrument; six times the thing found broken
#     bin/report.sh    built to stop hand-typed numbers; its own per-file regex
#                      was hole 5 living one file away
#     bin/feedback.sh  built as deletion pressure on gates; its own expiry
#                      silently coerced an unresolvable git age to zero
#     bin/ledger.sh    the field-width class was fixed here and instantiated in
#                      bin/verify.sh in the same change
#     the adjudication SuperNinja's defect was "cited artifacts were
#                      unreachable"; the pre-registration written afterwards
#                      cited five unreachable artifacts
#
#   A torus is orientable: go round and you come back on the same side, checker
#   still checker. That is not what happens. There is a half twist, and one
#   traversal swaps instrument and object.
#
#   Which means the useful question about a gate is not "who checks it" but
#   HOW MANY LAPS UNTIL IT IS THE OBJECT. This script answers it from the record.
#
# WHAT IT REPORTS, AND WHY THAT IS NOT A PASS
#
#   An instrument that has never appeared as a site is not clean. It is
#   UNEXAMINED. Reporting it as a number rather than a verdict is deliberate:
#   turning "never been the object" into a failure would make the honest move
#   (writing a new instrument) illegal, and turning it into a pass would repeat
#   the class this whole project keeps hitting.
#
# WHAT IT DOES FAIL ON
#
#   A site naming a file that does not exist. The ledger points at the corpus;
#   when the corpus moves and the ledger does not, the recurrence counts that
#   drive escalation are counting ghosts.
set -u

[ "${1:-}" = "--scope" ] && { echo "DOMAIN|laps|every *.sh in bin/, and every site row that names a path"; exit 0; }

ROOT=${1:-$(cd "$(dirname "$0")/.." && pwd)}
md=${2:-}
[ -d "$ROOT/bin" ] || { echo "laps.sh: no bin/ under $ROOT" >&2; exit 2; }
S="$ROOT/ledger/sites.tsv"
[ -f "$S" ] || { echo "laps.sh: ABORT -- $S missing" >&2; exit 2; }
TAB=$(printf '\t')
fail=0
strip() { grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null || :; }

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT INT TERM
strip "$S" > "$work/sites"

# ---- every site that names a path must name one that exists -----------------
# The site field is free-form after the path, by design ("bin/check.sh gate (b),
# name says ..."), so the path is the leading token when it looks like one.
sites_seen=0; sites_pathed=0
while IFS="$TAB" read -r _cid site _state; do
    [ -n "${site:-}" ] || continue
    sites_seen=$((sites_seen+1))
    p=$(printf '%s' "$site" | awk '{print $1}' | sed 's/[,:]$//')
    case "$p" in
      */*)
        sites_pathed=$((sites_pathed+1))
        [ -e "$ROOT/$p" ] || { echo "laps.sh: site names '$p', which does not exist under $ROOT" >&2; fail=1; } ;;
    esac
done < "$work/sites"

# ---- laps per instrument ----------------------------------------------------
instruments=0; objects=0; rows=''; virgin=''
for f in "$ROOT"/bin/*.sh; do
    [ -e "$f" ] || continue
    instruments=$((instruments+1))
    b="bin/$(basename "$f")"
    n=$(grep -cF "$b" "$work/sites" || true)
    if [ "$n" -gt 0 ]; then
        objects=$((objects+1))
        rows="${rows}| \`$b\` | $n | yes |
"
    else
        virgin="${virgin}$b "
        rows="${rows}| \`$b\` | 0 | **not yet** |
"
    fi
done

echo "SCOPE|laps|$instruments|$instruments"
[ "$fail" -eq 0 ] || exit 1

if [ "$md" = "--md" ]; then
cat <<LAPS_EOF

## Laps

The surface is one-sided. Instruments become the objects they check, and the
useful question about a gate is not who checks it but how many laps until it is
the thing being checked.

| | |
|---|---|
| Instruments in \`bin/\` | $instruments |
| Instruments that have appeared as a site | $objects |
| Never yet the object | $((instruments-objects)) |
| Site rows | $sites_seen |
| Site rows naming a path | $sites_pathed |

| instrument | times filed as a site | has come round |
|---|---|---|
$rows

An instrument that has never been the object is **not clean, it is unexamined**.
That is reported as a number and not as a verdict on purpose: failing on it would
make writing a new instrument illegal, and passing on it is the class this
project keeps hitting.

What does fail here is a site naming a path that no longer exists. The
recurrence counts drive escalation, and a count of ghosts escalates nothing.
LAPS_EOF
else
    printf '  instruments=%s have-been-objects=%s never=%s%s\n' \
        "$instruments" "$objects" "$((instruments-objects))" \
        "$([ -n "$virgin" ] && printf ' [%s]' "${virgin% }")"
fi
exit 0
