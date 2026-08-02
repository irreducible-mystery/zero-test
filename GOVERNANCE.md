# Governance

The seed. Deliberately small, because structure erected ahead of the defects
that would force it is the failure this project is most likely to commit next.

**Every rule below names the machine that enforces it.** A rule with no
enforcer is marked `UNENFORCED` and is a known weakness, not a norm. This is not
pedantry: a check for one exact failure, in writing, naming the document and the
failure mode, existed in this project's records and was violated four times
inside the very document that contained it. Prose does not bind. It cost nothing
to add and it did nothing.

## Three objects, one word

"Error" carries three things, and most of why failure records rot is that they
are kept in one pile.

- **Defect** — a claim diverges from an artifact. Always bad, cheap to detect
  mechanically, transfers without trust: anyone can verify a contradiction from
  the artifacts alone. *This is the only kind that should ever become
  structural.*
- **Surprise** — a belief meets reality and loses. Expensive, unpreventable by
  any gate, and the point of the work. Record them; never legislate them. A
  system that suppresses these has stopped working.
- **Waste** — cost with no output. Not an error at all. Confusing it with a
  defect is what makes people add a gate where they should have deleted a
  component.

## Architecture is not decoration

The parties here have different failure modes, and the remedies do not
cross over. Collapsing them produces rules that cannot possibly work.

| | fails by | can be remedied by |
|---|---|---|
| **AI-class** | no persistence, so no learning across sessions; no introspective access, so "did I run it" has no privileged internal answer; fluency uncorrelated with accuracy; no felt cost signal | **structural removal only** |
| **Human-class** | fatigue, sunk cost, bookkeeping under load, no parallelism | norms, because the party persists and updates |
| **Interface-class** | a claim in one system becoming a belief in the other with no gate at the boundary; ambiguity resolved confidently in the most code-shaped direction | a checkpoint the expensive step *consumes* |
| **Shared** | fitting to small n; a correction committing the error it corrects; never asking what invariance an answer is obliged to have | — |

**An AI-class defect can never be remedied by a norm, a rule, or a warning.**
There is nobody present next session to have heeded it. This is the single most
load-bearing sentence in this document, and most bad proposals die on it.

Corollary, for the same reason: **a post-hoc gate cannot deter an AI-class
actor.** Deterrence needs a feedback path to the author, and the next session
does not know the gate exists. So for a gate whose only actors are instances,
zero field yield is sufficient grounds for deletion — there is no prevention
effect to have been silently doing the work.

**Ambiguity is not the interface defect.** Loose talk is where the generative
errors live and it should stay free. The defect is ambiguity *reaching an
expensive or irreversible step with no checkpoint in between*. Gate the coupling
between ambiguity and cost, never the ambiguity.

## The seed

1. **A defect is recorded as a class, a site, and a state.** Not prose. You
   cannot threshold prose. — *enforced by `bin/ledger.sh`, run by `verify.sh`
   check 7; the validator's own controls are check 8.*

2. **A class is closed by a sweep, not by a fix.** When a mechanism lands, run
   the class's search key over the whole tree, enumerate every site, and close
   them or record the ones left open. — `UNENFORCED`. This is the rule that
   would have caught hole #6 on the day hole #5 died, and it currently relies on
   whoever lands the mechanism. Its weakest point is that nothing checks the
   sweep happened.

3. **Escalation requires a mechanism AND a search key.** A machine that makes
   the class unrepresentable, and a command that finds the other sites. "Be
   careful about counts" fails; "generate the counts" passes. A mechanism with
   no key cannot be swept, so its propagation failures are invisible. — *the
   key requirement is enforced by `bin/ledger.sh`; the quality of a mechanism
   is not, and cannot be.*

4. **Two open sites and no mechanism turns the build red.** Not a review, not a
   judgment about whether the class matters. One site might be a quirk; two
   means the shape propagates. — *enforced by `bin/ledger.sh`, controlled by
   `verify.sh` check 8, which tests both that it fires at two and that it does
   **not** fire at one.*

