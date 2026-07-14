#!/usr/bin/env python3
"""
PARALLEL HUNT FOR RECORD PRIME GAPS (gmpy2 + multiprocessing)

Optimizations:
- gmpy2.is_prime() for fast primality testing
- Extended trial division (first 500 primes)
- Multiprocessing for parallel valley searches
- Low memory per worker
"""

import math
import random
import time
import multiprocessing as mp
from functools import partial

# Use gmpy2 for fast primality
import gmpy2

# First 40 Riemann zeta zeros
ZEROS = [
    14.134725, 21.022040, 25.010858, 30.424876, 32.935062,
    37.586178, 40.918720, 43.327073, 48.005151, 49.773832,
    52.970321, 56.446248, 59.347044, 60.831779, 65.112544,
    67.079811, 69.546402, 72.067158, 75.704691, 77.144840,
    79.337375, 82.910381, 84.735493, 87.425275, 88.809111,
    92.491899, 94.651344, 95.870634, 98.831194, 101.317851,
    103.725538, 105.446623, 107.168611, 111.029536, 111.874659,
    114.320220, 116.226680, 118.790782, 121.370125, 122.946829
]

# Extended trial division - first 500 primes (rejects ~88% of composites)
def generate_small_primes(n):
    """Generate first n primes using sieve."""
    sieve = [True] * (n * 12)  # Upper bound estimate
    sieve[0] = sieve[1] = False
    for i in range(2, int(len(sieve)**0.5) + 1):
        if sieve[i]:
            for j in range(i*i, len(sieve), i):
                sieve[j] = False
    primes = [i for i, is_p in enumerate(sieve) if is_p]
    return primes[:n]

SMALL_PRIMES = generate_small_primes(500)
SMALL_PRIMES_SET = set(SMALL_PRIMES)

def is_prime_fast(n):
    """Fast primality test using trial division + gmpy2."""
    if n < 2:
        return False
    if n in SMALL_PRIMES_SET:
        return True
    if n % 2 == 0:
        return False

    # Trial division by first 500 primes
    for p in SMALL_PRIMES:
        if p * p > n:
            break
        if n % p == 0:
            return False

    # gmpy2's is_prime (uses Miller-Rabin with optimal witnesses)
    return gmpy2.is_prime(n) > 0

def interference(x):
    """Compute zero interference - LOW values = gap-prone."""
    if x <= 1:
        return 0
    total = 0.0
    log_x = math.log(x)
    for gamma in ZEROS:
        total += math.cos(gamma * log_x) / gamma
    return total

def find_prime_near(x):
    """Find a prime near x."""
    x = int(x)
    if x % 2 == 0:
        x += 1
    for offset in range(0, 500000, 2):
        if is_prime_fast(x + offset):
            return x + offset
    return None

def find_gap_after(p):
    """Find the gap after prime p."""
    candidate = p + 2
    for _ in range(1000000):
        if is_prime_fast(candidate):
            return candidate - p
        candidate += 2
    return None

def search_valley(args):
    """
    Search a single valley for large gaps.
    Returns list of (prime, gap, interference) tuples.
    Low memory: only returns gaps > threshold.
    """
    valley_x, valley_interf, threshold, max_primes = args
    results = []

    p = find_prime_near(valley_x)
    if p is None:
        return results

    for _ in range(max_primes):
        gap = find_gap_after(p)
        if gap is None:
            break

        if gap > threshold:
            results.append((p, gap, valley_interf))

        p = p + gap

    return results

def find_valleys(scale, num_samples, num_best):
    """Sample interference and return deepest valleys."""
    valleys = []
    for _ in range(num_samples):
        x = scale + random.randint(0, scale * 2)
        interf = interference(x)
        valleys.append((x, interf))

    valleys.sort(key=lambda t: t[1])
    return valleys[:num_best]

