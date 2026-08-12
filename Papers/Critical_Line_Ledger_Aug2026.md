# A Formal Ledger for the Critical-Line Problem

**Tracy McSheery, with Claude (Anthropic) — August 12, 2026 (ledger v1.2; revision history in §10)**

*This document is written for skeptical readers. Every claim is typed as **proven-classical**, **proven-recent**, **proven-here** (machine-checked, reproducible), **reframing** (no new content claimed), or **heuristic**. Nothing requires trusting the authors; the checked items are checkable by the Lean kernel on your machine.*

---

## 0. What is claimed, and what is not

**Not claimed:** a proof of the Riemann Hypothesis; any new unconditional bound; any new analytic theorem; originality of the individual components, most or all of which are classical and attributed to their owners; originality of the signature-(1,1) mechanism itself, which is stated in [Z23]'s own abstract (see §3).

**Claimed — three separable contributions, in decreasing order of defensibility:**

1. **Formal**: a machine-checked interface (`EulerStiffness`) capturing the Euler-product inputs consumed by [Z23]'s prime side, together with an exact, numerics-free demonstration that the Davenport–Heilbronn counterexample cannot satisfy the interface (§2); and a machine-checked identification of [Z23]'s zero-side mechanism with classical Witt/Clifford quadratic-form structure (§3). *We have not re-derived the two-thirds bound through the interface; no factorization theorem is claimed.*
2. **Methodological**: a formalization discipline — *definitions carry maps; scalar constants appear only in lemmas, as shadows* — under which twenty-six foundational statements compile (§4), plus the standing counterexample rule of §2.
3. **Conceptual, and subordinate to the first two**: a reframing thesis (§5), stated as a thesis: in the unfolded (adelic/torus/operator) presentation, RH is the *naturally-expected* statement, and its distance from theoremhood is one precisely-typed gap. This contribution has value only if it eventually produces mathematics; §8 records what the program commits to producing.

**The open obstruction.** One analytic fact remains open, under several names. Two are **classical equivalents of RH**: (i) the Speiser-circle criterion, (σ−½)·Re(ξ′/ξ)(σ+it) > 0 off the line; (ii) M(x) = O(x^(1/2+ε)) for the Mertens function (Littlewood). Two are **this framework's names for the same obstruction** — "no complementary-series contamination of the zero modes" and "pointwise fairness at the seam" (§5–6) — offered as translations, not as independently proven biconditionals. Nothing in this document discharges the obstruction, and §7 records the known walls constraining any attempt.

## 1. Verification

The formal artifacts are `Zeta23Bridge/Zeta23Bridge.lean` (10 audited theorems) and `Zeta23Bridge/SpongeStage.lean` (16 audited theorems) in this repository (public remote: `github.com/tracyphasespace/riemann-lean`, tag `ledger-v1`; if the tag is not yet visible on the remote, request it from the authors). Toolchain: `leanprover/lean4:v4.33.0-rc2`. Pinned dependency: `anthropics/zeta-23-lean` tag `v1.0` (commit `82ee6340`), which pins Mathlib commit `51e6992e`.

```
cd Zeta23Bridge
lake update            # fetches zeta-23-lean @ v1.0 and its pinned Mathlib
lake exe cache get     # Mathlib olean cache
lake build             # compiles both files
```

Expected output: no errors, no `sorry`, and each of the 26 audited theorems reporting a subset of Lean's three standard axioms `[propext, Classical.choice, Quot.sound]` — the verbatim output is Appendix A (one theorem, `Sponge.orthogonality`, uses only two of the three; the rest use all three; none uses `sorryAx` or any custom axiom).

[Z23]'s own repository carries an independent comparator-style audit of the two-thirds theorem itself.