5. **Not having written the thing.** Whoever authored a gate does not test it,
   and does not certify it. Reporting a defect needs no trust — the
   contradiction is in the artifacts — so accusation is cheap and should be
   constant. Confirmation is the part that does not transfer. — `UNENFORCED`,
   and probably unenforceable here; it is a fact about who runs what, which the
   artifacts cannot see.

6. **Unregulated, or impossible.** No "should", no "recommended", no "best
   practice". The middle is where bureaucracy grows, because prose accumulates
   for free and everyone knows it does not bind. Local norms live in the
   unregulated zone, are created without ceremony, and are allowed to die
   unmourned; they are a signal source, not governance.

Two declared terminal states are *not* the middle zone, because each is an
explicit claim that appears in a diff and gets counted: `unmechanizable` for a
class, `uncontrolled` for a gate. The distinction is between an unanswered
question and an answered one whose answer is "no". Only the first is a defect.
`-` in either field means nobody looked, and that is what fails.

## Prefer removing the degree of freedom

Two roads to "impossible", and they are not equal:

1. **Remove the degree of freedom** — generate it, derive it, ask the system
   that already knows.
2. **Reject at a gate.**

This repo is 2-for-2 on (1) holding and 6-for-6 on (2) needing a patch. Rank
them in that order when proposing a mechanism. A *warning* is not on the list.

## Information flow

```
  work  ──▶  local norms          created mid-work, no approval, disposable
              │                   read for patterns; never promoted directly
              ▼
           ledger/sites.tsv       append-only. class + site + state.
              │                   accusation is cheap and needs no trust
              ▼
           bin/ledger.sh          counts open sites per class
              │
        ≥2 open, no mechanism ──▶ BUILD RED
              │                   the escalation. mechanical, not convened.
              ▼
           mechanism named        by someone who did not report the site
              │                   attacked by someone who did not write it
              ▼
           search key run         the sweep: every site enumerated, not just
              │                   the one that hurt
              ▼
           STATE.md               generated. the counts flow back down, so a
                                  local can see what is now impossible and
                                  stop carrying it
```

The last arrow is the half that usually goes missing. Escalation without a
return path just moves work upward. `STATE.md` is regenerated from the ledger on
every run, so what has become structural is visible to everyone without anyone
announcing it.

## Growth and decay

`|G|`, the number of gates, grows monotonically unless something removes gates,
and nothing ever removes gates, because deleting a safeguard feels reckless. The
default trajectory is always toward verification costing more than discovery.

So deletion pressure is a first-class flow, and it needs a number:

- Every gate declares the class it closes and the negative control that proves
  it fires. — *enforced by `bin/ledger.sh`.*
- Gates with no control are **counted and displayed in `STATE.md`**, not
  tolerated silently. A gate whose only catch is its own control is either
  perfect or dead; one with no control cannot be told apart from either.
- A gate whose class has recorded no new site since the gate landed has zero
  field yield. Per the architecture note above, for gates whose only actors are
  instances that is grounds for deletion, not for suspicion. — *enforced by
  `bin/feedback.sh`, run by `verify.sh` check 9.* Every gate declares
  `expires_after` in `ledger/gates.tsv`: a commit count past which zero
  field-catches makes it a deletion candidate, or the declared terminal `never`.
  Age is derived from `git`, never typed, and an age `git` cannot resolve is
  refused rather than treated as zero. `-` is not legal in that column: it means
  nobody decided.

## What has no mechanism, honestly

- **The symmetry question.** "What invariance is this answer obliged to have"
  caught the worst error in this corpus and there is no way to automate it. It
  is generative rather than governance, which is the point: it does not need to
  live in this structure, and it should not become a role.
- **Rule 2 (sweep) and rule 5 (not having written it)** are unenforced above.
- **Waste has no live detector.** It is visible in aggregate and in retrospect.
  The gate-yield count above catches governance waste only.
- **Pattern-noticing across classes.** Four classes in this ledger's first draft
  turned out to be one class wearing four hats, and the counter could not have
  found that: the counter counts *sites*, and the thing recurring was the
  *shape of the fix*. Fixes that rhyme are the tell. Nothing computes it, and
  the party who can see it is structurally the one who wrote none of the
  entries.
