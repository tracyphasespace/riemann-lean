#!/usr/bin/env python3
"""
Newton's Ladder Prime Bootstrap

Can we find large primes quickly using:
1. Pre-computed zeros (universal constants)
2. Newton's method on ψ'(x) to find peaks
3. Miller-Rabin to verify candidates

This bypasses needing to sieve or know all smaller primes!
"""

import numpy as np
from scipy.optimize import minimize_scalar, brentq
from scipy.misc import derivative
import time

# First 100 zeta zeros (these are universal constants, tabulated)
ZETA_ZEROS = [
    14.134725, 21.022040, 25.010858, 30.424876, 32.935062,
    37.586178, 40.918720, 43.327073, 48.005151, 49.773832,
    52.970321, 56.446248, 59.347044, 60.831779, 65.112544,
    67.079811, 69.546402, 72.067158, 75.704691, 77.144840,
    79.337375, 82.910381, 84.735493, 87.425275, 88.809111,
    92.491899, 94.651344, 95.870634, 98.831194, 101.317851,
    103.725538, 105.446623, 107.168611, 111.029536, 111.874659,
    114.320220, 116.226680, 118.790782, 121.370125, 122.946829,
    124.256819, 127.516683, 129.578704, 131.087688, 133.497737,
    134.756509, 138.116042, 139.736209, 141.123707, 143.111846,
    146.000982, 147.422765, 150.053520, 150.925258, 153.024693,
    156.112909, 157.597592, 158.849988, 161.188964, 163.030709,
    165.537069, 167.184439, 169.094515, 169.911976, 173.411536,
    174.754191, 176.441434, 178.377407, 179.916484, 182.207078,
    184.874467, 185.598783, 187.228922, 189.416158, 192.026656,
    193.079726, 195.265396, 196.876481, 198.015309, 201.264751,
    202.493594, 204.189671, 205.394697, 207.906259, 209.576509,
    211.690862, 213.347919, 214.547044, 216.169538, 219.067596,
    220.714919, 221.430705, 224.007000, 224.983324, 227.421444,
    229.337413, 231.250188, 231.987235, 233.693404, 236.524230
]

def miller_rabin(n, k=10):
    """Miller-Rabin primality test"""
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

    # Witnesses to test
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

def psi_from_zeros(x, num_zeros=50):
    """Chebyshev psi(x) from explicit formula using pre-computed zeros"""
    if x <= 1:
        return 0.0

    psi = float(x)

    for gamma in ZETA_ZEROS[:num_zeros]:
        rho = 0.5 + 1j * gamma
        term = (x ** rho) / rho
        psi -= 2 * term.real  # Conjugate pair contribution

    return psi

def psi_derivative(x, num_zeros=50, dx=0.01):
    """Numerical derivative of psi - peaks at prime powers"""
    return (psi_from_zeros(x + dx, num_zeros) - psi_from_zeros(x - dx, num_zeros)) / (2 * dx)

def neg_psi_deriv(x, num_zeros):
    """Negative derivative for minimization (minima = prime candidates)"""
    return -psi_derivative(x, num_zeros)

def find_prime_near_newton(target, num_zeros=50, search_width=20):
    """
    Use optimization to find prime candidates near target.
    Newton-like method finds peaks in psi'(x).
    """
    candidates = []

    # Search for local maxima of psi'(x) in [target - width, target + width]
    # By finding minima of -psi'(x)

    x_start = max(2, target - search_width)
    x_end = target + search_width

    # Coarse scan to find promising regions
    x_scan = np.linspace(x_start, x_end, 100)
    deriv_vals = [psi_derivative(x, num_zeros) for x in x_scan]

    # Find local maxima
    for i in range(1, len(deriv_vals) - 1):
        if deriv_vals[i] > deriv_vals[i-1] and deriv_vals[i] > deriv_vals[i+1]:
            if deriv_vals[i] > 0.5:  # Threshold for significance
                # Refine with Brent's method (Newton-like)
                try:
                    result = minimize_scalar(
                        lambda x: neg_psi_deriv(x, num_zeros),
                        bounds=(x_scan[i-1], x_scan[i+1]),
                        method='bounded'
                    )
                    candidates.append(int(round(result.x)))
                except:
                    candidates.append(int(round(x_scan[i])))

    return list(set(candidates))

