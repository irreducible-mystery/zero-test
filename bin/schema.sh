#!/bin/sh
# schema.sh — every ledger table's shape, asserted from one declaration.
#
#   usage: schema.sh <ledger-dir>            validate every table
#          schema.sh <ledger-dir> --cols F   print the declared column count of F
#          schema.sh --scope                 declare what this instrument enumerates
#
# WHY THIS EXISTS
#
#   gates.tsv grew a fourth column. Four things knew the width, one was updated:
#     bin/feedback.sh   taught the new width
#     bin/ledger.sh     asserted NF!=3 and rejected every committed gates row
#     bin/verify.sh     fixtures wrote 3-field gates rows, so fixing ledger.sh
#                       broke the POSITIVE control in check 8
#     gates.tsv itself  header comment named 3 columns above 4 of data
#
#   Four sites. The third was created by the fix to the second, in the same
#   change, by the same author. The class is not "someone forgot"; the class is
#   that a width written in four places will disagree with itself.
#
#   So it is written once, in ledger/SCHEMA.tsv, and read here.
#
# THE COMPLEMENT IS COUNTED, NOT ASSUMED
#
#   Declared tables are checked against the directory, and the directory is
#   checked against the declarations. A .tsv with no SCHEMA row fails; a SCHEMA
#   row with no .tsv fails. A registry that only validates what it lists cannot
#   see what it omitted -- that is hole 6's shape (a filter invisible in its own
#   output), and the fix is the same one: report both counts and require them to
#   agree.
set -u

[ "${1:-}" = "--scope" ] && { echo "DOMAIN|schema|every *.tsv in the ledger directory"; exit 0; }

dir=${1:-ledger}
[ -d "$dir" ] || { echo "schema.sh: no such directory: $dir" >&2; exit 2; }
SCHEMA="$dir/SCHEMA.tsv"
[ -f "$SCHEMA" ] || { echo "schema.sh: ABORT -- $SCHEMA missing. Nothing declares any width." >&2; exit 2; }
TAB=$(printf '\t')
fail=0
strip() { grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null || :; }

# --cols: the accessor. verify.sh builds fixtures through this, so a fixture
# cannot be the wrong width unless the declaration is, and then everything
# fails together instead of one thing failing quietly.
if [ "${2:-}" = "--cols" ]; then
    want=$(strip "$SCHEMA" | awk -F"$TAB" -v f="${3:-}" '$1==f{print $2; found=1} END{exit !found}') \
        || { echo "schema.sh: no schema row for '${3:-}'" >&2; exit 1; }
    echo "$want"; exit 0
fi

declared=0; present=0; matched=0

# ---- declarations -> files -------------------------------------------------
while IFS="$TAB" read -r file ncols cols; do
    [ -n "${file:-}" ] || continue
    declared=$((declared+1))
    f="$dir/$file"
    if [ ! -f "$f" ]; then
        echo "schema.sh: SCHEMA declares '$file' and no such file exists" >&2; fail=1; continue
    fi
    matched=$((matched+1))

    # The header comment is DATA that describes data, so it drifts like data.
    # It is checked, not trusted. This is the fourth site of the class above.
    want_hdr="# $(printf '%s' "$cols" | tr ',' "$TAB")"
    got_hdr=$(head -1 "$f")
    if [ "$got_hdr" != "$want_hdr" ]; then
        echo "schema.sh: $file header does not match its schema" >&2
        echo "    declared: $(printf '%s' "$want_hdr" | cat -A | sed 's/\$$//')" >&2
        echo "    found:    $(printf '%s' "$got_hdr"  | cat -A | sed 's/\$$//')" >&2
        fail=1
    fi

    bad=$(strip "$f" | awk -F"$TAB" -v n="$ncols" -v F="$file" \
            'NF != n { print "    "F" line "FNR": expected "n" fields, found "NF }')
    [ -n "$bad" ] && { echo "schema.sh: $file has rows of the wrong width" >&2; printf '%s\n' "$bad" >&2; fail=1; }

    # An empty table is not a clean table. This project reported a vacuous pass
    # five separate times before the rule was mechanical.
    [ -s "$dir/.probe" ] && rm -f "$dir/.probe"
    if [ -z "$(strip "$f")" ]; then
        echo "schema.sh: $file has no data rows. An empty table is not a clean one." >&2; fail=1
    fi
done <<EOF
$(strip "$SCHEMA")
EOF

# ---- files -> declarations (THE COMPLEMENT) --------------------------------
for f in "$dir"/*.tsv; do
    [ -e "$f" ] || continue
    present=$((present+1))
    b=$(basename "$f")
    strip "$SCHEMA" | cut -f1 | grep -qxF "$b" || {
        echo "schema.sh: $b exists in $dir/ and SCHEMA.tsv does not declare it." >&2
        echo "           A registry that validates only what it lists cannot see what it omitted." >&2
        fail=1; }
done

# Reported whether or not anything failed, because the number IS the gate. A
# validator that prints only on failure gives a clean run no way to say how
# much it looked at.
echo "SCOPE|schema|$present|$matched"
if [ "$present" -ne "$declared" ] || [ "$declared" -ne "$matched" ]; then
    echo "schema.sh: scope mismatch -- $present tables present, $declared declared, $matched resolved." >&2
    fail=1
fi
exit $fail
