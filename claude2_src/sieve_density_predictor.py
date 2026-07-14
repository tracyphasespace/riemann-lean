#!/usr/bin/env python3
"""
Sieve Density Gap Predictor

At 10^308, the zeta zeros don't distinguish different windows because
log(x) is essentially constant. What DOES vary is the local divisibility
structure - how the residue classes mod small primes align.

Theory: When many numbers in a region are divisible by small primes,
there are fewer prime candidates, leading to larger gaps.

We compute a "sieve density" measuring what fraction of numbers in
each window survive trial division by small primes.
"""

import os
import sys
import math
import struct
import subprocess
import tempfile
import gmpy2
from pathlib import Path
from functools import reduce

CGBN_BINARY = "/tmp/cgbn_1024_primality"

# Small primes for sieve density calculation
SMALL_PRIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71]

def compute_primorial(primes):
    """Compute product of primes"""
    return reduce(lambda x, y: x * y, primes, 1)

def euler_phi(n, primes):
    """Compute Euler's totient for product of distinct primes"""
    result = 1
    for p in primes:
        if n % p == 0:
            result *= (p - 1)
        else:
            break
    return result

def compute_survivor_fraction(primes):
    """
    Fraction of integers that survive sieve by given primes.
    This is φ(P)/P where P = product of primes.
    """
    P = compute_primorial(primes)
    phi = 1
    for p in primes:
        phi *= (p - 1)
    return phi / P

def compute_local_sieve_density(base, offset, window_size, num_primes=10):
    """
    Compute how many integers in the window survive trial division.

    This measures the "local" prime density based on small divisibility.

    For each small prime p, the density of survivors is (p-1)/p.
    But this can vary slightly based on where the window starts mod p.
    """
    primes = SMALL_PRIMES[:num_primes]
    primorial = compute_primorial(primes)

    # Base survivor fraction (asymptotic)
    base_density = compute_survivor_fraction(primes)

    # Now compute how the specific window start affects things
    # The window spans positions [base+offset, base+offset+window_size)
    window_start = base + offset

    # For each prime p, count how many of the residue classes 0,1,...,p-1
    # contain numbers divisible by p in our window.
    # This is essentially always 1/p except for edge effects.

    # More interesting: compute the "interference pattern" of residues
    # Some starting positions align with more composite-rich regions

    # Compute combined residue pattern
    window_residue = int(window_start % primorial)

    # Count residue classes in [0, primorial) that are coprime to primorial
    # This is constant, but the DISTRIBUTION of coprime residues within
    # a window of size << primorial creates local variation.

    # For predicting gaps: look at the longest run of consecutive
    # non-coprime residue classes starting from window_residue

    # Simpler approach: sum of 1/(p-residue) for residues close to 0
    # Small residues mean we're "close" to a multiple of p
    proximity_score = 0.0
    for p in primes:
        r = int(window_start % p)
        if r == 0:
            r = p  # Actually divisible
        # How close to a multiple of p? Lower r = closer = more composites nearby
        proximity_score += 1.0 / r

    return base_density, proximity_score

def compute_gap_estimate(base, offset, window_size):
    """
    Estimate expected gap size based on local structure.

    At 10^308, expected gap ≈ log(10^308) ≈ 709.
    Local variations in sieve density should modulate this.
    """
    log_n = float(gmpy2.log(base + offset))

    base_density, proximity = compute_local_sieve_density(base, offset, window_size)

    # Higher proximity score = more composites nearby = expect larger gaps
    # Base gap estimate is log(n) / density_of_primes
    # density_of_primes ≈ 1/log(n), so gap ≈ log(n)

    # Modulation factor: proximity affects local density
    modulation = 1 + 0.1 * (proximity - 3.0)  # Normalized around typical value

    estimated_gap = log_n * modulation

    return estimated_gap, proximity

def compute_consecutive_composite_potential(base, offset, primes_to_use=10):
    """
    Compute the "potential" for long runs of consecutive composites.

    Use Chinese Remainder Theorem structure to find how many
    consecutive integers starting near base+offset are composite.
    """
    primes = SMALL_PRIMES[:primes_to_use]
    start = base + offset

    # For each prime p, find the distance to the next multiple
    distances = []
    for p in primes:
        r = int(start % p)
        dist_to_multiple = p - r if r != 0 else 0
        distances.append((p, dist_to_multiple))

    # Score based on how these distances combine
    # If multiple primes have small distances, composites cluster
    score = 0.0
    for p, d in distances:
        if d < p // 2:
            score += (p - d) / p  # Higher when close to multiple

    return score

