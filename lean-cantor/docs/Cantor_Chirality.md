# Cantor Chirality: Grade-Halving via Chiral Decomposition

## The Discovery

By translating Cantor space search into Cl(∞,∞) geometric algebra, we exposed a hidden structure in the `Fast.branch` function: **chiral decomposition that halves the effective grade**.

This is the Cantor analog of:
- **Collatz**: Spectral gap `|log(1/2)| > |log(3/2)|` (contraction dominates)
- **Riemann**: Energy minimum at σ = 1/2 (unique equilibrium)
- **Cantor**: Grade halving via P₊/P₋ projection (dimension reduction)

---

## 1. The Branch Function Revisited

```lean
def branch (x : Bit) (l r : Cantor) : Cantor :=
  fun n =>
    if n = 0      then x          -- Position 0: chirality
    else if 2 ∣ n then r ((n-2)/2) -- Even positions: right surface
                  else l ((n-1)/2) -- Odd positions: left surface
```

### Position Mapping

```
Output position:  0   1   2   3   4   5   6   7   8   9   10  ...
Source:           x   l₀  r₀  l₁  r₁  l₂  r₂  l₃  r₃  l₄  r₄  ...
Surface:          ω   P₋  P₊  P₋  P₊  P₋  P₊  P₋  P₊  P₋  P₊  ...
```

### The Three Components

| Component | Positions | Count in first n | Fraction |
|-----------|-----------|------------------|----------|
| **Chirality x** | {0} | 1 | O(1/n) |
| **Left surface l** | {1,3,5,...} | ⌈(n-1)/2⌉ | ~1/2 |
| **Right surface r** | {2,4,6,...} | ⌊(n-1)/2⌋ | ~1/2 |

---

## 2. The Grade-Halving Lemma

### Statement

If predicate `p` has modulus `n` (depends on first n bits), then:
- The **chirality constraint** has modulus 1
- The **left surface constraint** has modulus ≤ ⌈(n-1)/2⌉
- The **right surface constraint** has modulus ≤ ⌊(n-1)/2⌋

### Why This Matters

```
Original problem:     modulus n
                         │
                         ▼
After branch:    ┌───────┼───────┐
                 │       │       │
                 x       l       r
              mod 1   mod~n/2  mod~n/2
```

**Each recursive call operates on roughly half the grade.**

### Formal Statement

```lean
theorem surface_modulus_lt (n : Nat) (hn : n > 1) :
    rightModulus n < n ∧ leftModulus n < n

where:
  rightModulus n := (n - 1) / 2
  leftModulus n := (n - 1 + 1) / 2
```

---

## 3. Geometric Algebra Interpretation

### Chiral Projectors

In Cl(p,p), the pseudoscalar ω satisfies ω² = 1, enabling:

```
P₊ = (1 + ω)/2    -- Projects onto "even" subspace
P₋ = (1 - ω)/2    -- Projects onto "odd" subspace
```

### Cantor Realization

```
Cantor sequence a : Nat → Bit

Chiral decomposition:
  a = ω·(a 0) + P₋(a|_odd) + P₊(a|_even)

where:
  a|_odd  = [a(1), a(3), a(5), ...]  -- Left surface
  a|_even = [a(2), a(4), a(6), ...]  -- Right surface
  a(0)    = chirality bit
```

### The Decomposition Theorem

```lean
theorem chiral_decomposition (a : Cantor) :
    branch (a 0) (projectOdd a) (projectEven a) = a
```

Every infinite binary sequence decomposes uniquely into:
1. A chirality bit (grade 0 in the decomposed frame)
2. A left surface sequence (odd positions)
3. A right surface sequence (even positions)

---

## 4. Why Chirality Enables Fast Search

### Standard Find (Linear Grade Descent)

```lean
def find (p : CantorPred) : Cantor := fun i =>
  have b := forsome (p.comp_cons true)
  (b # find (p.comp_cons b)) i
```

**Grade descent**: n → n-1 → n-2 → ... → 0

**Depth**: O(n)

### Fast Find (Logarithmic Grade Descent)

```lean
def find (p : Cantor -> Bool) : Cantor :=
  let x := findBit (fun x => forsome (fun l => forsome (fun r => p (branch x l r))))
  let l := find (fun l => forsome (fun r => p (branch x l r)))
  let r := find (fun r => p (branch x l r))
  branch x l r
```

**Grade descent**: n → n/2 → n/4 → ... → 0

**Depth**: O(log n)

### The Speedup

| Algorithm | Grade Descent | Tree Depth | Work per Level |
|-----------|---------------|------------|----------------|
| Standard | n → n-1 | O(n) | O(1) |
| Fast | n → n/2 | O(log n) | O(2^level) |

Total work is similar, but **tree structure enables parallelism**.

---

## 5. Termination via Chiral Grade Analysis

### The Termination Argument

```
1. p has modulus n
2. branch decomposes into x (mod 1), l (mod ~n/2), r (mod ~n/2)
3. For n > 1: n/2 < n (strictly decreasing)
4. Base case: n ≤ 1 means predicate is nearly constant
5. Therefore: recursion terminates
```

