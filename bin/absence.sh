#!/bin/sh
# absence.sh — two of the three absences are rows. The third is refused.
#
#   usage: absence.sh <ledger-dir> [--md]
#          absence.sh --scope
#
# THE THREE ABSENCES BEHAVED DIFFERENTLY, MEASURABLY, IN ONE AFTERNOON:
#
#   unknown     Whether any irrational-density word is uniquely extremal. Open,
#               searchable, a bigger computer helps. The key is the search.
#
#   excluded    Cone.lean cannot witness its own axiom-freedom. The file is not
#               wrong and the world is not missing anything: the CHART cannot
#               express it, and another chart (the census output) can. The key
#               names that chart.
#
#   structural  REFUSED. Every one of the six holes in bin/check.sh was a filter
#               invisible in its own output. Not one of them could have been
#               written here before it was found, and the moment it was found it
#               stopped being this kind and became a fixed defect. A registry of
#               structural absences is a registry of the ones we happened to
#               find, which is precisely the shape of the five regexes -- each
#               closed the hole it could see, and the next one was invisible for
#               the same reason the last one had been.
#
#               Naming the center fills it. Filling it requires another hole.
#
# WHAT THE THIRD KIND GETS INSTEAD
#   A count of the complement. bin/check.sh does not name what its census
#   excluded; it reports how many things it excluded, and requires that number
#   to agree with the number that arrived. bin/center.sh does the same one level
#   up, over the instrument set. Neither removes the blind spot. Both make a
#   disagreement visible from inside, which is the most any of this can do.
#
#   The center is un-fillable but measurable. Count the complement, never name it.
set -u

[ "${1:-}" = "--scope" ] && { echo "DOMAIN|absence|every row of absences.tsv"; exit 0; }

dir=${1:-ledger}
md=${2:-}
[ -d "$dir" ] || { echo "absence.sh: no such directory: $dir" >&2; exit 2; }
A="$dir/absences.tsv"
[ -f "$A" ] || { echo "absence.sh: ABORT -- $A missing" >&2; exit 2; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TAB=$(printf '\t')
fail=0
strip() { grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null || :; }

rows=$(strip "$A")
[ -n "$rows" ] || { echo "absence.sh: ABORT -- no rows. An empty absence table is a claim that nothing is missing." >&2; exit 1; }

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT INT TERM
printf '%s\n' "$rows" > "$work/rows"

seen=0; checked=0; n_unknown=0; n_excluded=0
while IFS="$TAB" read -r id kind site key; do
    [ -n "${id:-}" ] || continue
    seen=$((seen+1))

    for f in "$id" "$kind" "$site" "$key"; do
        [ "$f" = "-" ] || [ -z "$f" ] && { echo "absence.sh: '$id' has an empty or '-' field." >&2; fail=1; continue 2; }
    done

    case "$kind" in
      structural)
        echo "absence.sh: '$id' declares kind=structural. REFUSED." >&2
        echo "    A named instance of the structurally-unavailable is a category error." >&2
        echo "    If you can write the row, it is not that kind; and if it is that kind," >&2
        echo "    no row could have existed before it stopped being that kind." >&2
        echo "    What this kind gets is a counted complement, not an entry." >&2
        fail=1; continue ;;
      unknown)
        n_unknown=$((n_unknown+1))
        # The key must be a SEARCH, not a restatement. Mechanically: it must not
        # simply repeat the site, and it must contain something to run or sweep.
        [ "$key" = "$site" ] && { echo "absence.sh: '$id' key restates its site. A key is a search that would answer it." >&2; fail=1; continue; }
        ;;
      excluded)
        n_excluded=$((n_excluded+1))
        # The key must name the representation that WOULD express it. If it
        # cannot, the absence is not excluded-by-representation, it is unknown.
        [ "$key" = "$site" ] && { echo "absence.sh: '$id' key restates its site. A key names the chart that would express it." >&2; fail=1; continue; }
        ;;
      *)
        echo "absence.sh: '$id' has kind '$kind'. Legal: unknown, excluded. Refused: structural." >&2
        fail=1; continue ;;
    esac

    # The site must exist. An absence filed against nothing is not an absence.
    case "$site" in
      */) [ -d "$ROOT/${site%/}" ] || { echo "absence.sh: '$id' names directory '$site', which does not exist." >&2; fail=1; continue; } ;;
      *)  [ -e "$ROOT/$site" ]     || { echo "absence.sh: '$id' names '$site', which does not exist." >&2; fail=1; continue; } ;;
    esac

    checked=$((checked+1))
done < "$work/rows"

echo "SCOPE|absence|$seen|$checked"
if [ "$seen" -ne "$checked" ]; then
    echo "absence.sh: scope mismatch -- $seen rows read, $checked validated." >&2
    fail=1
fi
[ "$fail" -eq 0 ] || exit 1

if [ "$md" = "--md" ]; then
cat <<ABS_EOF

## Absences

Three kinds, and only two of them are rows.

| kind | count | what it means |
|---|---|---|
| \`unknown\` | $n_unknown | askable and answerable; the key is the search |
| \`excluded\` | $n_excluded | this chart cannot express it; the key names one that can |
| \`structural\` | refused | a named instance is a category error |

The third kind is not absent from this table by oversight. \`bin/absence.sh\`
rejects any row claiming it. Every one of the six holes in \`bin/check.sh\` was a
filter invisible in its own output; none could have been written down before it
was found, and each stopped being that kind the moment it was. A registry of
structural absences is a registry of the ones we happened to find.

What it gets instead is a counted complement -- the \`SCOPE\` line in
\`bin/check.sh\`, and the registration sweep in \`bin/center.sh\`. Neither removes
the blind spot. Both make a disagreement visible from inside.
ABS_EOF
else
    printf '  absences=%s unknown=%s excluded=%s structural=refused\n' "$seen" "$n_unknown" "$n_excluded"
fi
exit 0