def analyze_residue_patterns(base, window_size, num_windows, num_primes=15):
    """
    Analyze residue patterns across windows.
    """
    profile = []

    for w in range(num_windows):
        offset = w * window_size

        base_density, proximity = compute_local_sieve_density(base, offset, window_size, num_primes)
        composite_potential = compute_consecutive_composite_potential(base, offset, num_primes)

        profile.append({
            'offset': offset,
            'proximity': proximity,
            'composite_potential': composite_potential,
            'combined_score': proximity + composite_potential
        })

    return profile

def int_to_limbs_1024(n):
    """Convert Python int to 32 uint32 limbs"""
    limbs = []
    for _ in range(32):
        limbs.append(n & 0xFFFFFFFF)
        n >>= 32
    return limbs

def find_primes_in_range(start, count):
    """Find all primes in range using CGBN GPU"""
    WHEEL_OFFSETS = [1, 7, 11, 13, 17, 19, 23, 29]
    candidates = []
    current = (start // 30) * 30
    wheel_idx = 0

    while current + WHEEL_OFFSETS[wheel_idx] < start:
        wheel_idx += 1
        if wheel_idx >= 8:
            wheel_idx = 0
            current += 30

    end = start + count
    while current + WHEEL_OFFSETS[wheel_idx] < end:
        cand = current + WHEEL_OFFSETS[wheel_idx]
        if cand >= start:
            candidates.append(cand)
        wheel_idx += 1
        if wheel_idx >= 8:
            wheel_idx = 0
            current += 30

    if len(candidates) < 32:
        return [c for c in candidates if gmpy2.is_prime(c)]

    with tempfile.NamedTemporaryFile(delete=False, suffix='.bin') as f:
        input_file = f.name
        for n in candidates:
            limbs = int_to_limbs_1024(n)
            f.write(struct.pack('<32I', *limbs))

    output_file = input_file + '.out'

    try:
        result = subprocess.run(
            [CGBN_BINARY, input_file, output_file],
            capture_output=True, timeout=300
        )

        with open(output_file, 'rb') as f:
            results = list(f.read())

        primes = [c for c, r in zip(candidates, results) if r]
        return primes
    finally:
        try:
            os.unlink(input_file)
            os.unlink(output_file)
        except:
            pass

def measure_gaps_in_window(base, window_size):
    """Find primes in window and compute gaps"""
    primes = find_primes_in_range(base, window_size)

    if len(primes) < 2:
        return [], 0

    gaps = []
    for i in range(len(primes) - 1):
        gap = primes[i+1] - primes[i]
        gaps.append(gap)

    max_gap = max(gaps) if gaps else 0
    return gaps, max_gap

def main():
    print("="*70)
    print("SIEVE DENSITY GAP PREDICTOR")
    print("="*70)
    print()
    print("Theory: Local divisibility structure determines gap distribution")
    print("        High proximity score = near multiples of small primes")
    print("        = more composites = larger gaps expected")
    print()

    # Check binary exists
    if not os.path.exists(CGBN_BINARY):
        print(f"Error: {CGBN_BINARY} not found")
        sys.exit(1)

    # Parameters
    base = 10**308
    window_size = 50000
    num_windows = 20
    num_primes = 15

    log_base = float(gmpy2.log(base))
    expected_gap = int(log_base)

    print(f"Base: 10^308")
    print(f"Expected gap: {expected_gap}")
    print(f"Window size: {window_size:,}")
    print(f"Windows: {num_windows}")
    print(f"Small primes used: {num_primes}")
    print()

    # Compute sieve density at base
    base_density, base_proximity = compute_local_sieve_density(base, 0, window_size, num_primes)
    print(f"Survivor fraction (sieve by first {num_primes} primes): {base_density:.4f}")
    print(f"Base proximity score: {base_proximity:.3f}")
    print()

    # Analyze residue patterns
    print("Computing residue pattern profile...")
    print("-" * 70)

    profile = analyze_residue_patterns(base, window_size, num_windows, num_primes)

    # Sort by combined score (high = expect large gaps)
    profile_sorted = sorted(profile, key=lambda x: -x['combined_score'])
    print("Top 5 by combined score (predict largest gaps):")
    for item in profile_sorted[:5]:
        print(f"  offset={item['offset']:,}: proximity={item['proximity']:.3f}, "
              f"composite_pot={item['composite_potential']:.3f}, combined={item['combined_score']:.3f}")
    print()

    # Measure actual gaps
    print("="*70)
    print("MEASURING ACTUAL GAPS")
    print("="*70)

    results = []
    for item in profile:
        offset = item['offset']
        window_start = base + offset

        gaps, max_gap = measure_gaps_in_window(window_start, window_size)

        if gaps:
            avg_gap = sum(gaps) / len(gaps)
            gap_ratio = max_gap / expected_gap
            results.append({
                'offset': offset,
                'proximity': item['proximity'],
                'composite_potential': item['composite_potential'],
                'combined': item['combined_score'],
                'max_gap': max_gap,
                'avg_gap': avg_gap,
                'gap_ratio': gap_ratio,
                'num_primes': len(gaps) + 1
            })
            print(f"offset={offset:>8,}: combined={item['combined_score']:.2f} → "
                  f"max_gap={max_gap:,} ({gap_ratio:.1f}x), primes={len(gaps)+1}")

    # Correlation analysis
    print("\n" + "="*70)
    print("CORRELATION ANALYSIS")
    print("="*70)

    if len(results) >= 3:
        proximities = [r['proximity'] for r in results]
        composite_pots = [r['composite_potential'] for r in results]
        combined = [r['combined'] for r in results]
        max_gaps = [r['max_gap'] for r in results]
        avg_gaps = [r['avg_gap'] for r in results]

        def pearson(x, y):
            n = len(x)
            mx, my = sum(x)/n, sum(y)/n
            num = sum((xi-mx)*(yi-my) for xi, yi in zip(x, y))
            den = (sum((xi-mx)**2 for xi in x) * sum((yi-my)**2 for yi in y)) ** 0.5
            return num / den if den > 0 else 0

        corr_prox_max = pearson(proximities, max_gaps)
        corr_comp_max = pearson(composite_pots, max_gaps)
        corr_comb_max = pearson(combined, max_gaps)
        corr_comb_avg = pearson(combined, avg_gaps)

        print(f"\nCorrelation (Proximity vs Max Gap):    {corr_prox_max:+.3f}")
        print(f"Correlation (Composite Pot vs Max Gap): {corr_comp_max:+.3f}")
        print(f"Correlation (Combined vs Max Gap):      {corr_comb_max:+.3f}")
        print(f"Correlation (Combined vs Avg Gap):      {corr_comb_avg:+.3f}")

        if corr_comb_max > 0.3:
            print("\n✓ POSITIVE correlation: High combined score predicts larger gaps!")
        elif corr_comb_max < -0.3:
            print("\n✗ NEGATIVE correlation: High combined score predicts smaller gaps")
        else:
            print("\n~ WEAK correlation")

        print("\n" + "-"*50)
        print("Sorted by COMBINED SCORE (highest first):")
        by_comb = sorted(results, key=lambda x: -x['combined'])[:5]
        for r in by_comb:
            print(f"  combined={r['combined']:.2f} → max_gap={r['max_gap']:,} ({r['gap_ratio']:.1f}x)")

        print("\nSorted by MAX GAP (largest first):")
        by_gap = sorted(results, key=lambda x: -x['max_gap'])[:5]
        for r in by_gap:
            print(f"  max_gap={r['max_gap']:,} ({r['gap_ratio']:.1f}x) ← combined={r['combined']:.2f}")

    # Summary
    print("\n" + "="*70)
    print("SUMMARY")
    print("="*70)

    if results:
        best = max(results, key=lambda x: x['max_gap'])
        print(f"\nLargest gap found: {best['max_gap']:,} ({best['gap_ratio']:.1f}x expected)")
        print(f"  Combined score: {best['combined']:.3f}")

        comb_sorted = sorted(results, key=lambda x: -x['combined'])
        comb_rank = next(i for i, r in enumerate(comb_sorted) if r['max_gap'] == best['max_gap']) + 1
        print(f"  Combined score rank: #{comb_rank} of {len(results)}")

if __name__ == "__main__":
    main()
