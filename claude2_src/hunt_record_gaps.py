#!/usr/bin/env python3
"""
HUNT FOR RECORD PRIME GAPS

Goal: Find gaps > 1676 (current record) using interference guidance.

Strategy:
1. Scan interference beyond current record prime
2. Focus on LOWEST interference regions (most gap-prone)
3. Search those regions for large gaps
4. Report any gaps approaching or exceeding 1676
"""

import math
import time
import sys

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

CURRENT_RECORD_PRIME = 20_733_746_510_561_442_863
CURRENT_RECORD_GAP = 1676

# First 100 primes for trial division (rejects ~76% of odd composites)
SMALL_PRIMES = [
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
    73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151,
    157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233,
    239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317,
    331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419,
    421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503,
    509, 521, 523, 541
]

def trial_division(n):
    """Quick rejection of composites divisible by small primes."""
    for p in SMALL_PRIMES:
        if n == p:
            return True  # n is a small prime
        if n % p == 0:
            return False  # n is composite
    return None  # Need Miller-Rabin

def miller_rabin_core(n):
    """Miller-Rabin without initial checks (called after trial division)."""
    r, d = 0, n - 1
    while d % 2 == 0:
        r += 1
        d //= 2
    for a in [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]:
        if a >= n: continue
        x = pow(a, d, n)
        if x == 1 or x == n - 1: continue
        for _ in range(r - 1):
            x = pow(x, 2, n)
            if x == n - 1: break
        else: return False
    return True

def miller_rabin(n):
    """Deterministic Miller-Rabin for n < 3.3×10^24, with trial division speedup."""
    if n < 2: return False
    if n == 2: return True
    if n % 2 == 0: return False

    # Try trial division first (cheap)
    td_result = trial_division(n)
    if td_result is not None:
        return td_result

    # Fall back to Miller-Rabin (expensive)
    return miller_rabin_core(n)

def zero_interference(x, num_zeros=40):
    """Compute interference - LOW values = gap-prone"""
    if x <= 1: return 0
    total = 0.0
    log_x = math.log(x)
    for gamma in ZEROS[:num_zeros]:
        phase = gamma * log_x
        total += math.cos(phase) / gamma
    return total

def find_next_prime(start):
    """Find next prime after start, return (next_prime, gap)"""
    candidate = start + 1
    if candidate % 2 == 0:
        candidate += 1

    checks = 0
    while True:
        checks += 1
        if miller_rabin(candidate):
            return candidate, candidate - start, checks
        candidate += 2

        # Safety limit
        if checks > 100000:
            return None, None, checks

def scan_for_gap_prone_regions(start, scan_range, num_samples=1000):
    """Find regions with lowest interference (most gap-prone)"""
    candidates = []
    step = scan_range // num_samples

    for i in range(num_samples):
        x = start + i * step
        interf = zero_interference(x)
        candidates.append((x, interf))

    # Sort by interference (lowest first)
    candidates.sort(key=lambda t: t[1])
    return candidates

def hunt_for_records(time_limit_seconds=60):
    """Hunt for gaps > current record"""

    print("="*70)
    print("HUNTING FOR PRIME GAPS > 1676 (CURRENT WORLD RECORD)")
    print("="*70)

    start_prime = CURRENT_RECORD_PRIME
    target_gap = CURRENT_RECORD_GAP + 2  # Need to beat record

    print(f"\nCurrent record: gap {CURRENT_RECORD_GAP} after {start_prime:,}")
    print(f"Target: gaps ≥ {target_gap}")
    print(f"Time limit: {time_limit_seconds} seconds")
    print(f"Strategy: Search LOW interference regions\n")

    # Scan for gap-prone regions
    print("Scanning interference pattern...")
    scan_start = start_prime + CURRENT_RECORD_GAP + 10  # Start after current gap
    scan_range = 10**18  # 1 quintillion range

    candidates = scan_for_gap_prone_regions(scan_start, scan_range, num_samples=500)

    # Get the most gap-prone regions (lowest 10%)
    best_regions = candidates[:50]

    print(f"Found {len(best_regions)} low-interference candidate regions")
    print(f"Interference range: {best_regions[0][1]:.4f} to {best_regions[-1][1]:.4f}")

    # Search each region
    print("\n" + "-"*70)
    print("Searching for large gaps in low-interference regions...")
    print("-"*70)
    print(f"\n{'Region':>5} | {'Prime p':>28} | {'Gap':>6} | {'Interf':>8} | Status")
    print("-"*70)

    large_gaps_found = []
    primes_checked = 0
    start_time = time.time()

    for region_idx, (region_x, interf) in enumerate(best_regions):
        if time.time() - start_time > time_limit_seconds:
            print(f"\n[Time limit reached after {time_limit_seconds}s]")
            break

        # Find a prime near this region
        p = int(region_x)
        if p % 2 == 0:
            p += 1

        # Search for prime in small window
        found_prime = None
        for offset in range(0, 10000, 2):
            if miller_rabin(p + offset):
                found_prime = p + offset
                break

        if not found_prime:
            continue

        # Find gap after this prime
        next_p, gap, checks = find_next_prime(found_prime)
        primes_checked += 1

        if gap is None:
            continue

        # Report progress
        status = ""
        if gap > 1000:
            status = "★ LARGE"
            large_gaps_found.append((found_prime, gap, interf))
        if gap > 1500:
            status = "★★ VERY LARGE"
        if gap >= target_gap:
            status = "★★★ NEW RECORD!"

        if gap > 500 or region_idx < 10:  # Show first few and any large ones
            print(f"{region_idx+1:>5} | {found_prime:>28,} | {gap:>6} | {interf:>8.4f} | {status}")

    elapsed = time.time() - start_time

    # Summary
    print("\n" + "="*70)
    print("SEARCH SUMMARY")
    print("="*70)
    print(f"Time elapsed: {elapsed:.1f}s")
    print(f"Regions searched: {min(region_idx+1, len(best_regions))}")
    print(f"Primes checked: {primes_checked}")

    if large_gaps_found:
        print(f"\nLarge gaps found (>1000):")
        for p, g, i in sorted(large_gaps_found, key=lambda x: -x[1])[:10]:
            pct = g / CURRENT_RECORD_GAP * 100
            print(f"  Gap {g} ({pct:.1f}% of record) after {p:,}")

        best_gap = max(g for _, g, _ in large_gaps_found)
        print(f"\nBest gap found: {best_gap} ({best_gap/CURRENT_RECORD_GAP*100:.1f}% of record)")
    else:
        print("\nNo gaps > 1000 found in this search window.")

    print(f"""
REALITY CHECK:
─────────────────────────────────────────────────────────────
Finding gaps > 1676 requires extraordinary luck or massive compute.

At scale 10^19:
  • Expected gap: ~44
  • Record gap: 1676 (38x expected)
  • Probability of gap > 1676: roughly 1 in 10^15

To find 17 new records:
  • Would need to check ~10^16 primes minimum
  • At 1μs per prime = ~300 years on single core
  • With 10,000 cores = ~10 days
  • With interference guidance: maybe 10-100x faster

The interference predictor helps FOCUS the search,
but the search space is still astronomically large.
─────────────────────────────────────────────────────────────
""")

    return large_gaps_found

if __name__ == '__main__':
    # Run for 60 seconds
    hunt_for_records(time_limit_seconds=60)
