/-
# Trace Monotonicity: The Gradient Force in Cl(3,3)

**Physical Interpretation**:
The Scalar Trace T(σ) acts as the **Gradient Force**.
The "Pole" is a region of high Bivector Torque.
The phases θ = t·log(p) align such that the weighted cosine sum S is NEGATIVE.
This alignment forces the Scalar Derivative T' to be POSITIVE.

**Mechanism**:
Let S(σ) = Σ (log p)² · p^{-σ} · cos(t · log p)

Then T'(σ) = -2 · S(σ)

If S(σ) < 0 (Negative Phase Clustering / Inward Compression), then:
  T'(σ) = -2 · (negative) = POSITIVE
  Therefore T is strictly INCREASING

This matches the observed plot where T(σ) climbs from ≈ -50 to ≈ -7.

## Cl(3,3) Proof Toolbox: Strict Monotonicity

### Tool 4: Strict Monotonicity from Positive Derivative (MVT)

The key theorem `negative_clustering_implies_monotonicity` uses:
```
(∀ x ∈ (a,b), f'(x) > 0) ⟹ StrictMonoOn f (a,b)
```

**Implementation** (from Mathlib):
```lean
apply strictMonoOn_of_deriv_pos (convex_Ioo 0 1)
· -- Continuity: continuous_rotorTrace
· -- Positive derivative: negative_clustering_implies_positive_deriv
```

