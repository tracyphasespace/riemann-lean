/-
InformationDepth.lean — F7, the beyond-interface experiment: opening moves
(`Factorization.md`, registered strategy fork, Track B).

`EulerStiffness` is frozen here as **E₀**. This file defines the first
off-diagonal observable and proves three things about the *informational
boundary* of E₀ — nothing more:

* `C2` — the two-point observable C₂(m,n) = aₘ·conj(aₙ). Its diagonal is
  the modulus data |aₙ|² (`C2_diag`): exactly what `EulerStiffnessC`
  consumes, since the complex interface is *defined* through the modulus.
* `PairEnergy` — the off-diagonal part of C₂ weighted by a kernel in
  log-ratio, Σ_{m≠n} aₘ·conj(aₙ)·K(log m − log n): the shape of the
  bilinear sums that appear on the prime side the moment Fourier support
  exceeds the diagonal regime ([Z23] §5.4's 𝒪-terms — there *dominated*,
  never evaluated).
* `eulerStiffnessC_of_modulus_eq` — **E₀ is modulus-blind**, in the
  strongest form: any two systems with pointwise equal modulus are
  indistinguishable to the entire interface (not merely to its five
  fields).
* `offdiag_split` — the full two-point sum decomposes as (E₀-visible
  diagonal)·K(0) + `PairEnergy`: the hierarchy's first level is literally
  "restore the off-diagonal of C₂."
* `counterfeit_pair` — **the registered first falsifiable target, won**:
  two explicit systems (Λ and a single-sign flip of Λ at n = 2) with
  pointwise equal modulus — hence both interface members, mutually
  indistinguishable at E₀ — separated by `PairEnergy` at an explicit
  kernel and truncation. The separation is exact: ±2·log 2·log 3.

What this file does **NOT** do (registered, per the F7 design): it does
not define E₁ — by design, E₁'s fields are to be extracted from the
minimal invariants of `PairEnergy` that the first beyond-diagonal
calculation demands, not postulated; it makes no zero-side claim; the
"depth" vocabulary d(T) remains audit-level. Falsification discipline:
D-H is rejected *at* E₀ (`dh_not_eulerStiffnessC`), so D-H is NOT a
counterfeit pair member — the pair below passes E₀ by construction.
-/
import Factorization
import Mathlib.NumberTheory.ArithmeticFunction.Misc

noncomputable section

namespace InformationDepth

open Finset Zeta23Bridge Factorization ArithmeticFunction

/-! ## The two-point observable and its diagonal -/

/-- The two-point observable C₂(m,n) = aₘ·conj(aₙ). -/
def C2 (a : ℕ → ℂ) (m n : ℕ) : ℂ := a m * (starRingEnd ℂ) (a n)

