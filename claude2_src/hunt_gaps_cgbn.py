#!/usr/bin/env python3
"""
CGBN GPU Gap Hunter - Batch prime testing at 10^100 scale
Uses CGBN for batch primality testing to find large gaps
"""

import os
import sys
import time
import struct
import subprocess
import tempfile
import random
import gmpy2
from gmpy2 import mpz

# Paths
CGBN_BINARY = "/tmp/cgbn_primality"

# World record
WORLD_RECORD_GAP = 1676
TARGET_GAP = 2000  # Report gaps > 2000

# Minimum batch size for CGBN efficiency
MIN_BATCH = 64
OPTIMAL_BATCH = 50000  # Good GPU utilization


def int_to_limbs(n):
    """Convert Python int to 16 uint32 limbs (little-endian)"""
    limbs = []
    for _ in range(16):
        limbs.append(n & 0xFFFFFFFF)
        n >>= 32
    return limbs


def cgbn_batch_test(candidates):
    """Test candidates for primality using CGBN GPU"""
    if len(candidates) < MIN_BATCH:
        return [bool(gmpy2.is_prime(c)) for c in candidates]

    # Write candidates to temp file
    with tempfile.NamedTemporaryFile(delete=False, suffix='.bin') as f:
        input_file = f.name
        for n in candidates:
            limbs = int_to_limbs(n)
            f.write(struct.pack('<16I', *limbs))

    output_file = input_file + '.out'

    try:
        result = subprocess.run([CGBN_BINARY, input_file, output_file],
                               capture_output=True, timeout=120)
        if result.returncode != 0:
            print(f"CGBN error: {result.stderr.decode()}")
            return [bool(gmpy2.is_prime(c)) for c in candidates]

        with open(output_file, 'rb') as f:
            results = list(f.read())

        return [bool(r) for r in results]

    finally:
        try:
            os.unlink(input_file)
            os.unlink(output_file)
        except:
            pass


def find_primes_in_range(start, count):
    """Find all primes in range [start, start + 2*count) using CGBN"""
    # Generate odd candidates
    candidates = []
    n = start if start % 2 == 1 else start + 1
    for _ in range(count):
        candidates.append(n)
        n += 2

    # Batch test
    results = cgbn_batch_test(candidates)

    # Return primes
    return [c for c, is_prime in zip(candidates, results) if is_prime]


def hunt_gaps_batch(start_offset=0, num_batches=10, batch_size=OPTIMAL_BATCH):
    """Hunt for gaps using batch CGBN testing"""
    print(f"\n{'='*60}")
    print(f"CGBN Batch Gap Hunter")
    print(f"{'='*60}")
    print(f"Base: 10^100")
    print(f"Batches: {num_batches} x {batch_size} candidates")
    print(f"Range: ~{num_batches * batch_size * 2} integers per region")
    print(f"World record: {WORLD_RECORD_GAP}")
    print()

    all_gaps = []
    total_primes = 0
    total_time = 0

    for batch_num in range(num_batches):
        # Random starting point
        offset = start_offset + random.randint(0, 10**50)
        base = 10**100 + offset

        print(f"Batch {batch_num + 1}/{num_batches}: offset {offset:.2e}")

        start_time = time.perf_counter()
        primes = find_primes_in_range(base, batch_size)
        batch_time = time.perf_counter() - start_time

        total_time += batch_time
        total_primes += len(primes)

        # Find gaps
        primes.sort()
        batch_gaps = []
        for i in range(len(primes) - 1):
            gap = primes[i + 1] - primes[i]
            if gap > TARGET_GAP:
                batch_gaps.append((gap, primes[i], primes[i + 1]))
                all_gaps.append((gap, primes[i], primes[i + 1]))

        throughput = batch_size / batch_time
        print(f"  Found {len(primes)} primes in {batch_time:.1f}s ({throughput:.0f}/sec)")
        if batch_gaps:
            for gap, p1, p2 in batch_gaps:
                ratio = 100 * gap / WORLD_RECORD_GAP
                print(f"  GAP {gap} ({ratio:.1f}% of record)")

    # Summary
    print(f"\n{'='*60}")
    print(f"Summary")
    print(f"{'='*60}")
    print(f"Total time: {total_time:.1f}s")
    print(f"Total primes found: {total_primes}")
    print(f"Throughput: {num_batches * batch_size / total_time:.0f} tests/sec")
    print(f"Gaps > {TARGET_GAP}: {len(all_gaps)}")

    if all_gaps:
        all_gaps.sort(reverse=True)
        print(f"\nLargest gaps:")
        for gap, p1, p2 in all_gaps[:10]:
            ratio = 100 * gap / WORLD_RECORD_GAP
            p1_str = str(p1)
            print(f"  {gap} ({ratio:.1f}%) - {p1_str[:30]}...{p1_str[-10:]}")

    return all_gaps


