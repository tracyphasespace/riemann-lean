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

## Canonical status statement (external wording, fixed after review round 3)

> We audited eleven coefficient-dependent touchpoints in [Z23] §5. Each is covered by a machine-checked theorem derived from the five-condition modulus interface. We found no additional coefficient dependence. The remaining unformalized assembly consists of the coefficient-independent analytic scaffolding identified in [Z23] §7.1. We therefore claim **arithmetic completeness of the interface — five modulus conditions suffice for every identified coefficient-dependent input** — not yet a formal abstract version of Theorem 5.8.

Two precision rules bound this claim. **Sufficiency, not necessity**: no minimality claim is made — none of the five conditions has been shown unweakenable. **Enumeration is not kernel-verified**: the kernel certifies that each of the eleven touchpoints is covered; that the *list of eleven is exhaustive* is a human/AI audit of [Z23] §5, the same epistemic type as the §7.1 scaffolding accounting, and it is where an error would live if one lives anywhere. On the counterexample: `dh_not_eulerStiffnessC` is a genuine second check — the 1 + κ² defect survives the modulus embedding — beyond the single support-gate `dh_not_eulerStiffness`.

## What the frame produces: the ceiling–factorization duality

The pre-registered failure point for F4 — an off-diagonal bilinear sum inexpressible from the five diagonal fields — resolved in its contrapositive, and the resolution is a result. The closure table shows Prop 5.6's off-diagonal terms O₁, O₂ covered by the Montgomery–Vaughan inequality (coefficient-free) plus *diagonal-derived* moments: in the bandwidth-≤1 regime, **the proof never evaluates off-diagonal prime correlations — it only dominates them.** The diagonal interface suffices *precisely because* the method stays under the ≈0.68185 ceiling, and the ceiling exists *precisely because* the method is diagonal-blind past Fourier support 1. **The factorization and [Z23] Remark 1.1 are two faces of one fact.**

This sharpens the ledger's falsifier (b) from an adopted expectation into a machine-checkable criterion:

> **Any unconditional proof of an on-line proportion exceeding ≈ 0.68185 cannot factor through `EulerStiffness`: it must consume at least one additional field of bilinear/additive-correlation type, and the interface now defines exactly what "new input" means.**

This is the first place in the program where the frame *produces* a criterion rather than reframing a result — the bar the ledger's §5 accepted ("make the frame produce something"), met at its first opportunity.

## Milestones

