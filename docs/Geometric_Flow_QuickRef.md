# Geometric Flow Quick Reference Card

## The Cl(p,p) Pattern at a Glance

```
                         SPLIT SIGNATURE Cl(p,p)
                                  │
                    e₊² = +1      │      e₋² = -1
                   (expansion)    │    (contraction)
                                  │
                         ω = e₊e₋, ω² = 1
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
              P₊ = (1+ω)/2              P₋ = (1-ω)/2
              (Even/Right)              (Odd/Left)
```

## Grade → Object Type Mapping

| Grade | Object | RH Example | Collatz Example |
|-------|--------|------------|-----------------|
| 0 | Scalar | Energy ‖V‖² | Lyapunov log(n) |
| 1 | Vector | Force T(σ,t) | Drift velocity |
| 2 | Bivector | Phase θ = t·log(p) | T/E operators |
| p | Pseudoscalar | Chirality ω | Parity switch |

## Differentiation = Grade Raising

```
T(σ)   →  T'(σ)   →  T''(σ)
log(p)¹   log(p)²    log(p)³
Grade 0   Grade 1    Grade 2
```

## The Four Pillars (Shared)

```
┌────────────────────────────────────────────────────────────┐
│  1. SPECTRAL ASYMMETRY: log(3/2) < log(2)                 │
│     RH: zeros cluster at σ=1/2                            │
│     Collatz: trajectories descend                         │
├────────────────────────────────────────────────────────────┤
│  2. ORTHOGONALITY: [B_p, B_q] = 0                         │
│     RH: prime bivectors commute                           │
│     Collatz: gcd(2^k, 3^m) = 1                           │
├────────────────────────────────────────────────────────────┤
│  3. TRANSCENDENCE: log(2)/log(3) ∉ ℚ                      │
│     RH: no exact phase cancellation                       │
│     Collatz: no non-trivial cycles (3^p ≠ 2^q)           │
├────────────────────────────────────────────────────────────┤
│  4. ENERGY DISSIPATION: unique minimum                    │
│     RH: ‖V‖² minimized at σ=1/2                          │
│     Collatz: V(n)=log(n) minimized at n=1                │
└────────────────────────────────────────────────────────────┘
```

## Motor = Dilation ∘ Rotor

```lean
-- Riemann
def primeMotor (p : ℕ) (σ t : ℝ) :=
  p^{-σ} • rotation2D(t * log p)

-- Collatz
M_T = [3/2  1/2]    M_E = [1/2  0]
      [0    1  ]          [0    1]
```

## Lift → Analyze → Project

```
Physical Space              Lifted Space H = ⊕ Plane_p
(interference)              (no interference)
      │                            │
      │◄─── project ───────────────┤
      │                            │
      └────── lift ───────────────►│
                                   │
                              ANALYZE HERE
                           (operators commute)
```

## Key Theorems

**Riemann** (`CliffordRH.lean`):
```lean
def TraceIsMonotonic (t : ℝ) (primes : List ℕ) : Prop :=
  StrictMonoOn (fun σ => rotorTrace σ t primes) (Set.Ioo 0 1)

def NormStrictMinAtHalf (t : ℝ) (primes : List ℕ) : Prop :=
  ∀ σ ∈ (0,1), σ ≠ 1/2 → rotorSumNormSq (1/2) t < rotorSumNormSq σ t
```

**Collatz** (`SpectralAnalysis.lean`):
```lean
theorem spectral_gap_pos : log 2 - log (3/2) > 0
theorem net_drift_neg : log(3/2) + log(1/2) < 0
theorem no_resonance : ∀ p q > 0, 3^p ≠ 2^q
```

## Conditional Operations as Grade Extraction

| Function | Encoding |
|----------|----------|
| Λ(n) = log(p) if n=p^k | Weight in bivector sum |
| ψ(x) = Σ Λ(n) | Accumulated ⟨·⟩₀ |
| 2^k barriers | Pseudoscalar eigenvalue |
| mod 32 class | Finite group projector |

## File Locations

```
Riemann/Lean/Riemann/ZetaSurface/
├── CliffordRH.lean           # rotorTrace, rotorSumNormSq
├── MotorCore.lean            # blade, actOn, projSum
├── TraceMonotonicity.lean    # derivatives, monotonicity

Collatz_Conjecture/Lean/
├── SpectralAnalysis.lean     # spectral_gap, net_drift
├── archive/RHBridge.lean     # rh_collatz_bridge theorem
├── archive/Collatz.lean      # Cl(1,1) framework docs
```

## The Punchline

> Both RH and Collatz are **geometric stability forcing** in Cl(p,p):
> - Spectral asymmetry creates direction
> - Transcendence blocks escape
> - Orthogonality enables clean analysis
> - Unique fixed point emerges (σ=1/2 or n=1)
