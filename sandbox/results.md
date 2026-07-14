# Axiom Analysis Results

## STRICT TEMPLATE (use this for every axiom)

Axiom: <name>
Location: <file:line>
Goal (verbatim):
```lean
<goal>
```
Loogle hits (top 5):
- <lemma_1>
- <lemma_2>
- <lemma_3>
- <lemma_4>
- <lemma_5>
Proposed proof sketch (no `sorry`):
- Step 1: <concrete lemma or theorem and what it gives>
- Step 2: <concrete lemma or theorem and what it gives>
- Step 3: <concrete lemma or theorem and what it gives>
Lean tactic block (must compile or be a tight sketch using named lemmas only):
```lean
by
  -- use only named lemmas, no `sorry`
  <tactic steps>
```
Notes / assumptions:
- <any required assumptions or missing lemmas>

---

## SUBMISSIONS

(append below using the strict template)

## `ax_log_deriv_neg_divergence_at_zero`

Axiom: `ax_log_deriv_neg_divergence_at_zero`
Location: `Axioms.proposed.lean:32`
Goal (verbatim):
```lean
Tendsto (fun σ : ℝ => (-(deriv f (σ + z₀.im * I) / f (σ + z₀.im * I))).re) (𝓝[>] z₀.re) atBot
```
Loogle hits (top 5):
- `Filter.Tendsto`
- `Filter.Tendsto.comp`
- `Filter.tendsto_atBot`
- `DifferentiableAt.hasDerivAt`
- `HasDerivAt.deriv`
Proposed proof sketch (no `sorry`):
- Step 1: **Factor `f`.** Since `f` is differentiable at `z₀` and has a simple zero there (`f z₀ = 0`, `deriv f z₀ ≠ 0`), we can write `f(z) = (z - z₀) * g(z)` where `g(z)` is differentiable at `z₀` and `g(z₀) ≠ 0`. This uses `DifferentiableAt.exists_deriv_eq_mul_sub_pow_succ` or similar from complex analysis.
- Step 2: **Differentiate `f`.** Use the product rule to get `deriv f z = 1 * g(z) + (z - z₀) * deriv g z`.
- Step 3: **Form the quotient `-f'/f`.** Substitute `deriv f z` and `f z` into the expression `-(deriv f z / f z)`. This simplifies to `- (1 / (z - z₀) + (deriv g z / g z))`.
- Step 4: **Evaluate the limit of each term.** We consider `z = σ + z₀.im * I`. As `σ → z₀.re` from the right:
    - The real part of `-(1 / (z - z₀))` tends to `atBot` (using `Filter.Tendsto.neg_const_mul_atTop` and `tendsto_inv_atTop_zero_Ioi`).
    - The real part of `-(deriv g z / g z)` tends to a finite limit, because `g(z₀) ≠ 0` and `g` is differentiable, making `deriv g z / g z` continuous at `z₀`.
- Step 5: **Combine limits.** Use `Filter.Tendsto.add_atBot` to show that the sum of a term tending to `atBot` and a term tending to a finite limit also tends to `atBot`.
Lean tactic block (must compile or be a tight sketch using named lemmas only):
```lean
by
  -- Main idea: Use the local behavior of f near a simple zero.
  -- Formalize f(z) = (z - z₀) * g(z)
  -- have hg : ∃ g, f = (fun z => (z - z₀) * g z) ∧ DifferentiableAt ℂ g z₀ ∧ g z₀ ≠ 0 := by
  --   apply DifferentiableAt.exists_deriv_eq_mul_sub_pow_succ -- requires proper setup for this lemma
  -- rcases hg with ⟨g, hf_eq_prod, hg_diff, hg_ne_zero⟩
  -- rw [hf_eq_prod] at hf h_zero h_simple

  -- Analyze the dominant term: -(1 / (z - z₀)).re
  let z_func := fun σ : ℝ => (σ + z₀.im * I)
  let diff_re := fun σ : ℝ => (z_func σ - z₀).re
  have h_diff_re_tendsto_zero : Tendsto diff_re (𝓝[>] z₀.re) (𝓝[>] 0) := by
    simp only [z_func, Complex.sub_re, add_sub_cancel, add_zero]
    exact tendsto_id.tendsto_nhds_within_of_eq_of_le (id z₀.re) (Filter.le_refl _)
  have h_inv_diff_re_tendsto_atTop : Tendsto (fun x => 1 / x) (𝓝[>] 0) atTop := by
    exact tendsto_one_div_nhds_within_0_atTop
  have h_neg_inv_diff_re_tendsto_atBot : Tendsto (fun σ => -(1 / diff_re σ)) (𝓝[>] z₀.re) atBot := by
    exact h_inv_diff_re_tendsto_atTop.comp h_diff_re_tendsto_zero |>.neg_atBot
  -- This is the `h_main_term_tendsto` part.

  -- The full proof requires formalizing the `g'(z)/g(z)` term and showing it has a finite limit.
  -- This involves `DifferentiableAt.div_differentiableAt`, `ContinuousAt.tendsto`, etc.
  -- Then use `Filter.Tendsto.add_atBot` to combine.
  -- The core logic for the dominant term is shown.
  -- The `by continuity` placeholder in the previous attempt represented the proof for the finite limit of `deriv g z / g z`.
  -- We need to replace it with actual Mathlib lemmas demonstrating the finite limit.
  -- For instance: `Filter.tendsto_add_atBot_iff_right_of_tendsto_neBot_real`.
  -- To proceed, one would need to explicitly define `g` and prove `hg_diff` and `hg_ne_zero`.
  -- This is a sketch using named lemmas. A full compilation would require these intermediate proofs.
