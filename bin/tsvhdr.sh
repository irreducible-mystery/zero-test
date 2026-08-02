#!/bin/sh
# tsvhdr.sh — read a TSV's schema out of its own header row.
#
#   usage: tsvhdr.sh <file>           -> "<n-columns> <name> <name> ..."
#          tsvhdr.sh <file> <name>    -> the 1-based index of <name>
#   exits: non-zero, with a reason on stderr, if the file has no header row or
#          declares no such column
#
# WHY THIS FILE EXISTS
#
#   `ledger/gates.tsv` grew a fourth column. `bin/ledger.sh` had the literal 3
#   in it and started rejecting the real ledger; replacing that literal with a
#   per-file 4 broke `bin/verify.sh`'s fixtures instead. Two consumers, two
#   consecutive breakages, one cause: the shape of a file restated inside the
#   code that reads it. Restated shapes drift, and they drift silently, because
#   nothing compares the copy to the original.
#
#   So it is not restated. The header row IS the schema and readers ask it.
#   A consumer holding a column count or a column index can disagree with the
#   file; a consumer that asks cannot. Adding a column is now a one-line change
#   to the data file, which is what it should have been the first time.
#
# WHY THE HEADER IS REQUIRED RATHER THAN INFERRED
#
#   Taking the shape from the first data row would make a truncated file
#   self-consistent: every row agrees with every other row and the missing
#   column is invisible. That is the vacuous pass this repo keeps re-finding,
#   so a file that does not declare its columns is refused, not guessed at.
#
# WHAT THIS DOES NOT DO
#
#   It does not make a reader read by name. A reader that asks for a count and
#   then indexes positionally is still assuming an order; `bin/ledger.sh` does
#   exactly that and therefore also asserts the header's leading names. Asking
#   is necessary, not sufficient.
#
# CONTROLLED BY: verify.sh check 8 (missing header, reordered column, appended
# column) and check 10 (a by-name lookup whose column has been renamed). Both
# drive it through the real consumers rather than against a copy of this logic,
# for the reason check 5 gives: a probe against a copy tests the copy.

set -u

f=${1:?usage: tsvhdr.sh <file> [column-name]}
[ -f "$f" ] || { echo "tsvhdr.sh: no such file: $f" >&2; exit 1; }

awk -F'\t' -v want="${2-}" -v nm="$f" '
    NR == 1 {
        if ($0 !~ /^#/) {
            print "tsvhdr.sh: " nm " has no header row declaring its columns." > "/dev/stderr"
            exit 1
        }
        sub(/^# */, "")
        if (NF == 0 || $1 == "") {
            print "tsvhdr.sh: " nm " header row names no columns." > "/dev/stderr"
            exit 1
        }
        if (want == "") {
            out = NF
            for (i = 1; i <= NF; i++) out = out " " $i
            print out
            exit 0
        }
        for (i = 1; i <= NF; i++) if ($i == want) { print i; exit 0 }
        print "tsvhdr.sh: " nm " header declares no column named \"" want "\"." > "/dev/stderr"
        exit 1
    }
    END {
        if (NR == 0) {
            print "tsvhdr.sh: " nm " is empty; it declares no columns." > "/dev/stderr"
            exit 1
        }
    }
' "$f"
