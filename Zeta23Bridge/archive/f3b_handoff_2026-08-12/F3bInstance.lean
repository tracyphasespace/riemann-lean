/-
F3bInstance.lean — the second inhabitant: Λχ ∈ 𝓔  (DRAFT)

REGISTER: written-here, NOT kernel-checked. This file was drafted outside
a build environment. Mathematics verified by hand and numerically
(verify_f3b.py, all checks PASS, margins match predicted tower tails to
1e-9); Lean surface NOT compiled. `sorry` marks are numbered TODO items,
each annotated with what discharges it. Under the frozen-interface
constraint (Factorization.md §F3b): this file consumes ONLY
`masked_twist` + `geom_tail_le` + Mathlib — no interface modification.

Scope (registered): the inhabitant claim is PER-CHARACTER. D_q depends
on q; no uniformity in q is claimed or needed for membership.

Chain (matching verify_f3b.py):
  L1  removed-energy terms vanish unless χ(n) = 0, i.e. ¬Coprime n q
  L2  masked prime-power support injects into primeFactors(q) × Icc 1 K
  L3  Λ(p^k)²/p^k = (log p)²/p^k
  L4  per-prime tower ≤ (log p)²/(p−1)   [geom_tail_le at r = 1/p]
  L5  assembly: masked energy ≤ D_q := Σ_{p|q} (log p)²/(p−1)
-/
import Factorization

noncomputable section
namespace Factorization

open Finset ArithmeticFunction

/-- The bad-prime energy constant. `q.primeFactors` is empty for q ≤ 1,
so `D 1 = 0` and the trivial character reduces to `EulerStiffness.toC`. -/
def badPrimeEnergy (q : ℕ) : ℝ :=
  ∑ p ∈ q.primeFactors, (Real.log p) ^ 2 / ((p : ℝ) - 1)

theorem badPrimeEnergy_nonneg (q : ℕ) : 0 ≤ badPrimeEnergy q := by
  refine Finset.sum_nonneg fun p hp => ?_
  have hp2 : 2 ≤ p := (Nat.prime_of_mem_primeFactors hp).two_le
  have : (1 : ℝ) ≤ (p : ℝ) := by exact_mod_cast Nat.one_le_of_lt hp2
  positivity  -- TODO-1: if positivity balks at (p:ℝ)-1 ≥ 0, use
              -- div_nonneg (sq_nonneg _) (by linarith)

/-- **L4 (per-prime tower)**: Σ_{k=1..K} (log p)²·(1/p)^k ≤ (log p)²/(p−1).
Consumes `geom_tail_le` at r = 1/p; the closed-form algebra
(1/p)/(1−1/p) = 1/(p−1) needs only 2 ≤ p. -/
theorem tower_le {p : ℕ} (hp : 2 ≤ p) (K : ℕ) :
    ∑ k ∈ Icc 1 K, (Real.log p) ^ 2 * ((1 : ℝ) / p) ^ k
      ≤ (Real.log p) ^ 2 / ((p : ℝ) - 1) := by
  have hpR : (2 : ℝ) ≤ (p : ℝ) := by exact_mod_cast hp
  have h0 : (0 : ℝ) ≤ 1 / p := by positivity
  have h1 : (1 : ℝ) / p < 1 := by
    rw [div_lt_one (by linarith)]; linarith
  have hg := geom_tail_le h0 h1 K
  have halg : (1 / (p : ℝ)) / (1 - 1 / p) = 1 / ((p : ℝ) - 1) := by
    field_simp
  calc ∑ k ∈ Icc 1 K, (Real.log p) ^ 2 * ((1 : ℝ) / p) ^ k
      = (Real.log p) ^ 2 * ∑ k ∈ Icc 1 K, ((1 : ℝ) / p) ^ k := by
        rw [Finset.mul_sum]
    _ ≤ (Real.log p) ^ 2 * ((1 / p) / (1 - 1 / p)) :=
        mul_le_mul_of_nonneg_left hg (sq_nonneg _)
    _ = (Real.log p) ^ 2 / ((p : ℝ) - 1) := by rw [halg]; ring

/-- **L3**: Λ(p^k)²/p^k = (log p)²/p^k, in the (1/p)^k shape L4 consumes.
TODO-2: exact Mathlib name for Λ(p^k) = log p with 1 ≤ k — candidates:
`ArithmeticFunction.vonMangoldt_apply_pow`,
`ArithmeticFunction.vonMangoldt_apply_prime_pow`; else derive from
`vonMangoldt_apply` + `IsPrimePow.minFac`. -/
theorem vonMangoldt_sq_div {p k : ℕ} (hp : p.Prime) (hk : 1 ≤ k) :
    (vonMangoldt (p ^ k) : ℝ) ^ 2 / (p ^ k : ℕ)
      = (Real.log p) ^ 2 * ((1 : ℝ) / p) ^ k := by
  have hΛ : (vonMangoldt (p ^ k) : ℝ) = Real.log p := by
    sorry -- TODO-2
  rw [hΛ]
  have hp0 : (0 : ℝ) < (p : ℝ) := by exact_mod_cast hp.pos
  push_cast
  rw [div_pow, one_pow]
  field_simp

