# InformationDepth — Experiment 2: the curvature interpolation (F8)

**Register: computed-in-code. This design section is committed BEFORE any
results exist (preregistration discipline). Companion instrument:
`curvature_interpolation_oracle.py`. Results will be appended below the
marked line, never edited into this section.**

## The family

Inside the two-dimensional space V = {a·L(s,χ) + b·L(s,χ̄)} for χ the
Dirichlet character mod 5 with χ(2) = i:

    F_t(s) = (1−t)·L(s,χ) + t·f_DH(s),   t ∈ [0,1]

where f_DH = ½(1−iκ)L(s,χ) + ½(1+iκ)L(s,χ̄) is the Davenport–Heilbronn
function, κ = (√(10−2√5) − 2)/(√5 − 1) ≈ 0.2840790. Equivalently
F_t = α(t)L(χ) + β(t)L(χ̄) with α = (1−t) + t(1−iκ)/2, β = t(1+iκ)/2.
Coefficients c_t(n) = α·χ(n) + β·χ̄(n). Endpoint t = 0 is a pure Euler
product (GRH-verified numerically at low height); endpoint t = 1 is the
classical off-line-zeros counterexample. Every member is a linear
combination of the same two completed objects, per the F8 registration.

## Observables

- **Curvature** 𝒦(t) = Σ_{m,n ≥ 2, gcd(m,n)=1, mn ≤ 3000}
  |c_t(mn) − c_t(m)·c_t(n)|² / (mn), plus the first cell |D_t(2,3)|².
  Exact expectation: 𝒦(0) = 0 (complete multiplicativity), 𝒦(t) ≍ t²
  as t → 0 (the defect is bilinear in (α,β) deviations).
- **Off-line zero counts** N_R(t; T), N_L(t; T): winding-number counts
  of zeros of F_t in RIGHT = [0.52, 1.50] × [2, 120] and
  LEFT = [−0.50, 0.48] × [2, 120]. (Zeros within 0.02 of the line are
  not counted anywhere — declared blind spot.)
- **First off-line height** T_first(t): for t with N_R > 0, bisected to
  a window of height ≤ 5. For t with N_R = 0 at T = 120, the hunt
  extends to T = 360 in strips (small-t behavior is the decisive data).

L-values via Hurwitz zeta: L(s,χ) = 5^{−s} Σ_{a=1}^{4} χ(a)ζ(s, a/5)
(valid in the strip). Winding numbers via adaptive argument tracking
(subdivide while |Δarg| > 1 rad; integrality check |W − round(W)| < 0.2
enforced, else the row is marked UNRELIABLE).

## Validation gates (instrument must pass before the science is read)

- **V1**: t = 0 gives N_R = N_L = 0 up to T = 120.
- **V2**: t = 1 finds an off-line zero in the window γ ∈ [80, 92]
  (literature: the Davenport–Heilbronn zero near 0.8085 + 85.70i).
- **V3**: 𝒦(0) = 0 to machine precision; 𝒦(t)/t² approximately
  constant on the small-t grid.

## Pre-registered outcomes (three-way, per Factorization.md F8)

1. **Continuity**: N_off(t; 120) > 0 already for the smallest t probed,
   with 𝒦(t) arbitrarily small — small curvature buys spectral defect
   immediately AND the count at fixed T is roughly t-independent.
2. **Rigidity gap**: N_off = 0 for all t below some threshold t₀ at all
   probed heights — off-line behavior requires a minimum curvature.
3. **Graded split (the registered prediction)**: pointwise-dichotomic
   but density-continuous — off-line zeros exist for every t > 0
   (possibly with T_first(t) → ∞ as t → 0), while the count at fixed T
   scales down with t (roughly like the fraction of the coefficient mass
   carried by the "wrong" component, |β(t)|²-ish). Signature in this
   instrument: N_off(t; 120) decreasing in t toward 0, reaching 0 for
   small t, with T_first(t) climbing as t decreases — not a clean t₀
   threshold but a sliding visibility horizon.

Anchor (audit-level until cite-checked): Bombieri–Hejhal 1995 —
conditionally, almost all zeros of such combinations lie ON the line —
predicts that even at t = 1 the off-line counts are a vanishing fraction
of all zeros; this experiment does not test that claim, only the
off-line counts' t-dependence.

