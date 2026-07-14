#!/usr/bin/env python3
"""
Multi-Scale Gap Predictor

Test zeta-based gap prediction at scales where log(n) actually varies.

The key insight: log(n) changes by Δn/n, so we need:
- Windows small enough relative to base
- Or base small enough that relative change matters
"""

import math
import gmpy2
import time

# First 50 zeta zeros
ZETA_ZEROS = [
    14.134725, 21.022040, 25.010858, 30.424876, 32.935062,
    37.586178, 40.918720, 43.327073, 48.005151, 49.773832,
    52.970321, 56.446248, 59.347044, 60.831779, 65.112544,
    67.079811, 69.546402, 72.067158, 75.704691, 77.144840,
    79.337375, 82.910381, 84.735493, 87.425275, 88.809111,
    92.491899, 94.651344, 95.870634, 98.831194, 101.317851
]

SMALL_PRIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]


def compute_explicit_oscillation(log_x, num_zeros=20):
    """Explicit formula oscillation term."""
    oscillation = 0.0
    for gamma in ZETA_ZEROS[:num_zeros]:
        rho_magnitude = math.sqrt(0.25 + gamma * gamma)
        oscillation -= 2 * math.cos(gamma * log_x) / rho_magnitude
    return oscillation


def compute_ecv_curvature(t, sigma=0.5, num_primes=10, k_max=5, h=0.001):
    """ECV second derivative at position t."""
    def ecv_norm(sig):
        log_norm = 0.0
        for p in SMALL_PRIMES[:num_primes]:
            a_p = 0.0
            log_p = math.log(p)
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


def find_primes_in_range(start, count):
    """Find primes using gmpy2."""
    primes = []
    n = int(start)
    if n < 2:
        n = 2
    if n % 2 == 0 and n > 2:
        n += 1

    end = start + count
    while n < end:
        if gmpy2.is_prime(n):
            primes.append(n)
        n += 1 if n == 2 else 2
    return primes


def analyze_scale(base, window_size, num_windows, scale_name):
    """Analyze gap prediction at a given scale."""
    print(f"\n{'='*70}")
    print(f"SCALE: {scale_name}")
    print(f"{'='*70}")

    log_base = math.log(base)
    expected_gap = log_base

    # Check log variation
    log_end = math.log(base + num_windows * window_size)
    delta_log = log_end - log_base

    print(f"Base: {base:.2e}")
    print(f"log(base): {log_base:.4f}")
    print(f"Expected gap: {expected_gap:.1f}")
    print(f"Window size: {window_size:,}")
    print(f"Δlog across range: {delta_log:.4f}")
    print()

    if delta_log < 0.01:
        print("WARNING: Δlog too small for meaningful variation!")
        print()

    results = []
    start_time = time.time()

    for w in range(num_windows):
        offset = w * window_size
        window_start = base + offset
        window_center = window_start + window_size // 2

        log_center = math.log(window_center)

        # Predictors
        oscillation = compute_explicit_oscillation(log_center)
        curvature = compute_ecv_curvature(log_center)

        # Find primes
        primes = find_primes_in_range(window_start, window_size)

        if len(primes) >= 2:
            gaps = [primes[i+1] - primes[i] for i in range(len(primes)-1)]
            max_gap = max(gaps)
            avg_gap = sum(gaps) / len(gaps)
            gap_ratio = max_gap / expected_gap

            results.append({
                'window': w,
                'log_center': log_center,
                'oscillation': oscillation,
                'curvature': curvature,
                'max_gap': max_gap,
                'avg_gap': avg_gap,
                'gap_ratio': gap_ratio,
                'num_primes': len(primes)
            })

    elapsed = time.time() - start_time

    if not results:
        print("No results!")
        return None

    # Print sample
    print(f"Sample results ({elapsed:.2f}s):")
    for r in results[:5]:
        print(f"  W{r['window']:2d}: log={r['log_center']:.4f} osc={r['oscillation']:+.3f} "
              f"→ max={r['max_gap']:4d} ({r['gap_ratio']:.1f}x)")
    if len(results) > 5:
        print(f"  ... ({len(results) - 5} more)")

    # Correlations
    def pearson(x, y):
        n = len(x)
        mx, my = sum(x)/n, sum(y)/n
        num = sum((xi-mx)*(yi-my) for xi, yi in zip(x, y))
        den = (sum((xi-mx)**2 for xi in x) * sum((yi-my)**2 for yi in y)) ** 0.5
        return num / den if den > 0 else 0

    oscillations = [r['oscillation'] for r in results]
    curvatures = [r['curvature'] for r in results]
    max_gaps = [r['max_gap'] for r in results]

    corr_osc = pearson(oscillations, max_gaps)
    corr_curv = pearson(curvatures, max_gaps)

    osc_span = max(oscillations) - min(oscillations)
    curv_span = max(curvatures) - min(curvatures)

    print(f"\nOscillation span: {osc_span:.4f}")
    print(f"Curvature span: {curv_span:.4f}")
    print(f"Correlation (Oscillation vs Max Gap): {corr_osc:+.3f}")
    print(f"Correlation (Curvature vs Max Gap):   {corr_curv:+.3f}")

    best_corr = max(abs(corr_osc), abs(corr_curv))
    if best_corr > 0.4:
        status = "✓ MODERATE"
    elif best_corr > 0.3:
        status = "~ WEAK"
    else:
        status = "✗ NONE"
    print(f"Status: {status} (|r| = {best_corr:.3f})")

    # Best/worst comparison
    by_osc = sorted(results, key=lambda x: x['oscillation'])
    print(f"\nLowest oscillation windows (theory: large gaps):")
    for r in by_osc[:3]:
        print(f"  osc={r['oscillation']:+.4f} → max_gap={r['max_gap']} ({r['gap_ratio']:.1f}x)")

    print(f"Highest oscillation windows (theory: small gaps):")
    for r in by_osc[-3:]:
        print(f"  osc={r['oscillation']:+.4f} → max_gap={r['max_gap']} ({r['gap_ratio']:.1f}x)")

    return {
        'scale': scale_name,
        'base': base,
        'delta_log': delta_log,
        'osc_span': osc_span,
        'corr_osc': corr_osc,
        'corr_curv': corr_curv,
        'best_corr': best_corr,
        'max_gap_found': max(r['max_gap'] for r in results),
        'max_ratio': max(r['gap_ratio'] for r in results)
    }


