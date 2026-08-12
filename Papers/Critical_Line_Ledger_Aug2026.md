# A Formal Ledger for the Critical-Line Problem

**Tracy McSheery, with Claude (Anthropic) — August 13, 2026**

*This document is written for skeptical readers. Every claim below is typed as **proven-classical**, **proven-recent**, **proven-here** (machine-checked, reproducible by two commands), **reframing** (no new content claimed), or **open**. There is exactly one item in the last category. Nothing requires trusting the authors; the checked items are checkable by the Lean kernel on your machine.*

---

## 0. What is claimed, and what is not

**Not claimed:** a proof of the Riemann Hypothesis; any new unconditional bound; any new analytic theorem; originality of the individual components, most or all of which are classical and attributed below to their owners.

**Claimed:** (1) a machine-checked dictionary showing that the linear-algebra core of the 2026 two-thirds theorem [Z23] is an inertia computation in a split-signature quadratic space, with the off-line zero pairs as the hyperbolic planes; (2) a machine-checked interface (`EulerStiffness`) isolating exactly what the Euler product contributes to that proof, together with an exact, numerics-free demonstration that the Davenport–Heilbronn counterexample cannot satisfy the interface; (3) a formalization discipline ("definitions carry maps; scalars appear only in lemmas, as shadows") under which sixteen further foundational statements compile; (4) a reframing thesis, stated as such: that in the unfolded (adelic/torus/operator) presentation, RH is the *default* statement — the generic behavior of independent phases — and its distance from theoremhood is one precisely-typed gap, not a fog.

**The one open item**, in its equivalent classical forms: Re(ξ′/ξ) > 0 for σ > 1/2 (Speiser circle); M(x) = O(x^(1/2+ε)) (Mertens function); no complementary-series contamination in the zero modes; "pointwise fairness at the seam" in the vocabulary of §6. Each form is equivalent to RH. Nothing in this document discharges it, and §7 records the known walls that constrain any attempt.

## 1. Verification first

The formal artifacts live in `Zeta23Bridge/` of this repository (`Zeta23Bridge.lean`, 10 theorems; `SpongeStage.lean`, 16 theorems), pinned against the Lean 4 formalization of [Z23]:

```
cd Zeta23Bridge
lake update            # fetches anthropics/zeta-23-lean @ v1.0 and its pinned Mathlib
lake exe cache get     # Mathlib olean cache
lake build             # compiles both files; #print axioms output appears in the log
```

Expected: no errors, no `sorry`, and every audited theorem reporting exactly `[propext, Classical.choice, Quot.sound]` — Lean's three standard axioms. [Z23]'s own repository carries an independent comparator-style audit of the two-thirds theorem itself.

**[Z23]:** Claude (Anthropic), *More than two thirds of the zeros of the Riemann zeta function lie on the critical line* (Aug 10, 2026); prior record 5/12 (Pratt–Robles–Zaharescu–Zeindler 2020); lineage Selberg 1942, Levinson 1974, Conrey 1989. Inputs: Montgomery 1973 pair correlation made unconditional by Baluyot–Goldston–Suriajaya–Turnage-Butterbaugh 2024; Bombieri 2000 on Weil's quadratic functional.

## 2. The dictionary (proven-here, 10 theorems)

[Z23] compresses Weil's explicit-formula form — positivity of which is equivalent to RH (Weil 1952) and which is unconditionally *indefinite* (a Krein-space metric) — to a finite real symmetric matrix, and bounds the proportion of on-line zeros by two trace moments. The dictionary states, and the kernel verifies, that its zero-side mechanism is classical quadratic-form theory:

| Theorem (verified) | Content | Classical owner |
|---|---|---|
| `bivector_commute` | bivectors of mutually orthogonal planes commute in any Clifford algebra | Clifford; Witt decomposition |
| `bivector_sq_neg_one` / `bivector_sq_one` | Euclidean plane: B² = −1 (rotation); split plane: B² = +1 (boost) | Clifford |
| `posIndex_hypBlock`, `negIndex_hypBlock` | the off-line-pair block `!![0,μ;μ,0]` has signature (1,1) | Witt's hyperbolic plane |
| `strut_hyperbolic_shadow_bound` | PSD part of rank ≤ s plus p pulled-back hyperbolic blocks ⟹ n₊ ≤ s + p | Sylvester's law of inertia |
| `shadow_posIndex_le` | positive index is monotone under pull-back (arbitrary maps, no independence assumed) | Sylvester |

Reading: each on-line zero contributes a positive rank-one direction; each off-line pair {ρ, 1−ρ̄} contributes a signature-(1,1) block — *is* Witt's hyperbolic plane; the theorem is a budget argument in which each hyperbolic plane refunds at most one positive direction while consuming two zeros of the census. The structural point a referee can check in an afternoon: **inertia is monotone under projection while convexity is not** — which is why this population-level accounting closes where pointwise-positivity programs (including the earlier program of the first author, and the Goldston–Suriajaya question it answers) remain open.

## 3. The Euler-product interface, with its falsification test (proven-here)

What does the Euler product actually contribute to [Z23]? Exactly four quantitative facts about the log-derivative coefficients, packaged as a Prop-structure:

`EulerStiffness f` : support on prime powers; nonnegativity; f(n) ≤ log n; and the Mertens second moment Σ_{n≤x} f(n)²/n = ½log²x + O(log x); plus the Chebyshev bound.

* `eulerStiffness_vonMangoldt` (verified): ζ satisfies the interface — from Mathlib's von Mangoldt lemmas and [Z23]'s own Chebyshev–Mertens module.
* `logDeriv6_eq_defect` (verified): for **any** coefficient system, the n = 6 log-derivative coefficient equals (c(6) − c(2)c(3))·log 6 — the multiplicativity defect at the first composite where one can exist. An Euler product is precisely the vanishing of all such defects.
* `dh_logDeriv6_pos`, `dh_not_eulerStiffness` (verified): for the Davenport–Heilbronn function (functional equation, no Euler product, known off-line zeros — Davenport–Heilbronn 1936), the defect is 1 + κ² — **a sum of squares, nonzero for every real κ**: no numerics, no interval arithmetic, no analytic continuation. D-H provably cannot satisfy the interface.

For a skeptic this pair is the load-bearing exhibit: the frame arrives carrying its own counterexample test, and shows *exactly why* the known counterexample fails it — at n = 6, in exact algebra. Any positivity-flavored claim in this program is required to fail on D-H or it is discarded as having used only the functional equation.

## 4. The formalization discipline and the frame (proven-here, 16 theorems)

The discipline (stated in full in the companion paper, §§10–12): *definitions carry maps — embeddings, descents, gradings, group averages, coordinates; scalar constants appear only in lemmas, as images under forgetful maps.* Three instances of the discipline with content:

1. **No literal 1/p in definitions.** The p-stratum is defined as the *image of the self-embedding* n ↦ pn (divisibility is the lemma); the averaging operator is a group average whose Haar weight surfaces in the lemma as the group order; the density shadow is floored division n/p; the volume shadow is the totient identity φ(∏p) = ∏(p−1). (Owners: Dedekind, Gauss, Dirichlet, Euler–Legendre.)
2. **No imaginary unit in definitions.** "s = σ+it" is treated as a commuting pair (non-compact damping generator, compact phase generator); a zero is the simultaneous vanishing of two real quadratures; characters are rotors — the ℂ-free Haar projector is the telescope (1−R)·ΣR^k = 1−R^p, verified in any ring (`rotor_telescope`, `rotor_haar_annihilate`).
3. **One circle per dimension.** The compliant global object is Bohr's lift of ζ to ∏_p S¹ (H. Bohr, 1920s); the vertical line is the Kronecker winding, aperiodic because {log p} are rationally independent — **which is unique factorization**, and is verified here as `log_independence` (a log-relation exponentiates to an equality of prime-power products; `Nat.factorization` reads the exponents back).