**[Z23]:** Claude (Anthropic), *More than two thirds of the zeros of the Riemann zeta function lie on the critical line* (Aug 10, 2026): unconditionally, liminf N₀*/N ≥ 2/3 on dyadic windows (Thm A), the same for simple-on-line zeros (Thm B), and liminf N_d/N ≥ 5/6 for distinct zeros (Thm C), with optimized constants 0.6725/0.83625 (Thm D). Prior record 5/12 (Pratt–Robles–Zaharescu–Zeindler 2020); lineage Selberg 1942, Levinson 1974, Conrey 1989. Inputs: Montgomery 1973, made unconditional by Baluyot–Goldston–Suriajaya–Turnage-Butterbaugh 2024; Bombieri 2000 on Weil's quadratic functional. The conditional-to-unconditional blueprint — what would follow "if RH could be removed from Montgomery's proof" — was posed explicitly by Goldston–Suriajaya (2025–26), whom [Z23] credits; the two-thirds constant is Montgomery's RH-conditional constant with RH removed.

## 2. The Euler-product interface, with its falsification test (proven-here)

This is the document's most defensible original content. `EulerStiffness f` is a Prop-structure packaging four quantitative facts about a system's log-derivative coefficients: support on prime powers; nonnegativity; f(n) ≤ log n; the Mertens second moment Σ_{n≤x} f(n)²/n = ½log²x + O(log x); plus the Chebyshev bound. These are the prime-side inputs [Z23] consumes ([Z23] §5, Lemma 5.1); the interface is offered as a *candidate abstraction* of that role — we have not proven that the two-thirds bound factors through it.

* `eulerStiffness_vonMangoldt` (verified): ζ satisfies the interface, from Mathlib's von Mangoldt lemmas and [Z23]'s own Chebyshev–Mertens module.
* `logDeriv6_eq_defect` (verified): for **any** coefficient system, the n = 6 log-derivative coefficient equals (c(6) − c(2)c(3))·log 6 — the multiplicativity defect at the first composite where one can exist. An Euler product is precisely the vanishing of all such defects.
* `dh_logDeriv6_pos`, `dh_not_eulerStiffness` (verified): for the Davenport–Heilbronn function (functional equation, no Euler product, off-line zeros known since 1936), the defect is 1 + κ² — **a sum of squares, nonzero for every real κ**: no numerics, no interval arithmetic, no analytic continuation. D-H provably cannot satisfy the interface.

**Standing rule of the program:** any positivity-flavored claim in this program is required to fail on Davenport–Heilbronn, or it is discarded as having used only the functional equation. A frame that arrives carrying its own counterexample test, and shows exactly where the canonical counterexample fails it — at n = 6, in exact algebra — is what we offer the skeptical reader first.

## 3. The dictionary (proven-here; mechanism due to [Z23])

**Attribution first:** [Z23]'s abstract itself states that each off-line pair {ρ, 1−ρ̄} contributes a block of signature (1,1), and proves the counting via a rank–trace inequality through von Neumann's trace inequality; Bombieri (2000) used the negative index of the same truncations. The mechanism is theirs. What is added here is the formal identification of that mechanism with classical Witt/Clifford structure, kernel-checked:

| Theorem (verified) | Content | Classical owner |
|---|---|---|
| `bivector_commute` | bivectors of mutually orthogonal planes commute in any Clifford algebra | Clifford; Witt decomposition |
| `bivector_sq_neg_one` / `bivector_sq_one` | Euclidean plane: B² = −1 (rotation); split plane: B² = +1 (boost) | Clifford |
| `posIndex_hypBlock`, `negIndex_hypBlock` | the off-line-pair block `!![0,μ;μ,0]` has signature (1,1) | Witt's hyperbolic plane |
| `strut_hyperbolic_shadow_bound` | PSD part of rank ≤ s plus p pulled-back hyperbolic blocks ⟹ n₊ ≤ s + p | Sylvester's law of inertia |
| `shadow_posIndex_le` | positive index is monotone under pull-back (arbitrary maps, no independence assumed) | Sylvester |

