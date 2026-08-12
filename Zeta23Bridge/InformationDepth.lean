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

/-! ## The fingerprint is thin: the first *estimate* of the stratification

`parity_diff_support` locates the parity fingerprint; the theorems below
measure it. Odd total grade forces one leg of every contributing pair to
have even grade ≥ 2 — i.e. to be a **perfect square** — and the square
von Mangoldt mass up to N is √N·log N-small while the total mass is
Chebyshev. Hence the fingerprint is O(N^{3/2}·log N) against the
N²-scale of the pair energies: the classically dangerous twin is
*quantitatively* invisible at two-point order. -/

open ArithmeticFunction in
/-- On Λ's support, even grade forces a perfect square: n = p^j with j
even is (p^{j/2})². -/
theorem isSquare_of_even_grade {n : ℕ} (hn : Λ n ≠ 0)
    (he : Even (ArithmeticFunction.cardFactors n)) : IsSquare n := by
  have hpp : IsPrimePow n := by
    by_contra hc
    exact hn (ArithmeticFunction.vonMangoldt_eq_zero_iff.mpr hc)
  obtain ⟨p, k, hp, hk, rfl⟩ := hpp
  rw [ArithmeticFunction.cardFactors_apply_prime_pow (Nat.prime_iff.mpr hp)] at he
  obtain ⟨i, rfl⟩ := he
  exact ⟨p ^ i, by rw [← pow_add]⟩