Further verified items: the p-adic tower with valuation-as-descent-count (Kummer–Hensel); CRT in image form (`orthogonality`); the free-commutative-monoid coordinates (multiplication of integers = addition of valuation vectors; Euclid–Gauss); the collapse fixed point n = p^v·core; the retraction of the full sieve to {1} (Euclid); the ordering identity x∂ + ∂x = 2·x∂ + 1 (the canonical commutator in symmetrized form — the constant of the Berry–Keating generator before division); and the Artin–Whaples product-formula cell n·∏(p^{v_p})⁻¹ = 1.

## 5. The reframing thesis (no new content claimed; stated for evaluation)

In the unfolded presentation, the following are *identifications*, each classical:

* the critical line = the unitary axis of the dilation group (half-densities; Mellin–Plancherel);
* = the fixed locus of the adjoint involution s ↦ 1 − s̄;
* = the RMS composition scale of independent contributions (CLT exponent);
* = the spectrum of the symmetrized dilation generator (xp + px)/2 = xp + ½, whose ½ is the fair split of the canonical commutator [∂, x] = 1 (Berry–Keating 1999; Connes);
* on-line vs off-line = principal series vs complementary series — the same type-dichotomy as Selberg's eigenvalue-¼ conjecture (¼ = s(1−s) at the mirror).

Calibration of the unfolded frame (classical): Bohr–Jessen — the torus governs ζ's value distribution faithfully for σ > 1/2; at σ = 1/2 the regime changes (Selberg's central limit theorem, variance ½ log log t). **The zeros live exactly on the seam where the lifted object and its one-dimensional shadow part ways.** The thesis, stated honestly: in this frame RH is the *default* — the assertion that no sparse conspiracy of modes escapes the generic (RMS) composition — and the frame *locates* the difficulty rather than dissolving it. The authors are aware that Deninger's program and Connes' trace-formula program make structurally similar naturality claims; the community's standing (and in our view correct) response — "make the frame produce something" — is accepted as the bar.

## 6. The ledger

| # | Component | Status | Owner |
|---|---|---|---|
| 1 | The flat frame: valuations as independent commuting derivations; CRT | proven-classical (formalized here) | Euclid, Gauss; Kummer–Hensel |
| 2 | Aperiodicity of the joint winding (ℚ-independence of {log p}) | proven-classical (formalized here) | Kronecker–Weyl; FTA |
| 3 | Criticality of the volume: zero volume ⟺ Σ1/p = ∞; log-speed decay; product formula | proven-classical (formalized here, in part) | Euler, Mertens; Artin–Whaples |
| 4 | Prime–zero duality (explicit formula) | proven-classical | Riemann, von Mangoldt, Weil |
| 5 | Fairness on average at the seam | proven-classical | Selberg (CLT); Bohr–Jessen above the seam |
| 6 | Fairness for ≥ 2/3 of modes (0.6725 optimized), 5/6 distinct | proven-recent | [Z23], from Montgomery; BGST 2024 |
| 7 | The Euler-product interface + counterexample discrimination | proven-here | §3; Davenport–Heilbronn as control |
| 8 | **Fairness pointwise** (≡ RH) | **open** | — |

Row 8 is the entire remaining content of the Riemann Hypothesis. Rows 1–7 are, in the authors' view, the decomposition a reader should hold while evaluating any claimed approach, including ours.

## 7. Known walls (stated so the reader does not have to)

