# Optimization Analysis: What the GA Translation Exposes

## The Point of Translation

Lifting to a new representation separates operations so we can:
1. **Sort them** - see which dominate
2. **Identify symmetries** - find invariants to exploit
3. **Spot asymmetries** - find "spectral gaps" to leverage
4. **Parallelize** - orthogonal operations can run independently

---

## 1. Operations Sorted by Type

### Grade Operations (Information Flow)

| Operation | Grade Change | Type |
|-----------|--------------|------|
| `comp_cons x` | n → n-1 | **Consume** (use one bit) |
| `find` recursion | n → n-1 | **Consume** |
| `branch` assembly | (0, n/2, n/2) → n | **Produce** (interleave) |
| `compApprox` | n → tree of depth n | **Expand** (materialize) |

**Pattern exposed**: Standard `find` consumes linearly (n steps). `Fast.find` with `branch` does something different - it produces structure that could be consumed in parallel.

### Chiral Operations (Surface Switching)

| Operation | Surface Effect |
|-----------|----------------|
| Query bit 0 | Read chirality ω |
| Query odd position | Read from P₋ (left) |
| Query even position | Read from P₊ (right) |
| `branch x l r` | Combine ω + P₋(l) + P₊(r) |

**Pattern exposed**: The surfaces are independent until projection. This is exploitable.

---

## 2. Asymmetries Found

### Asymmetry 1: The `findBit` Preference

```lean
def findBit (p : Bit → Bool) : Bit :=
  if p false then false else true
```

This prefers `false`. Why? It's arbitrary in the original, but in GA terms:

- `false` = -1 (negative basis)
- `true` = +1 (positive basis)

**Optimization opportunity**: If we had statistics about the predicate, we could choose the more likely branch first. This is analogous to "phase clustering" in RH - bias toward the direction that's more likely to succeed.

### Asymmetry 2: Left vs Right in `branch`

```lean
def branch (x : Bit) (l r : Cantor) : Cantor :=
  fun n =>
    if n = 0      then x
    else if 2 ∣ n then r ((n - 2) / 2)  -- even: right
                  else l ((n - 1) / 2)  -- odd: left
```

The mapping is:
- Position 0 → x (chirality)
- Odd positions 1,3,5,... → l₀,l₁,l₂,...
- Even positions 2,4,6,... → r₀,r₁,r₂,...

**Observation**: Odd positions come "first" (1 before 2). If predicate evaluation is left-to-right, `l` is queried before `r` for low positions.

**Optimization opportunity**: If we know the predicate tends to depend more on early bits, search `l` more aggressively.

### Asymmetry 3: No Spectral Gap (Unlike Collatz)

In Collatz: `|log(1/2)| > |log(3/2)|` - contraction dominates.

In Cantor: Each `comp_cons` reduces modulus by exactly 1. No gap.

**But in Fast.branch**: We split into three problems:
- Finding x: O(1) (just 2 choices)
- Finding l: modulus ≈ n/2
- Finding r: modulus ≈ n/2 (conditioned on x and l)

This is a **structural gap**: 1 + n/2 + n/2 = n+1, but the tree depth is log₂(n) with branching.

---

## 3. Parallelization Opportunities

### Orthogonality of Bit Positions

Different bit positions are independent until the predicate combines them. In GA terms, basis vectors eᵢ and eⱼ are orthogonal.

**Current**: Sequential querying
```
Query bit 0 → Query bit 1 → Query bit 2 → ...
```

**Possible**: Speculative parallel querying
```
Query bits 0,1,2,3 in parallel → Prune based on results
```

### Independence of L and R Surfaces

In `Fast.find`:
```lean
let x := findBit (fun x => forsome (fun l => forsome (fun r => p (branch x l r))))
let l := find (fun l => forsome (fun r => p (branch x l r)))
let r := find (fun r => p (branch x l r))
```

Once `x` is determined, `l` and `r` searches are on **orthogonal surfaces**.

**Current**: `l` found first, then `r` (sequential)

**Possible**: Search `l` and `r` in parallel (after x is fixed)

```lean
-- Hypothetical parallel version
let x := findBit (...)
let (l, r) := parallel_find
  (fun l => forsome (fun r => p (branch x l r)))
  (fun r => p (branch x l r))  -- Note: r-search needs l, so not fully independent
```

**Problem**: The r-search uses the result of l-search. But we could speculatively search r for multiple candidate l values.

---

## 4. New Algorithm Suggested by GA Structure

### Hierarchical Chiral Search

The `branch` structure suggests a hierarchical decomposition:

```
Level 0: Determine chirality x₀
Level 1: Determine x₁ (chirality of l) and y₁ (chirality of r)
Level 2: Determine x₂, y₂, z₂, w₂ (chiralities of l.l, l.r, r.l, r.r)
...
```

This is a **complete binary tree** of chirality bits, depth log₂(modulus).

**Algorithm**:
```
1. Build tree of chirality bits top-down (2^k choices at level k)
2. Prune branches where no witness exists
3. Reconstruct witness from surviving path
```

**Complexity**: O(modulus) queries but with potential for massive parallelism (2^k independent checks at level k).

### Spectral Biasing

Borrow the "phase clustering" idea from RH:

```lean
-- Instead of arbitrary true-first:
partial def find_biased (p : Cantor → Bool) (bias : Nat → Bool) : Cantor :=
  let preferred := bias 0  -- Use statistics/heuristics
  have b := forsome (fun a => p (preferred # a))
  if b then preferred # find_biased (fun a => p (preferred # a)) (fun i => bias (i+1))
  else let other := !preferred
       other # find_biased (fun a => p (other # a)) (fun i => bias (i+1))
```

If we have prior knowledge about the predicate, we can search more likely branches first.

---

## 5. Concrete Optimization: Prove Fast.find Terminates

The GA translation suggests why `Fast.find` should terminate:

**Claim**: For `p : CantorPred` with modulus n, `Fast.find p.pred` terminates.

**Proof sketch** (GA-informed):
1. `branch x l r` interleaves three components
2. The predicate p with modulus n, when composed with `branch x _ _`, yields:
   - Constraint on x: modulus 1 (just checks position 0)
   - Constraint on l: modulus ≤ ⌈(n-1)/2⌉ (odd positions only)
   - Constraint on r: modulus ≤ ⌊(n-1)/2⌋ (even positions only)
3. Both l-modulus and r-modulus are strictly less than n for n > 1
4. Therefore recursion terminates

**The GA insight**: The chiral split P₊/P₋ **halves the grade** on each surface. This is the "spectral gap" for Cantor - not in probability, but in dimension.

---

## 6. Summary: What Translation Revealed

| Aspect | Before Translation | After Translation |
|--------|-------------------|-------------------|
| Termination | "modulus decreases" | Grade descent with measurable rate |
| Fast.branch | "clever interleaving" | Chiral decomposition halving grade |
| findBit preference | "arbitrary choice" | Spectral bias opportunity |
| L/R independence | Implicit | Orthogonal surfaces (parallelizable) |
| Complexity | O(2^n) | Tree structure with log depth exposed |

**The translation didn't prove new theorems yet, but it exposed:**
1. A spectral gap in Fast.branch (grade halving)
2. Parallelization structure (orthogonal surfaces)
3. Optimization hooks (spectral biasing)
4. A path to proving Fast.find terminates

---

## Next Steps

1. **Formalize the grade-halving lemma** for branch decomposition
2. **Prove Fast.find terminates** using chiral grade analysis
3. **Implement parallel search** exploiting surface independence
4. **Benchmark spectral biasing** with different predicate families
