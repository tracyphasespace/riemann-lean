#!/usr/bin/env python3
"""
Explicit Formula Gap Predictor

Uses the explicit formula for ψ(x) to predict prime gaps.

The prime counting function π(x) is related to ψ(x) = Σ_{p^k ≤ x} log p
by ψ(x) = x - Σ_ρ x^ρ/ρ - log(2π) - (1/2)log(1 - 1/x²) + ...

The sum over zeros ρ = 1/2 + iγ creates oscillations in prime density.
When the oscillation term is large and negative = sparse primes = larger gaps.
"""

import os
import sys
import math
import struct
import subprocess
import tempfile
import gmpy2
from pathlib import Path

# First 50 zeta zeros (imaginary parts)
ZETA_ZEROS = [
    14.134725, 21.022040, 25.010858, 30.424876, 32.935062,
    37.586178, 40.918720, 43.327073, 48.005151, 49.773832,
    52.970321, 56.446248, 59.347044, 60.831779, 65.112544,
    67.079811, 69.546402, 72.067158, 75.704691, 77.144840,
    79.337375, 82.910381, 84.735493, 87.425275, 88.809111,
    92.491899, 94.651344, 95.870634, 98.831194, 101.317851,
    103.725538, 105.446623, 107.168611, 111.029536, 111.874659,
    114.320220, 116.226680, 118.790782, 121.370125, 122.946829,
    124.256818, 127.516683, 129.578704, 131.087688, 133.497737,
    134.756509, 138.116042, 139.736209, 141.123707, 143.111846
]

CGBN_BINARY = "/tmp/cgbn_1024_primality"

def compute_explicit_oscillation(x, num_zeros=20):
    """
    Compute the oscillation term from the explicit formula:

    Oscillation ≈ -2 Σ_γ x^{1/2} cos(γ log x) / |ρ|

    where ρ = 1/2 + iγ, so |ρ| ≈ γ for large γ.

    Large NEGATIVE oscillation = primes sparse = larger gaps
    Large POSITIVE oscillation = primes dense = smaller gaps
    """
    # At 10^308, we can't compute x^{1/2} directly, but we can use
    # the fact that we're comparing relative oscillations within a window.
    # The x^{1/2} factor is essentially constant, so we focus on the cos term.

    log_x = float(gmpy2.log(x))

    oscillation = 0.0
    for i in range(min(num_zeros, len(ZETA_ZEROS))):
        gamma = ZETA_ZEROS[i]
        rho_magnitude = math.sqrt(0.25 + gamma * gamma)  # |1/2 + iγ|

        # Contribution from this zero
        oscillation -= 2 * math.cos(gamma * log_x) / rho_magnitude

    return oscillation

def compute_oscillation_derivative(x, num_zeros=20, delta_log=0.001):
    """
    Compute d/d(log x) of the oscillation.

    Rapid change = unstable region = larger gaps expected.
    """
    log_x = float(gmpy2.log(x))

    osc_plus = 0.0
    osc_minus = 0.0

    for i in range(min(num_zeros, len(ZETA_ZEROS))):
        gamma = ZETA_ZEROS[i]
        rho_magnitude = math.sqrt(0.25 + gamma * gamma)

        osc_plus -= 2 * math.cos(gamma * (log_x + delta_log)) / rho_magnitude
        osc_minus -= 2 * math.cos(gamma * (log_x - delta_log)) / rho_magnitude

    derivative = (osc_plus - osc_minus) / (2 * delta_log)
    return derivative

def compute_oscillation_profile(base, window_size, num_windows, num_zeros=20):
    """
    Compute oscillation profile across windows.

    At 10^308, log(x) changes by ~10^-305 per integer, so across a window
    of 50000 integers, log changes by only ~5×10^-301. This is negligible!

    Solution: Use the window CENTER's position and compute local structure
    using a scaled representation based on the window offset.
    """
    profile = []
    log_base = float(gmpy2.log(base))

    for w in range(num_windows):
        offset = w * window_size
        window_center = base + offset + window_size // 2

        # Key insight: at this scale, actual log(x) barely changes.
        # Instead, we use the OFFSET to create an effective position
        # on the critical line, scaled to span several zero spacings.

        # Average zero spacing near γ ≈ 50 is about 2π/log(50/(2πe)) ≈ 3
        # We want offsets of 0 to 10^6 to span ~10 zero spacings
        effective_t_delta = offset / window_size * 0.1  # Small modulation

        # Compute oscillation at multiple effective positions
        total_osc = 0.0
        total_osc_deriv = 0.0
        samples = 5

        for s in range(samples):
            sample_offset = offset + s * window_size // samples
            # Use actual log(x) but recognize it barely changes
            sample_x = base + sample_offset

            osc = compute_explicit_oscillation(sample_x, num_zeros)
            osc_deriv = compute_oscillation_derivative(sample_x, num_zeros)

            total_osc += osc
            total_osc_deriv += abs(osc_deriv)

        avg_osc = total_osc / samples
        avg_osc_deriv = total_osc_deriv / samples

        profile.append({
            'start': base + offset,
            'offset': offset,
            'oscillation': avg_osc,
            'osc_derivative': avg_osc_deriv
        })

    return profile

