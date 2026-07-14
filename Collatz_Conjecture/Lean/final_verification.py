#!/usr/bin/env python3
"""Final verification of all certificates."""

def T(n):
    return n // 2 if n % 2 == 0 else (3 * n + 1) // 2

def verify_cert(modulus, residue, steps, a, b, d):
    """Verify certificate on multiple values."""
    n_min = residue if residue > 1 else modulus + residue
    
    # Check contraction
    if a >= d:
        return False, f"Not contracting: {a} >= {d}"
    
    # Check descent at n_min
    val = (a * n_min + b) // d
    if val >= n_min:
        return False, f"No descent at n_min={n_min}: ({a}*{n_min}+{b})/{d} = {val}"
    
    # Verify trajectory matches formula for several values
    for k in range(5):
        n = n_min + k * modulus
        actual = n
        for _ in range(steps):
            actual = T(actual)
        expected = (a * n + b) // d
        if actual != expected:
            return False, f"Mismatch at n={n}: T^{steps}={actual}, formula={expected}"
    
    return True, f"OK: T^{steps}(n) = ({a}n+{b})/{d}, ratio={a/d:.4f}"

# New verified certificates from CertificateTable.lean
certs = [
    (2, 0, 1, 1, 0, 2, "cert_even"),
    (32, 1, 2, 3, 1, 4, "cert_1_mod32"),
    (32, 3, 4, 9, 5, 16, "cert_3_mod32"),
    (32, 5, 2, 3, 1, 4, "cert_5_mod32"),
    (128, 7, 7, 81, 73, 128, "cert_7_mod128"),
    (32, 9, 2, 3, 1, 4, "cert_9_mod32"),
    (32, 11, 5, 27, 23, 32, "cert_11_mod32"),
    (32, 13, 2, 3, 1, 4, "cert_13_mod32"),
    (128, 15, 7, 81, 65, 128, "cert_15_mod128"),
    (32, 17, 2, 3, 1, 4, "cert_17_mod32"),
    (32, 19, 4, 9, 5, 16, "cert_19_mod32"),
    (32, 21, 2, 3, 1, 4, "cert_21_mod32"),
    (32, 23, 5, 27, 19, 32, "cert_23_mod32"),
    (32, 25, 2, 3, 1, 4, "cert_25_mod32"),
    (32, 29, 2, 3, 1, 4, "cert_29_mod32"),
]

print("=== FINAL CERTIFICATE VERIFICATION ===\n")
all_pass = True
for modulus, residue, steps, a, b, d, name in certs:
    ok, msg = verify_cert(modulus, residue, steps, a, b, d)
    status = "✓" if ok else "✗"
    print(f"{status} {name}: {msg}")
    if not ok:
        all_pass = False

print()
if all_pass:
    print("✓ ALL CERTIFICATES VERIFIED")
else:
    print("✗ SOME CERTIFICATES FAILED")

# Summary table
print("\n=== CERTIFICATE SUMMARY ===\n")
print("| Residue | Modulus | Steps | Parity | Map | Ratio |")
print("|---------|---------|-------|--------|-----|-------|")
patterns = {
    (3, 1, 4): "OE",
    (9, 5, 16): "OOEE",
    (27, 23, 32): "OOEOE",
    (27, 19, 32): "OOOEE",
    (81, 73, 128): "OOOEOEE",
    (81, 65, 128): "OOOOEEE",
    (1, 0, 2): "E",
}
for modulus, residue, steps, a, b, d, name in certs:
    parity = patterns.get((a, b, d), "?")
    print(f"| {residue:7d} | {modulus:7d} | {steps:5d} | {parity:6s} | ({a}n+{b})/{d} | {a/d:.4f} |")
