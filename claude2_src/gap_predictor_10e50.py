#!/usr/bin/env python3
"""
Gap Predictor at 10^50 Scale

Test whether zeta-based gap prediction works better at smaller scales.

At 10^50:
- log(n) ≈ 115.1
- Expected gap ≈ 115
- 166 bits - gmpy2 handles efficiently
"""

import math
import gmpy2
from concurrent.futures import ProcessPoolExecutor
import time

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

# Small primes for ECV
SMALL_PRIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]


def compute_explicit_oscillation(log_x, num_zeros=30):
    """
    Compute oscillation from explicit formula:
    Oscillation ≈ -2 Σ_γ cos(γ log x) / |ρ|
    """
    oscillation = 0.0
    for i in range(min(num_zeros, len(ZETA_ZEROS))):
        gamma = ZETA_ZEROS[i]
        rho_magnitude = math.sqrt(0.25 + gamma * gamma)
        oscillation -= 2 * math.cos(gamma * log_x) / rho_magnitude
    return oscillation


def compute_ecv_curvature(log_x, sigma=0.5, num_primes=10, k_max=5):
    """
    Compute ECV curvature d²/dσ² ||Z_ECV|| at given position.
    """
    h = 0.001

    def ecv_norm(sig):
        log_norm = 0.0
        for p in SMALL_PRIMES[:num_primes]:
            a_p = 0.0
            log_p = math.log(p)
            # Use log_x as the t parameter (position on critical line)
            t = log_x
            for k in range(1, k_max + 1):
                amplitude = (log_p / k) * (p ** (-k * sig))
                phase = k * t * log_p
                a_p += amplitude * math.cos(phase)
            log_norm += a_p
        return math.exp(log_norm)

    f_plus = ecv_norm(sigma + h)
    f_mid = ecv_norm(sigma)
    f_minus = ecv_norm(sigma - h)

    return (f_plus - 2*f_mid + f_minus) / (h * h)


def compute_local_interference(offset, log_base, num_zeros=30):
    """
    Compute interference using offset-based phase modulation.
    """
    # At 10^50, we can afford finer-grained analysis
    # Use offset to modulate phase
    primorial = 2 * 3 * 5 * 7 * 11 * 13  # 30030

    interference = 0.0
    for i, gamma in enumerate(ZETA_ZEROS[:num_zeros]):
        # Phase based on offset position
        phase = (offset % primorial) * 2 * math.pi / primorial
        rho_magnitude = math.sqrt(0.25 + gamma * gamma)

        # Base contribution from log position
        base_phase = gamma * log_base
        interference += math.cos(base_phase + gamma * phase * 0.01) / rho_magnitude

    return interference


def find_primes_in_range(start, count):
    """Find primes in range using gmpy2."""
    primes = []
    n = start
    if n % 2 == 0:
        n += 1

    end = start + count
    while n < end:
        if gmpy2.is_prime(n):
            primes.append(n)
        n += 2

    return primes


def measure_gaps(primes):
    """Compute gaps from prime list."""
    if len(primes) < 2:
        return [], 0, 0

    gaps = [primes[i+1] - primes[i] for i in range(len(primes)-1)]
    return gaps, max(gaps), sum(gaps)/len(gaps)