def hunt_parallel(num_workers=4, target_gap=3000, time_limit=300):
    """
    Hunt for large gaps using parallel processing.

    Args:
        num_workers: Number of parallel processes
        target_gap: Minimum gap to report
        time_limit: Maximum search time in seconds
    """
    SCALE = 10**100
    RECORD = 1676
    EXPECTED = int(math.log(SCALE))  # ~230

    print("=" * 70)
    print(f"PARALLEL GAP HUNT (gmpy2 + {num_workers} workers)")
    print("=" * 70)
    print(f"Scale: 10^100")
    print(f"Expected gap: {EXPECTED}")
    print(f"Target: gaps > {target_gap} ({target_gap/RECORD*100:.0f}% of record)")
    print(f"Workers: {num_workers}")
    print()

    all_results = []
    start_time = time.time()
    batch = 0

    with mp.Pool(num_workers) as pool:
        while time.time() - start_time < time_limit:
            batch += 1
            batch_start = time.time()

            # Find deep valleys
            valleys = find_valleys(SCALE, num_samples=1000, num_best=num_workers * 10)

            # Prepare work items (valley_x, valley_interf, threshold, max_primes)
            work_items = [
                (v[0], v[1], RECORD, 400)  # Search for gaps > 1676
                for v in valleys
            ]

            # Parallel search
            batch_results = pool.map(search_valley, work_items)

            # Collect results
            for results in batch_results:
                for p, gap, interf in results:
                    all_results.append((p, gap, interf))
                    if gap >= target_gap:
                        pct = gap / RECORD * 100
                        print(f"★★★ Gap {gap} ({pct:.1f}% of record) | I={interf:.4f}")
                    elif gap > 2000:
                        pct = gap / RECORD * 100
                        print(f"  ★ Gap {gap} ({pct:.1f}% of record)")

            batch_time = time.time() - batch_start
            elapsed = time.time() - start_time

            # Progress update every batch
            gaps_found = len(all_results)
            big_gaps = sum(1 for _, g, _ in all_results if g >= target_gap)
            print(f"[Batch {batch}] {batch_time:.1f}s | Total gaps>{RECORD}: {gaps_found} | Gaps>{target_gap}: {big_gaps} | Elapsed: {elapsed:.0f}s")

    # Final results
    elapsed = time.time() - start_time
    all_results.sort(key=lambda x: -x[1])

    print()
    print("=" * 70)
    print("RESULTS")
    print("=" * 70)
    print(f"Time: {elapsed:.1f}s")
    print(f"Workers: {num_workers}")
    print(f"Total gaps > {RECORD}: {len(all_results)}")
    print(f"Gaps > {target_gap}: {sum(1 for _, g, _ in all_results if g >= target_gap)}")
    print()

    if all_results:
        print(f"TOP 10 GAPS:")
        print(f"{'#':>2} | {'Gap':>5} | {'%Rec':>6} | {'I(x)':>8} | Prime")
        print("-" * 100)
        for i, (p, g, interf) in enumerate(all_results[:10]):
            pct = g / RECORD * 100
            print(f"{i+1:>2} | {g:>5} | {pct:>5.1f}% | {interf:>8.4f} | {p}")

        print()
        best = all_results[0]
        print(f"LARGEST: Gap {best[1]} ({best[1]/RECORD*100:.1f}% of record)")

    print("=" * 70)
    return all_results

def benchmark_primality():
    """Benchmark gmpy2 vs pure Python Miller-Rabin."""
    print("Benchmarking primality tests...")

    # Generate test numbers at scale 10^100
    test_nums = [10**100 + random.randint(0, 10**90) | 1 for _ in range(100)]

    # gmpy2
    start = time.time()
    for n in test_nums:
        gmpy2.is_prime(n)
    gmpy2_time = time.time() - start

    # With trial division
    start = time.time()
    for n in test_nums:
        is_prime_fast(n)
    fast_time = time.time() - start

    print(f"gmpy2 alone:     {gmpy2_time:.3f}s for 100 tests")
    print(f"trial + gmpy2:   {fast_time:.3f}s for 100 tests")
    print(f"Per test: {fast_time/100*1000:.2f}ms")
    print()

if __name__ == "__main__":
    import sys

    # Default to 4 workers
    num_workers = 4
    if len(sys.argv) > 1:
        num_workers = int(sys.argv[1])

    # Benchmark first
    benchmark_primality()

    # Hunt for gaps
    hunt_parallel(num_workers=num_workers, target_gap=3000, time_limit=180)