/-- **L2 (the reindexing injection)**: encode. On the masked support each
n is p^k with p = n.minFac ∣ q and 1 ≤ k = n.factorization p ≤ Nat.log 2 N
(since 2^k ≤ p^k = n ≤ N). Injectivity of (p,k) ↦ p^k on prime pairs:
p ∣ p'^k' forces p = p', then `Nat.pow_right_injective hp.two_le`. -/
theorem masked_subset_image (N q : ℕ) :
    (Ioc 0 N).filter (fun n => vonMangoldt n ≠ 0 ∧ ¬ n.Coprime q)
      ⊆ (q.primeFactors ×ˢ Icc 1 (Nat.log 2 N)).image
          (fun pk => pk.1 ^ pk.2) := by
  intro n hn
  obtain ⟨hnI, hΛ, hcop⟩ := by
    simpa [Finset.mem_filter, Finset.mem_Ioc] using hn
  -- Λ n ≠ 0 ↔ IsPrimePow n :  `ArithmeticFunction.vonMangoldt_ne_zero_iff`
  obtain ⟨p, k, hp, hk, rfl⟩ :
      ∃ p k, p.Prime ∧ 0 < k ∧ p ^ k = n := by
    sorry -- TODO-3: vonMangoldt_ne_zero_iff + isPrimePow_nat_iff (order of
          -- the existential and Nat.Prime vs Prime may need massaging)
  refine Finset.mem_image.mpr ⟨(p, k), ?_, rfl⟩
  refine Finset.mem_product.mpr ⟨?_, Finset.mem_Icc.mpr ⟨hk, ?_⟩⟩
  · -- p ∈ q.primeFactors: p ∣ q from ¬Coprime(p^k, q), q ≠ 0 side condition
    -- via `Nat.Prime.coprime_pow_left_iff` / `Nat.coprime_pow_left_iff`
    -- then `Nat.Prime.coprime_iff_not_dvd`; membership by
    -- `Nat.mem_primeFactors`.
    sorry -- TODO-4 (note: needs q ≠ 0 — see hypothesis threading below)
  · -- k ≤ Nat.log 2 N from 2^k ≤ p^k ≤ N:  `Nat.pow_le_pow_left hp.two_le`
    -- then `Nat.pow_le_iff_le_log (by norm_num) (N ≥ 1)`.
    sorry -- TODO-5

