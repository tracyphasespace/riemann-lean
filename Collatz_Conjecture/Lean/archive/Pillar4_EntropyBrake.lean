-- Pillar4_EntropyBrake.lean
-- Entropy braking: fuel consumption prevents sustained ascent

import Mathlib.Data.Nat.Defs
import Mathlib.Data.Nat.Log
import Mathlib.Data.Nat.Bitwise
import Mathlib.Tactic
import MersenneProofs

namespace EntropyBrake

open MersenneProofs

/-- Ascent potential: trailing 1s in binary (fuel for odd steps) -/
def ascent_potential (n : ℕ) : ℕ :=
  if n = 0 then 0
  else
    let xored := n ^^^ (n + 1)
    Nat.log2 xored

/-- Count trailing ones directly -/
def trailing_ones : ℕ → ℕ
  | 0 => 0
  | n + 1 =>
    if (n + 1) % 2 = 0 then 0
    else 1 + trailing_ones ((n + 1) / 2)

-- Verified: trailing_ones matches expected values
example : trailing_ones 1 = 1 := by native_decide
example : trailing_ones 3 = 2 := by native_decide
example : trailing_ones 7 = 3 := by native_decide
example : trailing_ones 15 = 4 := by native_decide
example : trailing_ones 31 = 5 := by native_decide

-- Verified: ascent_potential matches for Mersenne numbers
example : ascent_potential 1 = 1 := by native_decide
example : ascent_potential 3 = 2 := by native_decide
example : ascent_potential 7 = 3 := by native_decide
example : ascent_potential 15 = 4 := by native_decide
example : ascent_potential 31 = 5 := by native_decide

/-- Pure odd step: (3n + 1) / 2 -/
def oddStep (n : ℕ) : ℕ := (3 * n + 1) / 2

/-- Apply oddStep k times -/
def apply_odd_steps : ℕ → ℕ → ℕ
  | 0, n => n
  | k + 1, n => apply_odd_steps k (oddStep n)

-- Verified: apply_odd_steps k (2^k - 1) = 3^k - 1
example : apply_odd_steps 1 (2^1 - 1) = 3^1 - 1 := by native_decide
example : apply_odd_steps 2 (2^2 - 1) = 3^2 - 1 := by native_decide
example : apply_odd_steps 3 (2^3 - 1) = 3^3 - 1 := by native_decide
example : apply_odd_steps 4 (2^4 - 1) = 3^4 - 1 := by native_decide
example : apply_odd_steps 5 (2^5 - 1) = 3^5 - 1 := by native_decide

/-- 3^k is always odd -/
lemma pow3_odd (k : ℕ) : 3^k % 2 = 1 := by
  induction k with
  | zero => native_decide
  | succ k' ih =>
    have hexp : 3^(k' + 1) = 3 * 3^k' := by ring
    rw [hexp]; omega

/-- 3^k - 1 is always even -/
lemma pow3_minus1_even (k : ℕ) : (3^k - 1) % 2 = 0 := by
  have hodd := pow3_odd k
  have hge : 3^k ≥ 1 := Nat.one_le_pow k 3 (by omega)
  omega

/-- Even version -/
lemma even_pow3_minus1 (k : ℕ) : Even (3^k - 1) := by
  rw [Nat.even_iff]
  exact pow3_minus1_even k

/-- Mersenne burns out: after k odd steps, result is even -/
theorem mersenne_burns_out (k : ℕ) (_hk : k ≥ 1) : Even (apply_odd_steps k (2^k - 1)) := by
  -- By closed form: apply_odd_steps k (2^k - 1) = 3^k - 1
  -- 3^k - 1 is even
  sorry

/-- Post-ascent cooling: after bad chain, fuel is depleted -/
theorem post_ascent_cooling (k : ℕ) (_hk : k ≥ 2) :
    let n := 2^k - 1
    let final := trajectory n (k - 1)
    ascent_potential final ≤ 1 := by
  sorry

/-- Entropy braking: every n > 1 eventually drops -/
theorem entropy_braking (n : ℕ) (hn : n > 1) :
    ∃ k : ℕ, k > 0 ∧ trajectory n k < n := by
  sorry

end EntropyBrake
