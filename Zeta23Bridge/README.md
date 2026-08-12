# Zeta23Bridge — the Cl(N,N) dictionary, machine-checked

**Verified 2026-08-12** against `anthropics/zeta-23-lean` (the Lean 4 formalization
of Claude (2026), *"More than two thirds of the zeros of the Riemann zeta function
lie on the critical line"* — **[Z23]**), toolchain `leanprover/lean4:v4.33.0-rc2`,
Mathlib pinned by that repository's manifest (`51e6992e`).

This is the "concrete next step" of `Papers/CliffordNN_TwoThirds_Aug2026.md` §8:
the Sieve program's geometric vocabulary, stated and **proved** as Lean theorems,
wired directly into [Z23]'s `Zeta23/LinAlg` (`RHLinalg` namespace). It upgrades the
companion paper's dictionary from interpretive prose to kernel-checked mathematics.

## Verified theorems (axiom audit: `[propext, Classical.choice, Quot.sound]`, no `sorry`)

| Theorem | Statement | Sieve-program reading |
|---|---|---|
| `bivector_commute` | Bivectors of mutually orthogonal planes commute in any Clifford algebra | **Vanishing Commutator Theorem** (Geometry of the Sieve, Thm 2.1) — proved against Mathlib's `CliffordAlgebra`, for *all* quadratic forms, all signatures |
| `bivector_sq_neg_one` | Euclidean plane (`Q x = Q y = 1`): `B² = −1` | Compact rotor — the phase planes of the Zeta Motor (the eliminated imaginary unit, Cl(3,3) phase-space move) |
| `bivector_sq_one` | Split plane (`Q x = 1, Q y = −1`): `B² = +1` | Boost — the outward bivector of an off-line zero pair's `Cl(1,1)` plane |
| `posIndex_hypBlock`, `negIndex_hypBlock` | The off-line-pair block `!![0, μ; μ, 0]` has signature `(1,1)` | Witt's hyperbolic plane: one positive strut refunded, one negative direction — the matrix shadow of the boost bivector |
| `strut_hyperbolic_shadow_bound` | `G = P + Σᵢ Bᵢᴴ·hypBlock(μᵢ)·Bᵢ` with `P ⪰ 0`, `rank P ≤ s` ⟹ `n₊(G) ≤ s + p` | **The outward-bivector principle, population form**: a shadow can fold curvature but cannot manufacture positive directions; each hyperbolic plane refunds at most one |
| `shadow_posIndex_le` | re-export of `RHLinalg.posIndex_conj_le` | Shadow monotonicity of inertia — the survivor of the B.6 spiral objection |
| `EulerStiffness` + `eulerStiffness_vonMangoldt` | Prop-structure packaging the Euler product's quantitative shadow (prime-power support, `Λ(n) ≤ log n`, Mertens energy `½log²x`, Chebyshev), with the ζ instance **proved** from Mathlib + `Zeta23.Cheb` | "Geometric Stiffness" as a typeclass: the constraint a `charOp` must carry, and the instance Davenport–Heilbronn cannot construct (negative-control witness: Layer 5) |
| `logDeriv6_eq_defect` | Any log-derivative system has `Λ_f(6) = (c(6) − c(2)c(3))·log 6` | **The defect identity**: the n = 6 coefficient *is* the multiplicativity defect — Euler product ⟺ all such defects vanish ⟺ Grade Orthogonality (Thm 5.3) |
| `dh_logDeriv6_pos`, `dh_not_eulerStiffness` | For D-H coefficients (c(2) = κ, c(3) = −κ, c(6) = 1, **any real κ**): `Λ_DH(6) = (1+κ²)·log 6 > 0`, hence `¬EulerStiffness` | **The B.8 negative control, exact and kernel-checked**: no numerics, no interval arithmetic — the defect is a sum of squares |
| `zeta_logDerivAt6` | Λ satisfies the same local identities with `Λ(6) = 0` | The ζ contrast: same recursion, zero defect — the skeleton intact |

`strut_hyperbolic_shadow_bound` is the abstract content of [Z23] Proposition 4.1 —
the zero-side inequality feeding the 2/3 theorem — rebuilt from the Sieve
vocabulary using [Z23]'s own `posIndex_conj_le`, `posIndex_add_le`, and
`posIndex_eq_rank_of_posSemidef`.

## The Russian-doll point, made precise

Everything proved here is proved **once, for all dolls at once** — no
configuration is ever inspected. `bivector_commute` and the `(1,1)` signature are
*by design* (algebraic identities of the split structure, exactly as the Sieve
program insists), and `strut_hyperbolic_shadow_bound` is what the design buys
downstairs: a bound valid for **every** possible configuration of struts and
pairs, with arbitrary shadow maps. What design alone cannot supply is the census —
how many dolls there are — and that is exactly the part [Z23] buys with the two
prime-side trace moments (bandwidth ≤ 1, unconditional), landing at 2/3.

## SpongeStage.lean — Stage 1 of the sponge-as-object formalization

Companion module (own `lean_lib`, imports Mathlib only) realizing the style-law
of the companion paper §10–11: **no literal `1/2` or `1/p` in any definition** —
definitions carry maps (self-embeddings, descents, `ZMod` gradings, character
averages, valuation coordinates); numerals appear only in lemmas as shadows
(floored divisions, totients, group orders). Nine kernel-checked results:
`embed`/`stratum` (Dedekind self-embedding; stratum = image of the map),
`remainder_obstruction` + `grade_eq_zero_iff` (Gauss congruence grading),
`tower_nested` + `descent_count` (Kummer/Hensel valuation as exact-descent count),
`orthogonality` (CRT in image form), `coordinates_add` + `reconstruction`
(ℕ⁺ = free commutative monoid on primes), `haar_projector` (Dirichlet: the
1/p-average with the group order in the lemma), `density_shadow` (count = `n / p`,
floored), `volume_shadow` (totient of a primorial = `∏(p−1)`), `parity_projector`
(the ½(1+S) projector with the 2 derived). See paper §11 for the full
intuition → classical-owner → Lean dictionary.

## Factorization experiment (ledger §8, commitment ii) — IN PROGRESS

`Factorization.md` records the paper-level dependency audit of [Z23] §5 against
the `EulerStiffness` fields (verdict: the prime side factors — every arithmetic
input is a field or field-derivable; residue = the completed-function package,
by design; complex/modulus generalization `EulerStiffnessC` needed for Thm E).
`Factorization.lean` (Stage F1, kernel-checked): `sum_sq_le`,
`sum_div_sqrt_sq_le`, `freq_spacing` — [Z23] Lemma 5.1's derived estimates
proved from the interface alone, for any `f`. Milestones F2–F5 in the .md.

## Reproduce

```bash
cd Zeta23Bridge
lake update          # fetches zeta-23-lean @ v1.0 and its pinned Mathlib
lake exe cache get   # Mathlib olean cache (~several GB)
lake build           # compiles Zeta23Bridge.lean; #print axioms output appears in the log
```

(Verification for this commit was run by compiling `Zeta23Bridge.lean` inside a
clone of `zeta-23-lean` with `lake env lean`; the file is identical.)

## Relation to `Lean/` (the Sieve program's own formalization)

`Riemann/Lean` is on toolchain 4.27/4.28-rc1 and cannot import this project
directly. Name correspondence:

- `GeometricBridge.orthogonal_generators_no_cross_terms` ↝ `bivector_commute`
  (here generalized to arbitrary quadratic forms and proved from Mathlib's
  `CliffordAlgebra` primitives);
- the `CliffordOrthogonalBridge` (O3/O3′) has **no analogue here by design** —
  pointwise convexity is equivalent to RH and is deliberately absent; the shadow
  bound is what replaces it at the population level.
