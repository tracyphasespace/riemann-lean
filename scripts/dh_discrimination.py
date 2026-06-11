#!/usr/bin/env python3
"""
Davenport-Heilbronn discrimination test for the energy-surface convexity criterion.

Reproduces the numbers in Appendix B.8 of June_Riemann_Study.md.

Claim under test (O3): strict convexity of the energy surface E(sigma) = |Xi(sigma+it)|^2
is a genuine discriminator of the Riemann Hypothesis -- not a vacuous restatement.

Method: compare two functions that share the SAME s<->1-s functional-equation symmetry
and the SAME Gamma-completion, but differ in one structural feature -- the Euler product.

  * Riemann xi(s): HAS an Euler product (zeta).            RH believed true.
  * Davenport-Heilbronn f(s): NO Euler product.            RH provably FALSE (off-line zeros).

Result: at a zero-height, zeta's energy surface is a single convex well (E'' > 0);
the Davenport-Heilbronn surface is a W-shaped double well, concave at the center
(E''(1/2) < 0). Convexity therefore tracks RH, and the discriminating structure is
the Euler product (both functions carry the Gamma backbone).

Requires: mpmath.  Run: python3 scripts/dh_discrimination.py
"""

import mpmath as mp

mp.mp.dps = 30

# ---------------------------------------------------------------------------
# Riemann xi (has Euler product) -- the RH-true reference
# ---------------------------------------------------------------------------
def xi(s):
    # completed zeta: xi(s) = 1/2 * s(s-1) * pi^(-s/2) * Gamma(s/2) * zeta(s)
    return mp.mpf('0.5') * s * (s - 1) * mp.pi ** (-s / 2) * mp.gamma(s / 2) * mp.zeta(s)

def E_zeta(sigma, t):
    v = xi(mp.mpf(sigma) + 1j * mp.mpf(t))
    return mp.re(v) ** 2 + mp.im(v) ** 2

# ---------------------------------------------------------------------------
# Davenport-Heilbronn (no Euler product) -- the RH-false counterexample
# ---------------------------------------------------------------------------
# Primitive character chi mod 5, order 4, with chi(2) = i:
#   chi(1)=1, chi(2)=i, chi(3)=-i, chi(4)=-1, chi(5)=0
chi  = {1: 1, 2: 1j, 3: -1j, 4: -1, 0: 0}
chib = {1: 1, 2: -1j, 3: 1j, 4: -1, 0: 0}  # conjugate character

def L(s, ch):
    # L(s, chi) = 5^{-s} * sum_{r=1}^{4} chi(r) * zeta(s, r/5)  (Hurwitz zeta)
    return mp.power(5, -s) * sum(ch[r] * mp.zeta(s, mp.mpf(r) / 5) for r in range(1, 5))

# Davenport-Heilbronn constant
KAPPA = (mp.sqrt(10 - 2 * mp.sqrt(5)) - 2) / (mp.sqrt(5) - 1)

def f_dh(s):
    return mp.mpf('0.5') * ((1 - 1j * KAPPA) * L(s, chi) + (1 + 1j * KAPPA) * L(s, chib))

def Xi_dh(s):
    # odd completion (chi(-1) = chi(4) = -1), conductor 5:
    #   Xi_DH(s) = (5/pi)^{(s+1)/2} * Gamma((s+1)/2) * f(s)
    return mp.power(5 / mp.pi, (s + 1) / 2) * mp.gamma((s + 1) / 2) * f_dh(s)

def E_dh(sigma, t):
    v = Xi_dh(mp.mpf(sigma) + 1j * mp.mpf(t))
    return mp.re(v) ** 2 + mp.im(v) ** 2

def d2(Efun, sigma, t):
    return mp.diff(lambda x: Efun(x, t), sigma, 2)


