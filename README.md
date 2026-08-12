# Riemann — start here

**Reviewers and external readers:** the entry point is
[`Papers/Critical_Line_Ledger_Aug2026.md`](Papers/Critical_Line_Ledger_Aug2026.md) —
a claims-typed ledger (proven-classical / proven-recent / proven-here / reframing / open,
with exactly one open row) for the critical-line problem, anchored to the Aug 2026
two-thirds theorem ([Z23], Anthropic) and to 34 machine-checked Lean 4 theorems in
[`Zeta23Bridge/`](Zeta23Bridge/) (verification: `lake update && lake exe cache get && lake build`;
expected axiom audit is the ledger's Appendix A, regenerable via `Zeta23Bridge/audit.sh`). A name-correspondence table (Lean identifiers ↔ standard notation) is in the companion paper §11 and `Zeta23Bridge/README.md`. The program-internal development record is
[`Papers/CliffordNN_TwoThirds_Aug2026.md`](Papers/CliffordNN_TwoThirds_Aug2026.md).
Historical papers and conditional reductions are in `Papers/` and `Lean/`; their scope
statements govern (no unconditional proof of RH is claimed anywhere in this repository).

---

# Riemann Experiments

This repo contains exploratory scripts and visualizations for McSheery-style prime field experiments.

## McSheery Blind Navigator

`scripts/mcsheery_blind_navigator.py` implements a blind integer-rotor scan that does not use a precomputed
prime list. It treats every integer rotor 2..sqrt(N) as a potential resonance and marks composites by
exact divisibility.

### Modes

- `blind`: integer rotors 2..sqrt(N) (odd-only + 2). No precomputed prime data.
- `blind-stream`: integer rotors streamed (no basis list materialized). No precomputed prime data.
- `annealed`: rotor basis compressed to primes up to sqrt(N) using an internal sieve.
  This is faster but reintroduces a derived-prime basis.

### Why no cosine

Floating-point cosine phase checks drift at large `n`. This version uses exact divisibility marking
(`n % rotor == 0`) and fast slice assignment on a bytearray, which is numerically stable and faster.

### CLI usage

```
python3 scripts/mcsheery_blind_navigator.py --start 1000 --end 10000 --basis-mode blind
python3 scripts/mcsheery_blind_navigator.py --start 1000000000 --end 1000010000 --basis-mode blind --no-verify
python3 scripts/mcsheery_blind_navigator.py --start 1000000000 --end 1000010000 --basis-mode annealed --no-verify
```

### Performance notes (example)

Window: 1,000,000,000..1,000,010,000 (10,001 values)

- Blind basis: 15,812 rotors, scan ~0.0056s
- Annealed basis: 3,401 rotors, scan ~0.0016s

Both modes detected the same 487 primes in that window.

## McSheery Surface Mapper

`scripts/mcsheery_surface_mapper.py` builds a scalar energy field
`E(n) = sum(1 - cos(2*pi*(n % r)/r))` over a window. This keeps the
continuous surface interpretation and supports a sampled basis for scale.

Modes:

- `full`: uses every integer rotor 2..sqrt(N) (blind, expensive).
- `sampled`: includes all rotors up to `--cutoff` and randomly samples
  from the remaining rotors up to sqrt(N), scaling the sample to estimate
  full energy.

Example:

```
python3 scripts/mcsheery_surface_mapper.py --start 1000 --end 1100 --mode full
python3 scripts/mcsheery_surface_mapper.py --start 100000000000000 --end 100000000001000 --mode sampled --cutoff 100000 --sample-size 20000
```