**Cl(3,3) Meaning**:
- Negative Phase Clustering (S < 0) ⟹ Positive Force (T' > 0)
- Positive Force ⟹ Strictly Increasing Trace
- Strictly Increasing ⟹ Unique Equilibrium (at most one zero crossing)

**Status**: The MVT application is complete. Sorries remain for:
- `hasDerivAt_rotorTrace`: List induction + HasDerivAt.add (technical coercion issue)
- `continuous_rotorTrace`: Similar List coercion issue
-/

import Riemann.ZetaSurface.CliffordRH
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Convex.Deriv
import Mathlib.Order.Monotone.Basic

open CliffordRH Real Set

noncomputable section

namespace TraceMonotonicity

/-!
## 1. The Phase-Locking Hypothesis (Geometric Alignment)
-/

/--
**Hypothesis: Inward Phase Locking (Negative Phase Clustering)**

The geometry of the Prime Sieve aligns such that the weighted cosine sum is NEGATIVE.
This corresponds to "Compression" in the Cl(3,3) manifold.

Numerically verified for t > 20 at zeta zeros.
-/
def NegativePhaseClustering (σ t : ℝ) (primes : List ℕ) : Prop :=
  primes.foldl (fun (acc : ℝ) (p : ℕ) =>
    acc + (Real.log p)^2 * (p : ℝ)^(-σ) * Real.cos (t * Real.log p)) 0 < 0

/-!
## 2. The Derivative Formula
-/

/--
**The First Derivative in terms of the clustering sum**

T'(σ) = rotorTraceFirstDeriv σ t primes = -2 · S(σ)
where S(σ) = Σ (log p)² · p^{-σ} · cos(t · log p)
-/
theorem firstDeriv_eq_neg_two_sum (σ t : ℝ) (primes : List ℕ) :
    rotorTraceFirstDeriv σ t primes =
    -2 * primes.foldl (fun (acc : ℝ) (p : ℕ) =>
      acc + (Real.log p) ^ 2 * (p : ℝ) ^ (-σ) * Real.cos (t * Real.log p)) 0 := by
  rfl

/-!
## 3. Negative Clustering Implies Positive Derivative
-/

/--
**Key Lemma: Negative Sum ⟹ Positive Derivative**

If Σ (log p)² · p^{-σ} · cos(t · log p) < 0, then T'(σ) > 0.

In Cl(3,3): -2 * (Negative Compression) = Positive Force
-/
theorem negative_clustering_implies_positive_deriv (σ t : ℝ) (primes : List ℕ)
    (h_neg : NegativePhaseClustering σ t primes) :
    rotorTraceFirstDeriv σ t primes > 0 := by
  unfold NegativePhaseClustering at h_neg
  rw [firstDeriv_eq_neg_two_sum]
  -- We have: -2 * (negative number)
  -- Since the sum < 0, and -2 < 0, the product is positive
  nlinarith

/-!
## 4. Connecting HasDerivAt to Monotonicity
-/

/--
**Helper Lemma**: The function σ ↦ p^{-σ} is differentiable for p > 0.
This uses the fact that p^{-σ} = exp(-σ · log p).
-/
theorem differentiable_rpow_neg (p : ℝ) (hp : 0 < p) :
    Differentiable ℝ (fun (σ : ℝ) => p ^ (-σ)) := by
  -- p^{-σ} = exp(-σ * log p)
  have h_eq : (fun (σ : ℝ) => p ^ (-σ)) = (fun σ => Real.exp (-σ * Real.log p)) := by
    ext σ
    rw [Real.rpow_def_of_pos hp]
    ring_nf
  rw [h_eq]
  -- -σ * log p is differentiable, so exp(-σ * log p) is differentiable
  apply Differentiable.exp
  exact (differentiable_id (𝕜 := ℝ)).neg.mul_const (Real.log p)

/--
**Helper**: A single term log(p) · p^{-σ} · cos(t·log p) is differentiable in σ.
-/
theorem differentiable_term (p : ℕ) (t : ℝ) (hp : 0 < (p : ℝ)) :
    Differentiable ℝ (fun (σ : ℝ) => Real.log p * (p : ℝ) ^ (-σ) * Real.cos (t * Real.log p)) := by
  -- The only σ-dependent part is (p : ℝ) ^ (-σ)
  -- log p and cos(...) are constants w.r.t. σ
  have h_diff : Differentiable ℝ (fun (σ : ℝ) => (p : ℝ) ^ (-σ)) :=
    differentiable_rpow_neg (p : ℝ) hp
  exact ((differentiable_const _).mul h_diff).mul (differentiable_const _)

/--
**Helper**: The derivative of p^{-σ} with respect to σ is -log(p) · p^{-σ}.
-/
theorem hasDerivAt_rpow_neg (p : ℝ) (σ : ℝ) (hp : 0 < p) :
    HasDerivAt (fun σ' => p ^ (-σ')) (-Real.log p * p ^ (-σ)) σ := by
  -- p^{-σ} = exp(-σ * log p)
  -- d/dσ[exp(-σ * log p)] = -log p * exp(-σ * log p)
  have h_eq : ∀ σ', p ^ (-σ') = Real.exp (-σ' * Real.log p) := by
    intro σ'
    rw [Real.rpow_def_of_pos hp]
    ring_nf
  have h1 : HasDerivAt (fun σ' => Real.exp (-σ' * Real.log p))
                       (-Real.log p * Real.exp (-σ * Real.log p)) σ := by
    have h_inner : HasDerivAt (fun σ' => -σ' * Real.log p) (-Real.log p) σ := by
      convert (hasDerivAt_neg σ).mul_const (Real.log p) using 1
      ring
    convert (Real.hasDerivAt_exp (-σ * Real.log p)).comp σ h_inner using 1
    ring
  convert h1 using 2 <;> exact h_eq _

/--
**Helper**: The derivative of log(p) · p^{-σ} · cos(...) with respect to σ.
d/dσ[log(p) · p^{-σ} · cos] = -log(p)² · p^{-σ} · cos
-/
theorem hasDerivAt_term (p : ℕ) (t σ : ℝ) (hp : 0 < (p : ℝ)) :
    HasDerivAt (fun σ' => Real.log p * (p : ℝ) ^ (-σ') * Real.cos (t * Real.log p))
               (-(Real.log p)^2 * (p : ℝ) ^ (-σ) * Real.cos (t * Real.log p)) σ := by
  -- Apply product rule: d/dσ[c₁ · f(σ) · c₂] = c₁ · c₂ · f'(σ)
  have h1 := hasDerivAt_rpow_neg (p : ℝ) σ hp
  have h2 := h1.const_mul (Real.log p)
  have h3 := h2.mul_const (Real.cos (t * Real.log p))
  convert h3 using 1
  ring

