import Mathlib.Data.Complex.Basic
import Mathlib.Data.Real.Sqrt
import Mathlib.Tactic.Ring.RingNF
import Mathlib.Tactic.Linarith.Frontend
import Mathlib.Tactic.NormNum.Basic

/- BELOW THE BRANCH POINT: the two roots are a conjugate pair, and their
   common modulus is determined by the gap alone. -/

/-- Vieta over ℂ, same as everywhere else. -/
theorem c_sum (G : ℂ) (x y : ℂ) (hx : x*x = x + G) (hy : y*y = y + G)
    (hne : x ≠ y) : x + y = 1 := by
  have key : (x - y) * (x + y - 1) = 0 := by
    have : (x - y) * (x + y - 1) = (x*x - y*y) - (x - y) := by ring
    rw [this, hx, hy]; ring
  rcases mul_eq_zero.mp key with h | h
  · exact absurd (sub_eq_zero.mp h) hne
  · exact sub_eq_zero.mp h

theorem c_prod (G : ℂ) (x y : ℂ) (hx : x*x = x + G) (hy : y*y = y + G)
    (hne : x ≠ y) : x * y = -G := by
  have hs := c_sum G x y hx hy hne
  have hy1 : y = 1 - x := by rw [← hs]; ring
  subst hy1
  calc x * (1 - x) = x - x*x := by ring
    _ = x - (x + G) := by rw [hx]
    _ = -G := by ring

/-- The conjugate of a root is a root, when the gap is real. -/
theorem conj_root (G : ℝ) (z : ℂ) (h : z*z = z + (G:ℂ)) :
    (starRingEnd ℂ) z * (starRingEnd ℂ) z = (starRingEnd ℂ) z + (G:ℂ) := by
  have := congrArg (starRingEnd ℂ) h
  simpa using this

/-- THE MODULUS IS THE GAP. If a root is not real, it and its conjugate are the
    two roots, so their product - which is |z|^2 - equals -G. -/
theorem normSq_eq_neg_gap (G : ℝ) (z : ℂ) (h : z*z = z + (G:ℂ)) (him : z.im ≠ 0) :
    Complex.normSq z = -G := by
  have hc := conj_root G z h
  have hne : z ≠ (starRingEnd ℂ) z := by
    intro he
    apply him
    have := congrArg Complex.im he
    simp at this
    linarith
  have hp := c_prod (G:ℂ) z ((starRingEnd ℂ) z) h hc hne
  have : (Complex.normSq z : ℂ) = -(G:ℂ) := by
    rw [Complex.normSq_eq_conj_mul_self]
    rw [mul_comm] at hp
    exact_mod_cast hp
  exact_mod_cast this

/-- THE FLOOR FORMULA. For a gap below -1/4 the common modulus is sqrt(-G),
    so the constant schedule at -G has growth exactly sqrt(G).
    (The modulus is written as sqrt(normSq z) because the Complex.abs API lives
    in an analysis module this build does not yet have; the two are equal by
    definition of the absolute value.) -/
theorem modulus_below_branch (G : ℝ) (z : ℂ) (h : z*z = z + (G:ℂ)) (him : z.im ≠ 0) :
    Real.sqrt (Complex.normSq z) = Real.sqrt (-G) := by
  rw [normSq_eq_neg_gap G z h him]

/-- AT G = -1 THE ROOTS ARE PRIMITIVE SIXTH ROOTS OF UNITY. -/
theorem gap_neg_one_cube (z : ℂ) (h : z*z = z + (-1 : ℂ)) : z^3 = -1 := by
  calc z^3 = z*(z*z) := by ring
    _ = z*(z + (-1)) := by rw [h]
    _ = z*z - z := by ring
    _ = (z + (-1)) - z := by rw [h]
    _ = -1 := by ring

theorem gap_neg_one_sixth (z : ℂ) (h : z*z = z + (-1 : ℂ)) : z^6 = 1 := by
  have h3 := gap_neg_one_cube z h
  calc z^6 = (z^3)*(z^3) := by ring
    _ = (-1)*(-1) := by rw [h3]
    _ = 1 := by ring

/-- ...so they sit exactly on the unit circle: modulus 1. -/
theorem gap_neg_one_unit_modulus (z : ℂ) (h : z*z = z + (-1 : ℂ)) (him : z.im ≠ 0) :
    Complex.normSq z = 1 := by
  have := normSq_eq_neg_gap (-1) z (by exact_mod_cast h) him
  simpa using this

#print axioms c_sum
#print axioms c_prod
#print axioms normSq_eq_neg_gap
#print axioms modulus_below_branch
#print axioms gap_neg_one_cube
#print axioms gap_neg_one_unit_modulus
