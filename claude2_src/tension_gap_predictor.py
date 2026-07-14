#!/usr/bin/env python3
"""
Surface Tension Gap Predictor

Theory: High surface tension (constructive interference from zeta zeros)
indicates "unstable" regions where primes are sparse = larger gaps.

Instead of filtering individual candidates, we:
1. Compute tension over windows of integers
2. High tension windows = predict large gaps
3. Verify with actual prime search
4. Measure correlation between predicted and actual gaps
"""

import os
import sys
import time
import math
import struct
import subprocess
import tempfile
import numpy as np
import gmpy2
from pathlib import Path

# First 29 zeta zeros (imaginary parts)
ZETA_ZEROS = [
    14.134725, 21.022040, 25.010858, 30.424876, 32.935062,
    37.586178, 40.918720, 43.327073, 48.005151, 49.773832,
    52.970321, 56.446248, 59.347044, 60.831779, 65.112544,
    67.079811, 69.546402, 72.067158, 75.704691, 77.144840,
    79.337375, 82.910381, 84.735493, 87.425275, 88.809111,
    92.491899, 94.651344, 95.870634, 98.831194
]

CGBN_BINARY = "/tmp/cgbn_1024_primality"

def compute_tension_for_region(n, window_center, num_zeros=10):
    """
    Compute surface tension using LOCAL structure of the number.

    At 10^308, log(n) barely changes, so we use:
    1. Residues mod small primes (captures divisibility structure)
    2. The actual offset from base (captures position in range)

    The phase is derived from the number's "fingerprint" rather than log(n).
    """
    # Use multiple phases from the number's structure
    # Phase 1: Position-based (the offset matters)
    phase1 = float(window_center % 1000000007) * 1.618033988749 % (2 * math.pi)

    # Phase 2: Residue pattern mod small primes (captures divisibility)
    residue_phase = 0.0
    small_primes = [7, 11, 13, 17, 19, 23, 29, 31, 37, 41]
    for p in small_primes:
        r = int(window_center % p)
        residue_phase += r / p

    phase2 = (residue_phase * 1.618033988749) % (2 * math.pi)

    # Phase 3: Digit sum pattern (another structural feature)
    digit_sum = sum(int(d) for d in str(window_center) if d.isdigit())
    phase3 = (digit_sum * 0.618033988749) % (2 * math.pi)

    # Compute interference from zeta zeros
    tension = 0.0
    for i in range(min(num_zeros, len(ZETA_ZEROS))):
        gamma = ZETA_ZEROS[i]
        # Mix all three phases
        tension += math.cos(gamma * phase1)
        tension += 0.5 * math.cos(gamma * phase2)
        tension += 0.3 * math.cos(gamma * phase3)

    return tension