def find_next_prime_fast(start, num_zeros=50):
    """Find the next prime after 'start' using Newton + Miller-Rabin"""
    x = start
    max_search = 1000

    for offset in range(0, max_search, 10):
        candidates = find_prime_near_newton(x + offset, num_zeros, search_width=15)

        for c in sorted(candidates):
            if c > start and miller_rabin(c):
                return c

    return None

def benchmark_bootstrap():
    """Compare bootstrap method vs naive search"""

    print("="*70)
    print("NEWTON'S LADDER PRIME BOOTSTRAP TEST")
    print("="*70)

    # Test 1: Find primes near various targets
    print("\n--- Test 1: Find primes near target ---\n")

    targets = [100, 500, 1000, 5000, 10000]

    for target in targets:
        print(f"Target: {target}")

        # Newton method
        t0 = time.time()
        candidates = find_prime_near_newton(target, num_zeros=50, search_width=30)
        verified = [c for c in candidates if miller_rabin(c)]
        t_newton = time.time() - t0

        # Naive: check every odd number
        t0 = time.time()
        naive_prime = None
        for n in range(target, target + 100):
            if miller_rabin(n):
                naive_prime = n
                break
        t_naive = time.time() - t0

        print(f"  Newton candidates: {sorted(candidates)[:5]}...")
        print(f"  Verified primes:   {sorted(verified)[:5]}")
        print(f"  Naive found:       {naive_prime}")
        print(f"  Newton time: {t_newton*1000:.2f}ms, Naive time: {t_naive*1000:.2f}ms")
        print()

    # Test 2: Bootstrap large primes
    print("\n--- Test 2: Bootstrap to large primes ---\n")
    print("Using only 50 pre-computed zeros (no prime sieve needed):\n")

    large_targets = [10000, 50000, 100000]

    for target in large_targets:
        t0 = time.time()
        candidates = find_prime_near_newton(target, num_zeros=80, search_width=50)
        verified = [c for c in candidates if miller_rabin(c)]
        elapsed = time.time() - t0

        # Find actual nearest prime for comparison
        actual_prime = target
        while not miller_rabin(actual_prime):
            actual_prime += 1

        if verified:
            closest = min(verified, key=lambda x: abs(x - target))
            error = abs(closest - actual_prime)
            print(f"  Target {target}: found {closest}, actual next prime {actual_prime}, error {error}")
        else:
            print(f"  Target {target}: no candidates found")
        print(f"  Time: {elapsed*1000:.1f}ms, Candidates: {len(candidates)}")
        print()

    # Test 3: Measure how many zeros needed
    print("\n--- Test 3: Zeros needed for accuracy ---\n")

    target = 1000
    actual_primes_near = [p for p in range(target-20, target+20) if miller_rabin(p)]

    for n_zeros in [10, 20, 30, 50, 80, 100]:
        candidates = find_prime_near_newton(target, num_zeros=n_zeros, search_width=25)
        verified = [c for c in candidates if miller_rabin(c)]

        # How many actual primes did we find?
        hits = len(set(verified) & set(actual_primes_near))

        print(f"  {n_zeros:3d} zeros: {len(candidates):2d} candidates, {len(verified):2d} verified, {hits}/{len(actual_primes_near)} actual primes found")

    print("\n" + "="*70)
    print("CONCLUSION")
    print("="*70)
    print("""
The Newton bootstrap method:

ADVANTAGES:
- No prime sieve needed - uses universal zero constants
- Jumps directly to target region (no sequential search)
- O(zeros × newton_iterations) vs O(N log log N) for sieve

LIMITATIONS:
- Explicit formula converges slowly (needs many zeros for large N)
- psi'(x) peaks are approximate (need verification)
- Not faster than Miller-Rabin on random candidates for finding ANY prime

BEST USE CASE:
- When you need primes in a SPECIFIC region
- When you want to avoid storing/computing a sieve
- For understanding prime distribution (educational)

The method IS incremental: more zeros = better resolution
""")

if __name__ == '__main__':
    benchmark_bootstrap()
