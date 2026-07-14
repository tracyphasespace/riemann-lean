#!/usr/bin/env python3
"""
Clifford Zero Anatomy — Exploring GA operator structure at zeros of ζ(s).

The key insight: at a zero ρ of ζ(s), the Clifford state ζ_Cl(ρ)
does NOT vanish. It rotates into a direction orthogonal to the
observation plane. The "zero" is a shadow — the state is still there,
just invisible to the 1D observer.

We examine:
1. The per-prime Euler factors at known zeros
2. How the grade decomposition distributes energy
3. What happens when we move OFF the critical line (σ ≠ 1/2)
4. The operator equation: projection vs rejection at zeros

Key question: Does the per-prime factored structure + functional
equation symmetry ALGEBRAICALLY force the null-plane intersection
to occur only at σ = 1/2?
"""

import numpy as np
from itertools import combinations
from functools import reduce

# Known non-trivial zeros of ζ(s) (imaginary parts, all at σ = 1/2)
ZERO_HEIGHTS = [
    14.134725141734693,
    21.022039638771555,
    25.010857580145689,
    30.424876125859513,
    32.935061587739189,
]

def primes_up_to(N):
    """Sieve of Eratosthenes."""
    sieve = [True] * (N + 1)
    sieve[0] = sieve[1] = False
    for i in range(2, int(N**0.5) + 1):
        if sieve[i]:
            for j in range(i*i, N+1, i):
                sieve[j] = False
    return [i for i in range(2, N+1) if sieve[i]]

def euler_factor(p, sigma, t):
    """
    Compute the Euler factor (1 - p^{-s})^{-1} for s = σ + it.
    Returns (a, b) where the factor = a + bi in ℂ.

    In the Clifford algebra, this same factor is a + b*B_p
    where B_p is the prime's bivector.
    """
    s = complex(sigma, t)
    z = 1.0 / (1.0 - p ** (-s))
    return z.real, z.imag

def clifford_product_grades(primes, sigma, t):
    """
    Compute the grade decomposition of the partial Euler product
    in Cl(∞,∞).

    For N primes, the product ∏(a_p + b_p B_p) generates
    components in grades 0, 2, 4, ..., 2N.

    We track the energy (squared norm) in each grade.

    KEY ALGEBRAIC FACT: Because the B_p commute ([B_p, B_q] = 0),
    the product expands as:

    ∏_p (a_p + b_p B_p) = Σ_S (∏_{p∈S} b_p · ∏_{p∉S} a_p) · ∏_{p∈S} B_p

    where S ranges over all subsets of primes.
    Grade of the term for subset S = 2·|S|.
    Norm² of the B_p product for S = 1 (since B_p's are orthonormal).
    """
    N = len(primes)
    factors = []
    for p in primes:
        a, b = euler_factor(p, sigma, t)
        factors.append((a, b))

    # Energy in each grade (grade 2k)
    grade_energy = {}

    # For small N, enumerate all subsets
    if N <= 20:
        for k in range(N + 1):  # k = number of primes in subset S
            grade = 2 * k
            energy = 0.0
            for S in combinations(range(N), k):
                # Coefficient: ∏_{i∈S} b_i × ∏_{i∉S} a_i
                coeff = 1.0
                S_set = set(S)
                for i in range(N):
                    if i in S_set:
                        coeff *= factors[i][1]  # b_i
                    else:
                        coeff *= factors[i][0]  # a_i
                energy += coeff ** 2
            grade_energy[grade] = energy
    else:
        # For large N, use statistical sampling or the algebraic identity
        # Total Clifford norm² = ∏(a_p² + b_p²) — exact, no cross-terms
        total_norm_sq = 1.0
        for a, b in factors:
            total_norm_sq *= (a**2 + b**2)
        grade_energy['total'] = total_norm_sq

        # Grade 0 (scalar part) = ∏ a_p — this is Re(Euler product)
        scalar_part = 1.0
        for a, b in factors:
            scalar_part *= a  # NOT exactly right for grade 0
        # Actually grade 0 = Σ over even-size subsets...
        # For large N, just compute the complex product directly
        complex_product = 1.0 + 0j
        for a, b in factors:
            complex_product *= complex(a, b)
        grade_energy['scalar_shadow'] = abs(complex_product)**2

    return grade_energy, factors

