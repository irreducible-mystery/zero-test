# Pre-registration — golden rotation number in the sign-schedule family

**Filed before any stranger runs anything.** Ordering is the entire value of
this document. If it is edited after results arrive, it is worth nothing —
`git log` is the only thing making that checkable.

**Author:** the instance that wrote `Cone.lean`, `const_attains`, and the
prediction below. **Therefore disqualified from testing it.** That is the
standing rule and this is the first time it costs something real.

---

## The object

    T(g) = [[1, g], [1, 0]]        char. poly   λ² = λ + g

Fix `a > 0`. A **schedule** is an infinite word `w ∈ {+,−}^ℕ`; step `n` applies
`T(+a)` or `T(−a)`. Two quantities:

- **joint spectral radius** `ρ̂(a)` — fastest growth over all schedules
- **joint spectral subradius** `ρ̌(a)` — slowest

A word's **rotation number** is the limiting density of `+` letters. A word is
**Sturmian** iff that density is irrational and the word is balanced.

Separately, for `G < −1/4` the roots of `x² = x + G` are complex and the
**root's rotation number** is `arg(s₊)/2π`.

**These are two different rotation numbers.** Conflating them is the most
likely way to waste a day on this.

---

## The question, stated so it can be killed

> **Is there any `a > 0` and any word `w` with irrational letter-density such
> that `w` is uniquely extremal — attaining `ρ̂(a)` or `ρ̌(a)` — for that `a`?**

**Falsifier:** exhibit one such `(a, w)`. One counterexample kills the
prediction. There is no partial credit.

**Confirmer:** there isn't one. A dense sweep finding nothing is **weak
evidence and must be reported as weak.** Absence of a counterexample over a
finite search is not a proof and must not be written as one.

---

## The prediction

**No. The family has no Morris–Sidorov devil's staircase and no irrational
extremal rotation number at any `a`.**

1. The maximizer is the **constant `+` word at every `a`**. Rotation number 1,
   rational, finiteness property holds at length 1. (`GeneralCeiling.lean`,
   `const_attains` — kernel-proved, `sorryAx` 0.)
2. Below `a = 1/4` the minimizer is the **constant `−` word**. Rotation
   number 0.
3. Above `a = 1/4` the floor collapses onto the determinant bound `√a`,
   attained by **105 / 1738 / 5060 / 6191 distinct words** at lengths ≤ 14 for
   `a = 0.3 / 0.5 / 1 / 2`. A degenerate set with no determined rotation number.

**Structural reason.** The common invariant cone. Below `1/4` the sector
`K(α) = {0 ≤ y, αy ≤ x}` is preserved by both letters iff `a ≤ α(1−α)`, whose
max is `1/4` (`Cone.lean`, kernel-proved). A cone-preserving family has
constant extremizers. Above `1/4` the cone is gone but the determinant bound
degenerates the minimum. **Both regimes are too easy for a staircase.**

---

## Assumptions, stated because they are where this breaks

- `ρ̂` and `ρ̌` are the standard joint spectral radius and subradius.
- "Rotation number of a word" means limiting `+`-density. Other conventions
  exist and will give different answers.
- Numerical claims below are **floating point** unless marked exact.
- The published sweep figures were produced by the same party writing this.

---

## What is absent

- **No proof of items 2 or 3.** Item 1 is kernel-proved; the rest is computed
  to length 18 in exact rationals and length 14 by exhaustive search. That is
  not a theorem.
- **No independent implementation.** Every number here came from one author's
  code on one machine.
- **No Lean formalisation of anything about schedules with irrational density.**
- **No literature check** on whether this exact family is solved. The novelty
  triage found the general 2×2 problem is NP-hard, the finiteness property is
  false in general (Bousch–Mairesse), and Morris–Sidorov give devil's-staircase
  behaviour for *some* one-parameter families — it did **not** establish
  whether ours is among them.

## What cannot be claimed

- That the golden rotation number appears anywhere in this family. **The root's
  rotation number has range `(0, 1/4)`** over all `G < −1/4` — 0 at the branch
  point, 1/4 as `G → −∞`. `1/φ = 0.618…` and `1/φ² = 0.382…` are **outside it
  and unattainable by any `G`.** (Computed, not proved. Verify before relying.)
- That `1/φ³ = 0.2360679…` at `G = −32.7085677` or `1/φ⁴ = 0.1458980…` at
  `G = −0.6753146` mean anything. Both are in range and both are **currently
  definitions dressed as discoveries** — `−G`, `√(−G)` bear no relation to
  `φ, φ², φ³`. Absent an independent characterisation these are numerology.
- That `G = 1` is an edge of chaos. `c = −G` maps this family to `z² + c`, and
  `G = 1` is `c = −1`, the **superstable period-2 point, multiplier exactly 0**
  — the most ordered point of that window. The Feigenbaum accumulation is at
  `G = 1.4011552`. (Computed.)

## What cannot be proved here

- The general JSR/subradius problem is NP-hard; subradius-is-zero is
  undecidable (Blondel–Tsitsiklis); the lower spectral radius is discontinuous
  on a positive-measure set (Bochi–Morris). **A negative result over a finite
  search cannot be upgraded to a theorem by searching harder.**
- Whether an irrational-density word is *uniquely* extremal is a statement
  about an infinite object. Any finite computation gives evidence, not proof.

---

## A defect found while writing this

`gap/README.md` in the sibling repo publishes "period 3 at `G = −1`, 4 at
`−1/2`, 6 at `−1/3`". **The true root rotation numbers are 1/6, 1/8, 1/12 —
exactly half.** At `G = −1` the roots are primitive *sixth* roots of unity,
which that repo's own Lean proves (`gap_neg_one_cube`: `z³ = −1`, so `z⁶ = 1`).
The published figures are periods **up to sign**. Anyone testing this hits the
wrong convention immediately. Site filed; the defect is the author's.

---

## What would change my mind, in advance

- One `(a, w)` with irrational density, uniquely extremal → **prediction dead.**
- A proof that cone-preservation forces constant extremizers → **prediction
  upgraded from computed to proved**, and the interesting question moves
  entirely to `a > 1/4`.
- An independent recomputation disagreeing with the `(0, 1/4)` range →
  **everything above is void**, including the falsification of the golden claim.
