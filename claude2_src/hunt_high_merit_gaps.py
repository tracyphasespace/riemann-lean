#!/usr/bin/env python3
"""
Hunt for High-Merit Prime Gaps

Strategy: Search at scales where high merit gaps are more likely.
Merit = gap / ln(p)

Current records (Wikipedia):
- Merit 41.94 at 87 digits (gap 8350)
- Merit 39.62 at 175 digits (gap 15900)
- Merit 38.07 at 209 digits (gap 18306)

To compete, we need to search at similar scales with high throughput.
"""

import os
import sys
import time
import math
import gmpy2
from datetime import datetime
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, as_completed

# Output directory
OUTPUT_DIR = Path("/home/tracy/development/Riemann/wolfram_proof/docs/gap_results")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def find_gaps_in_range(start, count, min_merit=20.0):
    """
    Find all gaps with merit >= min_merit in range [start, start+count).
    Returns list of (gap, merit, p1, p2).
    """
    results = []

    # Find first prime >= start
    p1 = int(gmpy2.next_prime(start - 1))
    end = start + count

    while p1 < end:
        p2 = int(gmpy2.next_prime(p1))
        gap = p2 - p1

        log_p1 = float(gmpy2.log(p1))
        merit = gap / log_p1

        if merit >= min_merit:
            results.append((gap, merit, p1, p2))

        p1 = p2

    return results


def search_scale(base, search_size, min_merit=20.0, chunk_size=10**7, max_workers=14):
    """
    Search for high-merit gaps at a given scale.
    """
    log_base = float(gmpy2.log(base))
    expected_gap = log_base
    digits = len(str(base))

    print(f"\n{'='*70}")
    print(f"Searching at {digits}-digit scale")
    print(f"{'='*70}")
    print(f"Base: {base:.6e}")
    print(f"log(base): {log_base:.2f}")
    print(f"Expected gap: {expected_gap:.1f}")
    print(f"Search size: {search_size:,}")
    print(f"Min merit: {min_merit}")
    print()

    # For merit M, need gap = M * log(p) ≈ M * log_base
    target_gap_for_merit_30 = 30 * log_base
    target_gap_for_merit_40 = 40 * log_base
    print(f"Gap needed for merit 30: {target_gap_for_merit_30:.0f}")
    print(f"Gap needed for merit 40: {target_gap_for_merit_40:.0f}")
    print()

    all_results = []
    start_time = time.time()

    # Divide into chunks for parallel processing
    chunks = []
    for offset in range(0, search_size, chunk_size):
        chunk_start = base + offset
        chunk_count = min(chunk_size, search_size - offset)
        chunks.append((chunk_start, chunk_count, min_merit))

    print(f"Processing {len(chunks)} chunks with {max_workers} workers...")

    primes_tested = 0
    with ProcessPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(find_gaps_in_range, *chunk): i
                   for i, chunk in enumerate(chunks)}

        for future in as_completed(futures):
            chunk_idx = futures[future]
            try:
                results = future.result()
                all_results.extend(results)
                primes_tested += chunk_size // int(log_base)  # Approximate

                if results:
                    for gap, merit, p1, p2 in results:
                        print(f"  Found: gap={gap}, merit={merit:.2f} at chunk {chunk_idx}")

            except Exception as e:
                print(f"  Chunk {chunk_idx} failed: {e}")

    elapsed = time.time() - start_time

    # Sort by merit
    all_results.sort(key=lambda x: -x[1])

    print(f"\nCompleted in {elapsed:.1f}s")
    print(f"High-merit gaps found: {len(all_results)}")

    if all_results:
        print(f"\nTop 10 by merit:")
        print("-" * 60)
        for i, (gap, merit, p1, p2) in enumerate(all_results[:10]):
            print(f"{i+1:2d}. Gap {gap:6d}, Merit {merit:.2f}")

    return all_results, elapsed


def save_results(results, scale_digits, elapsed):
    """Save results to markdown file."""
    if not results:
        return

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = OUTPUT_DIR / f"high_merit_{scale_digits}digit_{timestamp}.md"

    with open(filename, 'w') as f:
        f.write(f"# High-Merit Gaps at {scale_digits}-Digit Scale\n\n")
        f.write(f"**Date**: {datetime.now().isoformat()}\n")
        f.write(f"**Runtime**: {elapsed:.1f}s\n")
        f.write(f"**Gaps found**: {len(results)}\n\n")

        f.write("## Top Results\n\n")
        f.write("| Rank | Gap | Merit | p1 (last 20 digits) |\n")
        f.write("|------|-----|-------|--------------------|\n")

        for i, (gap, merit, p1, p2) in enumerate(results[:20]):
            p1_str = str(p1)
            if len(p1_str) > 20:
                p1_display = "..." + p1_str[-20:]
            else:
                p1_display = p1_str
            f.write(f"| {i+1} | {gap} | {merit:.2f} | {p1_display} |\n")

        # Full primes for top 5
        f.write("\n## Full Prime Numbers (Top 5)\n\n")
        for i, (gap, merit, p1, p2) in enumerate(results[:5]):
            f.write(f"### #{i+1}: Gap {gap}, Merit {merit:.2f}\n\n")
            f.write(f"**p1** = {p1}\n\n")
            f.write(f"**p2** = {p2}\n\n")

    print(f"\nResults saved to: {filename}")
    return filename


def main():
    print("="*70)
    print("HIGH-MERIT GAP HUNTER")
    print("="*70)
    print()
    print("Wikipedia records:")
    print("  Merit 41.94 at 87 digits (gap 8350)")
    print("  Merit 39.62 at 175 digits (gap 15900)")
    print("  Merit 38.07 at 209 digits (gap 18306)")
    print()

    # Parse arguments
    if len(sys.argv) > 1:
        digits = int(sys.argv[1])
        search_size = int(sys.argv[2]) if len(sys.argv) > 2 else 10**9
        min_merit = float(sys.argv[3]) if len(sys.argv) > 3 else 20.0
    else:
        # Default: search at 87-digit scale (where record merit was found)
        digits = 87
        search_size = 10**9  # 1 billion integers
        min_merit = 25.0

    base = 10**digits

    results, elapsed = search_scale(base, search_size, min_merit)

    if results:
        save_results(results, digits, elapsed)

        best_gap, best_merit, best_p1, best_p2 = results[0]
        print(f"\n{'='*70}")
        print(f"BEST RESULT")
        print(f"{'='*70}")
        print(f"Gap: {best_gap}")
        print(f"Merit: {best_merit:.4f}")
        print(f"Digits: {len(str(best_p1))}")

        # Compare to Wikipedia record at this scale
        if digits <= 100:
            record_merit = 41.94
        elif digits <= 200:
            record_merit = 39.62
        else:
            record_merit = 38.0

        print(f"\nWikipedia record merit at ~{digits} digits: {record_merit}")
        if best_merit > record_merit:
            print("🏆 NEW RECORD! 🏆")
        else:
            print(f"Gap to record: {record_merit - best_merit:.2f}")


if __name__ == "__main__":
    main()