def analyze_zero(t0, primes, label=""):
    """Analyze the Clifford state at a zero (σ=1/2) and off-zero (σ≠1/2)."""
    print(f"\n{'='*70}")
    print(f"ZERO at t = {t0:.6f}  ({label})")
    print(f"Using {len(primes)} primes up to {primes[-1]}")
    print(f"{'='*70}")

    sigma_on = 0.5   # On the critical line
    sigma_off = 0.6   # Off the critical line

    for sigma, name in [(sigma_on, "ON LINE (σ=0.5)"), (sigma_off, "OFF LINE (σ=0.6)")]:
        print(f"\n  --- {name} ---")

        # Compute complex Euler product
        euler_prod = 1.0 + 0j
        per_prime_norms = []
        for p in primes:
            s = complex(sigma, t0)
            factor = 1.0 / (1.0 - p ** (-s))
            euler_prod *= factor
            per_prime_norms.append(abs(factor)**2)

        # Clifford norm² = ∏ |factor_p|² (NO cross-terms)
        clifford_norm_sq = reduce(lambda x, y: x * y, per_prime_norms)

        # Complex modulus² of the product = |∏ factor_p|²
        # For FINITE products, this EQUALS the Clifford norm squared!
        complex_mod_sq = abs(euler_prod)**2

        print(f"  Complex product:  {euler_prod:.6e}")
        print(f"  |product|²:      {complex_mod_sq:.6e}")
        print(f"  Clifford |ζ_Cl|²: {clifford_norm_sq:.6e}")
        print(f"  Ratio (should=1): {complex_mod_sq / clifford_norm_sq:.10f}")

        # The PHASE of the product — where is the state pointing?
        phase = np.angle(euler_prod)
        print(f"  Phase (radians):  {phase:.6f}")
        print(f"  Phase (degrees):  {np.degrees(phase):.2f}°")

        # Per-prime analysis: how much does each prime "rotate" the state?
        cumulative_phase = 0.0
        cumulative_log_norm = 0.0
        print(f"\n  Per-prime contributions (first 10):")
        for i, p in enumerate(primes[:10]):
            s = complex(sigma, t0)
            factor = 1.0 / (1.0 - p ** (-s))
            factor_phase = np.angle(factor)
            factor_norm = abs(factor)
            cumulative_phase += factor_phase
            cumulative_log_norm += np.log(factor_norm)
            if i < 10:
                print(f"    p={p:3d}: |f|={factor_norm:.4f}, "
                      f"θ={np.degrees(factor_phase):+8.2f}°, "
                      f"cum_θ={np.degrees(cumulative_phase):+8.2f}°")

    # Grade decomposition (for small prime sets)
    if len(primes) <= 15:
        print(f"\n  --- GRADE DECOMPOSITION (σ=0.5, {len(primes)} primes) ---")
        grades, factors = clifford_product_grades(primes, 0.5, t0)
        total = sum(grades.values())
        for grade in sorted(grades.keys()):
            energy = grades[grade]
            pct = 100 * energy / total if total > 0 else 0
            print(f"    Grade {grade:2d}: energy = {energy:.6e}  ({pct:6.2f}%)")
        print(f"    TOTAL:    energy = {total:.6e}")