open ArithmeticFunction in
/-- The von Mangoldt mass on perfect squares is √N·log N-small: at most
√N squares up to N, each carrying Λ ≤ log N. -/
theorem square_vonMangoldt_mass {N : ℕ} (hN : 1 ≤ N) :
    ∑ n ∈ (Ioc 0 N).filter (fun n => IsSquare n), Λ n
      ≤ Real.sqrt N * Real.log N := by
  classical
  set S := (Ioc 0 N).filter (fun n => IsSquare n) with hS
  have hlogN : 0 ≤ Real.log N := Real.log_nonneg (by exact_mod_cast hN)
  have hbound : ∀ n ∈ S, Λ n ≤ Real.log N := by
    intro n hn
    rw [hS, Finset.mem_filter, Finset.mem_Ioc] at hn
    calc Λ n ≤ Real.log n := ArithmeticFunction.vonMangoldt_le_log
      _ ≤ Real.log N :=
          Real.log_le_log (by exact_mod_cast hn.1.1) (by exact_mod_cast hn.1.2)
  have hsq_rep : ∀ a ∈ S, a = Nat.sqrt a ^ 2 := by
    intro a ha
    rw [hS, Finset.mem_filter] at ha
    obtain ⟨r, hr⟩ := ha.2
    rw [hr]
    simp only [← pow_two]
    rw [Nat.sqrt_eq']
  have hcard : S.card ≤ Nat.sqrt N := by
    have := Finset.card_le_card_of_injOn (fun n => Nat.sqrt n)
      (s := S) (t := Ioc 0 (Nat.sqrt N)) ?_ ?_
    · simpa using this
    · intro n hn
      have hn' := hn
      rw [Finset.mem_coe, hS, Finset.mem_filter, Finset.mem_Ioc] at hn'
      simp only [Finset.coe_Ioc, Set.mem_Ioc]
      exact ⟨Nat.sqrt_pos.mpr hn'.1.1, Nat.sqrt_le_sqrt hn'.1.2⟩
    · intro a ha b hb hab
      have hab' : Nat.sqrt a = Nat.sqrt b := hab
      rw [hsq_rep a (by simpa using ha), hsq_rep b (by simpa using hb), hab']
  calc ∑ n ∈ S, Λ n
      ≤ S.card • Real.log N := Finset.sum_le_card_nsmul S _ _ hbound
    _ = (S.card : ℝ) * Real.log N := nsmul_eq_mul _ _
    _ ≤ (Nat.sqrt N : ℝ) * Real.log N :=
        mul_le_mul_of_nonneg_right (by exact_mod_cast hcard) hlogN
    _ ≤ Real.sqrt N * Real.log N :=
        mul_le_mul_of_nonneg_right Real.nat_sqrt_le_real_sqrt hlogN

open ArithmeticFunction in
/-- Chebyshev at a natural cutoff, from the interface instance. -/
theorem vonMangoldt_sum_le (N : ℕ) :
    ∑ n ∈ Ioc 0 N, Λ n ≤ (Real.log 4 + 4) * N := by
  have h := eulerStiffness_vonMangoldt.chebyshev (N : ℝ) (Nat.cast_nonneg N)
  simpa using h

open ArithmeticFunction in
/-- **The fingerprint is thin**: for any kernel bounded by 1, the parity
pair's two-point separation is at most 4·(√N·log N)·((log 4 + 4)·N) =
O(N^{3/2}·log N) — against the N²-scale of the pair energies. The
classically dangerous twin is quantitatively invisible at two-point
order; the stratification's first estimate. -/
theorem parity_fingerprint_thin (K : ℝ → ℝ) (hK : ∀ t, |K t| ≤ 1)
    {N : ℕ} (hN : 1 ≤ N) :
    ‖PairEnergy
        (fun n => (((-1 : ℝ) ^ (ArithmeticFunction.cardFactors n) * Λ n : ℝ) : ℂ))
        K N
      - PairEnergy (fun n => ((Λ n : ℝ) : ℂ)) K N‖
    ≤ 4 * (Real.sqrt N * Real.log N) * ((Real.log 4 + 4) * N) := by
  classical
  rw [parity_diff_support]
  have hterm : ∀ m ∈ Ioc 0 N, ∀ n ∈ Ioc 0 N,
      ‖if m ≠ n ∧
          ¬ Even (ArithmeticFunction.cardFactors m
            + ArithmeticFunction.cardFactors n)
        then ((((-2 : ℝ) * (Λ m * Λ n) * K (Real.log m - Real.log n)) : ℝ) : ℂ)
        else 0‖
      ≤ 2 * ((if IsSquare m then Λ m else 0) * Λ n)
        + 2 * (Λ m * (if IsSquare n then Λ n else 0)) := by
    intro m _ n _
    have hΛm : (0 : ℝ) ≤ Λ m := ArithmeticFunction.vonMangoldt_nonneg
    have hΛn : (0 : ℝ) ≤ Λ n := ArithmeticFunction.vonMangoldt_nonneg
    have hRHS0 : (0 : ℝ) ≤ 2 * ((if IsSquare m then Λ m else 0) * Λ n)
        + 2 * (Λ m * (if IsSquare n then Λ n else 0)) := by
      have h1 : (0 : ℝ) ≤ (if IsSquare m then Λ m else 0) := by
        split_ifs <;> simp [hΛm]
      have h2 : (0 : ℝ) ≤ (if IsSquare n then Λ n else 0) := by
        split_ifs <;> simp [hΛn]
      have := mul_nonneg h1 hΛn
      have := mul_nonneg hΛm h2
      linarith
    by_cases hc : m ≠ n ∧
        ¬ Even (ArithmeticFunction.cardFactors m
          + ArithmeticFunction.cardFactors n)
    · rw [if_pos hc]
      obtain ⟨hmn, hodd⟩ := hc
      have hnorm : ‖((((-2 : ℝ) * (Λ m * Λ n)
            * K (Real.log m - Real.log n)) : ℝ) : ℂ)‖
          = |(-2 : ℝ) * (Λ m * Λ n) * K (Real.log m - Real.log n)| := by
        rw [Complex.norm_real, Real.norm_eq_abs]
      have habs : |(-2 : ℝ) * (Λ m * Λ n) * K (Real.log m - Real.log n)|
          ≤ 2 * (Λ m * Λ n) := by
        rw [abs_mul]
        have h1 : |(-2 : ℝ) * (Λ m * Λ n)| = 2 * (Λ m * Λ n) := by
          rw [abs_mul, abs_neg]
          simp [abs_of_nonneg (mul_nonneg hΛm hΛn)]
        rw [h1]
        calc 2 * (Λ m * Λ n) * |K (Real.log m - Real.log n)|
            ≤ 2 * (Λ m * Λ n) * 1 :=
              mul_le_mul_of_nonneg_left (hK _)
                (mul_nonneg (by norm_num) (mul_nonneg hΛm hΛn))
          _ = 2 * (Λ m * Λ n) := mul_one _
      by_cases hz : Λ m * Λ n = 0
      · rw [hnorm]
        calc |(-2 : ℝ) * (Λ m * Λ n) * K (Real.log m - Real.log n)|
            ≤ 2 * (Λ m * Λ n) := habs
          _ = 0 := by rw [hz, mul_zero]
          _ ≤ _ := hRHS0
      · have hΛm0 : Λ m ≠ 0 := fun h => hz (by rw [h, zero_mul])
        have hΛn0 : Λ n ≠ 0 := fun h => hz (by rw [h, mul_zero])
        have hsq : IsSquare m ∨ IsSquare n := by
          rcases Nat.even_or_odd (ArithmeticFunction.cardFactors m) with hem | hom
          · exact Or.inl (isSquare_of_even_grade hΛm0 hem)
          · have hen : Even (ArithmeticFunction.cardFactors n) := by
              rcases Nat.even_or_odd (ArithmeticFunction.cardFactors n)
                with hen | hon
              · exact hen
              · exact absurd (Odd.add_odd hom hon) hodd
            exact Or.inr (isSquare_of_even_grade hΛn0 hen)
      -- with a square leg, one of the two summands already dominates
        rw [hnorm]
        rcases hsq with h | h
        · rw [if_pos h]
          have h2 : (0 : ℝ) ≤ Λ m * (if IsSquare n then Λ n else 0) := by
            apply mul_nonneg hΛm
            split_ifs <;> simp [hΛn]
          calc |(-2 : ℝ) * (Λ m * Λ n) * K (Real.log m - Real.log n)|
              ≤ 2 * (Λ m * Λ n) := habs
            _ ≤ 2 * (Λ m * Λ n) + 2 * (Λ m * (if IsSquare n then Λ n else 0)) := by
                linarith
        · rw [if_pos h]
          have h1 : (0 : ℝ) ≤ (if IsSquare m then Λ m else 0) * Λ n := by
            apply mul_nonneg _ hΛn
            split_ifs <;> simp [hΛm]
          calc |(-2 : ℝ) * (Λ m * Λ n) * K (Real.log m - Real.log n)|
              ≤ 2 * (Λ m * Λ n) := habs
            _ ≤ 2 * ((if IsSquare m then Λ m else 0) * Λ n)
                + 2 * (Λ m * Λ n) := by linarith
    · rw [if_neg hc]
      simpa using hRHS0
  have hA0 : (0 : ℝ) ≤ ∑ n ∈ Ioc 0 N, (if IsSquare n then Λ n else 0) :=
    Finset.sum_nonneg fun n _ => by
      split_ifs <;> simp [ArithmeticFunction.vonMangoldt_nonneg]
  have hB0 : (0 : ℝ) ≤ ∑ n ∈ Ioc 0 N, Λ n :=
    Finset.sum_nonneg fun n _ => ArithmeticFunction.vonMangoldt_nonneg
  have hA : ∑ n ∈ Ioc 0 N, (if IsSquare n then Λ n else 0)
      ≤ Real.sqrt N * Real.log N := by
    rw [← Finset.sum_filter]
    exact square_vonMangoldt_mass hN
  have hB : ∑ n ∈ Ioc 0 N, Λ n ≤ (Real.log 4 + 4) * N := vonMangoldt_sum_le N
  calc ‖∑ m ∈ Ioc 0 N, ∑ n ∈ Ioc 0 N, _‖
      ≤ ∑ m ∈ Ioc 0 N, ‖∑ n ∈ Ioc 0 N, _‖ := norm_sum_le _ _
    _ ≤ ∑ m ∈ Ioc 0 N, ∑ n ∈ Ioc 0 N,
          (2 * ((if IsSquare m then Λ m else 0) * Λ n)
            + 2 * (Λ m * (if IsSquare n then Λ n else 0))) :=
        Finset.sum_le_sum fun m hm =>
          le_trans (norm_sum_le _ _)
            (Finset.sum_le_sum fun n hn => hterm m hm n hn)
    _ = 4 * (∑ n ∈ Ioc 0 N, (if IsSquare n then Λ n else 0))
          * (∑ n ∈ Ioc 0 N, Λ n) := by
        have hinner : ∀ m,
            ∑ n ∈ Ioc 0 N,
              (2 * ((if IsSquare m then Λ m else 0) * Λ n)
                + 2 * (Λ m * (if IsSquare n then Λ n else 0)))
            = 2 * (if IsSquare m then Λ m else 0) * (∑ n ∈ Ioc 0 N, Λ n)
              + 2 * Λ m
                * (∑ n ∈ Ioc 0 N, (if IsSquare n then Λ n else 0)) := by
          intro m
          have hpt : ∀ n ∈ Ioc 0 N,
              2 * ((if IsSquare m then Λ m else 0) * Λ n)
                + 2 * (Λ m * (if IsSquare n then Λ n else 0))
              = (2 * (if IsSquare m then Λ m else 0)) * Λ n
                + (2 * Λ m) * (if IsSquare n then Λ n else 0) :=
            fun n _ => by ring
          rw [Finset.sum_congr rfl hpt, Finset.sum_add_distrib,
            ← Finset.mul_sum, ← Finset.mul_sum]
        rw [Finset.sum_congr rfl fun m _ => hinner m, Finset.sum_add_distrib,
          ← Finset.sum_mul, ← Finset.sum_mul, ← Finset.mul_sum, ← Finset.mul_sum]
        ring
    _ ≤ 4 * (Real.sqrt N * Real.log N) * ((Real.log 4 + 4) * N) := by
        have hsl : (0 : ℝ) ≤ Real.sqrt N * Real.log N := by
          apply mul_nonneg (Real.sqrt_nonneg _)
          exact Real.log_nonneg (by exact_mod_cast hN)
        calc 4 * (∑ n ∈ Ioc 0 N, (if IsSquare n then Λ n else 0))
              * (∑ n ∈ Ioc 0 N, Λ n)
            ≤ 4 * (Real.sqrt N * Real.log N) * (∑ n ∈ Ioc 0 N, Λ n) := by
              apply mul_le_mul_of_nonneg_right _ hB0
              linarith
          _ ≤ 4 * (Real.sqrt N * Real.log N) * ((Real.log 4 + 4) * N) := by
              apply mul_le_mul_of_nonneg_left hB
              linarith

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
#print axioms InformationDepth.isSquare_of_even_grade
#print axioms InformationDepth.square_vonMangoldt_mass
#print axioms InformationDepth.vonMangoldt_sum_le
#print axioms InformationDepth.parity_fingerprint_thin