- **F1 (this commit): the derivable-lemma layer, easy grade.** `Factorization.lean`: F1.1 second-moment bound Σf² ≤ (log x)·(log 4+4)·x; F1.2 crude √-moment (Σ f/√n)² ≤ x·Σ f²/n (Cauchy–Schwarz — pairs with `mertens_energy` for the √x·log x grade); F1.3 the MV frequency spacing log(n+1) − log n ≥ 1/(n+1) from integer support alone. All from the five fields; kernel-checked.
- **F2a (DONE, same day): the sharp √-moment — by dyadic descent, not Abel.** `sum_div_sqrt_le` / `sum_div_sqrt_le_real` (kernel-checked): Σ f(n)/√n ≤ 2(√2+1)(log 4+4)·√x from `chebyshev` + `nonneg` alone. The proof avoids [Z23]'s Abel-summation route entirely: split at n/2, the top block pays (√2/√n)·chebyshev, the bottom recurses; the geometric series telescopes with the exact constant 2(√2+1) = 2/(√2−1). No integrals, no measure theory — finite sums only, and the recursion is the program's own collapse operator (companion §12, Rung 4). **This closes the λ = 1 endpoint**: with F2a, every bound-grade estimate in [Z23] Lemma 5.1 is now interface-derived at full strength. ([Z23]'s constant is 3; ours ≈ 26.2; their Lemma 5.2 remark licenses any absolute constant.)
- **F2b.1 (DONE, same day): the integrated second moment — equality grade, fully discrete.** `integrated_second_moment` (kernel-checked): for any interface-f, Σ_{n≤N} f(n)²/n·(log N − log n) = log³N/6 + O(log²N), **from the `mertens_energy` field alone**. This is the diagnostic result: an inequality can survive abstraction by discarding information, but recovering the exact L³/6 normalization asks whether the interface retains the asymptotic *mass* — and it does. The proof is a **finite Abel summation with no integrals and no measure theory**: a triangular sum swap (`abel_swap`, proved via `Finset.sum_comm'`), telescoping cubes and squares over `Ico` (`telescope_Ico`), per-step comparisons |½a²Δ − (b³−a³)/6| ≤ ½Δ²b and aΔ ≤ ½(b²−a²) (`cube_step`, `sq_step`), and two helper sums — the harmonic bound Σ1/m ≤ 1 + log N, **whose induction step is paid by F1.3's own spacing lemma**, and Σ1/m² ≤ 2 by telescoping. Supporting cast: `apply_one` (f(1) = 0 from the support field), `harmonic_le`, `inv_sq_le`, `log_succ_sub_le` (Δ_m ≤ 1/m). Fifteen theorems total in `Factorization.lean`, all `[propext, Classical.choice, Quot.sound]`.
- **F2b.2: the g-weighted diagonal.** Σ f(n)²/n·g(log n) main term for tapered windows (‖g′‖ ≤ 2) — the same finite-Abel skeleton applies (swap against g-increments instead of log-increments); natural to fold into F4's window machinery rather than build standalone.
- **F3 (DONE, same day): the modulus interface — phase-blind by definition.** Style-law audit mid-build (McSheery: "are we staying in Cl(N,N) and avoiding the complex plane?") caught the first draft carrying ℂ in a structure definition. The compliant design is stronger: since all four fields read only ‖g‖, `EulerStiffnessC g` is *defined* as `EulerStiffness (fun n => ‖g n‖)` — the concept is modulus + rotor, the interface consumes the modulus (a real object), ℂ appears only as the standard model (shadow, never carrier). Consequences become near-definitional: `EulerStiffnessC.norm` (modulus reduction) is `id`; **`EulerStiffnessC.twist`** (rotor invariance — the Dirichlet shape, [Z23] §7.3's "phases enter all bounds only through |aₙ|") is a `funext`; F2a/F2b transfer as one-line corollaries (`sum_norm_div_sqrt_le`, `integrated_second_momentC`); ζ embeds (`eulerStiffnessC_vonMangoldt`); and D-H is excluded from the modulus interface verbatim (`dh_not_eulerStiffnessC` — the 1 + κ² defect survives the embedding). Twenty-two `Factorization` theorems, all standard axioms. **F3b (open)**: the true primitive-character instance Λ(n)χ(n) — sub-unimodular at p ∣ q — needs the finitely-many-primes Mertens correction.
- **F4a (DONE, same day): arithmetic closure of the prime side.** The last two coefficient-consuming touchpoints of [Z23] §5 are now interface-derived: **`tapered_diagonal`** — the general-window diagonal main term (Prop 5.6 / §7.1, the heart of the Frobenius asymptotic), proved by sandwiching the window between sharp cutoffs at N and M and applying F2b.1 twice, with defect C·log²N + (taper width)·log²N, exactly [Z23]'s (1 + O(w/L)) shape; and `sum_mul_log_div_sqrt_le` (the log-weighted √-moment). **The arithmetic-closure table** — every step of [Z23] §5 that reads coefficients, with its covering theorem:

  | §5 coefficient touchpoint | Covering theorem (interface-derived) |
  |---|---|
  | Σ Λ(n) ≪ x (Lemma 5.1) | `chebyshev` field / `psi_nat_le` |
  | Σ Λ²/n = ½log²x + O(log x) | `mertens_energy` field |
  | Σ Λ(n)² ≪ x log x | F1.1 `sum_sq_le` |
  | Σ Λ/√n ≪ √x (sharp, λ=1) | F2a `sum_div_sqrt_le` |
  | Σ Λ·log n/√n | F4a `sum_mul_log_div_sqrt_le` |
  | MV frequency spacing; Σ aₙ²/δₙ | F1.3 `freq_spacing` + F1.1 |
  | integrated second moment (5.2b) | F2b.1 `integrated_second_moment` |
  | tapered/general-window diagonal (Prop 5.6, §7.1) | F4a `tapered_diagonal` |
  | O₂ off-diagonal ((Σ aₙ)²) | F2a squared |
  | Prop 5.7 cross terms (Σ aₙ/log n-type) | F2a (log n ≥ log 2 on the range) |
  | complex/Dirichlet coefficients (Thm E) | F3 modulus interface + `twist` |

  **No obstruction was found: every *identified* arithmetic touchpoint sees the interface, not Λ** (enumeration caveat in the canonical status statement above). The remaining unformalized §5 content — the Gabor/Poisson window identities, Dirichlet-kernel bounds, Stirling, and the assembly of Theorem 5.8 — is *coefficient-free by [Z23]'s own accounting* (§7.1: "Nothing in Sections 4–5 used that φ is flat-topped, only [window properties]"; the zero side is already abstract via `strut_hyperbolic_shadow_bound`). Precise status: **the factorization holds at arithmetic completeness** — the abstraction demonstrably supplies every coefficient input at full strength, bounds and main terms both. This is strictly stronger than F0's "architecture level" and strictly weaker than the full abstract Theorem 5.8, which additionally requires formalizing the coefficient-free analytic scaffolding (**F4-final**, large, zero arithmetic content, hence no *interface* obstruction can arise there on [Z23]'s own accounting — a research assessment, stated here and not for external use until F4-final compiles).
- **F5 (conditional on F4): the abstract theorem.** Completed-package + `EulerStiffnessC` ⟹ 2/3-type bounds; [Z23] Theorems A–E become two instantiations.

## Falsification discipline

Per the standing rule: the interface must continue to *reject* Davenport–Heilbronn at every stage (its log-derivative coefficients violate `support_primePow` at n = 6 — `dh_not_eulerStiffness` — and, having zeros in σ > 1, would violate any modulus-growth field of `EulerStiffnessC` as well, per [Z23] Remark 7.2(iii)). Any abstract theorem in F4/F5 that would apply to D-H is wrong by construction and must be discarded.
