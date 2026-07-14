-- Core_Collatz.lean
-- Core definitions for the Collatz conjecture
-- ARCHIVED: Definitions now consolidated into MersenneProofs.lean

import Mathlib.Data.Nat.Defs
import Mathlib.Tactic

namespace CoreCollatz

/-- Single Collatz step (standard form) -/
def collatz_step (n : ℕ) : ℕ :=
  if n % 2 = 0 then n / 2 else 3 * n + 1

/-- Compressed Collatz step: T(n) = n/2 if even, (3n+1)/2 if odd -/
def T (n : ℕ) : ℕ :=
  if n % 2 = 0 then n / 2 else (3 * n + 1) / 2

/-- Collatz trajectory using compressed map -/
def trajectory (n : ℕ) : ℕ → ℕ
  | 0 => n
  | k + 1 => T (trajectory n k)

/-- Collatz trajectory using standard map -/
def collatz_iterate : ℕ → ℕ → ℕ
  | 0, n => n
  | k + 1, n => collatz_iterate k (collatz_step n)

/-- Eventually reaches 1 -/
def eventuallyOne (n : ℕ) : Prop := ∃ k, trajectory n k = 1

/-- Drops below starting value -/
def drops (n : ℕ) : Prop := ∃ k, 0 < trajectory n k ∧ trajectory n k < n

/-- Is n in the "bad" class? (odd and ≡ 3 mod 4) -/
def isBad (n : ℕ) : Bool := n % 2 = 1 ∧ n % 4 = 3

/-- Count consecutive bad steps -/
def badChainLength : ℕ → ℕ → ℕ
  | _, 0 => 0
  | n, fuel + 1 =>
    if n ≤ 1 then 0
    else if isBad n then 1 + badChainLength (T n) fuel
    else 0

/-- Mersenne number: 2^k - 1 -/
def mersenne (k : ℕ) : ℕ := 2^k - 1

-- Basic lemmas

lemma T_pos (n : ℕ) (hn : 0 < n) : 0 < T n := by
  simp [T]; split_ifs <;> omega

lemma T_odd (n : ℕ) (hodd : n % 2 = 1) : T n = (3 * n + 1) / 2 := by
  unfold T; simp [hodd]

lemma T_even (n : ℕ) (heven : n % 2 = 0) : T n = n / 2 := by
  unfold T; simp [heven]

lemma trajectory_pos (n : ℕ) (hn : 0 < n) (k : ℕ) : 0 < trajectory n k := by
  induction k with
  | zero => simp [trajectory]; exact hn
  | succ k ih => simp only [trajectory]; exact T_pos _ ih

lemma trajectory_add (n : ℕ) (k j : ℕ) :
    trajectory n (k + j) = trajectory (trajectory n k) j := by
  induction j with
  | zero => simp [trajectory]
  | succ j ih =>
    calc trajectory n (k + (j + 1))
        = trajectory n ((k + j) + 1) := by ring_nf
      _ = T (trajectory n (k + j)) := by simp [trajectory]
      _ = T (trajectory (trajectory n k) j) := by rw [ih]
      _ = trajectory (trajectory n k) (j + 1) := by simp [trajectory]

end CoreCollatz