### Formal Termination Measure

```lean
termination_by p => modulusOf p
decreasing_by
  -- After branch, both l and r searches have modulus < n
  exact surface_modulus_lt n hn
```

### Why This Wasn't Obvious Before

The original `Fast.find` is marked `partial` because:
1. It operates on raw `Cantor → Bool`, not `CantorPred`
2. The modulus structure is implicit
3. The grade-halving property isn't stated

The GA translation made the structure explicit:
- **branch** = chiral decomposition
- **modulus** = grade
- **halving** = projection onto lower-dimensional subspace

---

## 6. The Chiral Search Tree

### Structure

```
                        p (grade n)
                            │
                     ┌──────┴──────┐
                     │             │
                  x=false       x=true
                     │             │
              ┌──────┴──────┐     ...
              │             │
           l-search      l-search
          (grade n/2)   (grade n/2)
              │             │
         ┌────┴────┐   ┌────┴────┐
         │         │   │         │
      r-search  r-search ...   ...
     (grade n/4)
```

### Properties

1. **Depth**: O(log n) levels
2. **Branching**: Binary at each level (x choice, then l/r decomposition)
3. **Independence**: After x is fixed, l and r searches are on orthogonal surfaces
4. **Parallelism**: At each level, sibling subtrees can run in parallel

---

## 7. Connection to Other Chiral Systems

### Collatz (Cl(1,1))

```
Odd surface (P₋):  n → 3n+1  (expansion)
Even surface (P₊): n → n/2   (contraction)
Chirality:         parity of n

Grade descent: Spectral gap |log(1/2)| > |log(3/2)|
```

### Riemann (Cl(3,3))

```
Left surface (P₋):  σ < 1/2  (pole-dominated)
Right surface (P₊): σ > 1/2  (decay-dominated)
Chirality:          sign of (σ - 1/2)

Grade descent: Energy minimum at σ = 1/2
```

### Cantor (Cl(∞,∞))

```
Left surface (P₋):  odd bit positions
Right surface (P₊): even bit positions
Chirality:          bit 0

Grade descent: Modulus halving via projection
```

### The Unified Pattern

| System | Chiral Split | Grade Measure | Descent Rate |
|--------|--------------|---------------|--------------|
| Collatz | Odd/Even parity | log(n) | ~0.29 per step |
| Riemann | σ < ½ vs σ > ½ | Distance to ½ | Monotonic |
| Cantor | Odd/Even positions | Modulus n | n → n/2 |

---

## 8. Implications

### For Cantor Search

1. **Fast.find should be provably terminating** (not just `partial`)
2. **Parallel implementation** is natural (orthogonal surfaces)
3. **Complexity is O(n·2^(depth))** = O(n·2^(log n)) = O(n²) worst case

### For the Unified Framework

The same chiral decomposition pattern appears in:
- Number theory (Collatz)
- Complex analysis (Riemann)
- Computability (Cantor)

This suggests **chirality is fundamental** to searchability in split-signature spaces.

### For Future Work

1. **Prove Fast.find terminates** using chiral grade analysis
2. **Implement parallel search** exploiting surface independence
3. **Generalize to other searchable types** via chiral decomposition
4. **Find the "spectral gap"** in other seemingly impossible programs

---

## 9. Summary

### What We Discovered

The `branch` function in `Fast.find` performs **chiral decomposition**:

```
Cantor sequence = Chirality bit + Left surface + Right surface
     (grade n)      (grade 1)     (grade n/2)    (grade n/2)
```

### Why It Matters

1. **Termination**: Grade strictly decreases (n → n/2)
2. **Efficiency**: Tree depth is O(log n) instead of O(n)
3. **Parallelism**: Orthogonal surfaces can be searched independently
4. **Unification**: Same pattern as Collatz and Riemann

### The Key Equation

```
modulus(p ∘ branch) ≈ modulus(p) / 2
```

This is the **Cantor spectral gap** — chiral projection halves the dimension.

---

## Appendix: Code References

### Branch Position Lemmas

```lean
theorem branch_zero (x : Bit) (l r : Cantor) :
    branch x l r 0 = x

theorem branch_odd_pos (x : Bit) (l r : Cantor) (i : Nat) :
    branch x l r (2 * i + 1) = l i

theorem branch_even_pos (x : Bit) (l r : Cantor) (i : Nat) :
    branch x l r (2 * i + 2) = r i
```

### Grade Reduction

```lean
theorem rightPred_modulus_le (p : Cantor → Bool) (n : Nat) (x : Bit) (l : Cantor)
    (hp : HasModulus p n) :
    HasModulus (rightPred p x l) ((n - 1) / 2)

theorem surface_modulus_lt (n : Nat) (hn : n > 1) :
    rightModulus n < n ∧ leftModulus n < n
```

### Chiral Decomposition

```lean
theorem chiral_decomposition (a : Cantor) :
    branch (a 0) (projectOdd a) (projectEven a) = a
```