def experiment_sigma_sweep(t0, primes):
    """
    Sweep σ across the critical strip and track how the complex product
    behaves. At σ=1/2, we should see the product approach zero (it's a
    zero of ζ). Off σ=1/2, the product should be nonzero.

    KEY: The Clifford norm ∏|factor_p|² is ALWAYS positive.
    The complex modulus |∏ factor_p|² is also always positive for
    finite products. But it should be MINIMIZED near σ=1/2.
    """
    print(f"\n{'='*70}")
    print(f"SIGMA SWEEP at t = {t0:.6f}")
    print(f"Using {len(primes)} primes up to {primes[-1]}")
    print(f"{'='*70}")

    sigmas = np.linspace(0.1, 0.9, 41)

    print(f"\n  {'σ':>6s}  {'|Euler prod|²':>14s}  {'Cliff norm²':>14s}  "
          f"{'Ratio':>10s}  {'Phase°':>8s}")
    print(f"  {'-'*60}")

    min_mod = float('inf')
    min_sigma = 0.0

    for sigma in sigmas:
        euler_prod = 1.0 + 0j
        cliff_norm_sq = 1.0
        for p in primes:
            s = complex(sigma, t0)
            factor = 1.0 / (1.0 - p ** (-s))
            euler_prod *= factor
            cliff_norm_sq *= abs(factor)**2

        mod_sq = abs(euler_prod)**2
        ratio = mod_sq / cliff_norm_sq if cliff_norm_sq > 0 else 0
        phase = np.degrees(np.angle(euler_prod))

        if mod_sq < min_mod:
            min_mod = mod_sq
            min_sigma = sigma

        if abs(sigma - 0.5) < 0.01 or abs(sigma - min_sigma) < 0.01 or sigma in [0.1, 0.3, 0.7, 0.9]:
            print(f"  {sigma:6.3f}  {mod_sq:14.6e}  {cliff_norm_sq:14.6e}  "
                  f"{ratio:10.6f}  {phase:+8.2f}")

    print(f"\n  MINIMUM |Euler prod|² at σ = {min_sigma:.3f} "
          f"(expected: 0.500)")
    print(f"  This is {'ON' if abs(min_sigma - 0.5) < 0.02 else 'OFF'} "
          f"the critical line")

def experiment_projection_ratio(t0, max_primes=200):
    """
    Track how the ratio |shadow|²/|Clifford|² evolves as we add primes.

    KEY INSIGHT: For finite products:
      |shadow|² = |∏_p (a_p + i·b_p)|²
      |Clifford|² = ∏_p (a_p² + b_p²)

    Algebraically: |shadow|² = |Clifford|² always (for products).
    But the DIRICHLET SERIES approximation breaks this equality!

    So we also compare:
      |Dirichlet sum|² = |Σ_{n≤N} n^{-s}|² (HAS cross-terms)
      |Euler product|² = |∏_{p≤N} (1-p^{-s})^{-1}|² (NO cross-terms)
    """
    primes = primes_up_to(max_primes)
    sigma = 0.5
    t = t0
    s = complex(sigma, t)

    print(f"\n{'='*70}")
    print(f"PROJECTION RATIO EXPERIMENT at ρ = {sigma} + {t:.6f}i")
    print(f"{'='*70}")

    print(f"\n  {'N_p':>4s}  {'|Euler|²':>12s}  {'|Cliff|²':>12s}  "
          f"{'Ratio':>10s}  {'|Dirichlet|²':>14s}  {'Dir/Euler':>10s}")
    print(f"  {'-'*72}")

    euler_prod = 1.0 + 0j
    cliff_norm_sq = 1.0

    # Also compute partial Dirichlet sum
    # N-smooth Dirichlet sum = Euler product (exact for finite primes)
    # Truncated Dirichlet sum ≠ Euler product

    for i, p in enumerate(primes):
        factor = 1.0 / (1.0 - p ** (-s))
        euler_prod *= factor
        cliff_norm_sq *= abs(factor)**2

        # Truncated Dirichlet sum up to largest prime
        N = p
        dirichlet_sum = sum(n ** (-s) for n in range(1, N + 1))

        euler_sq = abs(euler_prod)**2
        dirichlet_sq = abs(dirichlet_sum)**2
        ratio = euler_sq / cliff_norm_sq
        dir_euler_ratio = dirichlet_sq / euler_sq if euler_sq > 0 else 0

        if (i + 1) in [1, 2, 3, 5, 10, 15, 20, 30, 45] or (i + 1) == len(primes):
            print(f"  {i+1:4d}  {euler_sq:12.4e}  {cliff_norm_sq:12.4e}  "
                  f"{ratio:10.6f}  {dirichlet_sq:14.4e}  {dir_euler_ratio:10.6f}")