def main():
    print("="*70)
    print("GAP PREDICTOR AT 10^50 SCALE")
    print("="*70)
    print()

    base = 10**50
    window_size = 50000
    num_windows = 30
    num_zeros = 30

    log_base = float(gmpy2.log(base))
    expected_gap = int(log_base)

    print(f"Base: 10^50")
    print(f"log(base): {log_base:.2f}")
    print(f"Expected gap: {expected_gap}")
    print(f"Window size: {window_size:,}")
    print(f"Windows: {num_windows}")
    print(f"Zeta zeros: {num_zeros}")
    print()

    # Check log variation across full range
    log_end = float(gmpy2.log(base + num_windows * window_size))
    print(f"log(base + {num_windows * window_size:,}): {log_end:.6f}")
    print(f"Δlog across range: {log_end - log_base:.2e}")
    print()

    # Compute predictions and measure gaps
    print("Computing predictions and measuring gaps...")
    print("-" * 70)

    results = []
    start_time = time.time()

    for w in range(num_windows):
        offset = w * window_size
        window_start = base + offset
        window_center = window_start + window_size // 2

        log_center = float(gmpy2.log(window_center))

        # Compute various predictors
        oscillation = compute_explicit_oscillation(log_center, num_zeros)
        curvature = compute_ecv_curvature(log_center, sigma=0.5)
        interference = compute_local_interference(offset, log_base, num_zeros)

        # Find primes and measure gaps
        primes = find_primes_in_range(int(window_start), window_size)
        gaps, max_gap, avg_gap = measure_gaps(primes)

        if gaps:
            gap_ratio = max_gap / expected_gap
            results.append({
                'window': w,
                'offset': offset,
                'log_center': log_center,
                'oscillation': oscillation,
                'curvature': curvature,
                'interference': interference,
                'max_gap': max_gap,
                'avg_gap': avg_gap,
                'gap_ratio': gap_ratio,
                'num_primes': len(primes)
            })

            print(f"W{w:2d}: osc={oscillation:+.3f} curv={curvature:.3f} "
                  f"→ max={max_gap:4d} ({gap_ratio:.1f}x) primes={len(primes)}")

    elapsed = time.time() - start_time
    print(f"\nCompleted in {elapsed:.1f}s")

    # Correlation analysis
    print("\n" + "="*70)
    print("CORRELATION ANALYSIS")
    print("="*70)

    if len(results) >= 3:
        oscillations = [r['oscillation'] for r in results]
        curvatures = [r['curvature'] for r in results]
        interferences = [r['interference'] for r in results]
        max_gaps = [r['max_gap'] for r in results]
        avg_gaps = [r['avg_gap'] for r in results]

        def pearson(x, y):
            n = len(x)
            mx, my = sum(x)/n, sum(y)/n
            num = sum((xi-mx)*(yi-my) for xi, yi in zip(x, y))
            den = (sum((xi-mx)**2 for xi in x) * sum((yi-my)**2 for yi in y)) ** 0.5
            return num / den if den > 0 else 0

        corr_osc_max = pearson(oscillations, max_gaps)
        corr_curv_max = pearson(curvatures, max_gaps)
        corr_interf_max = pearson(interferences, max_gaps)
        corr_osc_avg = pearson(oscillations, avg_gaps)

        print(f"\nCorrelation (Oscillation vs Max Gap):   {corr_osc_max:+.3f}")
        print(f"Correlation (Curvature vs Max Gap):     {corr_curv_max:+.3f}")
        print(f"Correlation (Interference vs Max Gap):  {corr_interf_max:+.3f}")
        print(f"Correlation (Oscillation vs Avg Gap):   {corr_osc_avg:+.3f}")

        # Check for significant correlation
        best_corr = max(abs(corr_osc_max), abs(corr_curv_max), abs(corr_interf_max))
        if best_corr > 0.4:
            print(f"\n✓ MODERATE correlation found: |r| = {best_corr:.3f}")
        elif best_corr > 0.3:
            print(f"\n~ WEAK correlation: |r| = {best_corr:.3f}")
        else:
            print(f"\n✗ NO significant correlation: |r| = {best_corr:.3f}")

        # Show sorted results
        print("\n" + "-"*50)
        print("Sorted by OSCILLATION (most negative first - theory predicts large gaps):")
        by_osc = sorted(results, key=lambda x: x['oscillation'])[:5]
        for r in by_osc:
            print(f"  osc={r['oscillation']:+.3f} → max_gap={r['max_gap']:4d} ({r['gap_ratio']:.1f}x)")

        print("\nSorted by MAX GAP (largest first):")
        by_gap = sorted(results, key=lambda x: -x['max_gap'])[:5]
        for r in by_gap:
            print(f"  max_gap={r['max_gap']:4d} ({r['gap_ratio']:.1f}x) ← osc={r['oscillation']:+.3f}")

    # Summary
    print("\n" + "="*70)
    print("SUMMARY")
    print("="*70)

    if results:
        best = max(results, key=lambda x: x['max_gap'])
        print(f"\nLargest gap: {best['max_gap']} ({best['gap_ratio']:.1f}x expected)")
        print(f"  Oscillation: {best['oscillation']:+.3f}")
        print(f"  Curvature: {best['curvature']:.4f}")

        # Check variation in oscillation
        osc_min = min(r['oscillation'] for r in results)
        osc_max = max(r['oscillation'] for r in results)
        print(f"\nOscillation range: [{osc_min:.3f}, {osc_max:.3f}]")
        print(f"Oscillation span: {osc_max - osc_min:.3f}")

        # Check if log actually varies
        log_min = min(r['log_center'] for r in results)
        log_max = max(r['log_center'] for r in results)
        print(f"\nlog(n) range: [{log_min:.6f}, {log_max:.6f}]")
        print(f"log(n) span: {log_max - log_min:.2e}")


if __name__ == "__main__":
    main()
