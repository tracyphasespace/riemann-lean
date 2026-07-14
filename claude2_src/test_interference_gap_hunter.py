#!/usr/bin/env python3
"""
INTERFERENCE-GUIDED GAP HUNTER (Test Version)

This implements the insight from zero_gap_correlation.py and maximal_gap_predictor.py:
- LOW interference regions are GAP-PRONE (prime deserts)
- Scan interference "surface" first, find valleys, then test only those

At 10^308, we are WAY over the threshold where this was expected to be worthwhile.
Original comments said: "didn't expect it to be worth while for less than a quadrillion"
10^308 >> 10^15 (quadrillion), so interference guidance should help significantly.

Architecture:
1. INTERFERENCE SCAN: Sample interference across huge range (fast, just math)
2. VALLEY SELECTION: Sort by interference, pick N lowest (most gap-prone)
3. CPU PRE-SIEVE: Filter candidates in valleys with small primes
4. CGBN GPU TEST: Primality test only the survivors

The key insight: we don't need ALL primes, we need primes that BOUND large gaps.
Large gaps occur in LOW interference regions. So skip HIGH interference entirely.

Formula: I(x) = Σ cos(γ·log(x)) / γ  where γ are Riemann zeta zeros
- HIGH I(x) → constructive interference → twins/close primes
- LOW I(x)  → destructive interference → deserts/gaps

References:
- scripts/experiments/zero_gap_correlation.py (discovered correlation)
- scripts/experiments/maximal_gap_predictor.py (validated on known maximal gaps)
- scripts/experiments/hunt_record_gaps_gpu.py (GPU interference scanning)
"""

import os
import sys
import math
import time
import struct
import subprocess
import tempfile
import gmpy2
from datetime import datetime
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor
from threading import Lock

# Paths
CGBN_BINARY = "/tmp/cgbn_1024_primality"
RESULTS_DIR = Path(__file__).parent.parent / "wolfram_proof" / "docs" / "gap_results"

# At 10^308, expected gap ≈ ln(10^308) ≈ 709
EXPECTED_GAP = 709
TARGET_GAP = 5000  # Hunt for gaps ~7x expected

# 1024 bits = 32 limbs
LIMBS_PER_NUMBER = 32
BYTES_PER_NUMBER = 128

# =============================================================================
# RIEMANN ZETA ZEROS - The "treasure map" for prime structure
# =============================================================================
# These encode WHERE primes cluster (high interference) and
# WHERE gaps occur (low interference). First 50 zeros.
ZEROS = [
    14.134725, 21.022040, 25.010858, 30.424876, 32.935062,
    37.586178, 40.918720, 43.327073, 48.005151, 49.773832,
    52.970321, 56.446248, 59.347044, 60.831779, 65.112544,
    67.079811, 69.546402, 72.067158, 75.704691, 77.144840,
    79.337375, 82.910381, 84.735493, 87.425275, 88.809111,
    92.491899, 94.651344, 95.870634, 98.831194, 101.317851,
    103.725538, 105.446623, 107.168611, 111.029536, 111.874659,
    114.320220, 116.226680, 118.790782, 121.370125, 122.946829,
    124.256819, 127.516683, 129.578704, 131.087688, 133.497737,
    134.756509, 138.116042, 139.736209, 141.123707, 143.111846
]

# =============================================================================
# INTERFERENCE CALCULATION
# =============================================================================

def zero_interference(x, num_zeros=40):
    """
    Compute zero interference at x.

    I(x) = Σ cos(γ·log(x)) / γ

    LOW values (negative) → destructive interference → GAP-PRONE
    HIGH values (positive) → constructive interference → twin-rich

    This is O(num_zeros) per point - very fast compared to primality testing.
    """
    if x <= 1:
        return 0.0
    log_x = math.log(x)
    total = 0.0
    for gamma in ZEROS[:num_zeros]:
        phase = gamma * log_x
        total += math.cos(phase) / gamma
    return total