def compute_tension_profile(base, window_size, num_windows, num_zeros=10):
    """
    Compute tension profile across multiple windows.
    Returns array of (window_start, tension) pairs.
    """
    profile = []
    for w in range(num_windows):
        # Center of this window
        offset = w * window_size
        window_center = base + offset + window_size // 2

        # Compute average tension across window (sample multiple points)
        samples = 10
        total_tension = 0
        for s in range(samples):
            sample_point = base + offset + s * window_size // samples
            total_tension += compute_tension_for_region(base, sample_point, num_zeros)

        avg_tension = total_tension / samples
        profile.append((base + offset, avg_tension))

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
    # Generate wheel-coprime candidates
    WHEEL_OFFSETS = [1, 7, 11, 13, 17, 19, 23, 29]
    candidates = []
    current = (start // 30) * 30
    wheel_idx = 0

    # Align to first position >= start
    while current + WHEEL_OFFSETS[wheel_idx] < start:
        wheel_idx += 1
        if wheel_idx >= 8:
            wheel_idx = 0
            current += 30

    # Generate candidates
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
        # Too few for GPU, use gmpy2
        return [c for c in candidates if gmpy2.is_prime(c)]

    # Run GPU test
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
    print("SURFACE TENSION GAP PREDICTOR")
    print("="*70)
    print()
    print("Theory: High tension regions have sparse primes = larger gaps")
    print()

    # Check binary exists
    if not os.path.exists(CGBN_BINARY):
        print(f"Error: {CGBN_BINARY} not found")
        sys.exit(1)

    # Parameters
    base = 10**308
    window_size = 50000  # Size of each window to analyze
    num_windows = 20     # Number of windows to test
    num_zeros = 15       # Zeta zeros to use

    log_base = float(gmpy2.log(base))
    expected_gap = int(log_base)  # ~709

    print(f"Base: 10^308")
    print(f"log(base): {log_base:.1f}")
    print(f"Expected gap: {expected_gap}")
    print(f"Window size: {window_size:,}")
    print(f"Windows to test: {num_windows}")
    print(f"Zeta zeros used: {num_zeros}")
    print()

    # Compute tension profile
    print("Computing tension profile...")
    profile = compute_tension_profile(base, window_size, num_windows, num_zeros)

    # Sort by tension (highest first)
    profile_sorted = sorted(profile, key=lambda x: -x[1])

    print("\nTension Profile (sorted by tension):")
    print("-" * 50)
    for i, (start, tension) in enumerate(profile_sorted[:10]):
        offset = start - base
        print(f"  Window {offset//window_size}: offset={offset:,}, tension={tension:.3f}")

    # Now measure actual gaps in each window
    print("\n" + "="*70)
    print("MEASURING ACTUAL GAPS")
    print("="*70)

    results = []
    for i, (start, tension) in enumerate(profile):
        print(f"\nWindow {i}: offset={(start-base):,}, tension={tension:.3f}")

        gaps, max_gap = measure_gaps_in_window(start, window_size)

        if gaps:
            avg_gap = sum(gaps) / len(gaps)
            gap_ratio = max_gap / expected_gap
            results.append({
                'window': i,
                'offset': start - base,
                'tension': tension,
                'max_gap': max_gap,
                'avg_gap': avg_gap,
                'gap_ratio': gap_ratio,
                'num_primes': len(gaps) + 1
            })
            print(f"  Primes: {len(gaps)+1}, Max gap: {max_gap} ({gap_ratio:.1f}x), Avg: {avg_gap:.0f}")
        else:
            print(f"  Insufficient primes in window")

    # Compute correlation
    print("\n" + "="*70)
    print("CORRELATION ANALYSIS")
    print("="*70)

    if len(results) >= 3:
        tensions = [r['tension'] for r in results]
        max_gaps = [r['max_gap'] for r in results]
        avg_gaps = [r['avg_gap'] for r in results]

        # Pearson correlation
        def pearson(x, y):
            n = len(x)
            mx, my = sum(x)/n, sum(y)/n
            num = sum((xi-mx)*(yi-my) for xi, yi in zip(x, y))
            den = (sum((xi-mx)**2 for xi in x) * sum((yi-my)**2 for yi in y)) ** 0.5
            return num / den if den > 0 else 0

        corr_max = pearson(tensions, max_gaps)
        corr_avg = pearson(tensions, avg_gaps)

        print(f"\nCorrelation (Tension vs Max Gap): {corr_max:.3f}")
        print(f"Correlation (Tension vs Avg Gap): {corr_avg:.3f}")

        if corr_max > 0.3:
            print("\n✓ POSITIVE correlation: High tension predicts larger gaps!")
        elif corr_max < -0.3:
            print("\n✗ NEGATIVE correlation: High tension predicts smaller gaps (unexpected)")
        else:
            print("\n~ WEAK correlation: Tension doesn't strongly predict gap size")

        # Show sorted by tension vs sorted by max gap
        print("\n" + "-"*50)
        print("Sorted by TENSION (highest first):")
        by_tension = sorted(results, key=lambda x: -x['tension'])[:5]
        for r in by_tension:
            print(f"  tension={r['tension']:+.2f} → max_gap={r['max_gap']:,} ({r['gap_ratio']:.1f}x)")

        print("\nSorted by MAX GAP (largest first):")
        by_gap = sorted(results, key=lambda x: -x['max_gap'])[:5]
        for r in by_gap:
            print(f"  max_gap={r['max_gap']:,} ({r['gap_ratio']:.1f}x) ← tension={r['tension']:+.2f}")

    # Summary
    print("\n" + "="*70)
    print("SUMMARY")
    print("="*70)

    if results:
        best = max(results, key=lambda x: x['max_gap'])
        print(f"\nLargest gap found: {best['max_gap']:,} ({best['gap_ratio']:.1f}x expected)")
        print(f"  in window with tension: {best['tension']:.3f}")

if __name__ == "__main__":
    main()