def hunt_sequential(start_offset=0, search_range=100000):
    """Hunt by testing sequential odd numbers"""
    print(f"\n{'='*60}")
    print(f"CGBN Sequential Gap Hunter")
    print(f"{'='*60}")
    print(f"Testing {search_range} consecutive odd numbers")
    print()

    base = 10**100 + start_offset
    if base % 2 == 0:
        base += 1

    # Generate all odd candidates
    candidates = [base + 2*i for i in range(search_range)]

    print(f"Testing {len(candidates)} candidates...")
    start_time = time.perf_counter()
    results = cgbn_batch_test(candidates)
    test_time = time.perf_counter() - start_time

    primes = [c for c, r in zip(candidates, results) if r]
    print(f"Found {len(primes)} primes in {test_time:.1f}s ({len(candidates)/test_time:.0f}/sec)")

    # Find gaps
    gaps = []
    primes.sort()
    for i in range(len(primes) - 1):
        gap = primes[i + 1] - primes[i]
        if gap > WORLD_RECORD_GAP:
            gaps.append((gap, primes[i], primes[i + 1]))
            ratio = 100 * gap / WORLD_RECORD_GAP
            print(f"  GAP {gap} ({ratio:.1f}% of record)")

    return gaps


def verify_gap(p1, p2):
    """Verify a gap using gmpy2"""
    if not gmpy2.is_prime(p1):
        return False, "p1 not prime"
    if not gmpy2.is_prime(p2):
        return False, "p2 not prime"

    # Check no primes between
    n = p1 + 2
    while n < p2:
        if gmpy2.is_prime(n):
            return False, f"Found prime {n} in gap"
        n += 2

    return True, "Verified"


def main():
    if not os.path.exists(CGBN_BINARY):
        print(f"CGBN binary not found at {CGBN_BINARY}")
        print("Compile with:")
        print("  cd /tmp && nvcc -I/tmp/gmpy2_extracted/gmpy2 -I/tmp cgbn_primality.cu -o cgbn_primality -arch=sm_86")
        sys.exit(1)

    # Parse args
    mode = sys.argv[1] if len(sys.argv) > 1 else "batch"

    if mode == "seq":
        # Sequential search
        offset = int(sys.argv[2]) if len(sys.argv) > 2 else 0
        count = int(sys.argv[3]) if len(sys.argv) > 3 else 100000
        gaps = hunt_sequential(offset, count)
    else:
        # Batch search (random regions)
        offset = int(sys.argv[2]) if len(sys.argv) > 2 else 0
        batches = int(sys.argv[3]) if len(sys.argv) > 3 else 5
        gaps = hunt_gaps_batch(offset, batches)

    # Verify largest gaps
    if gaps:
        print(f"\nVerifying top gaps with gmpy2...")
        for gap, p1, p2 in gaps[:3]:
            ok, msg = verify_gap(p1, p2)
            status = "VERIFIED" if ok else f"FAILED: {msg}"
            print(f"  Gap {gap}: {status}")


if __name__ == "__main__":
    random.seed(42)
    main()