**Interpretive guard**: t is a *coordinate* on this one interpolation
line, and 𝒦 is one weighting of the defect tensor. A finding here is a
finding about this family — the first data point of F8, not a theorem
about "all near-Euler systems." The five checks apply; the outcome that
flatters the registered prediction gets checked hardest.

---

## Results (appended after the run; design above is frozen)

**Run 2026-08-12, instrument as committed (mp.dps=12, ε=0.02, T=120,
extended hunts to 360). Raw output preserved in git with this commit.**

### Validation gates

- **V1 PASS**: t = 0 clean to T = 360 both sides.
- **V2 PASS**: t = 1 gives N_right = 2 with first strip [83.1, 86.8] —
  the literature Davenport–Heilbronn zero (γ ≈ 85.70) rediscovered.
- **V3 PASS**: 𝒦(0) = 0 exactly; 𝒦/t² → ≈ 15 from the small-t side.

### Data

| t | 𝒦(t) | N_right (≤120) | N_left (≤120) | first right-zero |
|---|---|---|---|---|
| 0.00 | 0 | 0 (0 to 360) | 0 | — |
| 0.05 | 0.037 | 0 (0 to 360) | **2** | — |
| 0.15 | 0.301 | 4 | 12 | [24.1, 27.8] |
| 0.30 | 1.019 | 7 | 17 | [5.7, 9.4] |
| 0.60 | 2.798 | 11 | 20 | [5.7, 9.4] |
| 1.00 | 4.223 | 2 | 2 | [83.1, 86.8] |

### Findings (claim-typed)

**E2-F1 [computed]: none of the three pre-registered outcomes describes
the data.** The registered prediction (graded split via a height horizon
T_first(t) → ∞) is **not confirmed as stated**: off-line zeros exist
already at t = 0.05 *below* T = 120 — on the left.

**E2-F2 [computed]: the off-line count is non-monotone in t, with a
crash at the self-dual endpoint.** Total off-line zeros ≤ 120:
0 → 2 → 16 → 24 → 31 → **4**. Curvature 𝒦 rises monotonically
throughout (2.80 → 4.22 on [0.6, 1]) while the count collapses 31 → 4.
**𝒦 does not monotonically govern off-line abundance along this path.**

**E2-F3 [computed]: chirality.** Interior members put off-line zeros
predominantly LEFT of the critical line (12 vs 4 at t = 0.15; 20 vs 11
at t = 0.6); the endpoints are symmetric. Interior members are not
self-dual — each F_t's functional equation pairs it with a *different*
member of V — so nothing pins their zeros to the line or distributes
them symmetrically. The left excess itself is unexplained [open].

**E2-F4 [interpretation, typed]: the experiment separated two defect
axes the design conflated.** Endpoint t = 0 is rigid by Euler product;
endpoint t = 1 is rigid by self-duality (the Bombieri–Hejhal mechanism —
almost all zeros on the line for self-dual combinations); the interior
has *neither* protection and behaves like a generic perturbation: each
on-line zero ρ of L(χ) drifts off by ≈ t·|βʹ·L̄(ρ)/L′(ρ)|, escaping the
ε = 0.02 corridor gradually — a sliding visibility horizon in
*displacement*, not height. This mechanism explains the growth
0 → 31 and the t → 0 vanishing, but NOT the left bias (it predicts
symmetric escape) — so it is at best half the story. The Davenport–
Heilbronn point, classically "the counterexample," is along this path
the *second most line-rigid object after the Euler product itself*.

### Consequences for F8 (registered)

1. The defect tensor needs a **second coordinate**: duality defect,
   alongside multiplicativity defect 𝒦. Off-line abundance along this
   path tracks duality defect at least as strongly as 𝒦.
2. **Follow-up experiment (designed before run, not yet run): the
   self-dual sweep.** Identify the self-dual sub-family of V (the ray
   through f_DH; one real parameter after normalization) and sweep 𝒦
   along it with duality held fixed. That isolates pure
   curvature-vs-zeros. Outcomes to register before running.
3. **Robustness follow-up**: ε-sweep (0.005 / 0.01 / 0.05) — the
   corridor blind spot is now load-bearing for the "displacement
   horizon" reading; and localize T_first on the LEFT at t = 0.05
   (instrument gap: only right-box bisection was implemented).
4. Scored honestly: the registered prediction (iii) was wrong in
   mechanism (height vs displacement), right that no clean threshold
   exists, and blind to the dominant effect (duality). Both
   pre-registered "continuity"and "rigidity gap" are refuted as stated.
