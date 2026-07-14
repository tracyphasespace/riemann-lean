#!/usr/bin/env python3
"""Check residues 7 and 15 at higher moduli."""

def T(n):
    return n // 2 if n % 2 == 0 else (3 * n + 1) // 2

def trace_parity(n, steps):
    parities = []
    for _ in range(steps):
        parities.append('O' if n % 2 == 1 else 'E')
        n = T(n)
    return ''.join(parities), n

def compute_affine_from_parity(parity_word):
    a, b, d = 1, 0, 1
    for step in parity_word:
        if step == 'E':
            d *= 2
        else:
            a, b = 3 * a, 3 * b + d
            d *= 2
    return a, b, d

def find_uniform_certificate(modulus, residue, max_steps=50):
    n_min = residue if residue > 1 else modulus + residue
    reps = [n_min + k * modulus for k in range(4)]
    
    for steps in range(1, max_steps + 1):
        parities = [trace_parity(n, steps)[0] for n in reps]
        if len(set(parities)) == 1:
            parity_word = parities[0]
            a, b, d = compute_affine_from_parity(parity_word)
            
            all_match = True
            for n in reps:
                actual = trace_parity(n, steps)[1]
                expected = (a * n + b) // d
                if actual != expected:
                    all_match = False
                    break
            
            if all_match and a < d:
                if a * n_min + b < d * n_min:
                    return steps, a, b, d, parity_word
    return None

print("=== CHECKING 7 AND 15 AT HIGHER MODULI ===\n")

for base_residue in [7, 15]:
    print(f"Residue {base_residue} at different moduli:")
    for mod in [32, 64, 128, 256]:
        for offset in range(0, mod, 32):
            r = (base_residue + offset) % mod
            if r % 2 == 1 and r % 32 == base_residue:  # Same residue mod 32
                result = find_uniform_certificate(mod, r)
                if result:
                    steps, a, b, d, parity = result
                    print(f"  n ≡ {r:3d} (mod {mod}): steps={steps:2d}, ({a}n+{b})/{d}")
                    print(f"       Parity: {parity}, ratio={a/d:.4f}")
    print()

print("\n=== GENERATING LEAN CODE FOR MOD 64 ===\n")
for r in range(1, 64, 2):
    result = find_uniform_certificate(64, r, max_steps=30)
    if result:
        steps, a, b, d, parity = result
        n_min = r if r > 1 else 65
        if a * n_min + b < d * n_min:
            print(f"-- n ≡ {r} (mod 64): {steps} steps, parity={parity}")
            print(f"def cert_{r}_mod64 : Certificate := ⟨64, {r}, {steps}, ⟨{a}, {b}, {d}⟩⟩")
            print()