Reading: each on-line zero contributes a positive rank-one direction; each off-line pair a Witt hyperbolic plane; the theorem is a budget in which each hyperbolic plane refunds at most one positive direction while consuming two zeros of the census. A structural observation a referee can check in an afternoon: **inertia is monotone under projection while convexity is not** — which helps explain, though it does not by itself establish, why this population-level accounting closes where pointwise-positivity programs (including the first author's earlier program, and the Goldston–Suriajaya question) remain open.

## 4. The formalization discipline (proven-here, 16 further theorems)

The discipline: *definitions carry maps — embeddings, descents, gradings, group averages, coordinates; scalar constants appear only in lemmas, as images under forgetful maps.* Three instances with content:

1. **No literal 1/p in definitions.** The p-stratum is defined as the image of the self-embedding n ↦ pn (divisibility becomes a lemma); the averaging operator is a group average whose Haar weight surfaces in the lemma as the group order; the density shadow is floored division n/p; the volume shadow is φ(∏p) = ∏(p−1). (Dedekind; Gauss; Dirichlet; Euler–Legendre.)
2. **No imaginary unit in definitions.** "s = σ+it" is treated as a commuting pair (non-compact damping generator, compact phase generator); a zero is the simultaneous vanishing of two real quadratures; characters are rotors — the ℂ-free averaging identity is the telescope (1−R)·ΣR^k = 1−R^p, verified in any ring (`rotor_telescope`, `rotor_haar_annihilate`).
3. **One circle per dimension.** The compliant global object is Bohr's lift of ζ to ∏_p S¹ (H. Bohr); the vertical line is the Kronecker winding, aperiodic because {log p} are rationally independent — **which is unique factorization**, verified as `log_independence` (exponentiate the relation; `Nat.factorization` reads the exponents back).

Further verified: the p-adic tower with valuation-as-descent-count (Kummer–Hensel); CRT in image form; the free-commutative-monoid coordinates (Euclid–Gauss); the collapse fixed point n = p^v·core; retraction of the full sieve to {1} (Euclid); the ordering identity x∂ + ∂x = 2·x∂ + 1 (the canonical commutator in symmetrized form — the constant of the Berry–Keating generator, before division); the Artin–Whaples product-formula cell n·∏(p^{v_p})⁻¹ = 1.

## 5. The reframing thesis (interpretation; no new content claimed)

In the unfolded presentation the following are classical identifications: the critical line = the unitary axis of the dilation group (half-densities; Mellin–Plancherel) = the fixed locus of s ↦ 1−s̄ = the RMS composition scale of independent contributions = the spectrum of the symmetrized dilation generator (xp+px)/2 = xp + ½ (Berry–Keating; Connes), whose ½ is the fair split of [∂, x] = 1; on-line vs off-line is the principal-vs-complementary series dichotomy — the same type-statement as Selberg's eigenvalue-¼ conjecture (¼ = s(1−s) at the mirror).

Calibration (classical): **Bohr–Jessen** — the lifted torus governs ζ's value distribution faithfully for σ > 1/2; at σ = 1/2 the regime changes (Selberg's central limit theorem, variance ½ log log t). The zeros live exactly on the seam where the lifted object and its one-dimensional shadow part ways.

The thesis: in this frame, RH is the naturally-expected statement — the generic behavior of independent phases. But:

> **Default ≠ proof.** Generic phase behavior controls typical, population-level behavior. RH requires the exclusion of *every* exceptional off-line mode, and the population certificate is insensitive to o(N) exceptions (§7). **Genericity explains why RH looks natural; arithmetic rigidity is what would have to turn naturality into theorem.** The frame locates the difficulty; it does not discharge it, and it cannot be cited as evidence at the seam (Bohr–Jessen faithfulness is a theorem strictly above σ = 1/2 and precisely the open question at it).

The authors are aware that Deninger's program and Connes' trace-formula program make structurally similar naturality claims; the community's standing response — "make the frame produce something" — is accepted as the bar, and §8 states what this program commits to producing.

## 6. The ledger

