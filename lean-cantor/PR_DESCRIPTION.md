# Formal Totality and Correctness of `Fast.find` via Chiral Decomposition

## Summary

This PR provides a **formally verified, total version of `Fast.find`** with complete termination and correctness proofs. The key insight is that the `branch` function performs a **position interleaving** that halves the effective modulus at each recursive call, guaranteeing termination with O(log n) depth.

## Key Results

### 1. Total `find` Function (`FastFindTotal.lean`)
```lean
def find (p : BoundedPred) : Cantor
termination_by p.bound
```
- Replaces the `partial` annotation with a verified `termination_by` measure
- Uses the predicate's modulus bound as the termination measure

### 2. Full Correctness Proof
```lean
theorem find_correct (p : BoundedPred) (h : ∃ a, p.pred a) :
    p.pred (find p)
```
- If a witness exists, `find` returns one
- Proof by strong induction on the bound

### 3. Chiral Decomposition (`Chirality.lean`)
```lean
theorem chiral_decomposition (a : Cantor) :
    combine (chirality a) (projectLeft a) (projectRight a) = a

theorem surface_moduli_lt (n : Nat) (hn : n ≥ 2) :
    leftModulus n < n ∧ rightModulus n < n
```
- Every Cantor sequence decomposes into chirality bit + left surface + right surface
- Both surface moduli are strictly less than the original (for n ≥ 2)

## Files Added

| File | Purpose | Theorems | sorry |
|------|---------|----------|-------|
| `Chirality.lean` | Chiral decomposition framework | 18 | 0 |
| `FastFindTotal.lean` | Total find with correctness proof | ~20 | 0 |
| `FastTermination.lean` | Modulus reduction lemmas | ~10 | 0 |
| `CantorClifford.lean` | Geometric algebra perspective | ~15 | 0 |

## The Key Insight

The `branch` function performs a **grade-halving chiral decomposition**:

```
Position:  0    1    2    3    4    5    6    7    ...
Source:    x    l₀   r₀   l₁   r₁   l₂   r₂   l₃   ...
```

After `branch x l r`:
- Position 0 is the chirality bit `x` (modulus contribution: 1)
- Odd positions come from `l` (modulus: n/2)
- Even positions come from `r` (modulus: (n-1)/2)

This means each recursive call operates on a predicate with **strictly smaller modulus**, giving us termination with tree depth O(log n).

## Technical Approach

1. **BoundedPred wrapper**: Tracks predicates with known modulus bounds
2. **Terminating forsome**: Uses the existing `forsome_correct` theorem from `Cantor.lean`
3. **Strong induction**: On `p.bound` with explicit case analysis
4. **Witness propagation**: Through `existsLR_of_witness` and `leftPred_has_witness`

## Audit Summary

```
sorry:   0 across all files
trivial: 0 across all files
axiom:   0 across all files
True:    0 across all files
```

All proofs are complete with no placeholders.

## Build Verification

```bash
lake build Chirality FastFindTotal FastTermination CantorClifford
# Build completed successfully
```

## Why This Matters

The grade-halving structure explains why `Fast.find` is efficient:
- **O(log n) depth** instead of O(n) for predicates with modulus n
- **Parallelization potential**: After fixing chirality, left and right searches are independent
- **Verified termination**: The `termination_by p.bound` is machine-checked

This decomposition pattern (split → independent subproblems → descent) is a reusable technique for similar search problems over infinite spaces with bounded dependence.