1. **Bandwidth ceiling.** With pair-correlation input of Fourier support ≤ 1 (the unconditional regime), the inertia method's ceiling is ≈ 0.68185; supports ≈ 1.04 / 1.26 / 1.70 are needed for 0.70 / 0.80 / 0.90 [Z23, Rem. 1.1]. Progress past the ceiling requires additive prime correlations (Hardy–Littlewood strength).
2. **Population vs pointwise.** The certificate is insensitive to o(N) exceptional zeros; no accounting of this kind reaches row 8. Sparse-conspiracy exclusion needs a pointwise principle, and every known pointwise principle here is equivalent to RH.
3. **The parity barrier** (Selberg): sieve weights operating at density level cannot separate parity classes; the shadows (densities) forget the phases. Any claim to bypass it must say which non-density information it consumes.
4. **The seam** (Bohr–Jessen): the unfolded frame's faithfulness is a theorem strictly above σ = 1/2 and precisely the open question at it. The frame cannot be cited as evidence at the seam.
5. **Independence at the boundary**: Mertens' ∏(1−1/p) vs the true prime density differ by e^γ — the sieve's independence heuristic fails at the window edge. All boundary claims require the analytic corrections.

## 8. A remark on the archimedean place (typed observation; no claim)

The completed ξ carries the factor π^(−s/2)Γ(s/2): the analytic continuation of the sphere-measure sequence (surface of S^(n−1) = 2π^(n/2)/Γ(n/2)). Two classical non-coincidences meet in it. First, the surface area of S² is 4π = 2π^(3/2)/Γ(3/2), and Γ(3/2) = √π/2 traces to Γ(½) = √π — the Gaussian integral, the Fourier-self-dual function through which Riemann derived the functional equation (θ(1/t) = √t·θ(t): a form of weight ½, on the metaplectic double cover). Second, 4π is also 2π·χ(S²): the Gauss–Bonnet total curvature, a topological invariant. The archimedean factor of ζ is thus the place where sphere geometry, the Gaussian normalization, and the half-integral weight that fixes the mirror all coincide — the constants 4π and ½ are related bookkeeping of one structure, not numerology. (The proofs, as always in this subject, are more detailed than the statements suggest.)

## 9. Falsifiability

The program's bet fails, and the authors will say so, if: (a) an element of the Selberg class (Euler product + functional equation of the standard type) is shown to violate its Riemann hypothesis — the frame's "stiffness ⟹ fairness-by-default" reading would be dead; (b) the 2/3 record is substantially passed by purely folded methods consuming no new additive-correlation input — the frame's diagnosis of *where* the difficulty lives would be weakened; (c) any of the machine-checked artifacts fails to reproduce — the ledger's proven-here rows would be withdrawn. Conversely, the standing requirement on the program itself: every future positivity-flavored statement must fail on Davenport–Heilbronn (§3), or it is discarded.

## 10. Glossary (program term → standard object)

| Program term | Standard object |
|---|---|
| sponge (completed) | the profinite integers ẑ = ∏ℤ_p with Haar measure; each ℤ_p homeomorphic to the Cantor set |
| stratum / doll tower | pℤ; the filtration p^kℤ; valuation = descent count |
| skeleton / survivors | the unit group ẑ^× (Haar measure ∏(1−1/p) = 0 by second Borel–Cantelli; full local Hausdorff dimension) |
| collapse | the log-derivative: Λ(p^k) = log p — depth forgotten, prime kept |
| outward bivector | the (1,1) block of an off-line pair; Witt hyperbolic plane; B² = +1 |
| Zeta Motor / rotor | the compact phase generator; a character as an SO(2) element |
| the seam | σ = 1/2 as the boundary of Bohr–Jessen faithfulness / abscissa where Σp^(−2σ) diverges |
| fairness | RMS-scale composition of mode amplitudes; row 8 is its pointwise form |
| style-law | the formalization discipline of §4 |

## 11. Provenance

The two-thirds theorem and its Lean formalization are [Z23]'s (Anthropic, Aug 2026). The classical components are owned as attributed. The Lean artifacts in this repository were produced in an interactive session (McSheery/Claude, Aug 12–13, 2026) and are Apache-licensed alongside the repository; the companion paper `CliffordNN_TwoThirds_Aug2026.md` records the program-internal development, including the taught lesson (§12) from which the formal queue was drawn. The reader is invited to check the artifacts, attack row 8, and ignore the vocabulary.
