#!/bin/sh
# atlas.sh — the transition maps, and the only check here that needs no authority.
#
#   usage: atlas.sh <ledger-dir> [--md]
#          atlas.sh --scope
#
# WHAT IT DOES
#   * validates ledger/translations.tsv
#   * RUNS every roundtrip translation: back(forward(probe)) must equal probe
#   * checks every witness path exists
#   * counts connected components of the representation graph and derives the
#     number of holes from it
#   * emits its own SCOPE line, because an instrument exempt from the rule it
#     enforces is the sixth hole wearing a job title
#
# THE POINT
#   Every other gate in this repository resolves to "run it and see" -- which
#   requires a toolchain, or a kernel, or a party you trust to have run it. The
#   round trip does not. You do not need to know which convention is correct.
#   You need the loop to close. A translation failure is detectable WITHOUT
#   KNOWING WHICH SIDE IS RIGHT, and that is the only check in this project that
#   is true of.
#
#   The failure it was built from: a sweep reported a period on RP-1, a reader
#   read it as a period on R-2, and a correct figure was filed as a defect. The
#   factor of two was never wrong and nobody could see it, because the mapping
#   between the two charts existed only in someone's head. That is holonomy --
#   go around the loop of translations, come back multiplied.
#
# GENUS IS DERIVED, NOT CHOSEN
#   source and target are nodes; each row is an edge. Components are computed by
#   union-find. Each component is a set of languages that can reach each other;
#   content in one island cannot leave it. holes = components + 1, and the +1 is
#   the center that no translation removes and no refinement of the same charts
#   ever will.
#
#   The number MOVES. Add a translation joining two islands and it drops by one.
#   The shape of the surface is a fact about the atlas, not a fixed background,
#   so it is computed on every run rather than written down anywhere.
set -u

[ "${1:-}" = "--scope" ] && { echo "DOMAIN|atlas|every row of translations.tsv, and every representation named by one"; exit 0; }

dir=${1:-ledger}
md=${2:-}
[ -d "$dir" ] || { echo "atlas.sh: no such directory: $dir" >&2; exit 2; }
T="$dir/translations.tsv"
[ -f "$T" ] || { echo "atlas.sh: ABORT -- $T missing" >&2; exit 2; }
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TAB=$(printf '\t')
fail=0
strip() { grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null || :; }

rows=$(strip "$T")
[ -n "$rows" ] || { echo "atlas.sh: ABORT -- no translations. An empty atlas is not a connected one." >&2; exit 1; }

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT INT TERM
printf '%s\n' "$rows" > "$work/rows"

seen=0; checked=0; n_round=0; n_witness=0
: > "$work/edges"

