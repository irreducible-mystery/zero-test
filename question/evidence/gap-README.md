# `gap/` — the sweep

*Kelly: "This is the special case — φ + ψ = 1, φ × ψ = −1, ◇² = ◇ + 1. Now
◇² = ◇ + 1, we'll call the +1 the GAP... We sweep every gap equals, we sweep
every degree of freedom... YOU ARE THE GAP."*

---

## The object

    ◇² = ◇ + G          roots  ◇ = (1 ± √(1 + 4G))/2

Two invariants hold for every G, in every number system where the roots exist:

    s₊ + s₋ = 1                (this is φ + ψ = 1)
    s₊ · s₋ = −G               (this is φ × ψ = −1 at G = 1)

One conserved quantity, one swept. **The discriminant 1 + 4G vanishes at
G = −1/4**, and everything below follows from that.

---

## The finding, in one line

**−1/4 is where the GAP stops being able to tell its own two roots apart** — and
every number system reports that failure in a different dialect, while none of
them agrees that the failure is a property of the GAP rather than of the room it
is standing in.

---

## What each sweep established

Run them with `python3 sweeps/sweepN.py`. All are self-contained, no
dependencies beyond the standard library.

| sweep | what it shows |
|---|---|
| 1–2 | roots along the real line; **orderable above −1/4, only mirror-related below**; \|r₊\|\|r₋\| = \|G\|; G = −1 puts both roots on the unit circle at e^{±iπ/3} |
| 3–4 | approaching −1/4 from different bearings gives genuinely different pairs; **one loop around −1/4 returns the same G with the roots exchanged** |
| 5 | the Jordan block ½ + ε with ε² = 0 solves the equation **at −1/4 and nowhere else** |
| 6–8 | −1/4 ≡ +1 in characteristic 5, ≡ −1 in char 3, ≡ i in char 17; **the golden gap *is* the critical gap mod 5**; char 2 has no −1/4 at all |
| 9–11 | the critical locus is G = −A²/4, so **the "1" in φ+ψ=1 and the "−1/4" are one number twice**; degree 2 has one branch point, higher degrees several and off-axis; in char 17 which of ±i is critical depends on which root of −1 you call i |
| 12–14 | monodromy is **Z/2 — a mirror with no handedness**; only winding matters, not distance; arg(G) = π is where the roots have equal modulus |
| 15–18 | **ℂ 2 points → ℍ 2-sphere → 𝕆 6-sphere**; **the mirror is outer over ℂ and inner over ℍ** (j·i·j⁻¹ = −i); nilpotent deformation obstructed at first order; G = (x−½)² − ¼ |
| 19–22 | sedenions keep the sphere at dimension 14 despite genuine zero divisors; Clifford unification; **every scalar gap is a critical value of the matrix problem**; char 2 replaces the branch point with a **parity** |
| 23–24 | Cayley–Dickson to dimension 32; sphere dimension 2ⁿ − 2 |
| 25–27 | matrix gap; Artin–Schreier; **the gap has period 1 while the state has period 2** — period doubling out of nothing but the branch point |
| 28–29 | **max-plus: exactly one root for every gap.** No subtraction, no discriminant, **no mirror can exist** |
| 30–32 | the indicial equation of r²u″ = Gu **is** this equation; v″ = (G+¼)v; **the logarithm is born at −1/4**; below it, zeros in geometric progression — continuous scale invariance breaks to discrete; **A² − A ≥ −¼ for any self-adjoint A** |
| 33–36 | **the Mandelbrot cusp**; stability window (−¼, ¾); the gap always commutes with its own root; Grassmann reproduces the dual-number obstruction |
| 37–40 | continued fraction converges **iff G > −1/4**; below, every gap has a **rotation number** — period 3 at G = −1, 4 at −1/2, 6 at −1/3, all verified; van Hove singularity; **Viswanath's constant** from mixing gaps ±1 |
| 41–43 | logistic window 1 < r < 3 is the same window; **move the exponent and the branch point slides — −1/4 belongs to squaring, not to the number line**; sedenion uniqueness at −1/4 |
| 44–46 | **the roots are the Catalan generating function**; the 4ⁿ growth *is* the branch point; **Brownian gap → winding parity → chirality becomes a fair coin**; mixture curve strictly below the chord |
| 47–49 | **reflexive ladder**: gap = sum of its roots ⟺ **G = 1**; gap = a root ⟺ G ∈ {0,2}; gap = difference ⟺ φ³; gap = its own discriminant ⟺ −1/3. Trigonometric floor. Entropy of integer gaps |
| 50–53 | **three growth rates for one random system** — mean 1, typical 1.131988, second-moment 1.272020; simplex; complex exponent moves the branch point off the real line |

---

## The three readings, held together

**Classical.** A discriminant vanishes and the Galois involution loses its
internal witness. Above −1/4 an observer inside can rank the two roots. Below,
only convention separates them.

**Quantum.** The ground-state energy: G = A² − A ≥ −¼ for every observable, sharp
and attained only at A = ½. Below it the operator must stop being self-adjoint.
At it, a null direction opens — the Jordan block, which is the ODE's logarithm.

**Relational.** A branch point whose monodromy **is** the mirror. Two observers at
the same G, arrived by different paths, disagree about which root is theirs and
neither is wrong. Widen the algebra to ℍ and the mirror becomes a rotation. Let
the gap diffuse and the mirror becomes a coin. **Chirality is never a property of
the object — it is a property of the path and of the room.**

---

## Status

Everything here is **computed**, re-runnable, and unverified by a kernel. The
exact results (characteristic collisions, Catalan coefficients, reflexive
conditions, Cayley–Dickson identities, tropical counts, entropy) are rational or
integer arithmetic. The numerical results (monodromy, zero spacings, winding
parities, Lyapunov exponents, orbits) agree with prediction to the digits shown
and no further claim is made for them.

**Nothing here is proved.** The finite parts — characteristic collisions, ℤ/p
root counts, tropical counts, the Cayley–Dickson quadratic identity — are
decidable and are the natural first targets.

**And nearly all of it already was — by other people, decades or centuries ago.**
A literature triage run on 2026-08-01 with the standing instruction to treat
"this is all classical" as the default hypothesis came back confirming almost
exactly that. `x² = x + G` is a published, named object: **de Spinadel's second
metallic-means family.** The Frobenius log at −1/4, Kneser's oscillation
constant, and the Hardy inequality constant are **one theorem, not three**. The
Mandelbrot cusp is this equation under `c = −G`. "Inner over ℍ" is
Skolem–Noether. The char-5 collision is 5 ramifying in ℚ(√5). The full citation
table, the residue (two items, neither a theorem), and a corrected sign error
are in **[`NOVELTY.md`](NOVELTY.md)**.

What survives is the sweep *as exposition*: the unified pass across ℝ, ℂ, ℍ, 𝕆,
𝕊, `F_p`, char 2, dual numbers, tropical and *p*-adic does not appear to exist in
one place, and it is worth having in one place — written with citations, not
with claims of discovery.