/-- The diagonal of C₂ is the modulus data: C₂(n,n) = |aₙ|². This is the
bridge identity of the hierarchy: the diagonal is exactly what E₀
consumes. -/
theorem C2_diag (a : ℕ → ℂ) (n : ℕ) :
    C2 a n n = ((‖a n‖ ^ 2 : ℝ) : ℂ) := by
  rw [C2, Complex.mul_conj']
  norm_cast

/-- **E₀ is modulus-blind (strong form)**: two systems with pointwise
equal modulus are indistinguishable to the complex interface — not merely
to its five fields, but to the entire predicate, since `EulerStiffnessC`
is defined through the modulus. -/
theorem eulerStiffnessC_of_modulus_eq {g h : ℕ → ℂ}
    (hmod : ∀ n, ‖g n‖ = ‖h n‖) (hg : EulerStiffnessC g) :
    EulerStiffnessC h := by
  unfold EulerStiffnessC at hg ⊢
  have he : (fun n => ‖h n‖) = fun n => ‖g n‖ :=
    funext fun n => (hmod n).symm
  rw [he]
  exact hg

/-! ## The first off-diagonal observable -/

/-- `PairEnergy a K N`: the off-diagonal two-point sum
Σ_{m≠n ≤ N} aₘ·conj(aₙ)·K(log m − log n). The kernel argument is the
log-ratio — the frequency variable of the explicit formula. -/
def PairEnergy (a : ℕ → ℂ) (K : ℝ → ℝ) (N : ℕ) : ℂ :=
  ∑ m ∈ Ioc 0 N, ∑ n ∈ Ioc 0 N,
    if m = n then 0 else C2 a m n * ((K (Real.log m - Real.log n) : ℝ) : ℂ)

/-- The full two-point sum splits as E₀-visible diagonal times K(0) plus
`PairEnergy`: restoring the off-diagonal of C₂ *is* the first step past
the interface. -/
theorem offdiag_split (a : ℕ → ℂ) (K : ℝ → ℝ) (N : ℕ) :
    ∑ m ∈ Ioc 0 N, ∑ n ∈ Ioc 0 N,
      C2 a m n * ((K (Real.log m - Real.log n) : ℝ) : ℂ)
    = (∑ n ∈ Ioc 0 N, ((‖a n‖ ^ 2 : ℝ) : ℂ)) * ((K 0 : ℝ) : ℂ)
      + PairEnergy a K N := by
  rw [PairEnergy, Finset.sum_mul, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun m hm => ?_
  have e : ∀ n ∈ Ioc 0 N,
      C2 a m n * ((K (Real.log m - Real.log n) : ℝ) : ℂ)
      = (if m = n then C2 a m n * ((K (Real.log m - Real.log n) : ℝ) : ℂ)
          else 0)
        + (if m = n then 0
          else C2 a m n * ((K (Real.log m - Real.log n) : ℝ) : ℂ)) := by
    intro n _
    split_ifs <;> simp
  rw [Finset.sum_congr rfl e, Finset.sum_add_distrib, Finset.sum_ite_eq]
  simp only [if_pos hm, sub_self, C2_diag]

/-! ## The counterfeit pair: E₀ cannot see what PairEnergy sees -/

/-- The sign-flip selector: −1 at n = 2, +1 elsewhere. Unimodular, so it
is invisible to the modulus. -/
def flip2 (n : ℕ) : ℂ := if n = 2 then -1 else 1

theorem flip2_unimodular (n : ℕ) : ‖flip2 n‖ = 1 := by
  unfold flip2
  split_ifs <;> simp

/-- The flipped system has pointwise the same modulus as Λ. -/
theorem flip2_modulus_eq (n : ℕ) :
    ‖((Λ n : ℝ) : ℂ)‖ = ‖flip2 n * ((Λ n : ℝ) : ℂ)‖ := by
  rw [norm_mul, flip2_unimodular, one_mul]

/-- The flipped system inhabits the interface (E₀ admits it, blindly). -/
theorem flip2_eulerStiffnessC :
    EulerStiffnessC (fun n => flip2 n * ((Λ n : ℝ) : ℂ)) :=
  eulerStiffnessC_of_modulus_eq (fun n => flip2_modulus_eq n)
    eulerStiffnessC_vonMangoldt

/-- **The counterfeit pair (F7's registered first target)**: two
coefficient systems with pointwise equal modulus — hence both inhabiting
`EulerStiffnessC`, and indistinguishable to *any* functional of the
modulus, in particular to all of E₀ — which the first off-diagonal
observable separates. Witnesses: Λ and its sign-flip at n = 2, constant
kernel, truncation N = 3; the separation is 2·log 2·log 3 vs
−2·log 2·log 3. Consequence, stated informationally: `PairEnergy`
carries arithmetic information that E₀ provably discards. This fixes the
*direction* of E₁ (off-diagonal restoration); it does not yet define
E₁'s fields. -/
theorem counterfeit_pair :
    ∃ (A B : ℕ → ℂ) (K : ℝ → ℝ) (N : ℕ),
      (∀ n, ‖A n‖ = ‖B n‖) ∧
      EulerStiffnessC A ∧ EulerStiffnessC B ∧
      PairEnergy A K N ≠ PairEnergy B K N := by
  refine ⟨fun n => ((Λ n : ℝ) : ℂ),
    fun n => flip2 n * ((Λ n : ℝ) : ℂ),
    fun _ => 1, 3,
    fun n => flip2_modulus_eq n,
    eulerStiffnessC_vonMangoldt,
    flip2_eulerStiffnessC, ?_⟩
  have hIoc : (Ioc 0 3 : Finset ℕ) = {1, 2, 3} := by decide
  have hΛ1 : Λ 1 = 0 := ArithmeticFunction.vonMangoldt_apply_one
  have hΛ2 : Λ 2 = Real.log 2 :=
    ArithmeticFunction.vonMangoldt_apply_prime Nat.prime_two
  have hΛ3 : Λ 3 = Real.log 3 :=
    ArithmeticFunction.vonMangoldt_apply_prime Nat.prime_three
  have hlog2 : (0 : ℝ) < Real.log 2 := Real.log_pos (by norm_num)
  have hlog3 : (0 : ℝ) < Real.log 3 := Real.log_pos (by norm_num)
  unfold PairEnergy C2 flip2
  rw [hIoc]
  simp only [Finset.sum_insert, Finset.mem_insert, Finset.mem_singleton,
    Finset.sum_singleton, hΛ1, hΛ2, hΛ3]
  norm_num
  rw [hΛ2, hΛ3]
  intro h
  have h' : (Real.log 2 * Real.log 3 + Real.log 3 * Real.log 2 : ℝ)
      = -(Real.log 2 * Real.log 3) + -(Real.log 3 * Real.log 2) := by
    exact_mod_cast h
  nlinarith [mul_pos hlog2 hlog3]

/-! ## Experiment-1 targets (oracle findings F2–F4, `EXPERIMENT_1_REPORT`)

The numerical run defined four Lean targets; all four are discharged
here. Target 4 — `parity_diff_support`, the mixed-grade support theorem —
is the first theorem of the observability stratification. -/

open ArithmeticFunction in
/-- **Target 1 (rigorous core of finding F3, the stealth counterfeit)**:
the Liouville rotor is exactly invisible on prime-prime pairs —
λ(p)·λ(q) = (−1)^Ω(p)·(−1)^Ω(q) = 1 (Ω = cardFactors), so the two-point observable of λΛ
restricted to prime-prime pairs coincides *identically* with that of Λ.
The classically dangerous twin hides in the dominant stratum. -/
theorem liouville_pair_invisible {p q : ℕ} (hp : p.Prime) (hq : q.Prime) :
    ((((-1 : ℝ) ^ (ArithmeticFunction.cardFactors p) * Λ p : ℝ)) : ℂ)
      * (starRingEnd ℂ) ((((-1 : ℝ) ^ (ArithmeticFunction.cardFactors q) * Λ q : ℝ)) : ℂ)
    = ((Λ p : ℝ) : ℂ) * (starRingEnd ℂ) ((Λ q : ℝ) : ℂ) := by
  simp only [Complex.conj_ofReal]
  norm_cast
  rw [ArithmeticFunction.cardFactors_apply_prime hp,
    ArithmeticFunction.cardFactors_apply_prime hq]
  norm_num

/-- **Target 2 (tower horizon law, finding F4)**: two distinct powers of
the same prime are separated by at least log p in the log metric — so
same-prime pairs enter a bandwidth-Δ window only once Δ ≥ log p: tower
visibility switches on prime-by-prime. -/
theorem tower_horizon {p : ℕ} (hp : 2 ≤ p) {j k : ℕ} (hjk : j ≠ k) :
    Real.log p ≤ |Real.log ((p : ℝ) ^ j) - Real.log ((p : ℝ) ^ k)| := by
  have hlp : 0 ≤ Real.log p :=
    Real.log_nonneg (by exact_mod_cast Nat.one_le_of_lt hp)
  have hz : ((j : ℤ) - k) ≠ 0 := sub_ne_zero.mpr (by exact_mod_cast hjk)
  have h1 : (1 : ℝ) ≤ |(j : ℝ) - k| := by exact_mod_cast Int.one_le_abs hz
  calc Real.log p = 1 * Real.log p := (one_mul _).symm
    _ ≤ |(j : ℝ) - k| * Real.log p := mul_le_mul_of_nonneg_right h1 hlp
    _ = |(j : ℝ) - k| * |Real.log p| := by rw [abs_of_nonneg hlp]
    _ = |((j : ℝ) - k) * Real.log p| := (abs_mul _ _).symm
    _ = |Real.log ((p : ℝ) ^ j) - Real.log ((p : ℝ) ^ k)| := by
        rw [Real.log_pow, Real.log_pow, sub_mul]

/-- **Target 3 (general half of finding F2)**: any correlation between
two coefficients carrying the *same* unimodular rotor is rotor-invariant
— (u·z)·conj(u·w) = z·conj(w) when ‖u‖ = 1. Hence per-prime constant
rotors are exactly invisible to within-tower correlations, while
cross-prime pairs (different rotors) are not: the E_tower ⊊ E_cross
inclusion's algebraic half. -/
theorem rotor_pair_invariant {u z w : ℂ} (hu : ‖u‖ = 1) :
    (u * z) * (starRingEnd ℂ) (u * w) = z * (starRingEnd ℂ) w := by
  have huu : u * (starRingEnd ℂ) u = 1 := by
    rw [Complex.mul_conj', hu]
    norm_num
  calc (u * z) * (starRingEnd ℂ) (u * w)
      = (u * (starRingEnd ℂ) u) * (z * (starRingEnd ℂ) w) := by
        rw [map_mul]; ring
    _ = z * (starRingEnd ℂ) w := by rw [huu, one_mul]

open ArithmeticFunction in
/-- **Target 4 (the mixed-grade support theorem — finding F3 made exact).**
The parity pair's pair-energy difference is *identically* a sum over the
mixed-grade locus: for every kernel K and truncation N,

  PairEnergy(λΛ) − PairEnergy(Λ)
    = Σ_{m≠n, Ω(m)+Ω(n) odd} (−2·Λ(m)Λ(n)·K(log m − log n)),

so every pair with Ω(m)+Ω(n) even — in particular every prime-prime
pair, the dominant stratum — contributes *exactly zero* to the
difference, and on the thin odd locus the contribution is the explicit
−2Λ(m)Λ(n)K. This is the kernel-checked form of the stealth-counterfeit
finding: the classically dangerous twin's entire two-point fingerprint
is confined to mixed grades. (Numerically cross-checked: full difference
= mixed-grade sum to machine precision at N = 2·10⁴, Δ = 1.) -/
theorem parity_diff_support (K : ℝ → ℝ) (N : ℕ) :
    PairEnergy
        (fun n => (((-1 : ℝ) ^ (ArithmeticFunction.cardFactors n) * Λ n : ℝ) : ℂ))
        K N
      - PairEnergy (fun n => ((Λ n : ℝ) : ℂ)) K N
    = ∑ m ∈ Ioc 0 N, ∑ n ∈ Ioc 0 N,
        if m ≠ n ∧
            ¬ Even (ArithmeticFunction.cardFactors m
              + ArithmeticFunction.cardFactors n)
        then ((((-2 : ℝ) * (Λ m * Λ n) * K (Real.log m - Real.log n)) : ℝ) : ℂ)
        else 0 := by
  unfold PairEnergy C2
  rw [← Finset.sum_sub_distrib]
  refine Finset.sum_congr rfl fun m _ => ?_
  rw [← Finset.sum_sub_distrib]
  refine Finset.sum_congr rfl fun n _ => ?_
  by_cases hmn : m = n
  · subst hmn
    simp
  · rw [if_neg hmn, if_neg hmn]
    simp only [Complex.conj_ofReal]
    by_cases hev : Even (ArithmeticFunction.cardFactors m
        + ArithmeticFunction.cardFactors n)
    · rw [if_neg (fun hc => hc.2 hev)]
      have hsgnC : ((-1 : ℂ)) ^ (ArithmeticFunction.cardFactors m)
          * (-1 : ℂ) ^ (ArithmeticFunction.cardFactors n) = 1 := by
        rw [← pow_add]
        exact hev.neg_one_pow
      push_cast
      linear_combination (((Λ m : ℝ) : ℂ) * ((Λ n : ℝ) : ℂ)
        * ((K (Real.log m - Real.log n) : ℝ) : ℂ)) * hsgnC
    · rw [if_pos ⟨hmn, hev⟩]
      have hodd : Odd (ArithmeticFunction.cardFactors m
          + ArithmeticFunction.cardFactors n) :=
        Nat.not_even_iff_odd.mp hev
      have hsgnC : ((-1 : ℂ)) ^ (ArithmeticFunction.cardFactors m)
          * (-1 : ℂ) ^ (ArithmeticFunction.cardFactors n) = -1 := by
        rw [← pow_add]
        exact hodd.neg_one_pow
      push_cast
      linear_combination (((Λ m : ℝ) : ℂ) * ((Λ n : ℝ) : ℂ)
        * ((K (Real.log m - Real.log n) : ℝ) : ℂ)) * hsgnC

end InformationDepth

#print axioms InformationDepth.C2_diag
#print axioms InformationDepth.eulerStiffnessC_of_modulus_eq
#print axioms InformationDepth.offdiag_split
#print axioms InformationDepth.flip2_unimodular
#print axioms InformationDepth.flip2_modulus_eq
#print axioms InformationDepth.flip2_eulerStiffnessC
#print axioms InformationDepth.counterfeit_pair
#print axioms InformationDepth.liouville_pair_invisible
#print axioms InformationDepth.tower_horizon
#print axioms InformationDepth.rotor_pair_invariant
#print axioms InformationDepth.parity_diff_support
