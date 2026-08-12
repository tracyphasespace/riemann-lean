/-
Zeta23Bridge.lean — a machine-checked dictionary between the Cl(N,N) sieve
vocabulary of the Geometry-of-the-Sieve program (McSheery 2026) and the
linear-algebra core of [Z23]: Claude (Anthropic), "More than two thirds of
the zeros of the Riemann zeta function lie on the critical line" (Aug 2026),
as formalized in this repository's `Zeta23/LinAlg` (namespace `RHLinalg`).

Three layers:

1. **Clifford vocabulary** (against Mathlib's `CliffordAlgebra`):
   * `bivector Q x y` — the outward bivector of the plane spanned by x, y;
   * `bivector_commute` — the Vanishing Commutator theorem: bivectors of
     mutually orthogonal planes commute (McSheery 2026a, Thm 2.1);
   * `bivector_sq_neg_one` / `bivector_sq_one` — rotation vs boost:
     a Euclidean plane (Q x = Q y = 1) has B² = −1 (compact rotor: the
     phase planes of the Zeta Motor); a split plane (Q x = 1, Q y = −1)
     has B² = +1 (hyperbolic boost: the plane of an off-line zero pair).

2. **The hyperbolic block**: the off-line-pair matrix `!![0, μ; μ, 0]`
   ([Z23] §4, Prop 4.1: the 2×2 form contributed by a pair {ρ, 1−ρ̄})
   has signature (1,1): `posIndex = 1` and `negIndex = 1`.

3. **The shadow bound** (`strut_hyperbolic_shadow_bound`): any real
   symmetric matrix decomposed as (PSD struts of rank ≤ s) + (p pulled-back
   hyperbolic blocks) has positive index ≤ s + p. This is the abstract
   content of [Z23] Proposition 4.1, derived here from
   `RHLinalg.posIndex_conj_le` (inertia under pull-back: "a shadow cannot
   manufacture positive directions") and `RHLinalg.posIndex_add_le`.

Correspondence to the Sieve program's own Lean modules
(`Riemann/Lean`, different toolchain — names only):
  * `orthogonal_generators_no_cross_terms` (GeometricBridge.lean)
      ↝ `bivector_commute` (here, against Mathlib's CliffordAlgebra);
  * the "outward bivector / no inward collapse" principle (§3.6.2)
      ↝ `strut_hyperbolic_shadow_bound` (its population-level form);
  * O3′ pointwise convexity — no analogue here; deliberately absent.
-/
import Zeta23.LinAlg.Inertia
import Zeta23.Chebyshev
import Mathlib.LinearAlgebra.CliffordAlgebra.Basic

noncomputable section

namespace Zeta23Bridge

/-! ## Layer 1: Clifford vocabulary -/

section Clifford

variable {R M : Type*} [CommRing R] [AddCommGroup M] [Module R M]
variable (Q : QuadraticForm R M)

open CliffordAlgebra

/-- The (outward) bivector of the plane spanned by `x` and `y`. -/
def bivector (x y : M) : CliffordAlgebra Q := ι Q x * ι Q y

/-- Orthogonal vectors (vanishing polar form) anticommute. -/
lemma ι_anticomm {x y : M} (h : QuadraticMap.polar Q x y = 0) :
    ι Q y * ι Q x = -(ι Q x * ι Q y) := by
  have hs : ι Q x * ι Q y + ι Q y * ι Q x = 0 := by
    rw [ι_mul_ι_add_swap, h, map_zero]
  exact eq_neg_of_add_eq_zero_right hs

/-- The reversed form of `ι_anticomm`. -/
lemma ι_anticomm' {x y : M} (h : QuadraticMap.polar Q x y = 0) :
    ι Q x * ι Q y = -(ι Q y * ι Q x) := by
  rw [ι_anticomm Q h, neg_neg]

/-- A bivector commutes with `ι` of any vector orthogonal to its plane:
two anticommutations cancel. -/
lemma bivector_commute_ι {x y z : M}
    (hxz : QuadraticMap.polar Q x z = 0) (hyz : QuadraticMap.polar Q y z = 0) :
    Commute (bivector Q x y) (ι Q z) := by
  show bivector Q x y * ι Q z = ι Q z * bivector Q x y
  unfold bivector
  calc ι Q x * ι Q y * ι Q z
      = ι Q x * (ι Q y * ι Q z) := by rw [mul_assoc]
    _ = ι Q x * -(ι Q z * ι Q y) := by rw [ι_anticomm' Q hyz]
    _ = -(ι Q x * ι Q z) * ι Q y := by rw [mul_neg, neg_mul, mul_assoc]
    _ = -(-(ι Q z * ι Q x)) * ι Q y := by rw [ι_anticomm' Q hxz]
    _ = ι Q z * ι Q x * ι Q y := by rw [neg_neg]
    _ = ι Q z * (ι Q x * ι Q y) := by rw [mul_assoc]

/-- **The Vanishing Commutator theorem** (McSheery 2026a, Thm 2.1, formalized
against Mathlib's `CliffordAlgebra`): bivectors of mutually orthogonal planes
commute — four anticommutation swaps, four sign flips, net `+1`. In [Z23]
this is the orthogonality of distinct blocks in the Witt decomposition of
the zero-side form ([Z23] Prop 4.1). -/
theorem bivector_commute {x y z w : M}
    (hxz : QuadraticMap.polar Q x z = 0) (hxw : QuadraticMap.polar Q x w = 0)
    (hyz : QuadraticMap.polar Q y z = 0) (hyw : QuadraticMap.polar Q y w = 0) :
    Commute (bivector Q x y) (bivector Q z w) :=
  (bivector_commute_ι Q hxz hyz).mul_right (bivector_commute_ι Q hxw hyw)

/-- For an orthogonal pair, `B² = −(Q x)(Q y)` as a scalar. -/
theorem bivector_sq {x y : M} (h : QuadraticMap.polar Q x y = 0) :
    bivector Q x y * bivector Q x y
      = algebraMap R (CliffordAlgebra Q) (-(Q x * Q y)) := by
  unfold bivector
  have key : ι Q x * ι Q y * (ι Q x * ι Q y)
      = -(ι Q x * ι Q x * (ι Q y * ι Q y)) := by
    calc ι Q x * ι Q y * (ι Q x * ι Q y)
        = ι Q x * (ι Q y * ι Q x) * ι Q y := by
          simp only [mul_assoc]
      _ = ι Q x * -(ι Q x * ι Q y) * ι Q y := by rw [ι_anticomm Q h]
      _ = -(ι Q x * ι Q x * (ι Q y * ι Q y)) := by
          simp only [mul_neg, neg_mul, mul_assoc]
  rw [key, ι_sq_scalar, ι_sq_scalar, ← map_mul, ← map_neg]

/-- **Rotation bivector** (Euclidean plane, `Q x = Q y = 1`): `B² = −1`.
These are the compact rotors of the Zeta Motor — the phase planes carrying
`cos/sin(τₖu)` once the imaginary unit is eliminated (the Cl(3,3)
phase-space move; companion paper §3.1). -/
theorem bivector_sq_neg_one {x y : M} (h : QuadraticMap.polar Q x y = 0)
    (hx : Q x = 1) (hy : Q y = 1) :
    bivector Q x y * bivector Q x y = -1 := by
  rw [bivector_sq Q h, hx, hy, mul_one, map_neg, map_one]

/-- **Boost bivector** (split plane, `Q x = 1`, `Q y = −1`): `B² = +1`.
The outward bivector of an off-line zero pair — the `Cl(1,1)` hyperbolic
plane of [Z23] §4 in Clifford form. -/
theorem bivector_sq_one {x y : M} (h : QuadraticMap.polar Q x y = 0)
    (hx : Q x = 1) (hy : Q y = -1) :
    bivector Q x y * bivector Q x y = 1 := by
  rw [bivector_sq Q h, hx, hy, one_mul, neg_neg, map_one]

end Clifford

/-! ## Layer 2: the hyperbolic block of an off-line zero pair -/

section HypBlock

open Matrix RHLinalg Finset

/-- Proof-irrelevant congruence for `posIndex` along a matrix equality. -/
lemma posIndex_congr {n : Type*} [Fintype n] [DecidableEq n]
    {A B : Matrix n n ℝ} (h : A = B)
    (hA : A.IsHermitian) (hB : B.IsHermitian) :
    posIndex hA = posIndex hB := by
  subst h; rfl

/-- The 2×2 block contributed by an off-line zero pair `{ρ, 1−ρ̄}` with
multiplicity-weight `μ` ([Z23] §4, proof of Prop 4.1). -/
def hypBlock (μ : ℝ) : Matrix (Fin 2) (Fin 2) ℝ := !![0, μ; μ, 0]

lemma hypBlock_isHermitian (μ : ℝ) : (hypBlock μ).IsHermitian := by
  unfold hypBlock
  ext i j
  fin_cases i <;> fin_cases j <;> simp [conjTranspose_apply]

lemma hermForm_hypBlock (μ : ℝ) (x : Fin 2 → ℝ) :
    hermForm (hypBlock μ) x = 2 * μ * (x 0 * x 1) := by
  unfold hermForm hypBlock
  simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two, Matrix.vecHead,
    Matrix.vecTail, Function.comp]
  ring

lemma rtrace_hypBlock (μ : ℝ) : rtrace (hypBlock μ) = 0 := by
  unfold rtrace hypBlock
  simp [Matrix.trace, Matrix.diag, Fin.sum_univ_two]

/-- The hyperbolic block has exactly one positive direction. -/
theorem posIndex_hypBlock {μ : ℝ} (hμ : 0 < μ) :
    posIndex (hypBlock_isHermitian μ) = 1 := by
  refine le_antisymm ?_ ?_
  · -- ≤ 1: otherwise the form would be positive definite on all of ℝ²,
    -- but it is negative at (1, −1).
    by_contra hgt
    push_neg at hgt
    obtain ⟨W, hW, hdim⟩ :=
      posIndex_eq_max_finrank_posDefOn (hypBlock_isHermitian μ)
    have hcard : posIndex (hypBlock_isHermitian μ) ≤ 2 := by
      simpa using posIndex_le_card (hypBlock_isHermitian μ)
    have hdim2 : Module.finrank ℝ W = 2 := by omega
    have hWtop : W = ⊤ := by
      apply Submodule.eq_top_of_finrank_eq
      rw [hdim2]
      simp
    have hmem : (![1, -1] : Fin 2 → ℝ) ∈ W := by rw [hWtop]; trivial
    have hne : (![1, -1] : Fin 2 → ℝ) ≠ 0 := by
      intro h
      simpa using congrFun h 0
    have hpos := hW _ hmem hne
    rw [hermForm_hypBlock] at hpos
    norm_num at hpos
    linarith
  · -- ≥ 1: the form is positive definite on span{(1,1)}.
    have hne : (![1, 1] : Fin 2 → ℝ) ≠ 0 := by
      intro h
      simpa using congrFun h 0
    have hPD : PosDefOn (hypBlock μ) (Submodule.span ℝ {![1, 1]}) := by
      intro x hx hxne
      obtain ⟨c, rfl⟩ := Submodule.mem_span_singleton.mp hx
      have hc : c ≠ 0 := fun h => hxne (by simp [h])
      rw [hermForm_hypBlock]
      have h0 : (c • ![1, 1] : Fin 2 → ℝ) 0 = c := by simp
      have h1 : (c • ![1, 1] : Fin 2 → ℝ) 1 = c := by simp
      rw [h0, h1]
      have hcc : 0 < c * c := mul_self_pos.mpr hc
      positivity
    have hle := finrank_le_posIndex_of_posDefOn (hypBlock_isHermitian μ) hPD
    rwa [finrank_span_singleton hne] at hle

/-- The hyperbolic block has exactly one negative direction: together with
`posIndex_hypBlock`, the signature is `(1,1)` — Witt's hyperbolic plane, the
matrix shadow of the boost bivector (`bivector_sq_one`). -/
theorem negIndex_hypBlock {μ : ℝ} (hμ : 0 < μ) :
    negIndex (hypBlock_isHermitian μ) = 1 := by
  set hA := hypBlock_isHermitian μ with hA_def
  have htr : ∑ i, hA.eigenvalues i = 0 := by
    rw [← rtrace_eq_sum_eigenvalues hA, rtrace_hypBlock]
  have hposIdx : posIndex hA = 1 := posIndex_hypBlock hμ
  unfold negIndex
  unfold posIndex at hposIdx
  refine le_antisymm ?_ ?_
  · -- ≤ 1: positive-eigenvalue and negative-eigenvalue index sets are
    -- disjoint inside Fin 2, and the positive set already has one element.
    have hdisj : Disjoint ({i | 0 < hA.eigenvalues i} : Finset (Fin 2))
        ({i | hA.eigenvalues i < 0} : Finset (Fin 2)) := by
      simp only [Finset.disjoint_left, Finset.mem_filter, Finset.mem_univ, true_and]
      intro i h1 h2
      exact absurd h1 (not_lt.mpr h2.le)
    have hunion := Finset.card_union_of_disjoint hdisj
    have hle2 : #{i | 0 < hA.eigenvalues i} + #{i | hA.eigenvalues i < 0} ≤ 2 := by
      rw [← hunion]
      exact le_trans (Finset.card_le_univ _) (by decide)
    omega
  · -- ≥ 1: eigenvalues sum to zero and one of them is positive, so one
    -- must be negative.
    by_contra hlt
    push_neg at hlt
    have hzero : #{i | hA.eigenvalues i < 0} = 0 := by omega
    have hemp := Finset.card_eq_zero.mp hzero
    have hnn : ∀ i, 0 ≤ hA.eigenvalues i := by
      intro i
      by_contra hneg
      push_neg at hneg
      have hi : i ∈ ({i | hA.eigenvalues i < 0} : Finset (Fin 2)) := by
        simp only [Finset.mem_filter, Finset.mem_univ, true_and]
        exact hneg
      rw [hemp] at hi
      exact absurd hi (Finset.notMem_empty i)
    have hexpos : ∃ i, 0 < hA.eigenvalues i := by
      have hp : 0 < #{i | 0 < hA.eigenvalues i} := by omega
      obtain ⟨i, hi⟩ := Finset.card_pos.mp hp
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hi
      exact ⟨i, hi⟩
    obtain ⟨i, hi⟩ := hexpos
    have hsum : 0 < ∑ j, hA.eigenvalues j :=
      Finset.sum_pos' (fun j _ => hnn j) ⟨i, Finset.mem_univ i, hi⟩
    rw [htr] at hsum
    exact lt_irrefl 0 hsum

end HypBlock

/-! ## Layer 3: the shadow bound -/

section Shadow

open Matrix RHLinalg Finset

variable {N : Type*} [Fintype N] [DecidableEq N]

/-- Positive index of a finite sum of Hermitian matrices is subadditive
(iterated `RHLinalg.posIndex_add_le`). -/
lemma posIndex_sum_le {ι : Type*} (s : Finset ι) (M : ι → Matrix N N ℝ)
    (hM : ∀ i, (M i).IsHermitian)
    (hSum : (∑ i ∈ s, M i).IsHermitian) :
    posIndex hSum ≤ ∑ i ∈ s, posIndex (hM i) := by
  induction s using Finset.cons_induction with
  | empty =>
      have h0 : ((0 : Matrix N N ℝ)).PosSemidef := PosSemidef.zero
      have hz : (∑ i ∈ (∅ : Finset ι), M i) = (0 : Matrix N N ℝ) :=
        Finset.sum_empty
      rw [posIndex_congr hz hSum h0.isHermitian,
        posIndex_eq_rank_of_posSemidef h0, Matrix.rank_zero,
        Finset.sum_empty]
  | cons a t hat ih =>
      have htSum : (∑ i ∈ t, M i).IsHermitian := by
        unfold Matrix.IsHermitian
        rw [Matrix.conjTranspose_sum]
        exact Finset.sum_congr rfl fun i _ => hM i
      have hstep : (M a + ∑ i ∈ t, M i).IsHermitian := (hM a).add htSum
      have hEq : (∑ i ∈ Finset.cons a t hat, M i) = M a + ∑ i ∈ t, M i :=
        Finset.sum_cons hat
      rw [posIndex_congr hEq hSum hstep, Finset.sum_cons]
      calc posIndex hstep ≤ posIndex (hM a) + posIndex htSum :=
            posIndex_add_le (hM a) htSum
        _ ≤ posIndex (hM a) + ∑ i ∈ t, posIndex (hM i) :=
            Nat.add_le_add_left (ih htSum) _

/-- **The strut / hyperbolic-plane shadow bound** — the Cl(N,N) reading of
[Z23] Proposition 4.1, and the machine-checked population-level form of the
Sieve program's outward-bivector principle.

If a real symmetric matrix `G` decomposes as a positive-semidefinite strut
part `P` of rank at most `s` (the on-line zeros) plus `p` pulled-back
hyperbolic blocks (the off-line pairs — each an outward-bivector `Cl(1,1)`
plane, each entering through an arbitrary shadow map `B i`), then

    `n₊(G) ≤ s + p` :

a shadow can fold curvature, but it cannot manufacture positive directions.
Each hyperbolic plane refunds at most one positive direction
(`posIndex_hypBlock` + `posIndex_conj_le`); the struts refund at most `s`
(`posIndex_eq_rank_of_posSemidef`). -/
theorem strut_hyperbolic_shadow_bound
    {G P : Matrix N N ℝ} {s p : ℕ}
    (hP : P.PosSemidef) (hrank : P.rank ≤ s)
    (μ : Fin p → ℝ) (hμ : ∀ i, 0 < μ i)
    (B : Fin p → Matrix (Fin 2) N ℝ)
    (hG : G = P + ∑ i, (B i)ᴴ * hypBlock (μ i) * (B i)) :
    ∃ hG' : G.IsHermitian, posIndex hG' ≤ s + p := by
  have hMi : ∀ i, ((B i)ᴴ * hypBlock (μ i) * (B i)).IsHermitian := fun i =>
    isHermitian_conjTranspose_mul_mul (B i) (hypBlock_isHermitian (μ i))
  have hSum : (∑ i, (B i)ᴴ * hypBlock (μ i) * (B i)).IsHermitian := by
    unfold Matrix.IsHermitian
    rw [Matrix.conjTranspose_sum]
    exact Finset.sum_congr rfl fun i _ => hMi i
  have hAdd : (P + ∑ i, (B i)ᴴ * hypBlock (μ i) * (B i)).IsHermitian :=
    hP.isHermitian.add hSum
  have hG' : G.IsHermitian := hG ▸ hAdd
  refine ⟨hG', ?_⟩
  have h1 : posIndex hG' ≤ posIndex hP.isHermitian + posIndex hSum := by
    rw [posIndex_congr hG hG' hAdd]
    exact posIndex_add_le hP.isHermitian hSum
  have h2 : posIndex hP.isHermitian ≤ s := by
    rw [posIndex_eq_rank_of_posSemidef hP]; exact hrank
  have h3 : posIndex hSum ≤ p := by
    calc posIndex hSum ≤ ∑ i, posIndex (hMi i) :=
          posIndex_sum_le Finset.univ _ hMi hSum
      _ ≤ ∑ _i : Fin p, 1 := by
          refine Finset.sum_le_sum fun i _ => ?_
          calc posIndex (hMi i)
              ≤ posIndex (hypBlock_isHermitian (μ i)) :=
                posIndex_conj_le (hypBlock_isHermitian (μ i)) (B i)
            _ = 1 := posIndex_hypBlock (hμ i)
      _ = p := by simp
  omega

/-- **Shadow monotonicity of the positive index** — re-export of [Z23]'s
inertia/pull-back lemma (`RHLinalg.posIndex_conj_le`) under its
Sieve-program name: projection ("taking the shadow") never increases the
number of positive directions. This is the population-level survivor of the
B.6 spiral objection: shadows fold curvature, not inertia. -/
theorem shadow_posIndex_le {m d : Type*} [Fintype m] [DecidableEq m]
    [Fintype d] [DecidableEq d]
    {Q : Matrix m m ℝ} (hQ : Q.IsHermitian) (B : Matrix m d ℝ) :
    posIndex (isHermitian_conjTranspose_mul_mul B hQ) ≤ posIndex hQ :=
  posIndex_conj_le hQ B

end Shadow

/-! ## Layer 4: Euler stiffness — injecting the Euler product as a typeclass

"Whole numbers expressed by fractions": the Euler product
`∑ₙ n⁻ˢ = ∏ₚ (1 − p⁻ˢ)⁻¹` writes the full Dirichlet series over ℕ as a
product of one geometric-series "fraction" per prime; unique factorization
is exactly the statement that expanding the product lists every whole
number once. Taking `−log` splits the product into independent prime terms
(the orthogonal rotors), and differentiating gives `−ζ'/ζ = ∑ Λ(n) n⁻ˢ`
with `Λ` supported **only on prime powers** and bounded by `log n`. That
sparse, log-weighted support — plus its Mertens second moment — is the
entire "geometric stiffness" the [Z23] certificate consumes. A function
like Davenport–Heilbronn, built as a *sum* of L-functions, has no product:
its log-derivative coefficients spill onto non-prime-powers (n = 6, 10, …)
and, because it has zeros in σ > 1, grow like a power of n — the budget
`∑ |c(n)|²/n` then blows up like `x^{1+δ}` and no certificate exists
([Z23] Remark 7.2(iii); Sieve program §B.8).

`EulerStiffness` packages exactly these consequences as a Prop-valued
structure. Downstream operator theorems (`charOp`-style constructions)
should take it as a hypothesis/instance: the ζ instance is *proved* below
from Mathlib + `Zeta23.Cheb`; for Davenport–Heilbronn the instance is not
constructible — the formal negative-control witness being a nonzero
log-derivative coefficient off the prime-power skeleton (e.g. at n = 6). -/

section EulerStiffness

open ArithmeticFunction Finset

/-- The quantitative shadow of the Euler product: everything the stiffness
argument consumes about a system's log-derivative coefficients `f`.
Fields 1–2 are the fingerprint of the product (sparse prime-power support,
coherent log-size weights: "whole numbers from fractions"); fields 3–4 are
the Chebyshev–Mertens budget that makes the [Z23] second moment finite. -/
structure EulerStiffness (f : ℕ → ℝ) : Prop where
  support_primePow : ∀ n, f n ≠ 0 → IsPrimePow n
  nonneg : ∀ n, 0 ≤ f n
  log_size : ∀ n, f n ≤ Real.log n
  mertens_energy : ∃ C : ℝ, 0 < C ∧ ∀ x : ℝ, 2 ≤ x →
    |(∑ n ∈ Ioc 0 ⌊x⌋₊, f n ^ 2 / n) - Real.log x ^ 2 / 2| ≤ C * Real.log x
  chebyshev : ∀ x : ℝ, 0 ≤ x →
    ∑ n ∈ Ioc 0 ⌊x⌋₊, f n ≤ (Real.log 4 + 4) * x

/-- **ζ has Euler stiffness**: the von Mangoldt function satisfies all four
constraints. This is the instance a `charOp` built from ζ's primes can
supply, and the one Davenport–Heilbronn cannot. -/
theorem eulerStiffness_vonMangoldt : EulerStiffness (fun n => Λ n) where
  support_primePow := fun n h => by
    by_contra hn
    exact h (ArithmeticFunction.vonMangoldt_eq_zero_iff.mpr hn)
  nonneg := fun n => ArithmeticFunction.vonMangoldt_nonneg
  log_size := fun n => ArithmeticFunction.vonMangoldt_le_log
  mertens_energy := Zeta23.Cheb.sum_vonMangoldt_sq_div_eq
  chebyshev := fun x hx => Zeta23.Cheb.sum_vonMangoldt_le hx

end EulerStiffness

/-! ## Layer 5: the Davenport–Heilbronn negative-control witness `Λ_DH(6) ≠ 0`

The D-H function `f = ½(1−iκ)L(s,χ) + ½(1+iκ)L(s,χ̄)` (χ mod 5, χ(2) = i)
has Dirichlet coefficients `c(n) = Re χ(n) + κ·Im χ(n)`, hence
`c(1) = 1, c(2) = κ, c(3) = −κ, c(6) = 1` (as `χ(6) = χ(2)χ(3) = i·(−i) = 1`).
Its log-derivative coefficients are determined by the convolution recursion
`c(n)·log n = Σ_{d ∣ n} Λ_f(d)·c(n/d)`, and at `n = 6` the recursion closes
to an **exact identity**: `Λ_f(6) = (c(6) − c(2)c(3))·log 6` — the n = 6
coefficient *is* the multiplicativity defect at 6.

For ζ the defect is `1 − 1·1 = 0`: the prime-power skeleton is intact
(`Λ(6) = 0`), which is the Euler product speaking ("whole numbers from
fractions": the 6-cell is generated by the 2-rotor and the 3-rotor). For
D-H the defect is `1 − (κ)(−κ) = 1 + κ²` — **a sum of squares, nonzero for
every real κ**. No interval arithmetic, no radicals, no analytic
continuation: the witness that kills `EulerStiffness` for D-H is exact
algebra at the first composite where multiplicativity can fail. -/

section DHWitness

open ArithmeticFunction

/-- The log-derivative convolution identities at `n = 2, 3, 6` for a
coefficient system `f` (normalized `f 1 = 1`, `L 1 = 0`, both implicit in
how the divisor sums are written): `f(n)·log n = Σ_{d ∣ n} L(d)·f(n/d)`. -/
structure LogDerivAt6 (f L : ℕ → ℝ) : Prop where
  at2 : f 2 * Real.log 2 = L 2
  at3 : f 3 * Real.log 3 = L 3
  at6 : f 6 * Real.log 6 = L 6 + L 2 * f 3 + L 3 * f 2

/-- **The defect identity**: the `n = 6` log-derivative coefficient is the
multiplicativity defect at `6`, weighted by `log 6`. An Euler product is
exactly the statement that all such defects vanish. -/
theorem logDeriv6_eq_defect {f L : ℕ → ℝ} (h : LogDerivAt6 f L) :
    L 6 = (f 6 - f 2 * f 3) * Real.log 6 := by
  have hlog : Real.log 6 = Real.log 2 + Real.log 3 := by
    rw [show (6 : ℝ) = 2 * 3 by norm_num,
      Real.log_mul (by norm_num) (by norm_num)]
  have h2 := h.at2
  have h3 := h.at3
  have h6 := h.at6
  rw [hlog] at h6 ⊢
  linear_combination (-1 : ℝ) * h6 + f 3 * h2 + f 2 * h3

/-- `6` is not a prime power. -/
lemma not_isPrimePow_six : ¬ IsPrimePow (6 : ℕ) := by
  intro h
  obtain ⟨p, k, hp, hk, hpk⟩ := h
  have hp' : Nat.Prime p := Nat.prime_iff.mpr hp
  have hdvd : p ∣ 6 := by
    rw [← hpk]
    exact dvd_pow_self p hk.ne'
  have hple : p ≤ 6 := Nat.le_of_dvd (by norm_num) hdvd
  have hp2 : 2 ≤ p := hp'.two_le
  interval_cases p
  · -- p = 2: 2^k = 6 impossible
    rcases Nat.lt_or_ge k 3 with h3 | h3
    · interval_cases k <;> norm_num at hpk
    · have hge : (2 : ℕ) ^ 3 ≤ 2 ^ k := Nat.pow_le_pow_right (by norm_num) h3
      rw [hpk] at hge
      norm_num at hge
  · -- p = 3: 3^k = 6 impossible
    rcases Nat.lt_or_ge k 2 with h2 | h2
    · interval_cases k <;> norm_num at hpk
    · have hge : (3 : ℕ) ^ 2 ≤ 3 ^ k := Nat.pow_le_pow_right (by norm_num) h2
      rw [hpk] at hge
      norm_num at hge
  · -- p = 4 is not prime
    exact absurd hp' (by decide)
  · -- p = 5: 5^k = 6 impossible
    rcases Nat.lt_or_ge k 2 with h2 | h2
    · interval_cases k <;> norm_num at hpk
    · have hge : (5 : ℕ) ^ 2 ≤ 5 ^ k := Nat.pow_le_pow_right (by norm_num) h2
      rw [hpk] at hge
      norm_num at hge
  · -- p = 6 is not prime
    exact absurd hp' (by decide)

/-- **The Davenport–Heilbronn witness**: for the D-H coefficient pattern
`f 2 = κ, f 3 = −κ, f 6 = 1` and *any* real `κ` (in particular the actual
D-H constant `κ = (√(10−2√5) − 2)/(√5 − 1)`), the log-derivative
coefficient at `6` is `(1 + κ²)·log 6 > 0`: strictly positive, hence
nonzero **off the prime-power skeleton**. -/
theorem dh_logDeriv6_pos {f L : ℕ → ℝ} (κ : ℝ)
    (hf2 : f 2 = κ) (hf3 : f 3 = -κ) (hf6 : f 6 = 1)
    (h : LogDerivAt6 f L) :
    0 < L 6 := by
  rw [logDeriv6_eq_defect h, hf2, hf3, hf6,
    show (1 : ℝ) - κ * -κ = 1 + κ ^ 2 by ring]
  have hl : (0 : ℝ) < Real.log 6 := Real.log_pos (by norm_num)
  positivity

/-- **Davenport–Heilbronn has no Euler stiffness**: its log-derivative
coefficients violate the prime-power support constraint at `n = 6`.
Combined with `eulerStiffness_vonMangoldt`, the negative control is now
machine-checked on both sides: ζ constructs the `EulerStiffness` instance;
D-H provably cannot. -/
theorem dh_not_eulerStiffness {f L : ℕ → ℝ} (κ : ℝ)
    (hf2 : f 2 = κ) (hf3 : f 3 = -κ) (hf6 : f 6 = 1)
    (h : LogDerivAt6 f L) :
    ¬ EulerStiffness L := fun hE =>
  not_isPrimePow_six
    (hE.support_primePow 6 (ne_of_gt (dh_logDeriv6_pos κ hf2 hf3 hf6 h)))

/-- **The ζ contrast**: the von Mangoldt function satisfies the *same* local
convolution identities (with ζ's coefficients `c ≡ 1`) with the skeleton
intact: `Λ(6) = 0`. Same recursion, zero defect — the Euler product at work. -/
theorem zeta_logDerivAt6 : LogDerivAt6 (fun _ => 1) (fun n => Λ n) := by
  have h2 : Λ 2 = Real.log 2 := by
    simpa using ArithmeticFunction.vonMangoldt_apply_prime Nat.prime_two
  have h3 : Λ 3 = Real.log 3 := by
    simpa using ArithmeticFunction.vonMangoldt_apply_prime Nat.prime_three
  have h6 : Λ 6 = 0 :=
    ArithmeticFunction.vonMangoldt_eq_zero_iff.mpr not_isPrimePow_six
  refine ⟨by simpa using h2.symm, by simpa using h3.symm, ?_⟩
  rw [h2, h3, h6,
    show Real.log 6 = Real.log 2 + Real.log 3 by
      rw [show (6 : ℝ) = 2 * 3 by norm_num,
        Real.log_mul (by norm_num) (by norm_num)]]
  ring

end DHWitness

end Zeta23Bridge

#print axioms Zeta23Bridge.bivector_commute
#print axioms Zeta23Bridge.bivector_sq_one
#print axioms Zeta23Bridge.bivector_sq_neg_one
#print axioms Zeta23Bridge.shadow_posIndex_le
#print axioms Zeta23Bridge.posIndex_hypBlock
#print axioms Zeta23Bridge.negIndex_hypBlock
#print axioms Zeta23Bridge.strut_hyperbolic_shadow_bound
#print axioms Zeta23Bridge.eulerStiffness_vonMangoldt
#print axioms Zeta23Bridge.logDeriv6_eq_defect
#print axioms Zeta23Bridge.dh_logDeriv6_pos
#print axioms Zeta23Bridge.dh_not_eulerStiffness
#print axioms Zeta23Bridge.zeta_logDerivAt6