/-- **L5 (the bound, pure arithmetic — no characters yet)**:
the masked von Mangoldt energy is ≤ D_q, uniformly in x.
Numerically verified: margin = tower tails, 12 moduli incl. 9699690. -/
theorem masked_energy_le (q : ℕ) (hq : q ≠ 0) {x : ℝ} (hx : 2 ≤ x) :
    ∑ n ∈ (Ioc 0 ⌊x⌋₊).filter
        (fun n => vonMangoldt n ≠ 0 ∧ ¬ n.Coprime q),
      (vonMangoldt n : ℝ) ^ 2 / n
      ≤ badPrimeEnergy q := by
  classical
  set S := (Ioc 0 ⌊x⌋₊).filter
    (fun n => vonMangoldt n ≠ 0 ∧ ¬ n.Coprime q)
  set T := q.primeFactors ×ˢ Icc 1 (Nat.log 2 ⌊x⌋₊)
  -- Step 1: sum over S ≤ sum over the image (subset, nonneg terms)
  have h1 : ∑ n ∈ S, (vonMangoldt n : ℝ) ^ 2 / n
      ≤ ∑ n ∈ T.image (fun pk => pk.1 ^ pk.2),
          (vonMangoldt n : ℝ) ^ 2 / n := by
    refine Finset.sum_le_sum_of_subset_of_nonneg
      (masked_subset_image ⌊x⌋₊ q) ?_
    intro n _ _; positivity
  -- Step 2: image sum = product sum, by injectivity on T
  have hinj : Set.InjOn (fun pk : ℕ × ℕ => pk.1 ^ pk.2) T := by
    sorry -- TODO-6: p₁^k₁ = p₂^k₂, both prime, k ≥ 1 ⟹ p₁ = p₂
          -- (p₁ ∣ p₂^k₂ ⟹ p₁ = p₂ via Nat.Prime.dvd_of_dvd_pow +
          --  Nat.prime_dvd_prime_iff_eq), then
          -- Nat.pow_right_injective p₁.two_le for k₁ = k₂.
  have h2 : ∑ n ∈ T.image (fun pk => pk.1 ^ pk.2),
        (vonMangoldt n : ℝ) ^ 2 / n
      = ∑ pk ∈ T, (vonMangoldt (pk.1 ^ pk.2) : ℝ) ^ 2 / (pk.1 ^ pk.2) :=
    (Finset.sum_image (fun a ha b hb h => hinj ha hb h)).symm
    -- TODO-7: argument shape of `Finset.sum_image` vs `sum_image'`
  -- Step 3: product sum → iterated sum → L3 → L4 → D_q
  have h3 : ∑ pk ∈ T, (vonMangoldt (pk.1 ^ pk.2) : ℝ) ^ 2 / (pk.1 ^ pk.2)
      ≤ badPrimeEnergy q := by
    rw [Finset.sum_product]
    refine Finset.sum_le_sum fun p hp => ?_
    have hpp := Nat.prime_of_mem_primeFactors hp
    calc ∑ k ∈ Icc 1 (Nat.log 2 ⌊x⌋₊),
          (vonMangoldt (p ^ k) : ℝ) ^ 2 / (p ^ k)
        = ∑ k ∈ Icc 1 (Nat.log 2 ⌊x⌋₊),
            (Real.log p) ^ 2 * ((1 : ℝ) / p) ^ k := by
          refine Finset.sum_congr rfl fun k hk => ?_
          exact vonMangoldt_sq_div hpp (Finset.mem_Icc.mp hk).1
      _ ≤ (Real.log p) ^ 2 / ((p : ℝ) - 1) := tower_le hpp.two_le _
  linarith [h1, h2.le, h2.ge, h3]

/-- **L1 + assembly: the second inhabitant.** For any Dirichlet character
χ mod q (q ≠ 0; primitivity NOT required — it belongs to the completed
package, not the interface), Λχ satisfies the modulus interface.
Consumes only `masked_twist` — the interfaces are untouched. -/
theorem dirichletChar_eulerStiffnessC (q : ℕ) [NeZero q]
    (χ : DirichletCharacter ℂ q) :
    EulerStiffnessC (fun n => χ n * ((vonMangoldt n : ℝ) : ℂ)) := by
  refine masked_twist eulerStiffness_vonMangoldt (fun n => χ (n : ZMod q))
    (fun n => ?_) (badPrimeEnergy_nonneg q) (fun x hx => ?_)
  · -- dichotomy: χ(n) = 0 (n not a unit) or ‖χ(n)‖ = 1 (unit: root of unity)
    by_cases h : IsUnit ((n : ℕ) : ZMod q)
    · right
      sorry -- TODO-8: ‖χ u‖ = 1 for units. Candidates:
            -- `DirichletCharacter.unit_norm_eq_one`,
            -- `MulChar.norm_eq_one_of_isUnit`; else: χ(u) is a root of
            -- unity (order divides card of unit group) hence norm 1 in ℂ.
    · left; exact MulChar.map_nonunit χ h  -- TODO-9: name check
  · -- removed energy ≤ D_q: nonzero terms force ‖χ n‖ = 0 hence ¬Coprime,
    -- landing in masked_energy_le's filter.
    calc ∑ n ∈ Ioc 0 ⌊x⌋₊,
          ((vonMangoldt n : ℝ) ^ 2
            - (‖χ (n : ZMod q)‖ * vonMangoldt n) ^ 2) / n
        ≤ ∑ n ∈ (Ioc 0 ⌊x⌋₊).filter
            (fun n => vonMangoldt n ≠ 0 ∧ ¬ n.Coprime q),
            (vonMangoldt n : ℝ) ^ 2 / n := by
          sorry -- TODO-10: split by the dichotomy; ‖χ‖=1 terms vanish
                -- (ring), χ=0 terms equal Λ²/n and satisfy the filter via
                -- `ZMod.isUnit_iff_coprime` (+ q ≠ 0); then
                -- `Finset.sum_le_sum_of_ne_zero`-style transfer.
      _ ≤ badPrimeEnergy q := masked_energy_le q (NeZero.ne q) hx

end Factorization

#print axioms Factorization.badPrimeEnergy_nonneg
#print axioms Factorization.tower_le
#print axioms Factorization.vonMangoldt_sq_div
#print axioms Factorization.masked_subset_image
#print axioms Factorization.masked_energy_le
#print axioms Factorization.dirichletChar_eulerStiffnessC
