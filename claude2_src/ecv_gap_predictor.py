#!/usr/bin/env python3
"""
ECV (Euler-Clifford-von Mangoldt) Gap Predictor

Based on the second differential analysis:
- Z_ECV(σ,t) = Π_p exp(Σ_k (log p)/k · p^{-kσ} · R_p(kt))
- The second derivative d²/dσ² ||Z|| has a unique minimum at σ = 1/2
- High curvature regions = unstable = primes sparse = large gaps

This uses the curvature of the ECV discriminator to predict gap sizes.
"""

import os
import sys
import math
import struct
import subprocess
import tempfile
import gmpy2
from pathlib import Path

# Small primes for the product
SMALL_PRIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]

# First zeta zeros (imaginary parts)
ZETA_ZEROS = [
    14.134725, 21.022040, 25.010858, 30.424876, 32.935062,
    37.586178, 40.918720, 43.327073, 48.005151, 49.773832
]

CGBN_BINARY = "/tmp/cgbn_1024_primality"

def compute_ecv_term(p, k, sigma, t):
    """
    Compute a single term in the ECV sum:
    (log p)/k · p^{-kσ} · R_p(kt)

    The rotor R_p(θ) = cos(θ) + B·sin(θ) where B² = -1
    For the norm, we use |R_p| = 1, so the contribution is:
    (log p)/k · p^{-kσ} · (cos²(kt·log p) + sin²(kt·log p))^{1/2} = (log p)/k · p^{-kσ}

    But for curvature, we need the phase information.
    """
    log_p = math.log(p)
    amplitude = (log_p / k) * (p ** (-k * sigma))
    phase = k * t * log_p

    # Return real and "bivector" parts
    real_part = amplitude * math.cos(phase)
    biv_part = amplitude * math.sin(phase)

    return real_part, biv_part

def compute_ecv_norm(sigma, t, num_primes=10, k_max=5):
    """
    Compute ||Z_ECV(σ, t)|| using the product formula.

    Z_ECV = Π_p exp(Σ_k (log p)/k · p^{-kσ} · R_p(kt))

    For each prime p, the sum S_p = a_p + B·b_p (scalar + bivector)
    |exp(a_p + B·b_p)| = exp(a_p)

    So ||Z|| = Π_p exp(a_p) = exp(Σ_p a_p)
    where a_p = Σ_k (log p)/k · p^{-kσ} · cos(k·t·log p)
    """
    # Sum of real parts across all primes (log of the norm)
    log_norm = 0.0

    for p in SMALL_PRIMES[:num_primes]:
        # Compute a_p = real part of sum for this prime
        a_p = 0.0
        log_p = math.log(p)
        for k in range(1, k_max + 1):
            amplitude = (log_p / k) * (p ** (-k * sigma))
            phase = k * t * log_p
            a_p += amplitude * math.cos(phase)
        log_norm += a_p

    # ||Z|| = exp(log_norm)
    return math.exp(log_norm)

def compute_ecv_second_derivative(sigma, t, num_primes=10, k_max=5, h=0.001):
    """
    Compute d²/dσ² ||Z_ECV(σ, t)|| using finite differences.

    f''(σ) ≈ (f(σ+h) - 2f(σ) + f(σ-h)) / h²
    """
    # Get norms (now returns norm directly)
    f_plus = compute_ecv_norm(sigma + h, t, num_primes, k_max)
    f_mid = compute_ecv_norm(sigma, t, num_primes, k_max)
    f_minus = compute_ecv_norm(sigma - h, t, num_primes, k_max)

    second_deriv = (f_plus - 2*f_mid + f_minus) / (h * h)
    return second_deriv

def compute_ecv_curvature_at_point(n, base_t=14.134725, sigma=0.5):
    """
    Compute ECV curvature for a specific number n.

    The key insight: use the offset from base to create a meaningful t variation.
    At 10^308, log(n) barely changes, but the actual offset matters for gap structure.

    We use multiple zeta zeros and compute interference patterns based on
    the number's position modulo various scales related to log(n).
    """
    # Use the number's structure to compute an effective position
    # that captures local variation

    # Method: Use residues mod primorial to create a "fingerprint"
    # that varies significantly across the search window
    primorial = 2 * 3 * 5 * 7 * 11 * 13  # 30030
    residue = int(n % primorial)

    # Map residue to a position in [0, 2π] for phase calculation
    phase_scale = 2 * math.pi / primorial

    # Compute interference from multiple zeta zeros
    total_curvature = 0.0
    num_zeros = min(10, len(ZETA_ZEROS))

    for i, gamma in enumerate(ZETA_ZEROS[:num_zeros]):
        # Each zero contributes at a different phase
        phase = gamma * residue * phase_scale
        # Weight by 1/sqrt(gamma) as per explicit formula
        weight = 1.0 / math.sqrt(gamma)

        # Compute local curvature at t = gamma with this phase offset
        local_t = gamma + math.sin(phase) * 0.1  # Small perturbation near zero
        curv_i = compute_ecv_second_derivative(sigma, local_t)
        total_curvature += weight * curv_i

    return total_curvature

