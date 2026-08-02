#!/bin/sh

[ "${1:-}" = "--scope" ] && { echo "DOMAIN|check|every *.lean in the working directory, and every declaration Lean added from it"; exit 0; }
# check.sh — soundness census over EVERY declaration in a Lean file.
#
# HOW THE DECLARATION LIST IS OBTAINED, AND WHY IT CHANGED
#
#   Earlier versions extracted declaration names with an awk regex over the
#   source text. Every version of that regex was wrong, and each was found by
#   planting something false rather than by running it on files that pass:
#
#     1. it read only the `#print axioms` lines the author had written by hand
#        -- 45 of 66 declarations, while the docs claimed "every declaration"
#     2. it matched only `theorem|lemma`, so a `sorry` inside a `def` that no
#        theorem depended on was invisible
#     3. it used a DENYLIST of bad axioms, so a planted `axiom cheat : 0 = 1`
#        and a theorem proving `2 + 2 = 5` from it passed clean
#     4. its allowlist parser required `[` and `]` on the same line, and lean
#        WRAPS long axiom lists, so wrapped lists parsed as empty
#     5. it anchored on `[A-Za-z_]`, which is ASCII. Greek identifiers are
#        ordinary style in Lean mathematics, so `axiom δcheat : 0 = 1` and
#        `theorem δfalse : False` were invisible -- the census reported
#        "4 declarations, 4 audited" on a file with 7, and passed.
#
#   Five regexes, five holes. The regex was not the bug; parsing source text to
#   discover declarations is the bug. Nobody writing a regex can enumerate the
#   identifiers a future author may legally use.
#
#   So the list is no longer parsed. It is ASKED FOR. The census probe imports
#   Lean, appends the file, and walks `env.constants.map₂` -- the declarations
#   this module actually added -- calling `CollectAxioms.collect` on each. The
#   answer comes from the same elaborator that accepted the file.
#
#     6. that claim used to read "there is no identifier it can spell that this
#        cannot see", and it was false. The walk carried `unless n.isInternal do`,
#        and Name.isInternal is true of any name whose last component begins with
#        `_`. A planted `axiom _cheat` and a `theorem _false : False` censused as
#        "1 declarations, 1 audited, axioms within allowlist" and the gate exited
#        0 with a proof of False in the corpus. Asking the elaborator for the list
#        does not help if you then filter the answer.
#
#   Six holes, and the sixth is the fifth wearing a different alphabet. So the
#   census no longer claims completeness -- it MEASURES it. See the SCOPE gate.
#
# TWO INDEPENDENT GATES, because one gate is one point of failure:
#   (a) the axiom census below, ALLOWLIST not denylist
#   (b) a separate check on lean's own `uses 'sorry'` warning, which does not
#       depend on the census working at all
#
# NOTE: `lean f.lean; echo $?` returns 0 for a file full of `sorry`, and 0 for a
# file with a planted false axiom. Exit status is not a gate and never was.

set -u
command -v lean >/dev/null 2>&1 || { echo "no lean on PATH"; exit 2; }
fail=0

# Permitted axioms; anything else fails. An axiom nobody thought to name cannot
# pass an allowlist, which is the entire point of it being one.
ALLOW='propext|Classical\.choice|Quot\.sound'

echo "=== compile ==="
for f in *.lean; do
    [ -e "$f" ] || continue
    out=$(lean "$f" 2>&1)
    rc=$?
    # GATE (b): independent of the census below.
    sw=$(printf '%s' "$out" | grep -c "uses 'sorry'")
    printf '  %-24s EXIT=%s  sorry-warnings=%s\n' "$f" "$rc" "$sw"
    [ "$rc" -eq 0 ] || fail=1
    [ "$sw" -eq 0 ] || { echo "    ABORT: $f contains a declaration using 'sorry'"; fail=1; }
done

