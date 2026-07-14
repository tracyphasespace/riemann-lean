#!/usr/bin/env python3
"""Compute correct Collatz certificates by tracking parity patterns."""

def T(n):
    """Shortcut Collatz."""
    return n // 2 if n % 2 == 0 else (3 * n + 1) // 2

def trace_parity(n, steps):
    """Return parity sequence for n over steps iterations."""
    parities = []
    for _ in range(steps):
        parities.append('O' if n % 2 == 1 else 'E')
        n = T(n)
    return ''.join(parities), n

def compute_affine_from_parity(parity_word):
    """Compute (a, b, d) from parity word."""
    a, b, d = 1, 0, 1
    for step in parity_word:
        if step == 'E':
            d *= 2
        else:  # 'O'
            a, b = 3 * a, 3 * b + d
            d *= 2
    return a, b, d

def find_uniform_certificate(modulus, residue, max_steps=200):
    """Find a uniform affine certificate for residue class."""
    # Get representatives
    n_min = residue if residue > 1 else modulus + residue
    
    # Check first few representatives for shared parity prefix
    reps = [n_min + k * modulus for k in range(4)]
    
    for steps in range(1, max_steps + 1):
        # Get parity words for all reps
        parities = [trace_parity(n, steps)[0] for n in reps]
        
        # Check if all have same parity word
        if len(set(parities)) == 1:
            parity_word = parities[0]
            a, b, d = compute_affine_from_parity(parity_word)
            
            # Verify on all reps
            all_match = True
            for n in reps:
                actual = trace_parity(n, steps)[1]
                expected = (a * n + b) // d
                if actual != expected:
                    all_match = False
                    break
            
            if all_match and a < d:
                # Check descent condition
                if a * n_min + b < d * n_min:
                    return steps, a, b, d, parity_word
    
    return None

def verify_certificate(modulus, residue, steps, a, b, d):
    """Verify certificate on multiple values."""
    n_min = residue if residue > 1 else modulus + residue
    results = []
    for k in range(5):
        n = n_min + k * modulus
        actual = n
        for _ in range(steps):
            actual = T(actual)
        expected = (a * n + b) // d
        match = actual == expected
        descent = expected < n
        results.append((n, actual, expected, match, descent))
    return results

print("=== COMPUTING CORRECT CERTIFICATES FOR ALL ODD RESIDUES MOD 32 ===\n")

certificates = []
for r in range(1, 32, 2):  # Odd residues only
    result = find_uniform_certificate(32, r)
    if result:
        steps, a, b, d, parity = result
        print(f"n ≡ {r:2d} (mod 32): steps={steps:2d}, a={a:6d}, b={b:6d}, d={d:6d}")
        print(f"   Parity: {parity}")
        print(f"   Contraction: {a}/{d} = {a/d:.4f}")
        
        # Verify
        verif = verify_certificate(32, r, steps, a, b, d)
        all_ok = all(m and desc for n, act, exp, m, desc in verif)
        print(f"   Verified: {'✓' if all_ok else '✗'}")
        
        if all_ok:
            certificates.append((r, steps, a, b, d))
        print()
    else:
        # Find descent step for verification
        n = r if r > 4 else 32 + r
        for k in range(1, 200):
            if trace_parity(n, k)[1] < n:
                print(f"n ≡ {r:2d} (mod 32): No uniform certificate (descent at step {k})")
                break
        print()

print("\n=== LEAN CODE FOR VERIFIED CERTIFICATES ===\n")
for r, steps, a, b, d in certificates:
    print(f"-- n ≡ {r} (mod 32): {steps} steps → ({a}n + {b})/{d}")
    print(f"def cert_{r}_mod32 : Certificate := ⟨32, {r}, {steps}, ⟨{a}, {b}, {d}⟩⟩")
    print()