while IFS="$TAB" read -r id src tgt pres loses method spec; do
    [ -n "${id:-}" ] || continue
    seen=$((seen+1))

    ok=1
    for f in "$id" "$src" "$tgt" "$pres" "$loses" "$method" "$spec"; do
        [ "$f" = "-" ] && { echo "atlas.sh: '$id' has a '-' field. Two legal methods, and 'nobody looked' is not one." >&2; fail=1; ok=0; break; }
        [ -z "$f" ]    && { echo "atlas.sh: '$id' has an empty field." >&2; fail=1; ok=0; break; }
    done
    [ "$ok" -eq 1 ] || continue

    [ "$src" = "$tgt" ] && { echo "atlas.sh: '$id' translates '$src' to itself. That is not a transition map." >&2; fail=1; continue; }

    case "$method" in
      roundtrip)
        n_round=$((n_round+1))
        fwd=$(printf '%s' "$spec" | cut -d'|' -f1)
        bak=$(printf '%s' "$spec" | cut -d'|' -f2)
        probe=$(printf '%s' "$spec" | cut -d'|' -f3)
        if [ -z "$fwd" ] || [ -z "$bak" ] || [ -z "$probe" ]; then
            echo "atlas.sh: '$id' method=roundtrip but spec is not forward|back|probe: '$spec'" >&2; fail=1; continue
        fi
        # THE CHECK. Two awk evaluations, no shell eval, no toolchain, no
        # trusted party. If back(forward(probe)) is not probe, the loop does not
        # close and one of the two directions is lying about the other.
        mid=$(awk -v x="$probe" "BEGIN{printf \"%.10g\", $fwd}" 2>/dev/null) || mid=''
        [ -n "$mid" ] || { echo "atlas.sh: '$id' forward expression did not evaluate: '$fwd'" >&2; fail=1; continue; }
        out=$(awk -v x="$mid" "BEGIN{printf \"%.10g\", $bak}" 2>/dev/null) || out=''
        [ -n "$out" ] || { echo "atlas.sh: '$id' back expression did not evaluate: '$bak'" >&2; fail=1; continue; }
        same=$(awk -v a="$out" -v b="$probe" 'BEGIN{print (a-b < 1e-9 && b-a < 1e-9) ? "y" : "n"}')
        if [ "$same" != "y" ]; then
            echo "atlas.sh: '$id' ROUND TRIP DOES NOT CLOSE" >&2
            echo "    probe=$probe  --($fwd)-->  $mid  --($bak)-->  $out" >&2
            echo "    The two directions disagree. No adjudicator is needed to see it." >&2
            fail=1; continue
        fi
        ;;
      witness)
        n_witness=$((n_witness+1))
        if [ ! -e "$ROOT/$spec" ]; then
            echo "atlas.sh: '$id' method=witness names '$spec', which does not exist." >&2
            echo "    A translation whose witness is unreachable is the defect this project" >&2
            echo "    adjudicated in someone else's work and then committed in its own." >&2
            fail=1; continue
        fi
        ;;
      *)
        echo "atlas.sh: '$id' has method '$method'. Legal: roundtrip, witness." >&2; fail=1; continue ;;
    esac

    checked=$((checked+1))
    printf '%s\t%s\n' "$src" "$tgt" >> "$work/edges"
done < "$work/rows"

# ---- components, by union-find over the edge list ---------------------------
# Not a heuristic and not a count of anything typed: the graph is the file.
comp=$(awk -F"$TAB" '
  function find(a,  r){ r=a; while (p[r]!=r) r=p[r]; while (p[a]!=r){ t=p[a]; p[a]=r; a=t } return r }
  function add(a){ if (!(a in p)) { p[a]=a; n++ } }
  { add($1); add($2); ra=find($1); rb=find($2); if (ra!=rb) { p[ra]=rb; n-- } }
  END { print n+0 }
' "$work/edges")

nodes=$(awk -F"$TAB" '{print $1"\n"$2}' "$work/edges" | sort -u | grep -c . || true)
holes=$((comp+1))

echo "SCOPE|atlas|$seen|$checked"
if [ "$seen" -ne "$checked" ]; then
    echo "atlas.sh: scope mismatch -- $seen rows read, $checked validated." >&2
    fail=1
fi
[ "$fail" -eq 0 ] || exit 1

if [ "$md" = "--md" ]; then
cat <<ATLAS_EOF

## Atlas

Representations are charts. This section is the transition maps between them,
and it is the only check here that needs no authority: a round trip that does
not close is visible **without knowing which side is right**.

| | |
|---|---|
| Translations | $seen |
| Checked by round trip | $n_round |
| Checked by witness only | $n_witness |
| Representations | $nodes |
| Connected components | $comp |
| Holes (components + the center) | $holes |

The genus is computed, not chosen. Each component is a set of languages that can
reach each other; content in one island cannot leave it. Add a translation
joining two islands and the count drops. The \`+1\` is the center that no
translation removes -- see \`ledger/absences.tsv\`, which refuses to enumerate it.

Round trip is the strong form and witness is the weak one, counted separately so
the atlas reports its own honesty ratio instead of averaging it away.
ATLAS_EOF
else
    printf '  translations=%s roundtrip=%s witness=%s representations=%s components=%s holes=%s\n' \
        "$seen" "$n_round" "$n_witness" "$nodes" "$comp" "$holes"
fi
exit 0