def scan_interference_surface(base, scan_range, num_samples=100000):
    """
    Scan the interference "surface" to find gap-prone valleys.

    This is the KEY OPTIMIZATION: instead of testing all candidates,
    we first scan interference (cheap) to find WHERE to look (expensive).

    At 10^308, scanning 100K points takes ~100ms.
    This can identify the best 1% of regions to search.

    Returns: List of (x_value, interference) sorted by interference (lowest first)
    """
    samples = []
    step = scan_range // num_samples

    for i in range(num_samples):
        x = base + i * step
        interf = zero_interference(x)
        samples.append((x, interf))

    # Sort by interference - LOWEST first (most gap-prone)
    samples.sort(key=lambda t: t[1])

    return samples


def find_valleys(base, scan_range, num_valleys=50, samples_per_scan=100000):
    """
    Find the deepest interference valleys in the search range.

    These are the regions most likely to contain large gaps.
    We'll focus our expensive primality testing here.
    """
    print(f"  Scanning interference surface ({samples_per_scan:,} samples)...")
    scan_start = time.perf_counter()

    samples = scan_interference_surface(base, scan_range, samples_per_scan)

    scan_time = time.perf_counter() - scan_start

    # Get the deepest valleys
    valleys = samples[:num_valleys]

    print(f"  Scan complete in {scan_time*1000:.1f}ms")
    print(f"  Deepest valley: I(x) = {valleys[0][1]:.4f} at x ≈ {valleys[0][0]:.2e}")
    print(f"  Shallowest selected: I(x) = {valleys[-1][1]:.4f}")

    return valleys, scan_time


# =============================================================================
# STANDARD OPTIMIZATIONS (from Optimized_hunt_gaps_308digit.py)
# =============================================================================

# Sieve parameters
SIEVE_PRIMES_LIMIT = 10000
TRIAL_DIVISION_LIMIT = 100000
CPU_WORKERS = max(1, os.cpu_count() - 2)
VALLEY_SEARCH_RADIUS = 50000  # Search ±50K around each valley center

def sieve_of_eratosthenes(limit):
    """Generate all primes up to limit"""
    is_prime = [True] * (limit + 1)
    is_prime[0] = is_prime[1] = False
    for i in range(2, int(limit**0.5) + 1):
        if is_prime[i]:
            for j in range(i*i, limit + 1, i):
                is_prime[j] = False
    return [i for i in range(2, limit + 1) if is_prime[i]]

# Pre-compute primes at module load
print("Pre-computing sieve primes...", end=" ", flush=True)
SIEVE_PRIMES = sieve_of_eratosthenes(SIEVE_PRIMES_LIMIT)
print(f"{len(SIEVE_PRIMES)} primes up to {SIEVE_PRIMES_LIMIT}")

print("Pre-computing trial division primes...", end=" ", flush=True)
TRIAL_PRIMES = sieve_of_eratosthenes(TRIAL_DIVISION_LIMIT)
print(f"{len(TRIAL_PRIMES)} primes up to {TRIAL_DIVISION_LIMIT}")


def int_to_limbs_1024(n):
    """Convert Python int to 32 uint32 limbs (little-endian, 1024-bit)"""
    limbs = []
    for _ in range(32):
        limbs.append(n & 0xFFFFFFFF)
        n >>= 32
    return limbs


def presieve_candidate(n):
    """Quick sieve test with small primes. Returns True if n passes."""
    for p in SIEVE_PRIMES[1:]:  # Skip 2, we only test odd
        if n % p == 0:
            return False
    return True


def trial_division(n):
    """Extended trial division. Returns True if n passes."""
    start_idx = len(SIEVE_PRIMES)
    for p in TRIAL_PRIMES[start_idx:]:
        if n % p == 0:
            return False
    return True


def filter_candidates_chunk(args):
    """Worker: filter a chunk of candidates."""
    candidates, use_trial_division = args
    survivors = []
    for n in candidates:
        if not presieve_candidate(n):
            continue
        if use_trial_division and not trial_division(n):
            continue
        survivors.append(n)
    return survivors


