import Mathlib.Data.Real.Basic
import Mathlib.Data.Real.Sqrt
import Mathlib.Tactic.Ring.RingNF
import Mathlib.Tactic.Linarith.Frontend
import Mathlib.Tactic.NormNum.Basic
import Mathlib.Tactic.Positivity

/-
  Cone.lean — the branch point is the collapse of the common invariant cone.

  Setting. The transfer matrix of the gap recurrence is

      T(g) = [[1, g], [1, 0]]        char. poly  λ² = λ + g

  Fix a > 0 and consider the PAIR { T(+a), T(-a) } — a sign schedule with
  |gap| = a held fixed. Ask for a cone preserved by both.

  Take the sector          K α = { (x,y) : 0 ≤ y  ∧  α·y ≤ x }.

  Then:  T(+a) preserves K α for free (any 0 ≤ α ≤ 1),
         T(-a) preserves K α exactly when  a ≤ α·(1-α),
  and a slope α satisfying that exists iff  a ≤ 1/4.

  The punchline is `admissible_iff_between_roots`: the admissible slopes are
  exactly the closed interval between the two roots of  x² = x - a  — that is,
  the two roots of the gap equation at gap  G = -a.  The interval degenerates
  to the single point 1/2 exactly at a = 1/4, which is the branch point.

  So the collapse of the two roots into one and the collapse of the cone family
  into one cone are the same event, computed twice.

  Consequence for growth (not formalised here, it is the Perron–Frobenius half):
  below the branch point the pair is cone-preserving and both extremal growth
  rates are attained by constant schedules; above it no common cone survives,
  and the floor drops to the free determinant bound √a.
-/

namespace Cone

/-- One step of the recurrence, as a map on state pairs: `(x,y) ↦ (x + g·y, x)`. -/
def step (g : ℝ) (v : ℝ × ℝ) : ℝ × ℝ := (v.1 + g * v.2, v.1)

/-- The sector of slope `α`: `{ (x,y) : 0 ≤ y ∧ α·y ≤ x }`. -/
def Sector (α : ℝ) (v : ℝ × ℝ) : Prop := 0 ≤ v.2 ∧ α * v.2 ≤ v.1

/-- Membership in the sector forces the first coordinate nonnegative,
    provided the slope is. -/
theorem sector_fst_nonneg {α : ℝ} (hα : 0 ≤ α) {v : ℝ × ℝ} (hv : Sector α v) :
    0 ≤ v.1 :=
  le_trans (mul_nonneg hα hv.1) hv.2

/-- **The `+a` letter is free.** For any slope `α ≤ 1` and any nonnegative gap,
    `T(+a)` maps the sector into itself. No condition on `a` at all. -/
theorem step_pos_mem {α a : ℝ} (hα0 : 0 ≤ α) (hα1 : α ≤ 1) (ha : 0 ≤ a)
    {v : ℝ × ℝ} (hv : Sector α v) : Sector α (step a v) := by
  obtain ⟨hy, hxy⟩ := hv
  have hx : 0 ≤ v.1 := sector_fst_nonneg hα0 ⟨hy, hxy⟩
  refine ⟨hx, ?_⟩
  have h1 : 0 ≤ (1 - α) * v.1 := mul_nonneg (by linarith) hx
  have h2 : 0 ≤ a * v.2 := mul_nonneg ha hy
  simp only [step]
  linarith

/-- **The `-a` letter is the constraint.** `T(-a)` maps the sector of slope `α`
    into itself as soon as `a ≤ α·(1-α)`. -/
theorem step_neg_mem {α a : ℝ} (hα0 : 0 ≤ α) (hα1 : α ≤ 1) (ha : 0 ≤ a)
    (hcone : a ≤ α * (1 - α)) {v : ℝ × ℝ} (hv : Sector α v) :
    Sector α (step (-a) v) := by
  obtain ⟨hy, hxy⟩ := hv
  have hx : 0 ≤ v.1 := sector_fst_nonneg hα0 ⟨hy, hxy⟩
  refine ⟨hx, ?_⟩
  -- need  α · x ≤ x - a·y,  i.e.  a·y ≤ (1-α)·x
  have key : a * v.2 ≤ (1 - α) * v.1 := by
    have h1 : α * (1 - α) * v.2 ≤ (1 - α) * v.1 := by
      have := mul_le_mul_of_nonneg_left hxy (by linarith : (0:ℝ) ≤ 1 - α)
      nlinarith
    nlinarith [mul_le_mul_of_nonneg_right hcone hy]
  simp only [step]
  linarith

/-- Both letters at once: below the cone condition, the whole sign family
    preserves one and the same sector. -/
theorem step_both_mem {α a : ℝ} (hα0 : 0 ≤ α) (hα1 : α ≤ 1) (ha : 0 ≤ a)
    (hcone : a ≤ α * (1 - α)) {v : ℝ × ℝ} (hv : Sector α v) (s : Bool) :
    Sector α (step (if s then a else -a) v) := by
  cases s with
  | false => simpa using step_neg_mem hα0 hα1 ha hcone hv
  | true  => simpa using step_pos_mem hα0 hα1 ha hv

/-- The admissible-slope condition, completed to a square.
    `a ≤ α(1-α)` is exactly `(α - 1/2)² ≤ 1/4 - a`. -/
theorem admissible_iff_square (α a : ℝ) :
    a ≤ α * (1 - α) ↔ (α - 1/2) ^ 2 ≤ 1/4 - a := by
  constructor <;> intro h <;> nlinarith

