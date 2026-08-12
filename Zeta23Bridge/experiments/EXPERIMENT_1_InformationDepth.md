# InformationDepth — Experiment 1: counterfeit pairs on the E₀-fiber

**Register: computed-in-code (N = 10⁵ prime-power support, seeds fixed).
Interpretations typed per finding. Companion: `information_depth_oracle.py`.**

## Setup

Exact E₀-fiber twins of Λ (identical moduli, hence identical on ALL five
interface fields, verified to machine precision):

- **PARITY**: a_n = λ(n)Λ(n) — the Liouville rotor u_{p^k} = (−1)^k.
  Classically: the parity object; its Dirichlet series is the
  log-derivative of ζ(2s)/ζ(s), which has *poles at the zeros of ζ*.
  The maximally spectrally-different twin.
- **EPS_B**: a_{p^k} = ε_p Λ(p^k), ε_p i.i.d. unimodular — per-prime
  constant rotors (tower-phase-trivial by construction).
- **CHI4** (near-fiber control): Λχ₄ — rotor + mask at p = 2.

Observable: pair energy C_Δ = 2Re Σ_{m<n} a_m ā_n K((log m − log n)/Δ),
Fejér kernel, decomposed into SAME-PRIME (tower) and CROSS-PRIME parts.

## Findings

**F1 (fiber reality + F3b cross-validation).** The four unmasked systems
are field-identical to 9 decimals. CHI4's Mertens field sits below BASE
by 0.480445 = D₄ − tower-tail(10⁵) to 1e-6 — the F3b identity
reappearing uninvited inside a different experiment. [computed]

**F2 (strict hierarchy witnessed).** (EPS_A, EPS_B): tower separation is
machine-zero at every bandwidth (per-prime rotors cancel within towers,
as the algebra predicts) while cross-prime separation is total — the
scramble destroys ~all pair energy (1.76e9 → 1.9e5). So there exist
pairs identical at E₀ *and* at tower level, separated only by
cross-prime data: **E₀ ⊊ E_tower ⊊ E_cross**, each inclusion with an
explicit witness. [computed]

**F3 (prediction falsified → the stealth-counterfeit phenomenon).**
Design prediction: the parity pair separates at tower level. WRONG:
tower separation is negligible (0 below Δ = log 2; ≤ 52 vs totals of
10⁹ above), and even cross-prime separation is under 1% of total —
because λ(p)λ(q) = +1: **the Liouville twist is exactly invisible on
prime-prime pairs, which dominate the pair energy.** Its entire C_Δ
fingerprint is confined to the thin mixed-grade locus p^j ≈ q^k with
j+k odd (p ≈ q², etc.). Meanwhile the spectrally-harmless random twist
announces itself at full amplitude.

Interpretation [conjecture, typed]: the fiber carries an observability
stratification in which *the classically dangerous direction hides
best*. The twin whose completed object differs most from ζ (poles at
ζ's zeros) is leading-order invisible to two-point observation; its
discriminating data lives precisely on additive prime-power
coincidences of mixed parity — i.e., in the information class the
parity barrier says is expensive. This is a computable articulation,
in the frame's own vocabulary, of *why* parity is the barrier: its
two-point fingerprint has thin support. [interpretation]

**F4 (tower horizon law).** Same-prime pairs enter the Δ-window iff
log p ≤ Δ: tower visibility switches on prime-by-prime at Δ = log p
(observed exactly: zero tower energy below log 2 ≈ 0.693; p = 2 alone
at Δ = 0.8, magnitude matching the closed form). The tower slice of C_Δ
is finitely generated per bandwidth. [computed; trivially formalizable]

**F5 (observable-relative depth).** The *global one-point signed sum*
separates the parity pair at first order (−99419 vs +100052 — and
−ψ(x) + 2ψ_□(x) = −99419 checks exactly) while the *local two-point*
energy barely sees it (F3); the random twist shows square-root
cancellation (|Σa| ≈ 600 ≈ √N-scale). So "depth" is not a single
ladder: one-point phase data is cheap and catches parity; two-point
correlation is expensive and nearly misses it. Note the structural
alignment with Z23: its *bounds* consume moduli (fiber-collapsed = our
E₀), while its *main terms* come from ζ itself — the explicit formula
is a one-point phase observer. The arithmetic side of the proof is
exactly the fiber-blind part. [computed + observation]

## Lean targets defined by this run (InformationDepth.lean, F3b pipeline)

1. `liouville_prime_prime_invisible`: λ(p)λ(q) = 1 for primes —
   hence prime-prime-restricted pair energies of Λ and λΛ are EQUAL
   (an exact identity, the rigorous core of F3). One-liner + transfer.
2. `tower_horizon`: same-prime window membership ⟺ |j−k|·log p ≤ Δ,
   hence p ≤ e^Δ. Elementary.
3. `perPrime_rotor_tower_invariant`: within-tower correlations
   invariant under n ↦ ε_p·a_n — funext-grade, the F2 witness's
   general half.
4. [open, the real one] a formal statement of F3: the parity pair's
   C_Δ-difference is supported on {(p^j, q^k) : j+k odd} — exact,
   kernel-checkable, and the first theorem of the stratification.

## Honest boundary

Nothing here proves the stratification means anything to zeros; F3's
interpretation is a reading of one observable family at one N. The
next discriminating computation: whether package-preserving twists
(characters) versus package-breaking twists (λ, random ε) can be
separated by any *computable functional of the coefficients alone* —
or whether package-membership is itself deep. That is the refined F6,
and this oracle is the instrument for it.

---

## Verification stamp (main lane, 2026-08-12)

Independently re-run (`information_depth_oracle.py`, seed 23, N = 10⁵):
all five findings' numbers reproduce — F1 fiber identity PASS and CHI4
Mertens deficit 0.480446 = D₄ − tail(10⁵) to 1e-6; F2 tower separation
machine-zero (≤ 1.8e-15) at every Δ with cross separation total
(1.76e9 → 1.9e5); F3 parity tower separation 0 below Δ = log 2 and
≤ 52.2 against totals ~5.7e9 above, cross separation 0.88–0.97% of
total; F4 horizon switches on at Δ = log 2 exactly, p = 2 tower slice
±1.9252 (sign opposite for PARITY, matching adjacent-power λ flip); F5
signed sums −99418.67 / +100051.56 / |EPS_B| ≈ √N-scale. Elevation
check applied: F3 flatters the frame and was checked hardest — the
numbers hold; its *interpretation* remains typed as conjecture.

Lean targets 1–3 are now kernel-checked in `InformationDepth.lean`
(`liouville_pair_invisible`, `tower_horizon`, `rotor_pair_invariant`);
target 4 (mixed-grade support of the parity C_Δ-difference) is
registered open. Audit: 98 theorems, 98 audited, 0 gaps, 0 sorryAx.