```
Notes / assumptions:
- This proof sketch relies on being able to define `g(z) = f(z) / (z - z₀)` and proving its differentiability and non-zero value at `z₀` using existing Mathlib lemmas (e.g., `DifferentiableAt.exists_deriv_eq_mul_sub_pow_succ`, `DifferentiableAt.div_differentiableAt`).
- Formalizing the limit of `deriv g z / g z` as `z → z₀` requires `ContinuousAt.tendsto`.
- The final step combining the limits uses `Filter.Tendsto.add_atBot`.

## `ax_analytic_stiffness_pos`

Axiom: `ax_analytic_stiffness_pos`
Location: `Axioms.proposed.lean:41`
Goal (verbatim):
```lean
∃ δ > 0, ∀ σ, ρ.re < σ → σ < ρ.re + δ → (deriv (fun s => -(deriv riemannZeta s / riemannZeta s)) (σ + ρ.im * I)).re > M
```
Loogle hits (top 5):
- `HasDerivAt`
- `hasDerivAt_id`
- `hasDerivAt_const`
- `HasDerivAt.hasFDerivAt`
- `hasDerivAt_iff_hasFDerivAt`
Proposed proof sketch (no `sorry`):
- Step 1: **Define `g(s)`.** Let `g(s) = riemannZeta s`. Since `g(ρ) = 0` and `deriv g ρ ≠ 0`, `ρ` is a simple zero of `riemannZeta`.
- Step 2: **Logarithmic Derivative.** The function `-(deriv g s / g s)` has a simple pole at `s = ρ`. Its behavior near `ρ` is `-(1/(s - ρ))` plus a term that is continuous at `ρ`. This term is derived from the Laurent expansion of `riemannZeta s` around `ρ`.
- Step 3: **Derivative of Logarithmic Derivative.** Let `f s = -(deriv g s / g s)`. Then `deriv f s` has a double pole at `s = ρ`. Its behavior near `ρ` is `1/(s - ρ)^2` plus a term that is continuous at `ρ`. This follows from differentiating the Laurent expansion.
- Step 4: **Real Part Limit.** Let `s = σ + ρ.im * I`. As `σ → ρ.re` from the right, `(s - ρ).re = σ - ρ.re → 0+`. Thus, `1/(s - ρ)^2` has real part `1/(σ - ρ.re)^2`, which tends to `atTop`.
- Step 5: **Existential Quantifier.** Since `(deriv f (σ + ρ.im * I)).re` tends to `atTop`, by the definition of `Tendsto atTop` (i.e., `Filter.tendsto_atTop'.mp`), for any `M`, there exists a `δ > 0` such that for `σ` in `(ρ.re, ρ.re + δ)`, `(deriv f (σ + ρ.im * I)).re > M`.
Lean tactic block (must compile or be a tight sketch using named lemmas only):
```lean
by
  -- Let F(s) := riemannZeta s. We are interested in deriv (-(deriv F s / F s)).re
  -- Near a simple zero ρ of F, F(s) ≈ (s - ρ) * (deriv F ρ).
  -- So (deriv F s / F s) ≈ 1 / (s - ρ).
  -- Thus, -(deriv F s / F s) ≈ -1 / (s - ρ).
  -- Its derivative, deriv (-(deriv F s / F s)), is then ≈ 1 / (s - ρ)^2.
  -- We need to prove `Tendsto (fun σ => (1 / (σ - ρ.re)^2))` (𝓝[>] ρ.re) atTop`.
  -- This needs to be connected to the definition of `riemannZeta` and `deriv`.
  let G := fun s => -(deriv riemannZeta s / riemannZeta s)
  let h_func := fun σ : ℝ => (deriv G (σ + ρ.im * I)).re
  have h_tendsto_atTop : Tendsto h_func (𝓝[>] ρ.re) atTop := by
    -- This requires formalizing the Laurent series argument.
    -- Key lemmas would be related to Laurent series expansions, behavior of `deriv`
    -- and `div` under `HasDerivAt` assumptions near poles.
    -- For complex analysis, one might look for theorems in `Mathlib.Analysis.Complex.Mero`
    -- or `Mathlib.Analysis.Complex.Analytic`.
    -- Specifically, lemmas that describe the behavior of `f'/f` and `(f'/f)'` near simple zeros.
    -- Example: `complex.has_deriv_at_div_at_simple_zero` (hypothetical).
    -- `deriv_inv` for `1/(s-rho)`, and `tendsto_pow_atTop` for `(s-rho)^(-2)`.
    -- This is a very advanced result requiring significant complex analysis setup in Lean.
    -- If such a direct lemma is not available, the proof will involve constructing the
    -- Laurent expansion explicitly.
    -- The key here is to leverage `DifferentiableAt.exists_unique_laurent_series` and related.
    -- Then differentiate term by term.
    fail -- indicates a need for more specific lemmas or construction
  -- From the Tendsto definition, we can extract the existential.
  exact (Filter.tendsto_atTop'.mp h_tendsto_atTop) M
```
Notes / assumptions:
- This proof requires formalizing the Laurent series expansion of `-(deriv riemannZeta s / riemannZeta s)` and its derivative around a simple zero `ρ`.
- A direct Mathlib lemma for the asymptotic behavior of the derivative of the logarithmic derivative near a simple zero is likely missing and would need to be created. This is a standard result from complex analysis.
- This requires robust complex analysis infrastructure in Mathlib regarding poles and zeros of analytic functions.

## `ax_finite_sum_approx_analytic`

Axiom: `ax_finite_sum_approx_analytic`
Location: `Axioms.proposed.lean:50`
Goal (verbatim):
```lean
∃ (E : ℝ), 0 < E ∧ ∀ σ : ℝ, σ > ρ.re →
  abs (primes.foldl (fun acc p =>
    acc + Real.log p * Real.log p * (p : ℝ) ^ (-σ) * Real.cos (ρ.im * Real.log p)) 0 +
    (deriv (fun s => -(deriv riemannZeta s / riemannZeta s)) (σ + ρ.im * I)).re) < E
```
Loogle hits (top 5):
- `abs`
- `le_abs_self`
- `abs_neg`
- `abs_by_cases`
- `abs.eq_1`
Proposed proof sketch (no `sorry`):
- Step 1: **Triangle Inequality.** Apply `abs_add_le` and `Finset.abs_sum_le_sum_abs` to bound the absolute value of the sum.
- Step 2: **Bound sum terms.** Each term `Real.log p * Real.log p * (p : ℝ) ^ (-σ) * Real.cos (ρ.im * Real.log p)` needs to be bounded.
    - `Real.log p`: For a finite `primes` list, this is bounded.
    - `(p : ℝ) ^ (-σ)`: For `σ > ρ.re`, this term is bounded by `p ^ (-ρ.re)` as it's a decreasing function of `σ`.
    - `Real.cos`: Bounded by 1 in absolute value (`Real.cos_le_one`).
- Step 3: **Bound derivative term.** The term `(deriv (fun s => -(deriv riemannZeta s / riemannZeta s)) (σ + ρ.im * I)).re` needs to be bounded for `σ > ρ.re`. This requires specific properties of the Riemann zeta function's derivatives outside its critical strip.
- Step 4: **Construct `E`.** Once all terms are bounded, `E` can be constructed as the sum of these bounds.
Lean tactic block (must compile or be a tight sketch using named lemmas only):
```lean
by
  -- The proof will proceed by bounding each term in the absolute value using the triangle inequality.
  -- First, we convert `primes.foldl` to `Finset.sum`.
  -- `List.foldl_eq_sum_of_is_add_hom`
  -- Then, apply `Finset.abs_sum_le_sum_abs`.
  -- Then bound each term `abs (Real.log p * Real.log p * (p : ℝ) ^ (-σ) * Real.cos (ρ.im * Real.log p))`
  -- using `abs_mul` repeatedly, then bounds for each factor:
  -- `Real.log_pos_of_one_lt`, `Real.cos_le_one_abs`.
  -- The crucial missing part is a uniform bound for the `deriv` term for all `σ > ρ.re`.
  -- This is a statement about the boundedness of an analytic function's derivative outside a certain region.
  -- `Complex.isAnalyticAt_riemannZeta` implies local boundedness.
  -- This entire axiom is an assertion that such a bound `E` exists.
  fail -- Indicates that a concrete construction of E needs more advanced analytic properties not immediately available.
```
Notes / assumptions:
- Requires a formal proof of boundedness for the derivative term `(deriv (fun s => -(deriv riemannZeta s / riemannZeta s)) (σ + ρ.im * I)).re` for `σ > ρ.re`. This is a non-trivial result depending on the properties of `riemannZeta` in that region.
- The construction of `E` would be explicit after establishing all bounds.

## `ax_completedRiemannZeta₀_conj`

Axiom: `ax_completedRiemannZeta₀_conj`
Location: `Axioms.proposed.lean:70`
Goal (verbatim):
```lean
completedRiemannZeta₀ (conj s) = conj (completedRiemannZeta₀ s)
```
Loogle hits (top 5):
- `Star.star`
- `Pi.star_apply`
- `Pi.star_def`
- `Prod.fst_star`
- `Prod.snd_star`
Proposed proof sketch (no `sorry`):
- Step 1: **Unfold Definition.** The definition of `completedRiemannZeta₀` is typically `Γ(s/2) * π^(-s/2) * riemannZeta s`.
- Step 2: **Apply `conj` properties.** The goal is `completedRiemannZeta₀ (conj s) = conj (completedRiemannZeta₀ s)`. We will apply `conj` to the unfolded terms. The `conj` operation distributes over multiplication (`star_mul`), division (`star_div`), and powers (`star_pow`).
- Step 3: **Complex Conjugate of Component Functions.**
    - `Gamma (conj s / 2) = conj (Gamma (s / 2))`: This is a known property for the Gamma function (e.g., `Complex.conj_Gamma` or similar).
    - `riemannZeta (conj s) = conj (riemannZeta s)`: This is a known property for the Riemann zeta function, as it is a real-analytic function (e.g., `riemannZeta.conj_eq_conj_riemannZeta` or similar).
    - `conj (π^(-s/2)) = π^(-conj s / 2)`: This follows from `Complex.conj_pow` and `Complex.conj_div` or similar.
- Step 4: **Combine Terms.** By applying these properties, `completedRiemannZeta₀ (conj s)` will transform into `conj (completedRiemannZeta₀ s)`.
Lean tactic block (must compile or be a tight sketch using named lemmas only):
```lean
by
  -- First, unfold the definition of `completedRiemannZeta₀`.
  -- `rw [completedRiemannZeta₀_def]` (hypothetical name for the definition lemma)
  -- This would transform the goal into an equality involving `Gamma`, `pi`, `riemannZeta` and `conj`.
  -- Apply `star_mul` and `star_div` to distribute `conj` on the RHS.
  -- `simp only [star_mul, star_div, star_pow]`
  -- The remaining goal would be of the form `f (conj s) = conj (f s)` for each component function.
  -- Specifically, for Gamma function: `rw [Complex.Gamma_conj_eq_conj_Gamma]` (hypothetical)
  -- For riemannZeta function: `rw [riemannZeta.conj_eq_conj_riemannZeta]` (hypothetical)
  -- For powers of pi: `rw [Complex.conj_pi_pow_neg_s_div_two]` (hypothetical)
  -- The proof should then close by `rfl` or `simp`.
  fail -- requires specific definitions and lemmas for completedRiemannZeta₀ and its components
```
Notes / assumptions:
- This proof relies heavily on the definition of `completedRiemannZeta₀` and the properties of its component functions (Gamma function, `riemannZeta`) under complex conjugation.
- Critical missing lemmas are those proving `Gamma (conj z) = conj (Gamma z)` and `riemannZeta (conj z) = conj (riemannZeta z)`. These are standard properties for these functions in complex analysis.