/-- **The threshold.** A common invariant sector exists iff `a ≤ 1/4`.
    Forward: `α(1-α) ≤ 1/4` always. Backward: `α = 1/2` works. -/
theorem cone_exists_iff (a : ℝ) :
    (∃ α : ℝ, 0 ≤ α ∧ α ≤ 1 ∧ a ≤ α * (1 - α)) ↔ a ≤ 1/4 := by
  constructor
  · rintro ⟨α, _, _, h⟩
    nlinarith [sq_nonneg (α - 1/2)]
  · intro h
    exact ⟨1/2, by norm_num, by norm_num, by linarith⟩

/-- At the branch point the admissible slope is unique, and it is `1/2` —
    the same number as the double root of the gap equation there. -/
theorem cone_unique_at_branch {α : ℝ} (h : (1:ℝ)/4 ≤ α * (1 - α)) : α = 1/2 := by
  nlinarith [sq_nonneg (α - 1/2)]

/-- Above the branch point no sector is preserved by both letters. -/
theorem no_cone_above_branch {a : ℝ} (ha : 1/4 < a) :
    ¬ ∃ α : ℝ, 0 ≤ α ∧ α ≤ 1 ∧ a ≤ α * (1 - α) := by
  intro h
  exact absurd ((cone_exists_iff a).mp h) (not_le.mpr ha)

section Roots

variable (a : ℝ)

/-- The two roots of `x² = x - a`, i.e. the roots of the gap equation at
    gap `G = -a`. -/
noncomputable def rMinus : ℝ := (1 - Real.sqrt (1 - 4 * a)) / 2
noncomputable def rPlus  : ℝ := (1 + Real.sqrt (1 - 4 * a)) / 2

/-- `rPlus` really is a root of the gap equation at gap `-a`. -/
theorem rPlus_is_root (h : a ≤ 1/4) : (rPlus a) ^ 2 = rPlus a - a := by
  have hnn : (0:ℝ) ≤ 1 - 4 * a := by linarith
  have hsq : Real.sqrt (1 - 4 * a) ^ 2 = 1 - 4 * a := Real.sq_sqrt hnn
  simp only [rPlus]
  nlinarith [hsq]

theorem rMinus_is_root (h : a ≤ 1/4) : (rMinus a) ^ 2 = rMinus a - a := by
  have hnn : (0:ℝ) ≤ 1 - 4 * a := by linarith
  have hsq : Real.sqrt (1 - 4 * a) ^ 2 = 1 - 4 * a := Real.sq_sqrt hnn
  simp only [rMinus]
  nlinarith [hsq]

/-- **The headline.** The admissible cone slopes are exactly the closed
    interval spanned by the two roots of the gap equation at gap `-a`. -/
theorem admissible_iff_between_roots (h : a ≤ 1/4) (α : ℝ) :
    a ≤ α * (1 - α) ↔ rMinus a ≤ α ∧ α ≤ rPlus a := by
  have hnn : (0:ℝ) ≤ 1 - 4 * a := by linarith
  have hsq : Real.sqrt (1 - 4 * a) ^ 2 = 1 - 4 * a := Real.sq_sqrt hnn
  have hs0 : 0 ≤ Real.sqrt (1 - 4 * a) := Real.sqrt_nonneg _
  rw [admissible_iff_square]
  simp only [rMinus, rPlus]
  constructor
  · intro hle
    -- `(2α-1)² ≤ s²` with `s ≥ 0` forces `-s ≤ 2α-1 ≤ s`, by cases on the sign.
    have hs : (2 * α - 1) ^ 2 ≤ Real.sqrt (1 - 4 * a) ^ 2 := by nlinarith
    have hup : 2 * α - 1 ≤ Real.sqrt (1 - 4 * a) := by
      rcases le_or_lt (2 * α - 1) 0 with hc | hc
      · linarith
      · nlinarith [hs, hs0, hc]
    have hlo : -(Real.sqrt (1 - 4 * a)) ≤ 2 * α - 1 := by
      rcases le_or_lt 0 (2 * α - 1) with hc | hc
      · linarith
      · nlinarith [hs, hs0, hc]
    constructor <;> linarith
  · rintro ⟨h1, h2⟩
    nlinarith [mul_nonneg (by linarith : (0:ℝ) ≤ 2 * α - 1 + Real.sqrt (1 - 4 * a))
                          (by linarith : (0:ℝ) ≤ Real.sqrt (1 - 4 * a) - (2 * α - 1))]

/-- The interval of admissible slopes collapses to a point exactly at the
    branch point: `rMinus = rPlus ↔ a = 1/4` (for `a ≤ 1/4`). -/
theorem interval_collapses_at_branch (h : a ≤ 1/4) :
    rMinus a = rPlus a ↔ a = 1/4 := by
  have hnn : (0:ℝ) ≤ 1 - 4 * a := by linarith
  have hsq : Real.sqrt (1 - 4 * a) ^ 2 = 1 - 4 * a := Real.sq_sqrt hnn
  have hs0 : 0 ≤ Real.sqrt (1 - 4 * a) := Real.sqrt_nonneg _
  simp only [rMinus, rPlus]
  constructor
  · intro heq
    have hz : Real.sqrt (1 - 4 * a) = 0 := by linarith
    rw [hz] at hsq
    linarith [hsq]
  · intro ha
    subst ha
    norm_num

end Roots

end Cone
