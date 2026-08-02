#!/bin/sh
# center.sh — the empty center, and the complement count one level up.
#
#   usage: center.sh <repo-root> [--md]
#          center.sh --scope
#
# TWO THINGS, AND THEY ARE THE SAME THING
#
# 1. THE REGISTRATION SWEEP.
#    Every *.sh in bin/ is asked `--scope`. It must answer one of exactly two
#    ways:
#       DOMAIN|<name>|<what it enumerates>   exit 0   -- an enumerator
#       (nothing)                            exit 3   -- declares it enumerates
#                                                        nothing
#    Anything else is an UNREGISTERED INSTRUMENT and the build goes red.
#
#    This is bin/check.sh's SCOPE gate applied to the instrument set instead of
#    to a declaration list. The census could not see what the census excluded;
#    neither can this, and it does not claim to. What it can do is count what it
#    swept and require that count to equal what the directory holds. A future
#    instrument cannot hide in a sweep that reports its own complement -- not
#    because the sweep got smarter, but because the enumeration is the
#    filesystem and the disagreement is what is printed.
#
# 2. THE CENTER ITSELF.
#    center/ must stay empty. Its size is zero forever; the measurable thing is
#    its DEGREE -- how many instruments report a domain into it. If an instrument
#    stops reporting, an edge disappears and the degree drops.
#
#    center/EMPTY is a zero-byte file that exists because GIT CANNOT REPRESENT
#    AN EMPTY DIRECTORY. That is not a workaround, it is a kind-2 absence in the
#    storage medium of the thing being stored, and it is filed as one:
#    ledger/absences.tsv, a:emptydir. The representation cannot express emptiness
#    without adding content to it. The file has a name, and a name is content,
#    and that is as close to nothing as this medium goes.
#
#    Nothing is ever written there. It is never uninformative.
#
# WHY NOT A REGISTRY OF WHAT THE CENTER CONTAINS
#   Because the moment it has contents it is a jurisdiction, and somebody is its
#   director. See ledger/absences.tsv, which refuses kind=structural for the
#   same reason.
set -u

[ "${1:-}" = "--scope" ] && { echo "DOMAIN|center|every *.sh in bin/, and the contents of center/"; exit 0; }

ROOT=${1:-$(cd "$(dirname "$0")/.." && pwd)}
md=${2:-}
[ -d "$ROOT/bin" ] || { echo "center.sh: no bin/ under $ROOT" >&2; exit 2; }
fail=0

# ---- 1. the registration sweep ---------------------------------------------
present=0; registered=0; enumerators=0; silent=0; rows=''
for f in "$ROOT"/bin/*.sh; do
    [ -e "$f" ] || continue
    present=$((present+1))
    b=$(basename "$f")
    out=$(sh "$f" --scope 2>/dev/null); rc=$?
    case "$rc" in
      0)
        if printf '%s' "$out" | grep -q '^DOMAIN|'; then
            registered=$((registered+1)); enumerators=$((enumerators+1))
            what=$(printf '%s' "$out" | sed -n 's/^DOMAIN|[^|]*|//p' | head -1)
            rows="${rows}| \`bin/$b\` | enumerates | $what |
"
        else
            echo "center.sh: bin/$b answered --scope with exit 0 and no DOMAIN line." >&2
            echo "           An instrument that neither declares a domain nor declares it has" >&2
            echo "           none is unregistered, and unregistered is how the last six got in." >&2
            fail=1
        fi ;;
      3)
        registered=$((registered+1)); silent=$((silent+1))
        rows="${rows}| \`bin/$b\` | enumerates nothing | - |
" ;;
      *)
        echo "center.sh: bin/$b does not answer --scope (exit $rc). UNREGISTERED INSTRUMENT." >&2
        echo "           Add one of the two handlers at the top of the file. There is no third." >&2
        fail=1 ;;
    esac
done

# THE COMPLEMENT. Printed on every run, pass or fail, because a sweep that
# reports only its findings cannot say how much of the directory it reached.
echo "SCOPE|center|$present|$registered"
if [ "$present" -ne "$registered" ]; then
    echo "center.sh: scope mismatch -- $present instruments present, $registered registered." >&2
    fail=1
fi

# ---- 2. the center is empty -------------------------------------------------
C="$ROOT/center"
if [ ! -d "$C" ]; then
    echo "center.sh: center/ does not exist. The map must carry the hole it cannot fill." >&2
    fail=1
else
    entries=$(ls -A "$C" | sort)
    if [ "$entries" != "EMPTY" ]; then
        echo "center.sh: center/ holds something other than EMPTY:" >&2
        printf '%s\n' "$entries" | sed 's/^/    /' >&2
        echo "           The center is not storage. Whatever this is, it belongs on the surface." >&2
        fail=1
    elif [ -s "$C/EMPTY" ]; then
        echo "center.sh: center/EMPTY is not empty ($(wc -c < "$C/EMPTY") bytes)." >&2
        echo "           It exists only because git cannot represent an empty directory." >&2
        echo "           See ledger/absences.tsv, a:emptydir. Do not fill it." >&2
        fail=1
    fi
fi

[ "$fail" -eq 0 ] || exit 1

if [ "$md" = "--md" ]; then
cat <<CENTER_EOF

## Center

\`center/\` is empty and stays empty. Its size is zero; the measurable thing is
its **degree** -- how many instruments report a domain into it. If an instrument
stops reporting, an edge disappears and this number drops.

| | |
|---|---|
| Instruments swept | $present |
| Registered | $registered |
| Declaring a domain (degree) | $enumerators |
| Declaring they enumerate nothing | $silent |
| Bytes in \`center/\` | 0 |

| instrument | answer to \`--scope\` | domain |
|---|---|---|
$rows

\`center/EMPTY\` is a zero-byte file that exists because **git cannot represent
an empty directory**. That is not a workaround; it is an absence excluded by the
storage medium of the thing being stored, and it is filed as one
(\`ledger/absences.tsv\`, \`a:emptydir\`). The representation cannot express
emptiness without adding content to it. The file has a name, and a name is
content.

The sweep does not remove the blind spot and does not claim to. It counts what
it reached and requires that count to equal what the directory holds, so an
instrument cannot arrive unregistered -- not because the sweep got smarter, but
because the enumeration is the filesystem.
CENTER_EOF
else
    printf '  swept=%s registered=%s degree=%s silent=%s center=empty\n' \
        "$present" "$registered" "$enumerators" "$silent"
fi
exit 0
