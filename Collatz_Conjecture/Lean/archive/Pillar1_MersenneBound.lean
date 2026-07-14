-- Pillar1_MersenneBound.lean
-- Mersenne analysis: worst-case bad chain bounds

import Mathlib.Data.Nat.Defs
import Mathlib.Data.Nat.Log
import Mathlib.Data.Nat.ModEq
import Mathlib.Tactic
import MersenneProofs

namespace MersenneBound

open MersenneProofs

/-- Apply k odd steps: (3n+1)/2 repeatedly -/
def apply_odd_steps : ℕ → ℕ → ℕ
  | 0, n => n
  | k + 1, n => apply_odd_steps k ((3 * n + 1) / 2)

-- Verified: Mersenne numbers have chain length k-1
example : badChainLength (mersenne 3) 10 = 2 := by native_decide
example : badChainLength (mersenne 4) 10 = 3 := by native_decide
example : badChainLength (mersenne 5) 10 = 4 := by native_decide
example : badChainLength (mersenne 6) 10 = 5 := by native_decide

-- Verified: apply_odd_steps k (2^k - 1) = 3^k - 1
example : apply_odd_steps 1 (2^1 - 1) = 3^1 - 1 := by native_decide
example : apply_odd_steps 2 (2^2 - 1) = 3^2 - 1 := by native_decide
example : apply_odd_steps 3 (2^3 - 1) = 3^3 - 1 := by native_decide
example : apply_odd_steps 4 (2^4 - 1) = 3^4 - 1 := by native_decide
example : apply_odd_steps 5 (2^5 - 1) = 3^5 - 1 := by native_decide

/-- 3^k is always odd -/
lemma pow3_odd (k : ℕ) : 3^k % 2 = 1 := by
  induction k with
  | zero => simp
  | succ k' ih =>
    have hexp : 3^(k' + 1) = 3 * 3^k' := by rw [pow_succ, mul_comm]
    rw [hexp]; omega

/-- 3^k - 1 is always even -/
lemma pow3_minus1_even (k : ℕ) : (3^k - 1) % 2 = 0 := by
  have hodd := pow3_odd k
  have hge : 3^k ≥ 1 := Nat.one_le_pow k 3 (by omega)
  omega

/-- Mersenne numbers are bad for k ≥ 2 -/
lemma mersenne_is_bad (k : ℕ) (hk : 2 ≤ k) : isBad (mersenne k) = true := by
  simp [isBad, mersenne]
  constructor
  · have h2k : 2^k % 2 = 0 := by
      have : 2 ∣ 2^k := dvd_pow_self 2 (by omega : k ≠ 0)
      exact Nat.mod_eq_zero_of_dvd this
    have hpos : 0 < 2^k := by positivity
    omega
  · have h4 : 4 ∣ 2^k := by
      have : 2^2 ∣ 2^k := Nat.pow_dvd_pow 2 hk
      simp at this; exact this
    have h4k : 2^k % 4 = 0 := Nat.mod_eq_zero_of_dvd h4
    have hpos : 0 < 2^k := by positivity
    omega

/-- 3 is coprime to any power of 2 -/
lemma three_coprime_two_pow (k : ℕ) : Nat.Coprime 3 (2^k) := by
  unfold Nat.Coprime
  induction k with
  | zero => simp
  | succ k' ih =>
    have hpow : 2^(k' + 1) = 2 * 2^k' := by ring
    rw [hpow]
    calc Nat.gcd 3 (2 * 2^k') = Nat.gcd 3 (2^k' * 2) := by ring_nf
      _ = Nat.gcd 3 (2^k') := by
        have hc : Nat.Coprime 3 2 := by unfold Nat.Coprime; native_decide
        exact Nat.Coprime.gcd_mul_right_cancel_right (2^k') hc
      _ = 1 := ih

/-- Mersenne burn: after k odd steps on 2^k - 1, result is even -/
theorem mersenne_burn (k : ℕ) (hk : k ≥ 1) : (apply_odd_steps k (2^k - 1)) % 2 = 0 := by
  -- apply_odd_steps k (2^k - 1) = 3^k - 1 (verified computationally)
  -- 3^k - 1 is even (proven above)
  sorry -- Requires closed form proof

/-- Chain length is at most fuel -/
lemma badChainLength_le_fuel (n : ℕ) (fuel : ℕ) : badChainLength n fuel ≤ fuel := by
  induction fuel generalizing n with
  | zero => simp [badChainLength]
  | succ f ih =>
    simp only [badChainLength]
    split_ifs with h1 h2
    · omega
    · have := ih (T n); omega
    · omega

/-- Bad chain bound: badChainLength(n) ≤ log₂(n) + 1 -/
theorem bad_chain_bound (n : ℕ) (hn : 1 < n) :
    badChainLength n (Nat.log2 n + 10) ≤ Nat.log2 n + 1 := by
  -- This follows from Mersenne dominance: Mersenne numbers achieve the maximum
  sorry

end MersenneBound