echo
echo "=== axiom census, enumerated by Lean itself over every declaration ==="
tot=0; aud=0
for f in *.lean; do
    [ -e "$f" ] || continue
    probe=$(mktemp /tmp/gapcensus.XXXXXX.lean)
    {
        echo 'import Lean'
        # a corpus file may carry its own imports; they must precede everything.
        grep -E '^[[:space:]]*import[[:space:]]' "$f" 2>/dev/null
        grep -vE '^[[:space:]]*import[[:space:]]' "$f"
        echo
        echo 'open Lean Elab Command in'
        echo 'run_cmd do'
        echo '  let env ← getEnv'
        echo '  let mut seen := 0'
        echo '  let mut audited := 0'
        echo '  for (n, _) in env.constants.map₂.toList do'
        echo '    seen := seen + 1'
        echo '    audited := audited + 1'
        echo '    let (_, s) := ((CollectAxioms.collect n).run env).run {}'
        echo '    logInfo s!"CENSUS|{n}|{s.axioms.toList.map toString}"'
        # The COMPLEMENT, reported by the same elaborator that produced the list.
        # A filter is invisible in its own output; a count of what it excluded is
        # not. See the SCOPE gate below.
        echo '  logInfo s!"SCOPE|{seen}|{audited}"'
    } > "$probe"
    out=$(lean "$probe" 2>&1); prc=$?
    rm -f "$probe"

    if [ "$prc" -ne 0 ]; then
        echo "  ABORT: census probe for $f did not compile - NO CENSUS TAKEN"
        printf '%s\n' "$out" | grep 'error:' | head -3 | sed 's/^/    /'
        fail=1; continue
    fi

    lines=$(printf '%s\n' "$out" | grep '^CENSUS|')
    n=$(printf '%s\n' "$lines" | grep -c '^CENSUS|')
    if [ "$n" -eq 0 ]; then
        echo "  ABORT: $f yielded no declarations - refusing to report a vacuous pass"
        fail=1; continue
    fi

    # THE SCOPE GATE. Three counts that must agree: what Lean saw, what Lean
    # audited, and what actually arrived here as CENSUS lines. Any filter placed
    # between them shows up as a disagreement.
    #
    # This exists because the previous census carried `unless n.isInternal do`.
    # Name.isInternal is true for any name whose last component starts with `_`,
    # so a file containing
    #     axiom _cheat : (0:Nat) = 1
    #     theorem _false : False := by have h := _cheat; simp at h
    # censused as "1 declarations, 1 audited, axioms within allowlist" and the
    # whole gate exited 0 with a proof of False sitting in the corpus.
    #
    # That is hole #5's exact shape. The old restriction was the ASCII alphabet;
    # the new one was isInternal. Removing a filter does not close the class,
    # because the next filter is invisible for the same reason this one was. What
    # closes it is that the EXCLUDED SET IS COUNTED. A future filter cannot hide
    # in a census that reports its own complement.
    scope=$(printf '%s\n' "$out" | grep '^SCOPE|' | head -1)
    if [ -z "$scope" ]; then
        echo "  ABORT: $f census reported no scope line - the audit cannot vouch for its own coverage"
        fail=1; continue
    fi
    # NOTE: not `aud` -- that name is the running total below, and shadowing it
    # here silently reported "203 declarations, 24 audited" on a clean corpus.
    scope_seen=$(printf '%s' "$scope" | cut -d'|' -f2)
    scope_aud=$(printf '%s' "$scope" | cut -d'|' -f3)
    if [ "$scope_seen" != "$scope_aud" ] || [ "$scope_aud" != "$n" ]; then
        echo "  ABORT: $f scope mismatch - lean saw $scope_seen, audited $scope_aud, $n reached the census."
        echo "         Something is filtering declarations out of the audit."
        fail=1; continue
    fi

    extra=$(printf '%s\n' "$lines" \
            | sed 's/^CENSUS|[^|]*|//; s/^\[//; s/\]$//' \
            | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
            | grep -v '^$' | sort -u \
            | grep -vxE "$ALLOW")

    tot=$((tot+n)); aud=$((aud+n))
    # Machine record, emitted from the loop variable. The human line below is for
    # reading; this one is for consumption. report.sh used to re-derive the
    # filename by regex over the human line, which meant the alphabet of legal
    # filenames had to be guessed -- hole #5 all over again, one file away. The
    # name is no longer guessed because it is no longer re-read.
    printf 'PERFILE|%s|%s|%s\n' "$f" "$n" "$n"
    if [ -n "$extra" ]; then
        printf '  %-24s %3s declarations, %3s audited  FORBIDDEN AXIOMS:\n' "$f" "$n" "$n"
        printf '%s\n' "$extra" | sed 's/^/      /'
        fail=1
    else
        printf '  %-24s %3s declarations, %3s audited, axioms within allowlist\n' "$f" "$n" "$n"
    fi
done

echo
echo "  TOTAL: $tot declarations, $aud audited"
exit $fail
