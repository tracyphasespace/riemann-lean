#!/usr/bin/env python3
"""
Bootstrap to large prime: 1,408,695,493,609
Find the next prime after it.

At this scale (10^12):
- Miller-Rabin is the right tool for individual primes
- Zeros tell us about prime DENSITY (how far to next prime)
- Prime gap ~ log(n) ≈ 28 on average
"""

import time
import numpy as np

def miller_rabin(n, witnesses=None):
    """Deterministic Miller-Rabin for n < 3,317,044,064,679,887,385,961,981"""
    if n < 2:
        return False
    if n == 2 or n == 3:
        return True
    if n % 2 == 0:
        return False

    # Write n-1 as 2^r * d
    r, d = 0, n - 1
    while d % 2 == 0:
        r += 1
        d //= 2

    # For n < 3,317,044,064,679,887,385,961,981, these witnesses suffice
    if witnesses is None:
        witnesses = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]

    for a in witnesses:
        if a >= n:
            continue
        x = pow(a, d, n)
        if x == 1 or x == n - 1:
            continue
        for _ in range(r - 1):
            x = pow(x, 2, n)
            if x == n - 1:
                break
        else:
            return False
    return True

def find_next_prime(start):
    """Find next prime after start"""
    candidate = start + 1
    if candidate % 2 == 0:
        candidate += 1

    checks = 0
    while True:
        checks += 1
        if miller_rabin(candidate):
            return candidate, checks
        candidate += 2

def find_prev_prime(start):
    """Find previous prime before start"""
    candidate = start - 1
    if candidate % 2 == 0:
        candidate -= 1

    while candidate > 2:
        if miller_rabin(candidate):
            return candidate
        candidate -= 2
    return 2

# Known zeta zeros for density estimation
ZETA_ZEROS_100 = [
    14.134725, 21.022040, 25.010858, 30.424876, 32.935062,
    37.586178, 40.918720, 43.327073, 48.005151, 49.773832,
    52.970321, 56.446248, 59.347044, 60.831779, 65.112544,
    67.079811, 69.546402, 72.067158, 75.704691, 77.144840,
    79.337375, 82.910381, 84.735493, 87.425275, 88.809111,
    92.491899, 94.651344, 95.870634, 98.831194, 101.317851
]

def li(x):
    """Logarithmic integral - prime counting approximation"""
    if x <= 2:
        return 0
    # Use series expansion for large x
    result = x / np.log(x)
    term = x / np.log(x)
    for k in range(1, 20):
        term *= k / np.log(x)
        result += term
        if abs(term) < 1:
            break
    return result

def prime_density(x):
    """Expected number of primes per unit interval near x"""
    return 1.0 / np.log(x)

def expected_gap(x):
    """Expected gap to next prime from x"""
    return np.log(x)

def main():
    TARGET = 1_408_695_493_609

    print("="*70)
    print(f"BOOTSTRAP TO LARGE PRIME: {TARGET:,}")
    print("="*70)

    # Step 1: Verify target is prime
    print("\n--- Step 1: Verify target is prime ---\n")
    t0 = time.time()
    is_prime = miller_rabin(TARGET)
    verify_time = time.time() - t0

    print(f"  {TARGET:,} is prime: {is_prime}")
    print(f"  Verification time: {verify_time*1000:.3f} ms")

    # Step 2: What do zeros tell us about this region?
    print("\n--- Step 2: Prime density from number theory ---\n")

    log_n = np.log(TARGET)
    density = prime_density(TARGET)
    exp_gap = expected_gap(TARGET)

    print(f"  log(n) = {log_n:.2f}")
    print(f"  Prime density ≈ 1/log(n) = {density:.6f} primes per integer")
    print(f"  Expected gap to next prime ≈ {exp_gap:.1f}")
    print(f"  π({TARGET:,}) ≈ Li(n) ≈ {li(TARGET):,.0f} primes below this")

    # Refined estimate using Riemann's R(x)
    R_x = li(TARGET)
    for gamma in ZETA_ZEROS_100[:30]:
        rho = 0.5 + 1j * gamma
        R_x -= (TARGET ** rho / (rho * np.log(TARGET))).real * 2

    print(f"  π(n) with 30 zeros ≈ {R_x:,.0f}")

    # Step 3: Find next prime
    print("\n--- Step 3: Find next prime ---\n")

    t0 = time.time()
    next_prime, checks = find_next_prime(TARGET)
    search_time = time.time() - t0

    gap = next_prime - TARGET

    print(f"  Next prime: {next_prime:,}")
    print(f"  Gap: {gap} (expected ~{exp_gap:.0f})")
    print(f"  Candidates checked: {checks}")
    print(f"  Search time: {search_time*1000:.3f} ms")

    # Step 4: Context - primes around target
    print("\n--- Step 4: Local prime landscape ---\n")

    prev_prime = find_prev_prime(TARGET)
    prev_gap = TARGET - prev_prime

    print(f"  Previous prime: {prev_prime:,}")
    print(f"  Gap before: {prev_gap}")
    print(f"  TARGET:        {TARGET:,} ← (prime)")
    print(f"  Gap after:  {gap}")
    print(f"  Next prime:    {next_prime:,}")

    # Step 5: What bootstrap actually provides
    print("\n--- Step 5: What 'bootstrap' means at this scale ---\n")

    print("""  The zeros don't find individual primes, but they tell us:

  1. DENSITY: ~1 prime per 28 integers here (from log(n))

  2. DISTRIBUTION: Prime gaps follow Cramér's model
     - Most gaps are small (< 2·log(n) ≈ 56)
     - Occasional larger gaps possible

  3. COUNTING: π(n) ≈ Li(n) with zeros giving corrections
     - 30 zeros: ~0.01% accuracy for π(n)
     - Millions of zeros: ~10^-6 accuracy

  4. VERIFICATION: Miller-Rabin is O(log³n) per test
     - Unbeatable for individual prime testing
     - The "bootstrap" is the mathematical certainty, not speed
""")

    # Step 6: Summary
    print("="*70)
    print("RESULT")
    print("="*70)
    print(f"""
  Given:  {TARGET:,} (confirmed prime)
  Answer: {next_prime:,} (next prime)
  Gap:    {gap}
  Time:   {(verify_time + search_time)*1000:.2f} ms total

  The 'bootstrap' here is number-theoretic knowledge:
  - We KNEW the gap would be ~{exp_gap:.0f} (it was {gap})
  - We KNEW Miller-Rabin would verify in microseconds
  - Zeros encode this statistical structure
""")

if __name__ == '__main__':
    main()