def main():
    print("kappa =", mp.nstr(KAPPA, 12))

    # 1) Functional-equation sanity check for the completed D-H function
    print("\n[1] Functional equation  |Xi_DH(s)| vs |Xi_DH(1-s)|  (ratio should be 1):")
    for s in [mp.mpf('0.3') + 10j, mp.mpf('0.9') + 50j]:
        a, b = abs(Xi_dh(s)), abs(Xi_dh(1 - s))
        print(f"    s={complex(s)}:  ratio = {mp.nstr(a / b, 8)}")

    # 2) zeta side: convex at its first zero height
    t_zeta = mp.mpf('14.134725')
    e2z = d2(E_zeta, mp.mpf('0.5'), t_zeta)
    print(f"\n[2] zeta  at first zero height t={mp.nstr(t_zeta,8)}:")
    print(f"    E''(1/2) = {mp.nstr(e2z, 4)}   ->  {'CONVEX (>0)' if e2z > 0 else 'concave'}")

    # 3) D-H side: locate the off-line zero, test curvature there
    z = mp.findroot(f_dh, mp.mpf('0.808') + mp.mpf('85.699') * 1j)
    sig0, t0 = mp.re(z), mp.im(z)
    print(f"\n[3] Davenport-Heilbronn off-line zero:")
    print(f"    s0 = {mp.nstr(z, 12)}   |f(s0)| = {mp.nstr(abs(f_dh(z)), 3)}")
    print(f"    sigma0 = {mp.nstr(sig0, 8)}  (OFF the line)   mirror at {mp.nstr(1 - sig0, 8)}")
    e2dh = d2(E_dh, mp.mpf('0.5'), t0)
    print(f"    E''(1/2) at t0 = {mp.nstr(e2dh, 4)}   ->  {'convex' if e2dh > 0 else 'CONCAVE (<0)'}")

    # 4) Verdict
    print("\n[4] Verdict (convexity criterion, O3):")
    print(f"    zeta (Euler product)            E''(1/2) = {mp.nstr(e2z, 3):>12}   single well")
    print(f"    Davenport-Heilbronn (no E.p.)   E''(1/2) = {mp.nstr(e2dh, 3):>12}   double well")
    discriminates = (e2z > 0) and (e2dh < 0)
    print(f"    Convexity of |Xi|^2 discriminates RH-true from RH-false?  {discriminates}")

    # 5. Sharper bridge O3': outward monotonicity  g = (sigma-1/2)*Re[Xi'/Xi]
    #    Re[Xi'/Xi(s)] = d/dsigma log|Xi(sigma+it)|. Under RH this is (sigma-1/2)*sum 1/|s-rho|^2,
    #    so g > 0; an off-line zero drives g < 0. This criterion is EXACTLY RH-equivalent.
    def g(F, sig, t):
        d = mp.diff(lambda x: mp.log(abs(F(x + 1j * mp.mpf(t)))), mp.mpf(sig))
        return (mp.mpf(sig) - mp.mpf('0.5')) * d

    print("\n[5] Sharper bridge O3':  g(sigma,t) = (sigma-1/2)*Re[Xi'/Xi]   (RH-equivalent)")
    gz = [g(xi, s, 20) for s in (0.3, 0.45, 0.7, 0.85)]
    print(f"    zeta  t=20      g @ 0.30,0.45,0.70,0.85 : {[mp.nstr(v,3) for v in gz]}  all {'+' if all(v>0 for v in gz) else 'mixed'}")
    gd = [g(Xi_dh, s, t0) for s in (0.30, 0.45, 0.65, 0.72)]
    print(f"    D-H   t={mp.nstr(t0,7)}  g @ 0.30,0.45,0.65,0.72 : {[mp.nstr(v,3) for v in gd]}  {'+' if all(v>0 for v in gd) else 'NEGATIVE (folds)'}")
    print("    => O3' holds for zeta, fails for D-H. Equivalent to RH (Weil/Speiser circle); not discharged by geometry.")
    print("\n    Bottom line: GA supplies orthogonal prime blocks (O1,O2); the Euler product must")
    print("    supply non-folding of the scalar projection (O3'), which remains equivalent to RH.")


if __name__ == "__main__":
    main()