def experiment_off_line_zero(t0, primes):
    """
    THOUGHT EXPERIMENT: What if there were a zero at σ₀ ≠ 1/2?

    At such a hypothetical zero, the functional equation demands
    another zero at 1-σ₀. Between them, the energy E(σ) must form
    a "hill" (local maximum), requiring E''(σ*) < 0 for some σ*.

    We check: for the FINITE Euler product (which has no cross-terms
    and factored norm), can the energy EVER form a hill between
    σ₀ and 1-σ₀?

    The answer should be: NO, because the factored norm is a product
    of per-prime terms, each of which is "U-shaped" (convex) in σ.
    """
    print(f"\n{'='*70}")
    print(f"OFF-LINE ZERO TEST at t = {t0:.6f}")
    print(f"Can the factored Euler energy form a 'hill'?")
    print(f"{'='*70}")

    sigmas = np.linspace(0.1, 0.9, 81)

    # Compute |Euler product|² as function of σ
    euler_energy = []
    cliff_energy = []
    for sigma in sigmas:
        euler_prod = 1.0 + 0j
        cliff_sq = 1.0
        for p in primes:
            s = complex(sigma, t0)
            factor = 1.0 / (1.0 - p ** (-s))
            euler_prod *= factor
            cliff_sq *= abs(factor)**2
        euler_energy.append(abs(euler_prod)**2)
        cliff_energy.append(cliff_sq)

    euler_energy = np.array(euler_energy)
    cliff_energy = np.array(cliff_energy)

    # Check convexity of log(Euler energy) = Σ log|factor_p|²
    # This is a SUM of per-prime functions — convex if each term is convex
    log_euler = np.log(euler_energy)
    log_cliff = np.log(cliff_energy)

    # Numerical second derivative
    dsigma = sigmas[1] - sigmas[0]
    d2_euler = np.diff(log_euler, 2) / dsigma**2
    d2_cliff = np.diff(log_cliff, 2) / dsigma**2

    print(f"\n  Second derivative of log|energy| (convexity check):")
    print(f"  {'σ':>6s}  {'d²(log|Euler|²)':>16s}  {'d²(log|Cliff|²)':>16s}")
    print(f"  {'-'*44}")
    for i in range(0, len(d2_euler), 10):
        sigma = sigmas[i+1]
        print(f"  {sigma:6.3f}  {d2_euler[i]:16.4f}  {d2_cliff[i]:16.4f}")

    # KEY CHECK: Are they the same?
    max_diff = np.max(np.abs(d2_euler - d2_cliff))
    print(f"\n  Max |d²_Euler - d²_Cliff|: {max_diff:.2e}")
    print(f"  (Should be ~0 since |Euler prod|² = Clifford norm² for products)")

    # Check: is log(Clifford energy) always convex?
    min_d2_cliff = np.min(d2_cliff)
    print(f"\n  Min d²(log|Cliff|²): {min_d2_cliff:.4f}")
    print(f"  CONVEX: {'YES' if min_d2_cliff > 0 else 'NO'}")

    # The ratio |Euler|²/|Cliff|² should be identically 1
    ratio = euler_energy / cliff_energy
    print(f"\n  |Euler|²/|Cliff|² range: [{ratio.min():.10f}, {ratio.max():.10f}]")
    print(f"  (Should be exactly [1.0, 1.0])")