| # | Component | Status | Owner |
|---|---|---|---|
| 1 | The flat frame: valuations as independent commuting derivations; CRT | proven-classical (formalized here) | Euclid, Gauss; Kummer–Hensel |
| 2 | Aperiodicity of the joint winding (ℚ-independence of {log p}) | proven-classical (formalized here) | Kronecker–Weyl; FTA |
| 3 | Criticality of the volume: zero volume ⟺ Σ1/p = ∞; log-speed decay; product formula | proven-classical (formalized here, in part) | Euler, Mertens; Artin–Whaples |
| 4 | Prime–zero duality (explicit formula) | proven-classical | Riemann, von Mangoldt, Weil |
| 5 | Fairness on average at the seam | proven-classical | Selberg (CLT); Bohr–Jessen above the seam |
| 6 | ≥ 2/3 of zeros on the line (0.6725 optimized; Thms A/B/D), ≥ 5/6 distinct (Thm C) | proven-recent | [Z23]; Montgomery; BGST 2024; GS 2025–26 |
| 7 | The Euler-product interface + exact counterexample discrimination | proven-here | §2; Davenport–Heilbronn as control |
| 8 | The open obstruction (§0): classically, Speiser-circle positivity / Littlewood's Mertens bound; in this framework's vocabulary, "pointwise fairness" | **open** | — |

**Within this ledger, Row 8 is the unresolved statement: it is this framework's name for the pointwise condition that would amount to RH.** Rows 1–7 are the decomposition the authors believe a reader should hold while evaluating any claimed approach, including this one.

## 7. Known walls (stated so the reader does not have to)

1. **Bandwidth ceiling.** With pair-correlation input of Fourier support ≤ 1 (the unconditional regime), the inertia method's ceiling is ≈ 0.68185; supports ≈ 1.04 / 1.26 / 1.70 are needed for 0.70 / 0.80 / 0.90 [Z23, Rem. 1.1]. Progress past the ceiling requires additive prime correlations of Hardy–Littlewood strength.
2. **Population vs pointwise.** The certificate is insensitive to o(N) exceptional zeros; no accounting of this kind reaches Row 8. Every known pointwise principle here is equivalent to RH.
3. **The parity barrier** (Selberg): sieve weights operating at density level cannot separate parity classes; densities forget phases. Any claim to bypass it must state which non-density information it consumes.
4. **The seam** (Bohr–Jessen): see the box in §5.
5. **Independence at the boundary**: Mertens' ∏(1−1/p) vs the true prime density differ by e^γ — the sieve's independence heuristic fails at the window edge; all boundary claims require the analytic corrections.

## 8. Falsifiability and production commitments

**Falsifiers.** (a) An element of the Selberg class (Euler product + standard functional equation) violating its Riemann hypothesis would kill this program's "stiffness ⟹ fairness-by-default" interpretation — though we note it would simultaneously falsify much of analytic number theory's working picture, so it is not a *discriminating* test of this frame specifically. (b) More discriminating: a substantial advance of the on-line proportion past ≈ 0.682 by folded methods consuming **no** new additive-correlation input would directly weaken this frame's diagnosis of where the difficulty lives. (c) Any failure of the machine-checked artifacts to reproduce withdraws the corresponding ledger rows.

