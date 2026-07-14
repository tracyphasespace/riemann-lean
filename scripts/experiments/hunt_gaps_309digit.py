#!/usr/bin/env python3
"""
309-digit Gap Hunter using 1024-bit CGBN
Searches for prime gaps at 10^309 scale
Saves timestamped results with actual prime numbers
"""

import os
import sys
import time
import struct
import subprocess
import tempfile
import gmpy2
from datetime import datetime
from pathlib import Path

# Paths
CGBN_BINARY = "/tmp/cgbn_1024_primality"
RESULTS_DIR = Path(__file__).parent.parent.parent / "wolfram_proof" / "docs" / "gap_results"

# At 10^309, expected gap ≈ ln(10^309) ≈ 712
EXPECTED_GAP = 712
TARGET_GAP = 5000  # Hunt for gaps ~7x expected

# 1024 bits = 32 limbs
LIMBS_PER_NUMBER = 32
BYTES_PER_NUMBER = 128


def save_results(gaps, all_primes, total_time, total_candidates):
    """Save results to timestamped file with full prime numbers"""
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = RESULTS_DIR / f"gaps_309digit_{timestamp}.md"

    with open(filename, 'w') as f:
        f.write(f"# 309-Digit Prime Gap Results\n\n")
        f.write(f"**Timestamp:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"**Scale:** 10^309\n")
        f.write(f"**Expected gap:** ln(10^309) = {EXPECTED_GAP}\n")
        f.write(f"**Candidates tested:** {total_candidates:,}\n")
        f.write(f"**Primes found:** {len(all_primes):,}\n")
        f.write(f"**Total runtime:** {total_time:.1f}s\n")
        f.write(f"**Throughput:** {total_candidates/total_time:.0f} tests/sec\n")
        f.write(f"**Gaps > 2x expected:** {len(gaps)}\n\n")
        f.write(f"---\n\n")

        # Top gaps with full primes
        f.write(f"## Top {min(50, len(gaps))} Gaps with Full Primes\n\n")
        gaps.sort(reverse=True)
        for i, (gap, p1, p2, ratio) in enumerate(gaps[:50]):
            f.write(f"### Gap {gap} ({ratio:.1f}x expected) - Rank {i+1}\n\n")
            f.write(f"```\n")
            f.write(f"p1 = {p1}\n\n")
            f.write(f"p2 = {p2}\n")
            f.write(f"```\n\n")

        # Summary table
        f.write(f"---\n\n## Summary Table\n\n")
        f.write(f"| Rank | Gap | Multiple | p1 ends with | p2 ends with |\n")
        f.write(f"|------|-----|----------|--------------|---------------|\n")
        for i, (gap, p1, p2, ratio) in enumerate(gaps[:100]):
            p1_end = str(p1)[-10:]
            p2_end = str(p2)[-10:]
            f.write(f"| {i+1} | {gap} | {ratio:.1f}x | ...{p1_end} | ...{p2_end} |\n")

    print(f"\nResults saved to: {filename}")
    return filename


def int_to_limbs_1024(n):
    """Convert Python int to 32 uint32 limbs (little-endian, 1024-bit)"""
    limbs = []
    for _ in range(32):
        limbs.append(n & 0xFFFFFFFF)
        n >>= 32
    return limbs


def cgbn_batch_test(candidates):
    """Test candidates for primality using 1024-bit CGBN GPU"""
    if len(candidates) < 32:
        return [bool(gmpy2.is_prime(c)) for c in candidates]

    with tempfile.NamedTemporaryFile(delete=False, suffix='.bin') as f:
        input_file = f.name
        for n in candidates:
            limbs = int_to_limbs_1024(n)
            f.write(struct.pack('<32I', *limbs))

    output_file = input_file + '.out'

    try:
        result = subprocess.run([CGBN_BINARY, input_file, output_file],
                               capture_output=True, timeout=300)
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


def hunt_sequential(start_offset=0, count=100000):
    """Hunt for gaps by testing consecutive odd numbers at 10^309"""
    print(f"\n{'='*60}")
    print(f"309-Digit Gap Hunter (1024-bit CGBN)")
    print(f"{'='*60}")
    print(f"Scale: 10^309")
    print(f"Testing: {count} consecutive odd numbers")
    print(f"Expected gap: ~{EXPECTED_GAP}")
    print(f"Target: gaps > {TARGET_GAP} ({TARGET_GAP/EXPECTED_GAP:.1f}x expected)")
    print()

    base = 10**309 + start_offset
    if base % 2 == 0:
        base += 1

    # Generate odd candidates
    print(f"Generating {count} candidates...")
    candidates = [base + 2*i for i in range(count)]

    print(f"Testing with CGBN GPU...")
    start_time = time.perf_counter()
    results = cgbn_batch_test(candidates)
    test_time = time.perf_counter() - start_time

    primes = [c for c, r in zip(candidates, results) if r]
    print(f"Found {len(primes)} primes in {test_time:.1f}s ({count/test_time:.0f} tests/sec)")
    print(f"Prime rate: {100*len(primes)/count:.3f}%")

    # Find gaps
    gaps = []
    primes.sort()
    for i in range(len(primes) - 1):
        gap = primes[i + 1] - primes[i]
        if gap > EXPECTED_GAP * 2:  # Report gaps > 2x expected
            ratio = gap / EXPECTED_GAP
            gaps.append((gap, primes[i], primes[i + 1], ratio))
            if gap > TARGET_GAP:
                print(f"  *** GAP {gap} ({ratio:.1f}x expected) ***")
            elif gap > EXPECTED_GAP * 3:
                print(f"  GAP {gap} ({ratio:.1f}x expected)")

    # Summary
    if gaps:
        gaps.sort(reverse=True)
        print(f"\nTop gaps found:")
        for gap, p1, p2, ratio in gaps[:10]:
            marker = "***" if gap > TARGET_GAP else ""
            print(f"  {gap} ({ratio:.1f}x expected) {marker}")

    # Save results to timestamped file
    save_results(gaps, primes, test_time, count)

    return gaps, primes


def hunt_extended(total_candidates=1000000, batch_size=100000):
    """Extended hunt across multiple batches"""
    print(f"\n{'='*60}")
    print(f"Extended 309-Digit Gap Hunt")
    print(f"{'='*60}")
    print(f"Total candidates: {total_candidates:,}")
    print(f"Batch size: {batch_size:,}")
    print()

    all_gaps = []
    all_primes = []
    total_time = 0

    num_batches = (total_candidates + batch_size - 1) // batch_size

    for batch in range(num_batches):
        offset = batch * batch_size * 2  # *2 because we step by 2 (odd numbers)
        print(f"\nBatch {batch+1}/{num_batches} (offset {offset:,})...")

        base = 10**309 + offset
        if base % 2 == 0:
            base += 1

        candidates = [base + 2*i for i in range(batch_size)]

        start_time = time.perf_counter()
        results = cgbn_batch_test(candidates)
        batch_time = time.perf_counter() - start_time
        total_time += batch_time

        primes = [c for c, r in zip(candidates, results) if r]
        all_primes.extend(primes)

        print(f"  Found {len(primes)} primes in {batch_time:.1f}s ({batch_size/batch_time:.0f}/sec)")

        # Find gaps within batch
        primes.sort()
        for i in range(len(primes) - 1):
            gap = primes[i + 1] - primes[i]
            if gap > EXPECTED_GAP * 2:
                ratio = gap / EXPECTED_GAP
                all_gaps.append((gap, primes[i], primes[i + 1], ratio))
                if gap > TARGET_GAP:
                    print(f"  *** GAP {gap} ({ratio:.1f}x) ***")

    # Also check gaps between batches
    all_primes.sort()
    print(f"\nChecking inter-batch gaps...")
    for i in range(len(all_primes) - 1):
        gap = all_primes[i + 1] - all_primes[i]
        if gap > EXPECTED_GAP * 2:
            ratio = gap / EXPECTED_GAP
            # Only add if not already recorded
            if not any(g[1] == all_primes[i] for g in all_gaps):
                all_gaps.append((gap, all_primes[i], all_primes[i + 1], ratio))

    # Final summary
    print(f"\n{'='*60}")
    print(f"Final Summary")
    print(f"{'='*60}")
    print(f"Total time: {total_time:.1f}s")
    print(f"Total primes: {len(all_primes):,}")
    print(f"Throughput: {total_candidates/total_time:.0f} tests/sec")
    print(f"Primes/sec: {len(all_primes)/total_time:.0f}")
    print(f"Gaps > {EXPECTED_GAP*2}: {len(all_gaps)}")

    if all_gaps:
        all_gaps.sort(reverse=True)
        print(f"\nLargest gaps:")
        for gap, p1, p2, ratio in all_gaps[:15]:
            marker = "***" if gap > TARGET_GAP else ""
            print(f"  {gap:5d} ({ratio:5.1f}x) {marker}")

    # Save results to timestamped file
    save_results(all_gaps, all_primes, total_time, total_candidates)

    return all_gaps


def main():
    if not os.path.exists(CGBN_BINARY):
        print(f"CGBN binary not found: {CGBN_BINARY}")
        print("Compile with:")
        print("  cd /tmp && nvcc -I/tmp/gmpy2_extracted/gmpy2 -I/tmp cgbn_1024_primality.cu -o cgbn_1024_primality -arch=sm_86")
        sys.exit(1)

    # Parse args
    if len(sys.argv) > 1:
        total = int(sys.argv[1])
    else:
        total = 500000  # Default: 500k candidates

    if total <= 100000:
        hunt_sequential(0, total)
    else:
        hunt_extended(total, batch_size=100000)


if __name__ == "__main__":
    main()
