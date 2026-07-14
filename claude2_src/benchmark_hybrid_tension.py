#!/usr/bin/env python3
"""
Benchmark Hybrid Surface Tension vs Standard Miller-Rabin

Tests the theory that zeta zero interference can predict composites
without running expensive Miller-Rabin tests.
"""

import os
import sys
import time
import struct
import subprocess
import tempfile
import gmpy2
from pathlib import Path

# Binaries
HYBRID_BINARY = "/tmp/cgbn_hybrid_primality"
STANDARD_BINARY = "/tmp/cgbn_1024_primality"

def int_to_limbs_1024(n):
    """Convert Python int to 32 uint32 limbs (little-endian, 1024-bit)"""
    limbs = []
    for _ in range(32):
        limbs.append(n & 0xFFFFFFFF)
        n >>= 32
    return limbs

def generate_candidates(base, count):
    """Generate wheel-coprime candidates starting at base"""
    WHEEL_OFFSETS = [1, 7, 11, 13, 17, 19, 23, 29]
    candidates = []
    current = (base // 30) * 30
    wheel_idx = 0

    # Align to first position >= base
    while current + WHEEL_OFFSETS[wheel_idx] < base:
        wheel_idx += 1
        if wheel_idx >= 8:
            wheel_idx = 0
            current += 30

    while len(candidates) < count:
        candidates.append(current + WHEEL_OFFSETS[wheel_idx])
        wheel_idx += 1
        if wheel_idx >= 8:
            wheel_idx = 0
            current += 30

    return candidates

def run_hybrid_test(candidates, threshold=0.5, num_zeros=10, benchmark=1):
    """Run hybrid primality test"""
    with tempfile.NamedTemporaryFile(delete=False, suffix='.bin') as f:
        input_file = f.name
        for n in candidates:
            limbs = int_to_limbs_1024(n)
            f.write(struct.pack('<32I', *limbs))

    output_file = input_file + '.out'

    try:
        result = subprocess.run(
            [HYBRID_BINARY, input_file, output_file,
             str(threshold), str(num_zeros), str(benchmark)],
            capture_output=True,
            timeout=300
        )

        stderr = result.stderr.decode()
        print(stderr)

        with open(output_file, 'rb') as f:
            results = list(f.read())

        return results, stderr

    finally:
        try:
            os.unlink(input_file)
            os.unlink(output_file)
        except:
            pass

def verify_with_gmpy2(candidates, gpu_results):
    """Verify GPU results against gmpy2"""
    mismatches = []
    for i, (cand, gpu_prime) in enumerate(zip(candidates, gpu_results)):
        gmpy_prime = gmpy2.is_prime(cand)
        if bool(gpu_prime) != bool(gmpy_prime):
            mismatches.append((i, cand, gpu_prime, gmpy_prime))
    return mismatches

def tune_threshold(candidates, thresholds):
    """Find optimal threshold by testing different values"""
    print("\n" + "="*70)
    print("THRESHOLD TUNING")
    print("="*70)

    results = []

    for threshold in thresholds:
        print(f"\nTesting threshold={threshold:.2f}...")
        gpu_results, stderr = run_hybrid_test(candidates, threshold=threshold, benchmark=1)

        # Parse stderr for metrics
        lines = stderr.split('\n')
        speedup = 0
        missed = 0
        skipped = 0

        for line in lines:
            if 'Speedup:' in line:
                speedup = float(line.split(':')[1].strip().replace('x', ''))
            if 'Missed' in line:
                missed = int(line.split()[-2])
            if 'Skipped:' in line:
                parts = line.split()
                skipped = int(parts[1])

        results.append({
            'threshold': threshold,
            'speedup': speedup,
            'missed': missed,
            'skipped': skipped
        })

        print(f"  Threshold={threshold:.2f}: speedup={speedup:.2f}x, missed={missed}, skipped={skipped}")

    return results

def main():
    # Check binaries exist
    if not os.path.exists(HYBRID_BINARY):
        print(f"Hybrid binary not found: {HYBRID_BINARY}")
        print("Compile with:")
        print("  nvcc cgbn_hybrid_primality.cu -o cgbn_hybrid_primality -arch=sm_86 -I/tmp/CGBN/include -I<gmp_include_path>")
        sys.exit(1)

    # Test parameters
    base = 10**308
    count = 100000  # Number of candidates

    print("="*70)
    print("HYBRID SURFACE TENSION BENCHMARK")
    print("="*70)
    print(f"Base: 10^308")
    print(f"Candidates: {count:,}")
    print()

    # Generate candidates
    print("Generating candidates...")
    candidates = generate_candidates(base, count)
    print(f"Generated {len(candidates)} wheel-coprime candidates")

    # Run with benchmark mode to compare hybrid vs standard
    print("\n" + "="*70)
    print("INITIAL TEST (threshold=0.5, 10 zeros)")
    print("="*70)

    gpu_results, stderr = run_hybrid_test(candidates, threshold=0.5, num_zeros=10, benchmark=1)

    # Verify a sample with gmpy2
    print("\nVerifying sample with gmpy2...")
    sample_size = min(1000, len(candidates))
    sample_candidates = candidates[:sample_size]
    sample_results = gpu_results[:sample_size]

    mismatches = verify_with_gmpy2(sample_candidates, sample_results)

    if mismatches:
        print(f"  MISMATCHES FOUND: {len(mismatches)}")
        for i, cand, gpu, gmpy in mismatches[:5]:
            print(f"    idx={i}: GPU={gpu}, gmpy2={gmpy}")
    else:
        print(f"  All {sample_size} verified correct!")

    # Tune threshold - actual tension ranges ~[-4, +1] for this data
    # High tension = likely composite, so skip if tension > threshold
    thresholds = [-3.0, -2.5, -2.0, -1.5, -1.0, -0.5, 0.0, 0.5]
    tuning_results = tune_threshold(candidates, thresholds)

    # Print summary
    print("\n" + "="*70)
    print("TUNING SUMMARY")
    print("="*70)
    print(f"{'Threshold':<12} {'Speedup':<10} {'Missed':<10} {'Skipped':<12}")
    print("-"*50)
    for r in tuning_results:
        print(f"{r['threshold']:<12.2f} {r['speedup']:<10.2f}x {r['missed']:<10} {r['skipped']:<12}")

    # Find best threshold (maximize speedup while missing 0 primes)
    valid = [r for r in tuning_results if r['missed'] == 0]
    if valid:
        best = max(valid, key=lambda x: x['speedup'])
        print(f"\nBEST THRESHOLD: {best['threshold']:.2f} (speedup={best['speedup']:.2f}x, 0 primes missed)")
    else:
        print("\nWARNING: All thresholds missed primes! Tension filter may not be viable.")

if __name__ == "__main__":
    main()