def compute_local_interference(base, offset, window_size, num_zeros=20):
    """
    Compute local interference pattern using the offset structure.

    Since log(x) is constant at 10^308, we use the offset mod various
    scales to create a "local fingerprint" that captures prime structure.
    """
    # Use offset modulo characteristic lengths related to primes
    # The spacing between primes near 10^308 is ~log(10^308) ≈ 709
    # Use this and multiples to create interference

    log_scale = 709  # Expected gap size

    interference = 0.0
    for i, gamma in enumerate(ZETA_ZEROS[:num_zeros]):
        # Phase from offset mod various scales
        phase1 = 2 * math.pi * (offset % (int(log_scale) + i)) / (log_scale + i)
        phase2 = 2 * math.pi * (offset % (int(log_scale * gamma / 10))) / (log_scale * gamma / 10 + 1)

        rho_magnitude = math.sqrt(0.25 + gamma * gamma)

        # Interference contribution
        interference += math.cos(gamma * phase1) / rho_magnitude
        interference += 0.5 * math.cos(gamma * phase2) / rho_magnitude

    return interference

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
    print("EXPLICIT FORMULA GAP PREDICTOR")
    print("="*70)
    print()
    print("Theory: Oscillation from Σ_γ cos(γ log x) / |ρ| predicts prime density")
    print("        Large negative oscillation = sparse primes = larger gaps")
    print()

    # Check binary exists
    if not os.path.exists(CGBN_BINARY):
        print(f"Error: {CGBN_BINARY} not found")
        sys.exit(1)

    # Parameters
    base = 10**308
    window_size = 50000
    num_windows = 20
    num_zeros = 30

    log_base = float(gmpy2.log(base))
    expected_gap = int(log_base)

    print(f"Base: 10^308")
    print(f"log(base): {log_base:.1f}")
    print(f"Expected gap: {expected_gap}")
    print(f"Window size: {window_size:,}")
    print(f"Windows: {num_windows}")
    print(f"Zeta zeros used: {num_zeros}")
    print()

    # Check oscillation at base
    print("Oscillation at base:")
    osc = compute_explicit_oscillation(base, num_zeros)
    osc_deriv = compute_oscillation_derivative(base, num_zeros)
    print(f"  Oscillation = {osc:.6f}")
    print(f"  |d/d(log x) Oscillation| = {abs(osc_deriv):.6f}")
    print()

    # Compute local interference profile using offsets
    print("Computing local interference profile...")
    print("-" * 50)

    results = []

    for w in range(num_windows):
        offset = w * window_size
        window_start = base + offset

        # Compute interference (uses offset structure)
        interference = compute_local_interference(base, offset, window_size, num_zeros)

        # Measure actual gaps
        gaps, max_gap = measure_gaps_in_window(window_start, window_size)

        if gaps:
            avg_gap = sum(gaps) / len(gaps)
            gap_ratio = max_gap / expected_gap
            results.append({
                'window': w,
                'offset': offset,
                'interference': interference,
                'max_gap': max_gap,
                'avg_gap': avg_gap,
                'gap_ratio': gap_ratio,
                'num_primes': len(gaps) + 1
            })
            print(f"Window {w}: interf={interference:+.3f} → max_gap={max_gap:,} ({gap_ratio:.1f}x), primes={len(gaps)+1}")

    # Correlation analysis
    print("\n" + "="*70)
    print("CORRELATION ANALYSIS")
    print("="*70)

    if len(results) >= 3:
        interferences = [r['interference'] for r in results]
        max_gaps = [r['max_gap'] for r in results]
        avg_gaps = [r['avg_gap'] for r in results]

        def pearson(x, y):
            n = len(x)
            mx, my = sum(x)/n, sum(y)/n
            num = sum((xi-mx)*(yi-my) for xi, yi in zip(x, y))
            den = (sum((xi-mx)**2 for xi in x) * sum((yi-my)**2 for yi in y)) ** 0.5
            return num / den if den > 0 else 0

        corr_max = pearson(interferences, max_gaps)
        corr_avg = pearson(interferences, avg_gaps)

        print(f"\nCorrelation (Interference vs Max Gap): {corr_max:.3f}")
        print(f"Correlation (Interference vs Avg Gap): {corr_avg:.3f}")

        # Interpretation: negative interference should correlate with larger gaps
        if corr_max < -0.3:
            print("\n✓ NEGATIVE correlation: Low interference predicts larger gaps!")
        elif corr_max > 0.3:
            print("\n~ POSITIVE correlation: High interference predicts larger gaps")
        else:
            print("\n~ WEAK correlation")

        print("\n" + "-"*50)
        print("Sorted by INTERFERENCE (lowest first - predict large gaps):")
        by_interf = sorted(results, key=lambda x: x['interference'])[:5]
        for r in by_interf:
            print(f"  interf={r['interference']:+.3f} → max_gap={r['max_gap']:,} ({r['gap_ratio']:.1f}x)")

        print("\nSorted by MAX GAP (largest first):")
        by_gap = sorted(results, key=lambda x: -x['max_gap'])[:5]
        for r in by_gap:
            print(f"  max_gap={r['max_gap']:,} ({r['gap_ratio']:.1f}x) ← interf={r['interference']:+.3f}")

    # Summary
    print("\n" + "="*70)
    print("SUMMARY")
    print("="*70)

    if results:
        best = max(results, key=lambda x: x['max_gap'])
        print(f"\nLargest gap found: {best['max_gap']:,} ({best['gap_ratio']:.1f}x expected)")
        print(f"  Interference: {best['interference']:+.3f}")

        # Rank by interference (lowest should predict largest gaps)
        interf_sorted = sorted(results, key=lambda x: x['interference'])
        interf_rank = next(i for i, r in enumerate(interf_sorted) if r['max_gap'] == best['max_gap']) + 1
        print(f"  Interference rank (lowest first): #{interf_rank} of {len(results)}")

if __name__ == "__main__":
    main()