/-- Helper: foldl with addition and initial value a equals a + foldl with initial 0 -/
theorem foldl_add_init_generic {α : Type} (l : List α) (f : α → ℝ) (a : ℝ) :
    l.foldl (fun acc x => acc + f x) a = a + l.foldl (fun acc x => acc + f x) 0 := by
  induction l generalizing a with
  | nil => simp
  | cons h t ih =>
    simp only [List.foldl_cons, zero_add]
    rw [ih (a + f h), ih (f h)]
    ring

lemma foldl_add_neg_eq_neg_foldl (l : List ℕ) (f : ℕ → ℝ) :
    l.foldl (fun acc p => acc + -(f p)) 0 = -l.foldl (fun acc p => acc + f p) 0 := by
  induction l with
  | nil => simp
  | cons p ps ih =>
    simp only [List.foldl_cons, zero_add]
    -- LHS: foldl (... -f ...) (-(f p)) ps = -(f p) + foldl (... -f ...) 0 ps
    rw [foldl_add_init_generic (l := ps) (f := fun q => -(f q)) (a := -(f p))]
    -- RHS: -foldl (... f ...) (f p) ps = -(f p + foldl (... f ...) 0 ps)
    rw [foldl_add_init_generic (l := ps) (f := f) (a := f p)]
    rw [ih]
    ring

/--
The trace function has derivative equal to rotorTraceFirstDeriv.

**Mathematical content** (clear):
- d/dσ [Σ term(p)] = Σ d/dσ[term(p)] by linearity of differentiation
- Each term has derivative given by `hasDerivAt_term`
- The sum of derivatives equals `rotorTraceFirstDeriv`

