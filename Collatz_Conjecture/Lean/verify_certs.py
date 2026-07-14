#!/usr/bin/env python3
"""Verify and compute Collatz affine certificates."""

def T(n):
    """Shortcut Collatz: T(n) = (3n+1)/2 if odd, n/2 if even."""
    if n % 2 == 0:
        return n // 2
    else:
        return (3 * n + 1) // 2

def iterate_T(n, k):
    """Apply T k times."""
    for _ in range(k):
        n = T(n)
    return n

def compute_affine_certificate(modulus, residue, max_steps=20):
    """
    Compute affine certificate for n ≡ residue (mod modulus).
    
    Returns (steps, a, b, d) such that T^steps(n) = (a*n + b) / d
    for all n ≡ residue (mod modulus).
    """
    # Try to find uniform path by checking two representatives
    n1 = residue if residue > 1 else modulus + residue
    n2 = n1 + modulus
    
    for steps in range(1, max_steps + 1):
        t1 = iterate_T(n1, steps)
        t2 = iterate_T(n2, steps)
        
        # If T^k is affine: T^k(n) = (a*n + b) / d
        # Then T^k(n2) - T^k(n1) = a * (n2 - n1) / d = a * modulus / d
        # So a/d = (t2 - t1) / modulus
        
        diff = t2 - t1
        if diff != 0:
            # Check if this is a valid affine relationship
            # a/d = diff/modulus, simplified
            from math import gcd
            g = gcd(abs(diff), modulus)
            a = diff // g * (modulus // modulus)  # This isn't quite right
            
            # Better: solve for a, b, d directly
            # T^k(n1) = (a * n1 + b) / d
            # T^k(n2) = (a * n2 + b) / d
            # Subtracting: t2 - t1 = a * (n2 - n1) / d = a * modulus / d
            
            # Try different denominators
            for d in [2**steps, 2**(steps-1), 2**(steps+1)]:
                a = (t2 - t1) * d // modulus
                if a * modulus == (t2 - t1) * d:
                    b = t1 * d - a * n1
                    if b >= 0 and (a * n1 + b) % d == 0 and (a * n1 + b) // d == t1:
                        # Verify with n2
                        if (a * n2 + b) // d == t2:
                            # Check contraction
                            if a < d:
                                return steps, a, b, d
    return None

def verify_descent(modulus, residue, steps, a, b, d):
    """Verify the certificate produces descent."""
    # Check minimal representative
    n_min = residue if residue > 1 else (modulus if residue == 0 else modulus + 1)
    
    # Check contraction: a < d
    if a >= d:
        return False, f"Not contracting: a={a} >= d={d}"
    
    # Check descent: (a*n + b)/d < n for n >= n_min
    # Equivalent to: a*n + b < d*n, i.e., b < (d-a)*n
    if b >= (d - a) * n_min:
        return False, f"Descent fails at n_min={n_min}: b={b} >= (d-a)*n_min={(d-a)*n_min}"
    
    # Verify actual trajectory matches
    n1 = n_min
    n2 = n1 + modulus
    t1 = iterate_T(n1, steps)
    t2 = iterate_T(n2, steps)
    
    expected1 = (a * n1 + b) // d
    expected2 = (a * n2 + b) // d
    
    if t1 != expected1:
        return False, f"Trajectory mismatch at n={n1}: T^{steps}={t1}, formula={(a*n1+b)}/{d}={expected1}"
    if t2 != expected2:
        return False, f"Trajectory mismatch at n={n2}: T^{steps}={t2}, formula={(a*n2+b)}/{d}={expected2}"
    
    return True, f"Valid: T^{steps}(n) = ({a}n + {b})/{d}, contraction ratio = {a}/{d} = {a/d:.4f}"

# Certificates from Lean code
lean_certs = [
    (2, 0, 1, 1, 0, 2, "cert_even"),
    (4, 1, 4, 9, 2, 16, "cert_1_mod4"),
    (16, 3, 5, 9, 5, 16, "cert_3_mod16"),
    (8, 5, 5, 9, 2, 16, "cert_5_mod8"),
    (32, 7, 11, 81, 65, 128, "cert_7_mod32"),
    (16, 9, 4, 9, 2, 16, "cert_9_mod16"),
    (32, 11, 8, 27, 23, 32, "cert_11_mod32"),
    (16, 13, 5, 9, 2, 16, "cert_13_mod16"),
    (32, 15, 11, 81, 61, 128, "cert_15_mod32"),
    (32, 23, 8, 27, 19, 32, "cert_23_mod32"),
]

print("=== VERIFYING LEAN CERTIFICATES ===\n")
for modulus, residue, steps, a, b, d, name in lean_certs:
    valid, msg = verify_descent(modulus, residue, steps, a, b, d)
    status = "✓" if valid else "✗"
    print(f"{status} {name}: mod {modulus}, r={residue}")
    print(f"   {msg}\n")

print("\n=== COMPUTING FRESH CERTIFICATES ===\n")
for r in [3, 7, 11, 15, 19, 23, 27, 31]:
    result = compute_affine_certificate(32, r)
    if result:
        steps, a, b, d = result
        print(f"n ≡ {r} (mod 32): T^{steps}(n) = ({a}n + {b})/{d}")
        valid, msg = verify_descent(32, r, steps, a, b, d)
        print(f"   {msg}\n")
    else:
        # Try trajectory-based verification instead
        n_test = r if r > 4 else 32 + r
        for k in range(1, 200):
            if iterate_T(n_test, k) < n_test:
                print(f"n ≡ {r} (mod 32): Descent at step {k} (no uniform affine certificate found)")
                break
        print()