def parallel_filter_candidates(candidates, num_workers=CPU_WORKERS):
    """Filter candidates in parallel."""
    if len(candidates) == 0:
        return []

    chunk_size = max(1000, len(candidates) // num_workers)
    chunks = []
    for i in range(0, len(candidates), chunk_size):
        chunks.append((candidates[i:i+chunk_size], True))

    survivors = []
    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        results = executor.map(filter_candidates_chunk, chunks)
        for chunk_survivors in results:
            survivors.extend(chunk_survivors)

    return survivors


def cgbn_batch_test(candidates):
    """Test candidates for primality using 1024-bit CGBN GPU."""
    if len(candidates) == 0:
        return []

    if len(candidates) < 32:
        return [bool(gmpy2.is_prime(c)) for c in candidates]

    with tempfile.NamedTemporaryFile(delete=False, suffix='.bin') as f:
        input_file = f.name
        for n in candidates:
            limbs = int_to_limbs_1024(n)
            f.write(struct.pack('<32I', *limbs))

    output_file = input_file + '.out'

    try:
        result = subprocess.run(
            [CGBN_BINARY, input_file, output_file],
            capture_output=True, timeout=600
        )

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


# =============================================================================
# INTERFERENCE-GUIDED GAP HUNTER
# =============================================================================

class InterferenceGuidedHunter:
    """
    Gap hunter that uses interference scanning to focus the search.

    Instead of testing ALL candidates sequentially, we:
    1. Scan interference to find valleys (fast)
    2. Generate candidates only in those valleys
    3. Filter with CPU sieve
    4. Test with CGBN GPU

    This should be more efficient for finding GAPS specifically,
    because gaps occur in LOW interference regions.
    """

    def __init__(self, base, scan_range, num_valleys=50, valley_radius=VALLEY_SEARCH_RADIUS):
        self.base = base
        self.scan_range = scan_range
        self.num_valleys = num_valleys
        self.valley_radius = valley_radius

        # Results
        self.all_primes = []
        self.all_gaps = []
        self.stats = {
            'scan_samples': 0,
            'scan_time': 0,
            'valleys_searched': 0,
            'candidates_generated': 0,
            'candidates_after_sieve': 0,
            'candidates_tested_gpu': 0,
            'primes_found': 0,
            'cpu_filter_time': 0,
            'gpu_test_time': 0,
        }

    def generate_valley_candidates(self, valley_center):
        """Generate odd candidates around a valley center."""
        start = valley_center - self.valley_radius
        if start % 2 == 0:
            start += 1

        candidates = []
        for i in range(self.valley_radius):  # valley_radius odd numbers
            candidates.append(start + 2*i)

        return candidates

    def search_valley(self, valley_x, valley_interf, valley_idx, total_valleys):
        """Search a single valley for primes."""
        # Generate candidates
        candidates = self.generate_valley_candidates(int(valley_x))

        # CPU filter
        cpu_start = time.perf_counter()
        filtered = parallel_filter_candidates(candidates)
        cpu_time = time.perf_counter() - cpu_start

        # GPU test
        gpu_start = time.perf_counter()
        results = cgbn_batch_test(filtered)
        gpu_time = time.perf_counter() - gpu_start

        # Collect primes
        primes = [c for c, r in zip(filtered, results) if r]

        # Update stats
        self.stats['candidates_generated'] += len(candidates)
        self.stats['candidates_after_sieve'] += len(filtered)
        self.stats['candidates_tested_gpu'] += len(filtered)
        self.stats['primes_found'] += len(primes)
        self.stats['cpu_filter_time'] += cpu_time
        self.stats['gpu_test_time'] += gpu_time

        # Progress
        filter_rate = 100 * len(filtered) / len(candidates) if candidates else 0
        print(f"  Valley {valley_idx+1}/{total_valleys}: "
              f"I={valley_interf:.4f} | "
              f"{len(candidates):,} → {len(filtered):,} ({filter_rate:.1f}%) → "
              f"{len(primes)} primes")

        return primes

    def run(self):
        """Run the interference-guided gap hunt."""
        print(f"\n{'='*70}")
        print(f"INTERFERENCE-GUIDED GAP HUNTER")
        print(f"{'='*70}")
        print(f"Base: 10^308")
        print(f"Scan range: {self.scan_range:,}")
        print(f"Valleys to search: {self.num_valleys}")
        print(f"Search radius per valley: ±{self.valley_radius:,}")
        print(f"Total candidates: ~{self.num_valleys * self.valley_radius:,}")
        print(f"CPU workers: {CPU_WORKERS}")
        print()

        total_start = time.perf_counter()

        # Step 1: Scan interference surface
        print("STEP 1: Scanning interference surface...")
        valleys, scan_time = find_valleys(
            self.base, self.scan_range,
            num_valleys=self.num_valleys,
            samples_per_scan=100000
        )
        self.stats['scan_samples'] = 100000
        self.stats['scan_time'] = scan_time

        # Step 2: Search each valley
        print(f"\nSTEP 2: Searching {len(valleys)} valleys...")
        all_primes = []

        for i, (valley_x, valley_interf) in enumerate(valleys):
            primes = self.search_valley(valley_x, valley_interf, i, len(valleys))
            all_primes.extend(primes)
            self.stats['valleys_searched'] += 1

        total_time = time.perf_counter() - total_start

        # Find gaps
        print(f"\nSTEP 3: Finding gaps among {len(all_primes):,} primes...")
        all_primes.sort()
        self.all_primes = all_primes

        for i in range(len(all_primes) - 1):
            gap = all_primes[i + 1] - all_primes[i]
            if gap > EXPECTED_GAP * 2:
                ratio = gap / EXPECTED_GAP
                self.all_gaps.append((gap, all_primes[i], all_primes[i + 1], ratio))
                if gap > TARGET_GAP:
                    print(f"  *** GAP {gap} ({ratio:.1f}x expected) ***")

        # Summary
        self.print_summary(total_time)

        # Save results
        self.save_results(total_time)

        return self.all_gaps

    def print_summary(self, total_time):
        """Print performance summary."""
        print(f"\n{'='*70}")
        print(f"PERFORMANCE SUMMARY")
        print(f"{'='*70}")

        s = self.stats

        print(f"\nInterference Scanning:")
        print(f"  Samples scanned:         {s['scan_samples']:>12,}")
        print(f"  Scan time:               {s['scan_time']*1000:>11.1f}ms")
        print(f"  Valleys selected:        {s['valleys_searched']:>12,}")

        if s['candidates_generated'] > 0:
            filter_reduction = (1 - s['candidates_after_sieve'] / s['candidates_generated']) * 100
        else:
            filter_reduction = 0

        print(f"\nCandidate Filtering:")
        print(f"  Candidates generated:    {s['candidates_generated']:>12,}")
        print(f"  After CPU filter:        {s['candidates_after_sieve']:>12,}")
        print(f"  Filter reduction:        {filter_reduction:>11.1f}%")

        print(f"\nTiming:")
        print(f"  Interference scan:       {s['scan_time']:>11.3f}s")
        print(f"  CPU filter time:         {s['cpu_filter_time']:>11.1f}s")
        print(f"  GPU test time:           {s['gpu_test_time']:>11.1f}s")
        print(f"  Total time:              {total_time:>11.1f}s")

        if total_time > 0:
            print(f"\nThroughput:")
            print(f"  Effective:               {s['candidates_generated']/total_time:>11,.0f} candidates/sec")
            print(f"  Primes found:            {s['primes_found']:>12,}")

        print(f"\nGaps found: {len(self.all_gaps)} (>{EXPECTED_GAP*2})")
        if self.all_gaps:
            self.all_gaps.sort(reverse=True)
            print(f"Top 10 gaps:")
            for gap, p1, p2, ratio in self.all_gaps[:10]:
                marker = " ***" if gap > TARGET_GAP else ""
                print(f"  {gap:6,} ({ratio:5.1f}x){marker}")

    def save_results(self, total_time):
        """Save results to timestamped file."""
        RESULTS_DIR.mkdir(parents=True, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = RESULTS_DIR / f"gaps_308digit_interference_{timestamp}.md"

        s = self.stats

        with open(filename, 'w') as f:
            f.write(f"# 308-Digit Prime Gap Results (Interference-Guided)\n\n")
            f.write(f"**Timestamp:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"**Scale:** 10^308\n")
            f.write(f"**Method:** Interference-guided valley search\n")
            f.write(f"**Expected gap:** ln(10^308) = {EXPECTED_GAP}\n\n")

            f.write(f"## Method\n\n")
            f.write(f"This uses zero interference to find gap-prone regions:\n")
            f.write(f"- I(x) = Σ cos(γ·log(x)) / γ where γ are zeta zeros\n")
            f.write(f"- LOW interference → destructive → gaps likely\n")
            f.write(f"- Scan surface first, then search only lowest valleys\n\n")

            f.write(f"## Performance\n\n")
            f.write(f"| Metric | Value |\n")
            f.write(f"|--------|-------|\n")
            f.write(f"| Interference samples | {s['scan_samples']:,} |\n")
            f.write(f"| Scan time | {s['scan_time']*1000:.1f}ms |\n")
            f.write(f"| Valleys searched | {s['valleys_searched']} |\n")
            f.write(f"| Candidates generated | {s['candidates_generated']:,} |\n")
            f.write(f"| After CPU filter | {s['candidates_after_sieve']:,} |\n")
            f.write(f"| GPU tests | {s['candidates_tested_gpu']:,} |\n")
            f.write(f"| Primes found | {s['primes_found']:,} |\n")
            f.write(f"| Total time | {total_time:.1f}s |\n")
            f.write(f"| Gaps > 2x expected | {len(self.all_gaps)} |\n\n")

            f.write(f"---\n\n")

            # Top gaps with full primes
            f.write(f"## Top {min(50, len(self.all_gaps))} Gaps\n\n")
            self.all_gaps.sort(reverse=True)

            for i, (gap, p1, p2, ratio) in enumerate(self.all_gaps[:50]):
                f.write(f"### Gap {gap} ({ratio:.1f}x expected) - Rank {i+1}\n\n")
                f.write(f"```\n")
                f.write(f"p1 = {p1}\n\n")
                f.write(f"p2 = {p2}\n")
                f.write(f"```\n\n")

            # Summary table
            if self.all_gaps:
                f.write(f"---\n\n## Summary Table\n\n")
                f.write(f"| Rank | Gap | Multiple | p1 ends with | p2 ends with |\n")
                f.write(f"|------|-----|----------|--------------|---------------|\n")
                for i, (gap, p1, p2, ratio) in enumerate(self.all_gaps[:100]):
                    p1_end = str(p1)[-10:]
                    p2_end = str(p2)[-10:]
                    f.write(f"| {i+1} | {gap} | {ratio:.1f}x | ...{p1_end} | ...{p2_end} |\n")

        print(f"\nResults saved to: {filename}")
        return filename


def main():
    # Check for CGBN binary
    if not os.path.exists(CGBN_BINARY):
        print(f"CGBN binary not found: {CGBN_BINARY}")
        print("Compile with:")
        print("  cd /tmp && nvcc cgbn_1024_primality.cu -o cgbn_1024_primality -arch=sm_86")
        sys.exit(1)

    # Parse arguments
    if len(sys.argv) > 1:
        num_valleys = int(sys.argv[1])
    else:
        num_valleys = 20  # Default: 20 valleys

    if len(sys.argv) > 2:
        valley_radius = int(sys.argv[2])
    else:
        valley_radius = 25000  # Default: ±25K per valley

    # Base at 10^308 (fits in 1024 bits)
    base = 10**308
    scan_range = 10**10  # Scan 10 billion range for valleys

    print(f"Configuration:")
    print(f"  Valleys: {num_valleys}")
    print(f"  Radius per valley: {valley_radius}")
    print(f"  Total candidates: ~{num_valleys * valley_radius:,}")
    print(f"  Scan range: {scan_range:,}")

    # Run interference-guided hunter
    hunter = InterferenceGuidedHunter(
        base=base,
        scan_range=scan_range,
        num_valleys=num_valleys,
        valley_radius=valley_radius
    )
    hunter.run()


if __name__ == "__main__":
    main()
