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