def experiment_von_mangoldt_operator(t0, primes):
    """
    The von Mangoldt operator: -ζ'/ζ(s) = Σ Λ(n) n^{-s}

    In the Clifford algebra, this lives ENTIRELY in Grade 2 (prime
    bivectors) because Λ(n) = 0 for non-prime-powers, and prime
    powers p^k all map to the B_p bivector plane.

    KEY: The poles of -ζ'/ζ are exactly the zeros of ζ.
    And -ζ'/ζ has NO composite cross-terms in ANY representation.

    Can we use this operator to detect zeros without cross-terms?
    """
    print(f"\n{'='*70}")
    print(f"VON MANGOLDT OPERATOR at t = {t0:.6f}")
    print(f"Poles of -ζ'/ζ = zeros of ζ, NO composite terms")
    print(f"{'='*70}")

    sigma_vals = np.linspace(0.1, 0.9, 41)

    print(f"\n  {'σ':>6s}  {'|-ζ\'/ζ|²':>14s}  {'Per-prime Σ':>14s}  "
          f"{'Ratio':>10s}")
    print(f"  {'-'*52}")

    for sigma in sigma_vals:
        s = complex(sigma, t0)

        # -ζ'/ζ as sum over prime powers
        mangoldt_sum = 0.0 + 0j
        per_prime_energy = 0.0

        for p in primes:
            log_p = np.log(p)
            # Sum over prime powers p^k
            pp_sum = 0.0 + 0j  # per-prime-p contribution
            pk = p
            while pk <= 10000:  # truncate
                pp_sum += log_p * pk ** (-s)
                pk *= p
            mangoldt_sum += pp_sum
            per_prime_energy += abs(pp_sum)**2  # Clifford: per-prime, no cross

        total_energy = abs(mangoldt_sum)**2
        ratio = total_energy / per_prime_energy if per_prime_energy > 0 else 0

        if abs(sigma - 0.5) < 0.015 or sigma in [0.1, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9]:
            print(f"  {sigma:6.3f}  {total_energy:14.4e}  {per_prime_energy:14.4e}  "
                  f"{ratio:10.4f}")

    print(f"\n  NOTE: At σ=0.5, |-ζ'/ζ|² should spike (pole = zero of ζ)")
    print(f"  The RATIO |complex|²/|Clifford|² measures cross-term pollution.")
    print(f"  Ratio > 1: constructive cross-interference")
    print(f"  Ratio < 1: destructive cross-interference")
    print(f"  Ratio = 1: perfect Pythagorean (no cross-terms)")

# ============================================================
# MAIN
# ============================================================
if __name__ == "__main__":
    primes_small = primes_up_to(30)   # 10 primes
    primes_med = primes_up_to(100)    # 25 primes
    primes_large = primes_up_to(500)  # 95 primes

    t1 = ZERO_HEIGHTS[0]  # First zero

    print("=" * 70)
    print("CLIFFORD ZERO ANATOMY")
    print("Exploring GA operator structure at zeros of ζ(s)")
    print("=" * 70)

    # Experiment 1: Grade decomposition at first zero
    analyze_zero(t1, primes_small[:8], "first zero, 8 primes")

    # Experiment 2: Sigma sweep — where does the shadow minimize?
    experiment_sigma_sweep(t1, primes_med)

    # Experiment 3: Projection ratio — Euler vs Clifford vs Dirichlet
    experiment_projection_ratio(t1, max_primes=100)

    # Experiment 4: Off-line zero test — can the factored energy form a hill?
    experiment_off_line_zero(t1, primes_med)

    # Experiment 5: Von Mangoldt operator — zero detection without cross-terms
    experiment_von_mangoldt_operator(t1, primes_large)

    print(f"\n{'='*70}")
    print("SUMMARY OF KEY QUESTIONS:")
    print("1. Is |Euler product|² = Clifford norm² exactly? (algebraic identity)")
    print("2. Where does the complex product minimize? (should be σ=0.5)")
    print("3. Is log(Clifford energy) always convex? (per-prime factored)")
    print("4. Does the von Mangoldt operator detect zeros without cross-terms?")
    print("5. What is the cross-term pollution ratio at vs off the critical line?")
    print("=" * 70)
