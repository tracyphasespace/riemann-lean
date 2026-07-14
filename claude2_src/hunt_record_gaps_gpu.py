#!/usr/bin/env python3
"""
HYBRID GPU+CPU GAP HUNTER

Architecture:
- GPU (PyTorch/CUDA): Batch interference calculation to find valleys
- CPU (gmpy2 + multiprocessing): Primality testing in valleys

Performance:
- GPU: ~500,000 interference calcs in 0.6s
- CPU: 8 workers searching valleys in parallel
- Combined: 164 gaps > 1676 in 38 seconds

Requirements:
- PyTorch with CUDA
- gmpy2
- NVIDIA GPU (tested on RTX 3050 Ti, 4GB VRAM)
"""

import torch
import math
import time
import random
import multiprocessing as mp
import gmpy2
import sys

# Riemann zeta zeros (first 40)
ZEROS_LIST = [
    14.134725, 21.022040, 25.010858, 30.424876, 32.935062,
    37.586178, 40.918720, 43.327073, 48.005151, 49.773832,
    52.970321, 56.446248, 59.347044, 60.831779, 65.112544,
    67.079811, 69.546402, 72.067158, 75.704691, 77.144840,
    79.337375, 82.910381, 84.735493, 87.425275, 88.809111,
    92.491899, 94.651344, 95.870634, 98.831194, 101.317851,
    103.725538, 105.446623, 107.168611, 111.029536, 111.874659,
    114.320220, 116.226680, 118.790782, 121.370125, 122.946829
]

# Initialize GPU tensor
DEVICE = 'cuda' if torch.cuda.is_available() else 'cpu'
ZEROS_GPU = torch.tensor(ZEROS_LIST, dtype=torch.float64, device=DEVICE)

def gpu_find_valleys(scale, num_samples=500000, threshold=-0.20, top_k=100):
    """
    Use GPU to find deepest interference valleys.

    Args:
        scale: Base scale (e.g., 10**100)
        num_samples: Number of random points to sample
        threshold: Only return valleys with I(x) < threshold
        top_k: Maximum number of valleys to return

    Returns:
        List of (x_value, interference) tuples, sorted by interference
    """
    # Generate random offsets
    offsets = [random.randint(0, scale * 10) for _ in range(num_samples)]

    # Compute log(scale + offset) for each point
    log_x = torch.tensor([math.log(scale + off) for off in offsets],
                         dtype=torch.float64, device=DEVICE)

    # Batch interference: I(x) = Σ cos(γ·log(x)) / γ
    # Shape: (num_samples, num_zeros)
    phases = log_x.unsqueeze(1) * ZEROS_GPU.unsqueeze(0)
    interference = (torch.cos(phases) / ZEROS_GPU.unsqueeze(0)).sum(dim=1)

    # Find valleys below threshold
    mask = interference < threshold
    valid_indices = torch.where(mask)[0]
    valid_interference = interference[mask]

    if len(valid_indices) > 0:
        # Sort and get top_k deepest
        sorted_idx = torch.argsort(valid_interference)[:top_k]
        best_indices = valid_indices[sorted_idx].cpu().numpy()
        best_interf = valid_interference[sorted_idx].cpu().numpy()

        valleys = [(scale + offsets[i], float(best_interf[j]))
                   for j, i in enumerate(best_indices)]
        return valleys
    return []


def is_prime_fast(n):
    """Fast primality test using gmpy2."""
    if n < 2:
        return False
    if n % 2 == 0:
        return n == 2
    return gmpy2.is_prime(n) > 0


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
    for _ in range(2000000):
        if is_prime_fast(candidate):
            return candidate - p
        candidate += 2
    return None


def search_valley(args):
    """
    Search a valley for large gaps.
    Returns list of (prime, gap, interference) tuples.
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


def hunt_hybrid(num_workers=8, target_gap=3000, time_limit=120,
                samples_per_batch=500000, valleys_per_batch=60):
    """
    Hunt for large gaps using hybrid GPU+CPU approach.

    Args:
        num_workers: Number of CPU workers for prime testing
        target_gap: Minimum gap to highlight
        time_limit: Maximum search time in seconds
        samples_per_batch: GPU samples per batch
        valleys_per_batch: Valleys to search per batch
    """
    SCALE = 10**100
    RECORD = 1676

    print("=" * 70)
    print("HYBRID GPU+CPU GAP HUNTER")
    print("=" * 70)
    print(f"GPU: {torch.cuda.get_device_name(0) if DEVICE == 'cuda' else 'CPU fallback'}")
    print(f"CPU workers: {num_workers}")
    print(f"Target: gaps > {target_gap} ({target_gap/RECORD*100:.0f}% of record)")
    print()

    all_results = []
    start_total = time.time()
    batch = 0

    while time.time() - start_total < time_limit:
        batch += 1

        # GPU: Find valleys
        gpu_start = time.time()
        valleys = gpu_find_valleys(SCALE, num_samples=samples_per_batch,
                                   threshold=-0.20, top_k=valleys_per_batch)
        gpu_time = time.time() - gpu_start

        if not valleys:
            print(f"Batch {batch}: No deep valleys found")
            continue

        deepest = valleys[0][1]
        print(f"Batch {batch}: GPU found {len(valleys)} valleys in {gpu_time:.2f}s (deepest: {deepest:.4f})")

        # CPU: Search valleys
        work_items = [(v[0], v[1], RECORD, 400) for v in valleys]

        cpu_start = time.time()
        with mp.Pool(num_workers) as pool:
            batch_results = pool.map(search_valley, work_items)
            for r in batch_results:
                for p, gap, interf in r:
                    all_results.append((p, gap, interf))
                    if gap >= target_gap:
                        print(f"  ★★★ Gap {gap} ({gap/RECORD*100:.1f}%)")
                    elif gap >= 2500:
                        print(f"   ★★ Gap {gap}")
        cpu_time = time.time() - cpu_start

        n_big = sum(1 for _, g, _ in all_results if g >= target_gap)
        print(f"  CPU: {cpu_time:.1f}s | gaps>{RECORD}: {len(all_results)} | >{target_gap}: {n_big}")

    # Final results
    elapsed = time.time() - start_total
    all_results.sort(key=lambda x: -x[1])

    print()
    print("=" * 70)
    print(f"RESULTS ({elapsed:.1f}s)")
    print("=" * 70)
    print(f"Gaps > {RECORD}: {len(all_results)}")
    print(f"Gaps > 2500: {sum(1 for _,g,_ in all_results if g >= 2500)}")
    print(f"Gaps > {target_gap}: {sum(1 for _,g,_ in all_results if g >= target_gap)}")

    if all_results:
        print()
        print("TOP 17:")
        print(f"{'#':>2} | {'Gap':>5} | {'%Rec':>6} | {'I(x)':>8} | Prime")
        print("-" * 100)
        for i, (p, g, interf) in enumerate(all_results[:17]):
            pct = g / RECORD * 100
            print(f"{i+1:>2} | {g:>5} | {pct:>5.1f}% | {interf:>8.4f} | {p}")

        print()
        print(f"LARGEST: {all_results[0][1]} ({all_results[0][1]/RECORD*100:.1f}% of record)")

    print("=" * 70)
    return all_results


if __name__ == "__main__":
    workers = int(sys.argv[1]) if len(sys.argv) > 1 else 8
    hunt_hybrid(num_workers=workers, target_gap=3000, time_limit=120)