def compute_curvature_profile(base, window_size, num_windows):
    """
    Compute ECV curvature profile across multiple windows.
    Higher curvature = more unstable = expect larger gaps.
    """
    profile = []

    for w in range(num_windows):
        offset = w * window_size
        window_center = base + offset + window_size // 2

        # Sample multiple points and average
        total_curvature = 0.0
        samples = 5
        for s in range(samples):
            sample_point = base + offset + s * window_size // samples
            curv = compute_ecv_curvature_at_point(sample_point)
            total_curvature += abs(curv)  # Use absolute curvature

        avg_curvature = total_curvature / samples
        profile.append((base + offset, avg_curvature))

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
    print("ECV SECOND-DIFFERENTIAL GAP PREDICTOR")
    print("="*70)
    print()
    print("Theory: High curvature d²/dσ² ||Z_ECV|| = unstable = larger gaps")
    print("        Low curvature = stable (near critical line) = smaller gaps")
    print()

    # First, verify the curvature minimum at σ = 1/2
    print("Verifying curvature minimum at σ = 1/2:")
    print("-" * 50)
    t = 14.134725  # First zero
    for sigma in [0.45, 0.48, 0.50, 0.52, 0.55]:
        curv = compute_ecv_second_derivative(sigma, t)
        print(f"  σ = {sigma:.2f}: d²/dσ² ||Z|| = {curv:.6e}")
    print()

    # Check binary exists
    if not os.path.exists(CGBN_BINARY):
        print(f"Error: {CGBN_BINARY} not found")
        sys.exit(1)

    # Parameters
    base = 10**308
    window_size = 50000
    num_windows = 20

    log_base = float(gmpy2.log(base))
    expected_gap = int(log_base)

    print(f"Base: 10^308")
    print(f"Expected gap: {expected_gap}")
    print(f"Window size: {window_size:,}")
    print(f"Windows: {num_windows}")
    print()

    # Compute curvature profile
    print("Computing ECV curvature profile...")
    profile = compute_curvature_profile(base, window_size, num_windows)

    # Sort by curvature
    profile_sorted = sorted(profile, key=lambda x: -x[1])
    print("\nTop 10 highest curvature windows (predict largest gaps):")
    print("-" * 50)
    for i, (start, curv) in enumerate(profile_sorted[:10]):
        offset = start - base
        print(f"  #{i+1}: offset={offset:,}, curvature={curv:.6e}")

    # Measure actual gaps
    print("\n" + "="*70)
    print("MEASURING ACTUAL GAPS")
    print("="*70)

    results = []
    for i, (start, curvature) in enumerate(profile):
        print(f"\nWindow {i}: offset={(start-base):,}, curvature={curvature:.3e}")

        gaps, max_gap = measure_gaps_in_window(start, window_size)

        if gaps:
            avg_gap = sum(gaps) / len(gaps)
            gap_ratio = max_gap / expected_gap
            results.append({
                'window': i,
                'offset': start - base,
                'curvature': curvature,
                'max_gap': max_gap,
                'avg_gap': avg_gap,
                'gap_ratio': gap_ratio,
                'num_primes': len(gaps) + 1
            })
            print(f"  Primes: {len(gaps)+1}, Max gap: {max_gap} ({gap_ratio:.1f}x), Avg: {avg_gap:.0f}")

    # Correlation analysis
    print("\n" + "="*70)
    print("CORRELATION ANALYSIS")
    print("="*70)

    if len(results) >= 3:
        curvatures = [r['curvature'] for r in results]
        max_gaps = [r['max_gap'] for r in results]
        avg_gaps = [r['avg_gap'] for r in results]

        def pearson(x, y):
            n = len(x)
            mx, my = sum(x)/n, sum(y)/n
            num = sum((xi-mx)*(yi-my) for xi, yi in zip(x, y))
            den = (sum((xi-mx)**2 for xi in x) * sum((yi-my)**2 for yi in y)) ** 0.5
            return num / den if den > 0 else 0

        corr_max = pearson(curvatures, max_gaps)
        corr_avg = pearson(curvatures, avg_gaps)

        print(f"\nCorrelation (Curvature vs Max Gap): {corr_max:.3f}")
        print(f"Correlation (Curvature vs Avg Gap): {corr_avg:.3f}")

        if corr_max > 0.3:
            print("\n✓ POSITIVE correlation: High curvature predicts larger gaps!")
        elif corr_max < -0.3:
            print("\n✗ NEGATIVE correlation: High curvature predicts smaller gaps")
        else:
            print("\n~ WEAK correlation")

        print("\n" + "-"*50)
        print("Sorted by CURVATURE (highest first):")
        by_curv = sorted(results, key=lambda x: -x['curvature'])[:5]
        for r in by_curv:
            print(f"  curv={r['curvature']:.2e} → max_gap={r['max_gap']:,} ({r['gap_ratio']:.1f}x)")

        print("\nSorted by MAX GAP (largest first):")
        by_gap = sorted(results, key=lambda x: -x['max_gap'])[:5]
        for r in by_gap:
            print(f"  max_gap={r['max_gap']:,} ({r['gap_ratio']:.1f}x) ← curv={r['curvature']:.2e}")

    # Summary
    print("\n" + "="*70)
    print("SUMMARY")
    print("="*70)

    if results:
        best = max(results, key=lambda x: x['max_gap'])
        print(f"\nLargest gap found: {best['max_gap']:,} ({best['gap_ratio']:.1f}x expected)")
        print(f"  in window with curvature: {best['curvature']:.3e}")

        # Check if high curvature predicted it
        curv_rank = sorted(results, key=lambda x: -x['curvature']).index(best) + 1
        print(f"  curvature rank: #{curv_rank} of {len(results)}")

if __name__ == "__main__":
    main()