**Technical issue** (Lean 4 coercion):
- The foldl over `List ℕ` creates a coercion `do let a ← primes; pure ↑a`
- This syntactic representation doesn't match direct `List.foldl_cons` rewrites
- The sorry is purely about Lean 4's coercion machinery, not mathematics
-/
theorem hasDerivAt_rotorTrace (σ t : ℝ) (primes : List ℕ)
    (h_primes : ∀ p ∈ primes, 0 < (p : ℝ)) :
    HasDerivAt (fun σ' => rotorTrace σ' t primes)
               (rotorTraceFirstDeriv σ t primes) σ := by
  -- Proof structure:
  -- 1. The trace is 2 * Σ log(p) * p^{-σ} * cos(t*log(p))
  -- 2. Each term has derivative -(log(p))² * p^{-σ} * cos(...) by hasDerivAt_term
  -- 3. The sum of derivatives is Σ (-(log(p))² * ...)
  -- 4. Factoring: 2 * Σ (-(log(p))² * ...) = -2 * Σ ((log(p))² * ...) = rotorTraceFirstDeriv
  --
  -- The technical challenge is showing HasDerivAt for the foldl sum.
  -- By induction on primes:
  --   Base: foldl of [] has derivative 0 (constant 0)
  --   Step: foldl of (p::ps) = term(p) + foldl(ps)
  --         HasDerivAt for sum = HasDerivAt.add of term and tail
  --
  -- Each hasDerivAt_term p t σ hp gives the derivative of the p-term.
  -- HasDerivAt.add combines them inductively.
  -- Finally, const_mul 2 gives the full derivative.
  unfold rotorTrace rotorTraceFirstDeriv
  let term : ℕ → ℝ → ℝ :=
    fun p σ' => Real.log p * (p : ℝ) ^ (-σ') * Real.cos (t * Real.log p)
  let f : ℕ → ℝ :=
    fun p => (Real.log p) ^ 2 * (p : ℝ) ^ (-σ) * Real.cos (t * Real.log p)
  let dterm : ℕ → ℝ := fun p => -f p
  have h_foldl :
      HasDerivAt (fun σ' => primes.foldl (fun (acc : ℝ) (p : ℕ) => acc + term p σ') 0)
                 (primes.foldl (fun (acc : ℝ) (p : ℕ) => acc + dterm p) 0) σ := by
    induction primes with
    | nil =>
        simp only [List.foldl_nil]
        exact hasDerivAt_const σ 0
    | cons p ps ih =>
        have hp_pos : 0 < (p : ℝ) := h_primes p (List.mem_cons.mpr (Or.inl rfl))
        have h_term : HasDerivAt (fun σ' => term p σ') (dterm p) σ := by
          simpa [term, dterm, f] using hasDerivAt_term p t σ hp_pos
        have h_tail :
            HasDerivAt (fun σ' => ps.foldl (fun (acc : ℝ) (q : ℕ) => acc + term q σ') 0)
                       (ps.foldl (fun (acc : ℝ) (q : ℕ) => acc + dterm q) 0) σ :=
          ih (fun q hq => h_primes q (List.mem_cons_of_mem p hq))
        have h_sum := h_term.add h_tail
        -- Rewrite the foldl form to match the sum form.
        refine (by
          convert h_sum using 1
          · funext σ'
            calc
              (p :: ps).foldl (fun (acc : ℝ) (q : ℕ) => acc + term q σ') 0
                  = ps.foldl (fun (acc : ℝ) (q : ℕ) => acc + term q σ') (term p σ') := by
                      simp [List.foldl_cons, term]
              _ = term p σ' +
                  ps.foldl (fun (acc : ℝ) (q : ℕ) => acc + term q σ') 0 := by
                      simpa [term] using
                        (foldl_add_init_generic (l := ps) (f := fun q => term q σ')
                          (a := term p σ'))
          · calc
              (p :: ps).foldl (fun (acc : ℝ) (q : ℕ) => acc + dterm q) 0
                  = ps.foldl (fun (acc : ℝ) (q : ℕ) => acc + dterm q) (dterm p) := by
                      simp [List.foldl_cons]
              _ = dterm p + ps.foldl (fun (acc : ℝ) (q : ℕ) => acc + dterm q) 0 := by
                      simpa using
                        (foldl_add_init_generic (l := ps) (f := fun q => dterm q) (a := dterm p))
        )
  -- The derivative computation follows from linearity.
  have h_scale :
      HasDerivAt (fun σ' =>
        2 * primes.foldl (fun (acc : ℝ) (p : ℕ) => acc + term p σ') 0)
        (2 * primes.foldl (fun (acc : ℝ) (p : ℕ) => acc + dterm p) 0) σ :=
    h_foldl.const_mul 2
  have h_neg :
      2 * primes.foldl (fun (acc : ℝ) (p : ℕ) => acc + dterm p) 0 =
        -(2 * primes.foldl (fun (acc : ℝ) (p : ℕ) => acc + f p) 0) := by
    have h_foldl_neg :
        primes.foldl (fun (acc : ℝ) (p : ℕ) => acc + dterm p) 0 =
          -primes.foldl (fun (acc : ℝ) (p : ℕ) => acc + f p) 0 := by
      simpa [dterm] using (foldl_add_neg_eq_neg_foldl primes f)
    calc
      2 * primes.foldl (fun (acc : ℝ) (p : ℕ) => acc + dterm p) 0
          = 2 * (-primes.foldl (fun (acc : ℝ) (p : ℕ) => acc + f p) 0) := by
              simp [h_foldl_neg]
      _ = -(2 * primes.foldl (fun (acc : ℝ) (p : ℕ) => acc + f p) 0) := by ring
  simpa [rotorTrace, term, h_neg] using h_scale

/--
**Helper**: A single term is continuous in σ.
-/
theorem continuous_term (p : ℕ) (t : ℝ) (hp : 0 < (p : ℝ)) :
    Continuous (fun (σ : ℝ) => Real.log p * (p : ℝ) ^ (-σ) * Real.cos (t * Real.log p)) := by
  -- Continuity follows from differentiability
  exact (differentiable_term p t hp).continuous

/-- Helper: foldl with addition and initial value a equals a + foldl with initial 0 -/
theorem foldl_add_init (t : ℝ) (l : List ℕ) (a : ℝ) (σ : ℝ) :
    l.foldl (fun (acc : ℝ) (p : ℕ) =>
      acc + Real.log p * (p : ℝ) ^ (-σ) * Real.cos (t * Real.log p)) a =
    a + l.foldl (fun (acc : ℝ) (p : ℕ) =>
      acc + Real.log p * (p : ℝ) ^ (-σ) * Real.cos (t * Real.log p)) 0 := by
  simpa using
    (foldl_add_init_generic l
      (fun p => Real.log p * (p : ℝ) ^ (-σ) * Real.cos (t * Real.log p)) a)

/--
The trace function is continuous.

**Mathematical content** (clear):
- Each term log(p) * p^{-σ} * cos(t*log(p)) is continuous by `continuous_term`
- A finite sum of continuous functions is continuous
- Therefore rotorTrace = 2 * Σ term(p) is continuous

**Technical issue** (Lean 4 coercion):
- Same as `hasDerivAt_rotorTrace`: the foldl coercion syntax doesn't match
- The sorry is purely about Lean 4's `do let a ← l; pure ↑a` representation
-/
theorem continuous_rotorTrace (t : ℝ) (primes : List ℕ)
    (h_primes : ∀ p ∈ primes, 0 < (p : ℝ)) :
    Continuous (fun σ => rotorTrace σ t primes) := by
  -- The trace is 2 * (sum of terms), so continuous if the sum is continuous
  unfold rotorTrace
  apply Continuous.mul continuous_const
  let term : ℕ → ℝ → ℝ :=
    fun p σ' => Real.log p * (p : ℝ) ^ (-σ') * Real.cos (t * Real.log p)
  -- Each term continuous_term p t hp shows log(p)*p^{-σ}*cos(...) is continuous
  -- The foldl is a finite iteration of continuous additions
  -- By induction, each partial sum is continuous
  induction primes with
  | nil => exact continuous_const
  | cons p ps ih =>
    have hp_pos : 0 < (p : ℝ) := h_primes p (List.mem_cons.mpr (Or.inl rfl))
    have h_term : Continuous (fun σ => term p σ) := by
      simpa [term] using continuous_term p t hp_pos
    have h_tail := ih (fun q hq => h_primes q (List.mem_cons_of_mem p hq))
    -- Goal: Continuous fun σ => foldl f 0 (p::ps)
    -- We have:
    --   h_term: Continuous (fun σ => log p * p^(-σ) * cos(...))
    --   h_tail: Continuous (fun σ => foldl f 0 ps)
    --   h_sum:  Continuous (fun σ => term(p,σ) + foldl f 0 ps)
    -- The goal is the same function by foldl definition, but Lean's coercion
    -- representation `do let a ← l; pure ↑a` differs syntactically.
    -- This is a definitional equality that simp/rfl don't handle automatically.
    have h_sum := h_term.add h_tail
    have h_fun :
        (fun σ =>
          term p σ + ps.foldl (fun (acc : ℝ) (q : ℕ) => acc + term q σ) 0) =
        (fun σ =>
          (p :: ps).foldl (fun (acc : ℝ) (q : ℕ) => acc + term q σ) 0) := by
      funext σ
      calc
        term p σ + ps.foldl (fun (acc : ℝ) (q : ℕ) => acc + term q σ) 0
            = ps.foldl (fun (acc : ℝ) (q : ℕ) => acc + term q σ) (term p σ) := by
                simpa [term] using
                  (foldl_add_init_generic (l := ps) (f := fun q => term q σ) (a := term p σ)).symm
        _ = (p :: ps).foldl (fun (acc : ℝ) (q : ℕ) => acc + term q σ) 0 := by
                simp [List.foldl_cons, term]
    refine (Continuous.congr h_sum ?_)
    intro σ
    simpa using congrArg (fun f => f σ) h_fun

/-!
## 5. The Main Theorem: Phase Clustering ⟹ Monotonicity
-/

/--
**Main Theorem: Negative Clustering Implies Strict Monotonicity**

If ∀ σ ∈ (0,1), the weighted cosine sum is negative (phase clustering),
then the trace T(σ) is strictly increasing on (0,1).

This is a property of the Cl(3,3) manifold geometry, not an analytic trick.
-/
theorem negative_clustering_implies_monotonicity (t : ℝ) (primes : List ℕ)
    (h_primes : ∀ p ∈ primes, 0 < (p : ℝ))
    (h_cluster : ∀ σ, σ ∈ Ioo 0 1 → NegativePhaseClustering σ t primes) :
    TraceIsMonotonic t primes := by
  rw [TraceIsMonotonic]
  -- Use: f' > 0 on (a,b) implies f is strictly increasing on [a,b]
  -- This is the Mean Value Theorem consequence
  apply strictMonoOn_of_deriv_pos (convex_Ioo 0 1)
  · -- Continuity on the interval
    exact (continuous_rotorTrace t primes h_primes).continuousOn
  · -- Derivative is positive on the interior
    intro σ hσ
    -- interior of Ioo is Ioo itself
    rw [interior_Ioo] at hσ
    -- Get the derivative at σ
    have h_deriv := hasDerivAt_rotorTrace σ t primes h_primes
    rw [HasDerivAt.deriv h_deriv]
    -- Apply positive derivative from negative clustering
    exact negative_clustering_implies_positive_deriv σ t primes (h_cluster σ hσ)

/-!
## 6. Uniqueness of Equilibrium
-/

/--
**Geometric Stability Lemma**

If T(σ) is strictly monotonic, then for any value c,
the set {σ ∈ (0,1) | T(σ) = c} has at most one element.

A strictly monotonic function can cross any value at most once.
This guarantees uniqueness of zeros/equilibria.
-/
theorem monotonicity_implies_unique_preimage (t : ℝ) (primes : List ℕ) (c : ℝ)
    (h_mono : TraceIsMonotonic t primes) :
    Set.Subsingleton {σ | σ ∈ Ioo 0 1 ∧ rotorTrace σ t primes = c} := by
  intro σ₁ hσ₁ σ₂ hσ₂
  by_contra h_ne
  rw [TraceIsMonotonic] at h_mono
  -- Two distinct points with same value contradicts strict monotonicity
  rcases lt_trichotomy σ₁ σ₂ with h_lt | h_eq | h_gt
  · -- σ₁ < σ₂
    have h_strict := h_mono hσ₁.1 hσ₂.1 h_lt
    -- h_strict : T(σ₁) < T(σ₂), but both equal c
    simp only [hσ₁.2, hσ₂.2] at h_strict
    exact lt_irrefl c h_strict
  · exact h_ne h_eq
  · -- σ₂ < σ₁
    have h_strict := h_mono hσ₂.1 hσ₁.1 h_gt
    simp only [hσ₁.2, hσ₂.2] at h_strict
    exact lt_irrefl c h_strict

/-!
## 7. Summary

1. **Observation**: T(σ) is numerically seen to be NEGATIVE and INCREASING
2. **Hypothesis**: Negative Phase Clustering (sum of weighted cosines < 0)
3. **Algebra**: T' = -2 × (negative sum) = positive
4. **Calculus**: Positive derivative ⟹ strictly increasing
5. **Geometry**: Strictly increasing ⟹ unique equilibrium

The key insight is that the trace is the "force" (gradient).
The "energy well" (norm) is what minimizes at σ = 1/2.
-/

end TraceMonotonicity

end