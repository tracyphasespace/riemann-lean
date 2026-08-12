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

end Zeta23Bridge

#print axioms Zeta23Bridge.bivector_commute
#print axioms Zeta23Bridge.bivector_sq_one
#print axioms Zeta23Bridge.posIndex_hypBlock
#print axioms Zeta23Bridge.negIndex_hypBlock
#print axioms Zeta23Bridge.strut_hyperbolic_shadow_bound
