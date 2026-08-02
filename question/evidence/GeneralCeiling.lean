import Mathlib.Data.Real.Basic
import Mathlib.Data.Real.Sqrt
import Mathlib.Tactic.Ring.RingNF
import Mathlib.Tactic.Linarith.Frontend
import Mathlib.Tactic.NormNum.Basic

/- THE CEILING AT ANY GAP MAGNITUDE, not just 1.
   The core file proved |f_n| <= F_n for unit gaps. This generalises it: for
   gaps drawn from {+G, -G} the bound sequence obeys the SAME recurrence with
   the SAME gap, so the ceiling is the object's own positive root. -/

variable {G : ℝ}

/-- The bound sequence: u_{n+1} = u_n + G * u_{n-1}, the gap equation's own
    recurrence. -/
def bound (G : ℝ) : Nat → ℝ × ℝ
  | 0 => (1, 1)
  | n+1 => ((bound G n).2, (bound G n).2 + G * (bound G n).1)

def run (G : ℝ) (s : Nat → ℝ) : Nat → ℝ × ℝ
  | 0 => (1, 1)
  | n+1 => ((run G s n).2, (run G s n).2 + s n * (run G s n).1)

def Mags (G : ℝ) (s : Nat → ℝ) : Prop := ∀ n, |s n| = G

/-- The bound sequence is non-negative when the gap is. -/
theorem bound_nonneg (hG : 0 ≤ G) (n : Nat) :
    0 ≤ (bound G n).1 ∧ 0 ≤ (bound G n).2 := by
  induction n with
  | zero => constructor <;> norm_num [bound]
  | succ k ih =>
    obtain ⟨h1, h2⟩ := ih
    refine ⟨h2, ?_⟩
    show (0:ℝ) ≤ (bound G k).2 + G * (bound G k).1
    nlinarith

/-- THE CEILING. Any schedule of gaps of magnitude G is dominated, term by
    term, by the constant-gap-G recurrence. -/
theorem run_le_bound (hG : 0 ≤ G) (s : Nat → ℝ) (hs : Mags G s) (n : Nat) :
    |(run G s n).1| ≤ (bound G n).1 ∧ |(run G s n).2| ≤ (bound G n).2 := by
  induction n with
  | zero => constructor <;> simp [run, bound]
  | succ k ih =>
    obtain ⟨h1, h2⟩ := ih
    obtain ⟨b1, b2⟩ := bound_nonneg hG k
    refine ⟨h2, ?_⟩
    show |(run G s k).2 + s k * (run G s k).1| ≤ (bound G k).2 + G * (bound G k).1
    calc |(run G s k).2 + s k * (run G s k).1|
        ≤ |(run G s k).2| + |s k * (run G s k).1| := abs_add _ _
      _ = |(run G s k).2| + G * |(run G s k).1| := by
          rw [abs_mul, hs k]
      _ ≤ (bound G k).2 + G * (bound G k).1 := by nlinarith

/-- AND IT IS ATTAINED: the constant schedule +G IS the bound sequence. -/
theorem const_attains (s : Nat → ℝ) (hs : ∀ n, s n = G) (n : Nat) :
    run G s n = bound G n := by
  induction n with
  | zero => rfl
  | succ k ih => show (_, _) = (_, _); rw [ih, hs k]

/-- The bound sequence grows exactly at the object's own positive root:
    if u_{n+1} = u_n + G*u_{n-1} then the geometric solution is r with
    r^2 = r + G. This is that identity. -/
theorem geometric_solution (r : ℝ) (hr : r*r = r + G) (n : Nat) :
    r^(n+2) = r^(n+1) + G * r^n := by
  have : r^(n+2) = r^n * (r*r) := by ring
  rw [this, hr]; ring

#print axioms bound_nonneg
#print axioms run_le_bound
#print axioms const_attains
#print axioms geometric_solution