**Pre-registered expectation** (theorem-backed via [Z23] Rem. 1.1, stated here as this frame's prediction about the field): every future unconditional improvement of the on-line proportion beyond ≈ 0.68185 will be traceable to additive prime-correlation input of Fourier support > 1; the next natural waypoint is 13/18 ≈ 0.722 under a fourth-moment hypothesis. If an improvement arrives that provably consumes only bandwidth-≤1 data, this frame's account is wrong.

**Production commitments.** The program's next deliverables, by which it asks to be judged: (i) the native test — a re-derivation of one zero-side statement entirely inside the formalized frame, with the D-H control required to fail (companion paper §10, Stage 3); (ii) the interface factorization — either prove that [Z23]'s bound factors through `EulerStiffness`, or report the obstruction to doing so.

## 9. Glossary (for the companion paper's vocabulary)

External readers may encounter the program-internal vocabulary in the companion document (`CliffordNN_TwoThirds_Aug2026.md`). Translations: *sponge* (completed) = the profinite integers ẑ = ∏ℤ_p with Haar measure (each ℤ_p homeomorphic to the Cantor set); *stratum/tower* = pℤ and the filtration p^kℤ, valuation = descent count; *skeleton* = the unit group ẑ^× (Haar measure zero by second Borel–Cantelli; full local Hausdorff dimension); *collapse* = the log-derivative, Λ(p^k) = log p; *outward bivector* = the (1,1) block of an off-line pair (Witt); *the seam* = σ = 1/2 as the boundary of Bohr–Jessen faithfulness; *fairness* = RMS-scale composition of mode amplitudes, Row 8 being its pointwise form. The reader is invited to check the artifacts, attack Row 8, and ignore the vocabulary.

## 10. Provenance and versioning

The two-thirds theorem and its Lean formalization are [Z23]'s (Anthropic, Aug 2026). Classical components are owned as attributed. The Lean artifacts here were produced in an interactive session (McSheery/Claude, Aug 12, 2026); ledger v1.0 was drafted the same day and revised to v1.1 after three independent external reviews, whose accepted findings included: the §3 attribution of the (1,1) mechanism to [Z23]'s abstract; the demotion of "isolating exactly" to "candidate abstraction" in §2; the separation of classical RH-equivalents from framework translations in §0; the Row 8 rewording; the §5 firewall box; the removal of a heuristic archimedean remark to the companion paper; and this versioning section. The companion paper records the program-internal development. Repository tag for this revision: `ledger-v1`. v1.2 (same day) adds the verbatim audit appendix, corrects “each reporting exactly” to the observed subset behavior, and adds the repository-root reviewer routing.

---

## Appendix A. Verbatim axiom audit (26 theorems)

Output of `lake env lean` on `Zeta23Bridge.lean` and `SpongeStage.lean`, toolchain `leanprover/lean4:v4.33.0-rc2`, against `zeta-23-lean` v1.0 / Mathlib `51e6992e`:

```
'Zeta23Bridge.bivector_commute' depends on axioms: [propext, Classical.choice, Quot.sound]
'Zeta23Bridge.bivector_sq_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'Zeta23Bridge.posIndex_hypBlock' depends on axioms: [propext, Classical.choice, Quot.sound]
'Zeta23Bridge.negIndex_hypBlock' depends on axioms: [propext, Classical.choice, Quot.sound]
'Zeta23Bridge.strut_hyperbolic_shadow_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'Zeta23Bridge.eulerStiffness_vonMangoldt' depends on axioms: [propext, Classical.choice, Quot.sound]
'Zeta23Bridge.logDeriv6_eq_defect' depends on axioms: [propext, Classical.choice, Quot.sound]
'Zeta23Bridge.dh_logDeriv6_pos' depends on axioms: [propext, Classical.choice, Quot.sound]
'Zeta23Bridge.dh_not_eulerStiffness' depends on axioms: [propext, Classical.choice, Quot.sound]
'Zeta23Bridge.zeta_logDerivAt6' depends on axioms: [propext, Classical.choice, Quot.sound]
'Sponge.orthogonality' depends on axioms: [propext, Quot.sound]
'Sponge.descent_count' depends on axioms: [propext, Classical.choice, Quot.sound]
'Sponge.haar_projector' depends on axioms: [propext, Classical.choice, Quot.sound]
'Sponge.density_shadow' depends on axioms: [propext, Classical.choice, Quot.sound]
'Sponge.volume_shadow' depends on axioms: [propext, Classical.choice, Quot.sound]
'Sponge.parity_projector' depends on axioms: [propext, Classical.choice, Quot.sound]
'Stage2.descent_by_two' depends on axioms: [propext, Classical.choice, Quot.sound]
'Stage2.half_step' depends on axioms: [propext, Classical.choice, Quot.sound]
'Stage2.log_linearizes' depends on axioms: [propext, Classical.choice, Quot.sound]
'Stage2.sieve_times_tower' depends on axioms: [propext, Classical.choice, Quot.sound]
'Stage3.collapse_reconstruct' depends on axioms: [propext, Classical.choice, Quot.sound]
'Stage3.cascade_limit' depends on axioms: [propext, Classical.choice, Quot.sound]
'Stage3.rotor_haar_annihilate' depends on axioms: [propext, Classical.choice, Quot.sound]
'Stage3.log_independence' depends on axioms: [propext, Classical.choice, Quot.sound]
'Stage3.fair_split' depends on axioms: [propext, Classical.choice, Quot.sound]
'Stage3.product_formula' depends on axioms: [propext, Classical.choice, Quot.sound]
```
