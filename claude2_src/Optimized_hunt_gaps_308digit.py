#!/usr/bin/env python3
"""
Optimized 308-digit Gap Hunter using 1024-bit CGBN

NOTE: Using 10^308 (not 10^309) because:
- 10^309 requires 1027 bits (OVERFLOW in 1024-bit container!)
- 10^308 requires 1024 bits (fits exactly)
- 2^1024 ≈ 10^308.25

Optimizations:
1. Single-instance GPU access (no competing processes)
2. CPU worker pool for pre-sieving (eliminates ~70% of candidates)
3. Pipelined batch processing (CPU prepares while GPU computes)
4. Wheel sieve (2,3,5): tests only 26.7% of integers vs 50% for odd-only

Expected speedup: 120x+ over naive approach
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
from multiprocessing import Pool, Queue, Process, cpu_count, Manager
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor
from threading import Thread, Lock
from queue import Empty
import signal

# Paths
CGBN_BINARY = "/tmp/cgbn_1024_primality"
RESULTS_DIR = Path(__file__).parent.parent / "wolfram_proof" / "docs" / "gap_results"

# At 10^308, expected gap ≈ ln(10^308) ≈ 709
EXPECTED_GAP = 709
TARGET_GAP = 5000  # Hunt for gaps ~7x expected

# 1024 bits = 32 limbs
LIMBS_PER_NUMBER = 32
BYTES_PER_NUMBER = 128

# Optimization parameters - BALANCED for CPU/GPU
# Analysis showed: CPU was 82% of time, GPU 18% idle
# Reduced filtering to balance load (target ~50% survival rate)
SIEVE_PRIMES_LIMIT = 1000       # Reduced from 10000 (168 primes vs 1229)
TRIAL_DIVISION_LIMIT = 0        # DISABLED - was causing CPU bottleneck
CPU_WORKERS = max(1, cpu_count() - 2)  # Leave cores for GPU management
GPU_BATCH_SIZE = 200000         # Increased from 100000 for better GPU efficiency
PIPELINE_DEPTH = 2              # Number of batches to prepare ahead

# Wheel sieve (2,3,5): only test n where gcd(n,30)=1
# This reduces candidates from 50% (odd only) to 26.7% (8 per 30)
# Nearly doubles throughput by eliminating multiples of 2, 3, and 5 upfront
WHEEL_OFFSETS = [1, 7, 11, 13, 17, 19, 23, 29]  # residues coprime to 30
WHEEL_GAPS = [6, 4, 2, 4, 2, 4, 6, 2]           # gaps between consecutive wheel positions
WHEEL_SIZE = 30                                  # wheel period
WHEEL_DENSITY = 8                                # candidates per wheel period

# Pre-compute small primes for sieving
def sieve_of_eratosthenes(limit):
    """Generate all primes up to limit"""
    is_prime = [True] * (limit + 1)
    is_prime[0] = is_prime[1] = False
    for i in range(2, int(limit**0.5) + 1):
        if is_prime[i]:
            for j in range(i*i, limit + 1, i):
                is_prime[j] = False
    return [i for i in range(2, limit + 1) if is_prime[i]]

# Global prime lists (computed once at module load)
print("Pre-computing sieve primes...", end=" ", flush=True)
SIEVE_PRIMES = sieve_of_eratosthenes(SIEVE_PRIMES_LIMIT)
print(f"{len(SIEVE_PRIMES)} primes up to {SIEVE_PRIMES_LIMIT}")

if TRIAL_DIVISION_LIMIT > 0:
    print("Pre-computing trial division primes...", end=" ", flush=True)
    TRIAL_PRIMES = sieve_of_eratosthenes(TRIAL_DIVISION_LIMIT)
    print(f"{len(TRIAL_PRIMES)} primes up to {TRIAL_DIVISION_LIMIT}")
else:
    TRIAL_PRIMES = []
    print("Trial division: DISABLED (GPU will handle more)")


def int_to_limbs_1024(n):
    """Convert Python int to 32 uint32 limbs (little-endian, 1024-bit)"""
    limbs = []
    for _ in range(32):
        limbs.append(n & 0xFFFFFFFF)
        n >>= 32
    return limbs


def presieve_candidate(n):
    """
    Quick sieve test: check if n is divisible by small primes.
    Returns True if n passes (not divisible), False if composite.
    Skip 2, 3, 5 since wheel sieve already excludes their multiples.
    """
    for p in SIEVE_PRIMES[3:]:  # Skip 2, 3, 5 (indices 0, 1, 2)
        if n % p == 0:
            return False
    return True


def trial_division(n):
    """
    Extended trial division with larger primes.
    Only called on candidates that passed pre-sieve.
    Returns True if n passes, False if composite.
    """
    # Start after sieve primes to avoid redundant work
    start_idx = len(SIEVE_PRIMES)
    for p in TRIAL_PRIMES[start_idx:]:
        if n % p == 0:
            return False
    return True


def filter_candidates_chunk(args):
    """
    Worker function: filter a chunk of candidates using sieve + trial division.
    Returns list of candidates that passed all CPU filters.
    """
    candidates, use_trial_division = args
    survivors = []

    for n in candidates:
        # Stage 1: Pre-sieve with small primes
        if not presieve_candidate(n):
            continue

        # Stage 2: Trial division (optional, more expensive)
        if use_trial_division and not trial_division(n):
            continue

        survivors.append(n)

    return survivors


def parallel_filter_candidates(candidates, num_workers=CPU_WORKERS, use_trial_division=True):
    """
    Filter candidates in parallel using CPU worker pool.
    Returns candidates that survived sieve and trial division.
    """
    if len(candidates) == 0:
        return []

    # Split into chunks for parallel processing
    chunk_size = max(1000, len(candidates) // num_workers)
    chunks = []
    for i in range(0, len(candidates), chunk_size):
        chunks.append((candidates[i:i+chunk_size], use_trial_division))

    # Process in parallel
    survivors = []
    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        results = executor.map(filter_candidates_chunk, chunks)
        for chunk_survivors in results:
            survivors.extend(chunk_survivors)

    return survivors


def cgbn_batch_test(candidates, gpu_lock=None):
    """
    Test candidates for primality using 1024-bit CGBN GPU.
    Uses lock to ensure single GPU access.
    """
    if len(candidates) == 0:
        return []

    if len(candidates) < 32:
        # Too small for GPU, use gmpy2
        return [bool(gmpy2.is_prime(c)) for c in candidates]

    # Acquire GPU lock if provided
    if gpu_lock:
        gpu_lock.acquire()

    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix='.bin') as f:
            input_file = f.name
            for n in candidates:
                limbs = int_to_limbs_1024(n)
                f.write(struct.pack('<32I', *limbs))

        output_file = input_file + '.out'

        try:
            result = subprocess.run(
                [CGBN_BINARY, input_file, output_file],
                capture_output=True,
                timeout=600
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

    finally:
        if gpu_lock:
            gpu_lock.release()


class PipelinedGapHunter:
    """
    Pipelined gap hunter: prepares batches on CPU while GPU processes.

    Pipeline stages:
    1. Generate candidates (main thread)
    2. CPU filter (worker pool) - sieve + trial division
    3. GPU test (single thread with lock)
    4. Collect results (main thread)
    """

    def __init__(self, base, total_candidates, batch_size=GPU_BATCH_SIZE):
        self.base = base
        self.total_candidates = total_candidates
        self.batch_size = batch_size
        self.gpu_lock = Lock()

        # Results
        self.all_primes = []
        self.all_gaps = []
        self.stats = {
            'candidates_generated': 0,
            'candidates_after_sieve': 0,
            'candidates_tested_gpu': 0,
            'primes_found': 0,
            'cpu_filter_time': 0,
            'gpu_test_time': 0,
        }

    def generate_batch(self, batch_idx):
        """Generate a batch of wheel-coprime candidates (gcd(n,30)=1)"""
        # Each batch of N candidates covers N * 30/8 integers on average
        # This is more efficient than odd-only (N * 2 integers)
        integers_per_batch = self.batch_size * WHEEL_SIZE // WHEEL_DENSITY
        offset = batch_idx * integers_per_batch
        start = self.base + offset

        # Align to wheel: find first wheel position >= start
        base_30 = (start // WHEEL_SIZE) * WHEEL_SIZE

        candidates = []
        current = base_30
        wheel_idx = 0

        # Skip to first position >= start
        while current + WHEEL_OFFSETS[wheel_idx] < start:
            wheel_idx += 1
            if wheel_idx >= WHEEL_DENSITY:
                wheel_idx = 0
                current += WHEEL_SIZE

        # Generate candidates using wheel pattern
        remaining = self.total_candidates - (batch_idx * self.batch_size)
        count = min(self.batch_size, remaining)

        while len(candidates) < count:
            candidate = current + WHEEL_OFFSETS[wheel_idx]
            candidates.append(candidate)
            wheel_idx += 1
            if wheel_idx >= WHEEL_DENSITY:
                wheel_idx = 0
                current += WHEEL_SIZE

        return candidates

    def process_batch(self, candidates, batch_idx, total_batches):
        """Process a single batch through CPU filter and GPU test"""
        batch_start = time.perf_counter()

        # Stage 1: CPU filtering (parallel)
        cpu_start = time.perf_counter()
        filtered = parallel_filter_candidates(candidates, use_trial_division=(TRIAL_DIVISION_LIMIT > 0))
        cpu_time = time.perf_counter() - cpu_start

        filter_rate = len(filtered) / len(candidates) * 100 if candidates else 0

        # Stage 2: GPU primality testing
        gpu_start = time.perf_counter()
        results = cgbn_batch_test(filtered, self.gpu_lock)
        gpu_time = time.perf_counter() - gpu_start

        # Collect primes
        primes = [c for c, r in zip(filtered, results) if r]

        batch_time = time.perf_counter() - batch_start

        # Update stats
        self.stats['candidates_generated'] += len(candidates)
        self.stats['candidates_after_sieve'] += len(filtered)
        self.stats['candidates_tested_gpu'] += len(filtered)
        self.stats['primes_found'] += len(primes)
        self.stats['cpu_filter_time'] += cpu_time
        self.stats['gpu_test_time'] += gpu_time

        # Progress output
        throughput = len(candidates) / batch_time if batch_time > 0 else 0
        gpu_throughput = len(filtered) / gpu_time if gpu_time > 0 else 0

        print(f"  Batch {batch_idx+1}/{total_batches}: "
              f"{len(candidates):,} → {len(filtered):,} ({filter_rate:.1f}% survived) → "
              f"{len(primes)} primes | "
              f"CPU:{cpu_time:.1f}s GPU:{gpu_time:.1f}s | "
              f"{throughput:.0f}/s effective, {gpu_throughput:.0f}/s GPU")

        return primes

    def run_pipelined(self):
        """
        Run with pipelined batch processing.
        Uses ThreadPoolExecutor to overlap CPU and GPU work.
        """
        print(f"\n{'='*70}")
        print(f"Optimized 308-Digit Gap Hunter (1024-bit CGBN + Wheel Sieve)")
        print(f"{'='*70}")
        print(f"Base: 10^308")
        print(f"Total candidates: {self.total_candidates:,}")
        print(f"Batch size: {self.batch_size:,}")
        print(f"CPU workers: {CPU_WORKERS}")
        print(f"Wheel sieve: 2×3×5=30 (tests only 26.7% of integers)")
        print(f"Sieve primes: {len(SIEVE_PRIMES)-3} (7 to {SIEVE_PRIMES_LIMIT}, skipping 2,3,5)")
        print(f"Trial division primes: {len(TRIAL_PRIMES)} (up to {TRIAL_DIVISION_LIMIT})")
        print(f"Expected filter rate: ~70% eliminated by CPU")
        print()

        total_start = time.perf_counter()

        num_batches = (self.total_candidates + self.batch_size - 1) // self.batch_size

        # Process batches with pipelining
        # We use a simple approach: prepare next batch while GPU processes current

        all_primes = []

        with ThreadPoolExecutor(max_workers=2) as executor:
            pending_future = None
            pending_batch_idx = None

            for batch_idx in range(num_batches):
                # Generate current batch
                candidates = self.generate_batch(batch_idx)

                if pending_future is not None:
                    # Wait for previous batch to complete
                    primes = pending_future.result()
                    all_primes.extend(primes)

                # Submit current batch for processing
                pending_future = executor.submit(
                    self.process_batch, candidates, batch_idx, num_batches
                )
                pending_batch_idx = batch_idx

            # Wait for final batch
            if pending_future is not None:
                primes = pending_future.result()
                all_primes.extend(primes)

        total_time = time.perf_counter() - total_start

        # Find gaps
        all_primes.sort()
        self.all_primes = all_primes

        print(f"\nFinding gaps among {len(all_primes):,} primes...")

        for i in range(len(all_primes) - 1):
            gap = all_primes[i + 1] - all_primes[i]
            if gap > EXPECTED_GAP * 2:
                ratio = gap / EXPECTED_GAP
                self.all_gaps.append((gap, all_primes[i], all_primes[i + 1], ratio))
                if gap > TARGET_GAP:
                    print(f"  *** GAP {gap} ({ratio:.1f}x expected) ***")

        # Final summary
        self.print_summary(total_time)

        # Save results
        self.save_results(total_time)

        return self.all_gaps

    def print_summary(self, total_time):
        """Print performance summary"""
        print(f"\n{'='*70}")
        print(f"Performance Summary")
        print(f"{'='*70}")

        s = self.stats

        # Filter efficiency
        filter_reduction = (1 - s['candidates_after_sieve'] / s['candidates_generated']) * 100

        print(f"\nFilter Efficiency:")
        print(f"  Candidates generated:    {s['candidates_generated']:>12,}")
        print(f"  After CPU filter:        {s['candidates_after_sieve']:>12,} ({100-filter_reduction:.1f}% survived)")
        print(f"  Filter reduction:        {filter_reduction:>11.1f}%")
        print(f"  GPU tests saved:         {s['candidates_generated'] - s['candidates_after_sieve']:>12,}")

        print(f"\nTiming:")
        print(f"  CPU filter time:         {s['cpu_filter_time']:>11.1f}s")
        print(f"  GPU test time:           {s['gpu_test_time']:>11.1f}s")
        print(f"  Total time:              {total_time:>11.1f}s")
        print(f"  Overhead:                {total_time - s['cpu_filter_time'] - s['gpu_test_time']:>11.1f}s")

        print(f"\nThroughput:")
        print(f"  Effective (total):       {s['candidates_generated']/total_time:>11,.0f} candidates/sec")
        print(f"  GPU actual:              {s['candidates_tested_gpu']/s['gpu_test_time']:>11,.0f} tests/sec")
        print(f"  Primes found:            {s['primes_found']:>12,}")
        print(f"  Primes/sec:              {s['primes_found']/total_time:>11,.0f}")

        # Estimate speedup vs naive
        naive_time_est = s['candidates_generated'] / (s['candidates_tested_gpu']/s['gpu_test_time'])
        speedup = naive_time_est / total_time
        print(f"\nEstimated speedup vs naive: {speedup:.1f}x")

        print(f"\nGaps found: {len(self.all_gaps)} (>{EXPECTED_GAP*2})")
        if self.all_gaps:
            self.all_gaps.sort(reverse=True)
            print(f"Top 10 gaps:")
            for gap, p1, p2, ratio in self.all_gaps[:10]:
                marker = " ***" if gap > TARGET_GAP else ""
                print(f"  {gap:6,} ({ratio:5.1f}x){marker}")

    def save_results(self, total_time):
        """Save results to timestamped file"""
        RESULTS_DIR.mkdir(parents=True, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = RESULTS_DIR / f"gaps_308digit_optimized_{timestamp}.md"

        s = self.stats
        filter_reduction = (1 - s['candidates_after_sieve'] / s['candidates_generated']) * 100

        with open(filename, 'w') as f:
            f.write(f"# 308-Digit Prime Gap Results (Optimized)\n\n")
            f.write(f"**Timestamp:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"**Scale:** 10^308\n")
            f.write(f"**Expected gap:** ln(10^308) = {EXPECTED_GAP}\n\n")

            f.write(f"## Performance\n\n")
            f.write(f"| Metric | Value |\n")
            f.write(f"|--------|-------|\n")
            f.write(f"| Candidates generated | {s['candidates_generated']:,} |\n")
            f.write(f"| After CPU filter | {s['candidates_after_sieve']:,} |\n")
            f.write(f"| Filter reduction | {filter_reduction:.1f}% |\n")
            f.write(f"| GPU tests | {s['candidates_tested_gpu']:,} |\n")
            f.write(f"| Primes found | {s['primes_found']:,} |\n")
            f.write(f"| Total time | {total_time:.1f}s |\n")
            f.write(f"| Effective throughput | {s['candidates_generated']/total_time:,.0f}/sec |\n")
            f.write(f"| Gaps > 2x expected | {len(self.all_gaps)} |\n\n")

            f.write(f"## Optimizations Applied\n\n")
            f.write(f"1. **Wheel sieve (2×3×5)**: Tests only 26.7% of integers (vs 50% for odd-only)\n")
            f.write(f"2. Single-instance GPU access (no competition)\n")
            f.write(f"3. CPU pre-sieve with {len(SIEVE_PRIMES)-3} primes (7 to {SIEVE_PRIMES_LIMIT})\n")
            f.write(f"4. Trial division with {len(TRIAL_PRIMES)} primes (up to {TRIAL_DIVISION_LIMIT})\n")
            f.write(f"5. Pipelined batch processing ({CPU_WORKERS} CPU workers)\n\n")

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

    # Check for competing processes
    try:
        result = subprocess.run(
            ["pgrep", "-f", "hunt_gaps.*30[89]"],
            capture_output=True,
            text=True
        )
        if result.stdout.strip():
            pids = result.stdout.strip().split('\n')
            my_pid = str(os.getpid())
            other_pids = [p for p in pids if p != my_pid]
            if other_pids:
                print(f"WARNING: Other gap hunter processes detected: {other_pids}")
                print("Running multiple instances will degrade GPU performance!")
                response = input("Continue anyway? [y/N]: ")
                if response.lower() != 'y':
                    sys.exit(0)
    except:
        pass

    # Parse arguments
    if len(sys.argv) > 1:
        total = int(sys.argv[1])
    else:
        total = 500000  # Default: 500k candidates

    # Base at 10^308 (fits in 1024 bits; 10^309 would overflow!)
    base = 10**308
    if base % 2 == 0:
        base += 1

    # Run optimized hunter
    hunter = PipelinedGapHunter(base, total, batch_size=GPU_BATCH_SIZE)
    hunter.run_pipelined()


if __name__ == "__main__":
    main()
