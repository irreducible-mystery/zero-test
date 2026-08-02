#!/bin/sh

[ "${1:-}" = "--scope" ] && { echo "DOMAIN|probes|every *.lean and *.expect in the named probe directory"; exit 0; }
# probes.sh — run every negative control and check WHY it failed, not that it did.
#
#   usage: probes.sh <probes-dir>
#   emits: one STATE.md table row per probe, on stdout
#   exits: non-zero, loudly, on any violation
#
# WHY THIS FILE EXISTS
#
#   verify.sh check 2 is named "every probe MUST be rejected". What it actually
#   asserted was "every file in probes/ exits non-zero". Those came apart, and
#   the gap is exploitable:
#
#     Replace unicode_probe.lean -- the negative control for hole #5, the one
#     that let `False` through -- with a plain-ASCII planted axiom. It still
#     compiles, still exits non-zero, still prints "rejected PASS". No Greek
#     identifier is tested anywhere in the tree any more. STATE.md regenerates
#     BYTE-IDENTICALLY, because the filename and the exit code did not change.
#     verify.sh exits 0 and prints ALL GATES PASS.
#
#   The defense can be removed while the gate reports it active. A cruder
#   substitution (a syntax error) happens to be caught, but by check 3, not by
#   check 2 -- a non-compiling file changes lean's exit code in STATE.md's
#   second table. That is accidental coverage, and relying on it is how the real
#   version above stayed invisible.
#
#   This is the class "a gate asserts a weaker property than its name", and it
#   is more dangerous than a missing gate, because the NAME is what everyone
#   downstream reasons with.
#
# THE FIX IS TYPE-1: the exit code stops being the assertion.
#
#   Each probe declares, in a sidecar `<name>.expect`, the failure signature it
#   is claiming to produce. The gate checks the signature. An exit code is a
#   single bit and every wrong answer has one; a signature names the thing the
#   probe exists to pin, so a probe that pins something else no longer passes as
#   the probe it replaced.
#
#   Three further properties, each closing a way to satisfy this vacuously:
#
#     * A probe with no `.expect`, or an empty one, ABORTS. A probe that
#       declares nothing asserts nothing.
#     * An `.expect` with no corresponding `.lean` ABORTS. Deleting a probe body
#       and leaving its declaration is the same substitution by another route.
#     * A signature that is ALSO satisfied by a different probe's output ABORTS.
#       This is the one that stops the fix from acquiring the disease it cures:
#       without it, an `.expect` containing something generic would pass for
#       anything, and the gate would again assert less than its name.
#
#   Note what is NOT here: no rule that a probe must compile. A probe pinning
#   check.sh's own ABORT-on-malformed-input path is legitimate; it just has to
#   say so in its `.expect`, where a reader and a diff can see it.

set -u

dir=${1:-probes}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
CHECK="$ROOT/bin/check.sh"
[ -d "$dir" ] || { echo "probes.sh: no such directory: $dir" >&2; exit 2; }
[ -f "$CHECK" ] || { echo "probes.sh: cannot find bin/check.sh" >&2; exit 2; }
command -v lean >/dev/null 2>&1 || { echo "probes.sh: no lean on PATH" >&2; exit 2; }

lean_files=$(find "$dir" -name '*.lean' | sort)
exp_files=$(find "$dir" -name '*.expect' | sort)

# Vacuous pass, the class this project has hit three times. A gate with no
# negative control is not a gate, and an empty probe set is that.
if [ -z "$lean_files" ]; then
    echo "probes.sh: ABORT -- no probes under $dir. A gate with no negative control is not a gate." >&2
    exit 1
fi

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT INT TERM
fail=0; rows=''

# ---- orphan declarations --------------------------------------------------
for e in $exp_files; do
    if [ ! -f "${e%.expect}.lean" ]; then
        echo "probes.sh: ABORT -- $(basename "$e") declares a signature but its .lean is gone." >&2
        echo "  A declared probe with no body is a defense that reports itself active." >&2
        fail=1
    fi
done

# ---- run each probe, check its declared signature -------------------------
for p in $lean_files; do
    b=$(basename "$p"); stem=${b%.lean}
    exp="$dir/$stem.expect"

    if [ ! -f "$exp" ]; then
        echo "probes.sh: ABORT -- $b has no $stem.expect. A probe that declares nothing asserts nothing." >&2
        fail=1; continue
    fi
    # Comments and blanks are not assertions.
    grep -vE '^[[:space:]]*(#|$)' "$exp" > "$work/$stem.sig" 2>/dev/null || :
    if [ ! -s "$work/$stem.sig" ]; then
        echo "probes.sh: ABORT -- $stem.expect declares no signature lines (comments only)." >&2
        fail=1; continue
    fi

    d=$(mktemp -d); cp "$p" "$d/"; cp "$CHECK" "$d/"
    ( cd "$d" && sh check.sh >"$work/$stem.out" 2>&1 ); rc=$?
    rm -rf "$d"

    # Necessary but not sufficient -- kept, because a probe that passes
    # check.sh is a broken gate regardless of what it prints.
    if [ "$rc" -eq 0 ]; then
        printf '   %-24s ACCEPTED (exit 0)   FAIL -- the gate is broken\n' "$b" >&2
        rows="${rows}| \`$b\` | $rc | **ESCAPED** | n/a |
"
        fail=1; continue
    fi

    missing=''
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        grep -Fq -- "$line" "$work/$stem.out" || missing="${missing}${line}
"
    done < "$work/$stem.sig"

    if [ -n "$missing" ]; then
        printf '   %-24s rejected (exit %s) but SIGNATURE MISMATCH  FAIL\n' "$b" "$rc" >&2
        echo "     $b failed, but not for the reason it exists. Not present in its output:" >&2
        printf '%s' "$missing" | sed 's/^/       /' >&2
        echo "     A probe that fails for the wrong reason is not testing what its name claims." >&2
        rows="${rows}| \`$b\` | $rc | CAUGHT | **MISMATCH** |
"
        fail=1; continue
    fi

    printf '   %-24s rejected (exit %s), signature matched  PASS\n' "$b" "$rc" >&2
    rows="${rows}| \`$b\` | $rc | CAUGHT | matched |
"
done

# ---- signatures must discriminate -----------------------------------------
# Without this, `.expect` could contain something every probe prints, and this
# gate would assert less than its name -- the exact class it was built to close.
for p in $lean_files; do
    b=$(basename "$p"); stem=${b%.lean}
    [ -s "$work/$stem.sig" ] || continue
    for q in $lean_files; do
        ob=$(basename "$q"); ostem=${ob%.lean}
        [ "$stem" = "$ostem" ] && continue
        [ -f "$work/$ostem.out" ] || continue
        all=1
        while IFS= read -r line; do
            [ -n "$line" ] || continue
            grep -Fq -- "$line" "$work/$ostem.out" || { all=0; break; }
        done < "$work/$stem.sig"
        if [ "$all" -eq 1 ]; then
            echo "probes.sh: ABORT -- $stem.expect is not discriminating: it is also satisfied" >&2
            echo "  in full by $ob's output. A signature that matches another probe does not" >&2
            echo "  pin this probe's failure mode." >&2
            fail=1
        fi
    done
done

printf '%s' "$rows"
exit $fail