def main():
    print("="*70)
    print("MULTI-SCALE GAP PREDICTION TEST")
    print("="*70)
    print()
    print("Testing at scales where log(n) actually varies meaningfully.")
    print()

    # Test at different scales
    scales = [
        # (base, window_size, num_windows, name)
        (10**6, 10000, 50, "10^6 (million)"),
        (10**8, 10000, 50, "10^8 (100 million)"),
        (10**10, 10000, 50, "10^10 (10 billion)"),
        (10**12, 20000, 40, "10^12 (trillion)"),
        (10**15, 50000, 30, "10^15 (quadrillion)"),
    ]

    all_results = []

    for base, window_size, num_windows, name in scales:
        result = analyze_scale(base, window_size, num_windows, name)
        if result:
            all_results.append(result)

    # Summary
    print("\n" + "="*70)
    print("SUMMARY ACROSS SCALES")
    print("="*70)
    print()
    print(f"{'Scale':<20} {'Δlog':<10} {'Osc Span':<12} {'Corr(osc)':<12} {'Best |r|':<10}")
    print("-" * 70)
    for r in all_results:
        print(f"{r['scale']:<20} {r['delta_log']:<10.4f} {r['osc_span']:<12.4f} "
              f"{r['corr_osc']:+.3f}      {r['best_corr']:<10.3f}")

    print()
    print("CONCLUSION:")
    print("-" * 70)

    # Check if correlation improves with scale
    if len(all_results) >= 2:
        first_corr = all_results[0]['best_corr']
        last_corr = all_results[-1]['best_corr']
        avg_corr = sum(r['best_corr'] for r in all_results) / len(all_results)

        if avg_corr > 0.3:
            print("Zeta-based predictors show MODERATE correlation with gaps")
        elif avg_corr > 0.2:
            print("Zeta-based predictors show WEAK correlation with gaps")
        else:
            print("Zeta-based predictors show NO significant correlation with gaps")

        # Check oscillation span trend
        if all_results[0]['osc_span'] > 0.1 and all_results[-1]['osc_span'] < 0.01:
            print("Oscillation variation DECREASES at larger scales (as expected)")


if __name__ == "__main__":
    main()
