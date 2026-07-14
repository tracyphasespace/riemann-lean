# Gap Prediction: Negative Result

## Summary

**Zeta-based gap prediction does NOT work at any scale tested.**

Prime gap sizes are **random fluctuations** around the expected value log(n), consistent with Cramér's probabilistic model.

---

## Methods Tested

| Method | Description | Correlation |
|--------|-------------|-------------|
| Surface Tension | Artificial phases from residues/digit sums | ~0 |
| ECV Curvature | d²/dσ² ‖Z_ECV‖ at σ=1/2 | ~0 |
| Explicit Formula | Σ cos(γ log n) / \|ρ\| | ~0 |
| Rotor Coherence | cos(γ log n) + 0.5 sin(2γ log n) | ~0 |
| Sieve Density | Local divisibility structure | -0.34 (inverse!) |

---

## Multi-Scale Results

| Scale | log span | Coherence span | Correlation |
|-------|----------|----------------|-------------|
| 10^4 | 0.406 | 12.75 | +0.041 |
| 10^5 | 0.049 | 5.33 | -0.011 |
| 10^6 | 0.010 | 3.35 | -0.004 |
| 10^7 | 0.001 | 0.05 | -0.010 |
| 10^10+ | ~0 | ~0 | ~0 |

Even at 10^4 where log(n) and coherence vary significantly, correlation is **zero**.

---

## Key Visualization

![Coherence vs Primes](../plots/coherence_vs_primes_1e+04.png)

The visualization shows:
1. **Top**: Coherence oscillates, but primes appear uniformly at all coherence values
2. **Middle**: Distribution at primes ≈ distribution everywhere
3. **Bottom**: Gap size vs coherence shows zero correlation (r = 0.045)

---

## Why This Happens

The **explicit formula** relates primes to zeta zeros:

```
ψ(x) = x - Σ_ρ x^ρ/ρ + O(1)
```

This controls the **asymptotic/global** distribution of primes. But:

1. The oscillation has period ~2π/γ in log-space
2. At any fixed scale, we sample a tiny fraction of one period
3. Local fluctuations are dominated by **random noise**, not zeta structure

---

## Cramér's Model

Primes behave as if each integer n is prime with probability 1/log(n), independently.

Under this model:
- Expected gap: log(n)
- Gap variance: log²(n)
- Max gap in [n, 2n]: ~log²(n) (Cramér conjecture)

Our observations match this random model, not zeta-based prediction.

---

## Conclusion

> **The Riemann zeros encode global prime structure, not local gap sizes.**
>
> Gap prediction from zeta zeros is not viable.

The rotor/coherence formulation correctly describes the **asymptotic** behavior (RH as coherence condition), but cannot predict **local** fluctuations.

---

## Files

| File | Purpose |
|------|---------|
| `claude2_src/rotor_coherence_visualizer.py` | Visualization code |
| `claude2_src/gap_predictor_multiscale.py` | Multi-scale tests |
| `claude2_src/explicit_formula_predictor.py` | Explicit formula approach |
| `plots/coherence_vs_primes_1e+04.png` | Key visualization |

---

*Date: 2026-01-16*
