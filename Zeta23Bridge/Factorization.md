# The Factorization Experiment: does [Z23] factor through `EulerStiffness`?

**Status: OPEN experiment — Stage F0 (paper-level audit) and Stage F1 (first derived lemmas) recorded here. This is the production commitment (ii) of the ledger (`Papers/Critical_Line_Ledger_Aug2026.md`, §8): *either prove that [Z23]'s bound factors through `EulerStiffness`, or report the obstruction to doing so.* Started August 12, 2026, immediately after ledger v1.3 froze.**

---

## F0. The paper-level dependency audit

Method: every lemma/proposition of [Z23] §§2–6 was checked for the arithmetic it consumes, and each input classified as **FIELD** (one of `EulerStiffness`'s five fields), **DERIVED** (provable from the fields alone), or **PACKAGE** (a property of the completed function/zero side, not of the coefficients — outside the interface by design).

| [Z23] item | Arithmetic consumed | Classification |
|---|---|---|
| Lemma 5.1, Σ_{n≤x} Λ(n) ≪ x | Chebyshev bound | **FIELD** (`chebyshev`) |
| Lemma 5.1, Σ Λ(n)²/n = ½log²x + O(log x) | Mertens second moment | **FIELD** (`mertens_energy`) |
| Lemma 5.1, Σ Λ(n)² ≪ x·log x | — | **DERIVED** (F1.1: `log_size` × `chebyshev`) |
| Lemma 5.1, Σ Λ(n)/√n ≪ √x (and its log-weighted variant) | — | **DERIVED**, two grades: crude √x·log x by Cauchy–Schwarz from `mertens_energy` (F1.2, proven); sharp √x by Abel summation from `chebyshev` (F2, standard, not yet formalized) |
| (5.2) second form, Σ Λ²/n·(L − log n) = L³/6 + O(L²) | — | **DERIVED** (F2: one integration of `mertens_energy`; [Z23] itself proves it as ∫(5.2a)dt/t) |
| Prop 5.6 general-window diagonal, Σ aₙ²·g(log n) | — | **DERIVED** (F2: partial summation from `mertens_energy` with ‖g′‖ ≤ 2; this is [Z23] §7.1's own route) |
| Lemma 5.2 (Montgomery–Vaughan Hilbert inequality) | none (coefficient-free analytic inequality; already formalized in `Zeta23/MV`) | analytic, not arithmetic |
| (5.3) frequency spacing δₙ⁻¹ ≤ 2n and Σ aₙ²/δₙ ≪ XL | integer support geometry + Σ f² | **DERIVED** (F1.3 spacing; then F1.1) |
| (5.4) pointwise ν_X bound | Σ f/√n + Stirling | **DERIVED** + archimedean |
| Prop 5.3 (trace): µ-part / P-part / Π-part | archimedean / Σ f/√n / pole term | archimedean + **DERIVED** + **PACKAGE** |
| Prop 5.5 (M[µ,µ]) | none (archimedean) | archimedean |
| Prop 5.6 off-diagonal O₁, O₂ | MV + Σ f², (Σ f/√n)² | **DERIVED** |
| Prop 5.7 (cross terms) | Σ f/√n, Σ f/(√n·log n)-type sums | **DERIVED** (F2 grade) |
| §2 explicit formula; App A normalization | functional equation, entire completion, contour | **PACKAGE** |
| §4 zero side: ρ ↦ 1−ρ̄ symmetry; N(t+1)−N(t) ≪ log; RvM; tail Prop 4.2 | zero-multiset properties | **PACKAGE** (and the inertia core is already abstract: `strut_hyperbolic_shadow_bound` holds for *any* configuration) |
| §6 assembly | bookkeeping | — |

## F0 verdict (paper level)

**The prime side factors.** Every arithmetic input of [Z23] §5 is a field of `EulerStiffness` or derivable from the fields. No hidden coefficient fact was found. Two precise qualifications:

1. **Endpoint grades.** The crude (Cauchy–Schwarz) derivations lose a log factor on the √-moments, which survives every bandwidth λ < 1 and hence yields the full 2/3-liminf constants via λ → 1⁻ and dyadic summation ([Z23] Remark 6.1 makes exactly this move available). The sharp λ = 1 endpoint uses the Abel-summed grades — still interface-derivable, just more Lean work (F2).
2. **The residue is the completed-function package, by design.** The explicit formula for the specific function, the ρ ↦ 1−ρ̄ symmetry, the Riemann–von Mangoldt density, the unit-interval zero count, and Stirling are properties of the completed object, not of coefficients — the interface was never meant to carry them. The abstract factorization theorem therefore has the shape: *completed-package hypotheses* + `EulerStiffness` ⟹ two-thirds-type bound.
3. **A genuine finding — the interface is the ζ-shaped special case.** [Z23]'s own Theorem E (Dirichlet L-functions) reruns the proof with coefficients Λ(n)χ(n), which are **complex**; `EulerStiffness` as defined (real, nonnegative) does not cover them. The prime side there uses modulus controls |f(n)| ≤ log n plus exact diagonal |χ(n)|² = 1. So the general factorization requires **`EulerStiffnessC`** (modulus form: support, |f(n)| ≤ log n, Σ|f(n)|²/n moment, Chebyshev on |f|, plus a diagonal-exactness field). That Theorem E exists and goes through with only these changes is strong evidence the factorization is real — [Z23] already ran the proof through the interface twice, for two different instances, without naming it.

**Answer to the ledger's question, at current evidence:** *it factors, at the architecture level* — with the completed-package residue named (as it must be) and one required generalization (complex/modulus form) identified. What remains to convert this from audited claim to theorem is the Lean work below.

## Milestones

- **F1 (this commit): the derivable-lemma layer, easy grade.** `Factorization.lean`: F1.1 second-moment bound Σf² ≤ (log x)·(log 4+4)·x; F1.2 crude √-moment (Σ f/√n)² ≤ x·Σ f²/n (Cauchy–Schwarz — pairs with `mertens_energy` for the √x·log x grade); F1.3 the MV frequency spacing log(n+1) − log n ≥ 1/(n+1) from integer support alone. All from the five fields; kernel-checked.
- **F2: the Abel layer.** Sharp Σ f/√n ≪ √x from `chebyshev` (adapting [Z23]'s own `Zeta23.Cheb` Abel machinery, which currently hardcodes Λ); the integrated second moment; the g-weighted diagonal. Outcome: the full Lemma 5.1/5.2 list holds for abstract interface-f.
- **F3: `EulerStiffnessC`** (modulus form) + the ζ and Dirichlet instances.
- **F4: the abstract prime side.** Restate [Z23] Theorem 5.8 (trace and Frobenius asymptotics) for abstract f with `EulerStiffnessC`, reusing `Zeta23/MV` and the window machinery. This is the genuinely large item — [Z23]'s §5 is ~15 pages of tapered-window analysis — and the point where "factors" becomes a theorem rather than an audit. If F4 hits a step that consumes coefficient structure beyond the interface, **that step is the obstruction**, and reporting it precisely is an equally valid completion of the experiment.
- **F5 (conditional on F4): the abstract theorem.** Completed-package + `EulerStiffnessC` ⟹ 2/3-type bounds; [Z23] Theorems A–E become two instantiations.

## Falsification discipline

Per the standing rule: the interface must continue to *reject* Davenport–Heilbronn at every stage (its log-derivative coefficients violate `support_primePow` at n = 6 — `dh_not_eulerStiffness` — and, having zeros in σ > 1, would violate any modulus-growth field of `EulerStiffnessC` as well, per [Z23] Remark 7.2(iii)). Any abstract theorem in F4/F5 that would apply to D-H is wrong by construction and must be discarded.
