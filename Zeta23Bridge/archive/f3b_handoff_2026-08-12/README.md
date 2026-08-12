# Archived: F3b-instance handoff package (2026-08-12)

**Status: SUPERSEDED — kept for provenance.** This package was drafted in a
parallel lane, outside a build environment, *before* the F3b-instance was
completed in the main lane. The kernel-checked completion landed the same day
(commits `4a8bb0e`, `46a2993`); every theorem this draft targeted now exists
sorry-free in `../../Factorization.lean`.

Supersession map (draft → kernel-checked):

| Draft (this dir, 8 `sorry`s, never compiled) | Completed theorem |
|---|---|
| `badPrimeEnergy` def + `badPrimeEnergy_nonneg` | inlined into `euler_factor_deletion` (D_Q as an explicit sum, nonneg proved in place) |
| `tower_le` (L4, per-prime tower via `geom_tail_le`) | `prime_tower_energy` (valuation reindex + geometric tail) |
| L5 assembly (masked energy ≤ D_q) | `bad_prime_energy` |
| main theorem `dirichletChar_eulerStiffnessC` | `euler_factor_deletion` (abstract selector) + `dirichlet_inhabitant` (named character corollary) |

The draft's registered scopings (per-character claim; primitivity not
required; `[NeZero q]` threading; worst constant p = 2) all match the
completed build — the pre-registered route was the route taken. The
frozen-interface constraint was satisfied in both lanes.

**`verify_f3b.py` is NOT superseded**: it remains an active development
oracle / regression test, promoted to `../../verify_f3b.py`. Register:
computed-in-code. It checks something *stronger* than the formalized
inequality — the exact identity `D_q − M_q(x) = Σ_{p|q} Σ_{p^k>x} log²p/p^k`
(margin ≡ predicted tower tail, verified to 1e-9 over 12 moduli up to the
primorial 9699690). The Lean proof drops the nonneg tails, so the identity
form is a registered optional strengthening, not a gap.

Per program discipline: numerical checks are development engineering, not
mathematical evidence — nothing here is advertised as "numerical
verification of F3b."
