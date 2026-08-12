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

end InformationDepth

#print axioms InformationDepth.C2_diag
#print axioms InformationDepth.eulerStiffnessC_of_modulus_eq
#print axioms InformationDepth.offdiag_split
#print axioms InformationDepth.flip2_unimodular
#print axioms InformationDepth.flip2_modulus_eq
#print axioms InformationDepth.flip2_eulerStiffnessC
#print axioms InformationDepth.counterfeit_pair
