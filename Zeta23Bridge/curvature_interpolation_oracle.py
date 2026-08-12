"""
F8 curvature interpolation oracle — Experiment 2 (see
experiments/EXPERIMENT_2_CurvatureInterpolation.md for the frozen design
and preregistered outcomes; run AFTER committing the design).

Family: F_t = (1-t) L(s,chi) + t f_DH(s), chi mod 5 with chi(2)=i.
Observables: curvature K(t); off-line winding counts in LEFT/RIGHT boxes
up to T=120; T_first hunts to T=360 when the count is 0.
"""
import math, sys, time
from mpmath import mp, mpc, mpf, zeta, sqrt, power

mp.dps = 12
KAPPA = (sqrt(10 - 2 * sqrt(5)) - 2) / (sqrt(5) - 1)

CHI = {1: mpc(1, 0), 2: mpc(0, 1), 3: mpc(0, -1), 4: mpc(-1, 0)}


def chi(n):
    return CHI.get(n % 5, mpc(0, 0))


_lcache = {}


def Lpair(s):
    """(L(s,chi), L(s,chibar)) via Hurwitz zeta, cached."""
    key = (round(float(s.real), 9), round(float(s.imag), 9))
    if key in _lcache:
        return _lcache[key]
    zs = [zeta(s, mpf(a) / 5) for a in (1, 2, 3, 4)]
    p5 = power(5, -s)
    L = p5 * (CHI[1] * zs[0] + CHI[2] * zs[1] + CHI[3] * zs[2] + CHI[4] * zs[3])
    Lb = p5 * (CHI[1].conjugate() * zs[0] + CHI[2].conjugate() * zs[1]
               + CHI[3].conjugate() * zs[2] + CHI[4].conjugate() * zs[3])
    _lcache[key] = (L, Lb)
    return (L, Lb)


def alpha(t):
    return (1 - t) + t * (1 - 1j * complex(KAPPA)) / 2


def beta(t):
    return t * (1 + 1j * complex(KAPPA)) / 2


def F(t, s):
    L, Lb = Lpair(s)
    return mpc(alpha(t)) * L + mpc(beta(t)) * Lb


# ---------------- curvature ----------------

def curvature(t, MN=3000):
    a, b = alpha(t), beta(t)

    def c(n):
        z = chi(n)
        return a * complex(z) + b * complex(z).conjugate()

    tot = 0.0
    d23 = abs(c(6) - c(2) * c(3)) ** 2
    m = 2
    while m * 2 <= MN:
        n = 2
        while m * n <= MN:
            if math.gcd(m, n) == 1:
                tot += abs(c(m * n) - c(m) * c(n)) ** 2 / (m * n)
            n += 1
        m += 1
    return tot, d23


# ---------------- winding ----------------

def winding_rect(t, s_lo, s_hi, T_lo, T_hi, step=0.05, minlen=1e-4):
    corners = [mpc(s_lo, T_lo), mpc(s_hi, T_lo), mpc(s_hi, T_hi), mpc(s_lo, T_hi)]
    pts = []
    for i in range(4):
        a, b = corners[i], corners[(i + 1) % 4]
        nseg = max(2, int(abs(b - a) / step))
        for j in range(nseg):
            pts.append(a + (b - a) * j / nseg)
    pts.append(pts[0])
    vals = [F(t, s) for s in pts]
    total = 0.0
    stack = [(pts[i], pts[i + 1], vals[i], vals[i + 1]) for i in range(len(pts) - 1)]
    evals = len(pts)
    while stack:
        a, b, fa, fb = stack.pop()
        if abs(fa) == 0 or abs(fb) == 0:
            raise RuntimeError("zero on boundary")
        r = fb / fa
        d = math.atan2(float(r.imag), float(r.real))
        if abs(d) > 1.0 and abs(b - a) > minlen:
            m = (a + b) / 2
            fm = F(t, m)
            evals += 1
            stack.append((a, m, fa, fm))
            stack.append((m, b, fm, fb))
        else:
            total += d
    w = total / (2 * math.pi)
    if abs(w - round(w)) > 0.2:
        return None, evals
    return int(round(w)), evals


def first_offline(t, s_lo, s_hi, T_lo, T_hi):
    """Bisect in T to localize the lowest off-line zero to a strip <= 5."""
    while T_hi - T_lo > 5:
        mid = (T_lo + T_hi) / 2
        w, _ = winding_rect(t, s_lo, s_hi, T_lo, mid)
        if w is None:
            return (T_lo, T_hi, "UNRELIABLE")
        if w > 0:
            T_hi = mid
        else:
            T_lo = mid
    return (T_lo, T_hi, "ok")


# ---------------- run ----------------

TGRID = [0.0, 0.05, 0.15, 0.3, 0.6, 1.0]
EPS = 0.02
T_BASE = 120.0
T_EXT = 360.0

print("== K(t) curvature (pairs mn<=3000, weight 1/mn) ==", flush=True)
kvals = {}
for t in TGRID:
    K, d23 = curvature(t)
    kvals[t] = K
    rat = K / t ** 2 if t > 0 else float("nan")
    print(f"  t={t:<5} K={K:.6f}  |D(2,3)|^2={d23:.6f}  K/t^2={rat:.6f}",
          flush=True)

print("\n== off-line winding counts, boxes [0.52,1.50] / [-0.50,0.48] x "
      f"[2,{T_BASE}] ==", flush=True)
for t in TGRID:
    t0 = time.time()
    _lcache.clear()
    wR, eR = winding_rect(t, 0.5 + EPS, 1.5, 2.0, T_BASE)
    wL, eL = winding_rect(t, -0.5, 0.5 - EPS, 2.0, T_BASE)
    msg = (f"  t={t:<5} N_right={wR}  N_left={wL}  "
           f"(evals {eR}+{eL}, {time.time()-t0:.0f}s)")
    print(msg, flush=True)
    if wR and wR > 0:
        lo, hi, st = first_offline(t, 0.5 + EPS, 1.5, 2.0, T_BASE)
        print(f"          first right-zero strip: [{lo:.1f},{hi:.1f}] ({st})",
              flush=True)
    elif wR == 0:
        wX, eX = winding_rect(t, 0.5 + EPS, 1.5, T_BASE, T_EXT, step=0.05)
        print(f"          extended hunt [{T_BASE},{T_EXT}]: N_right={wX} "
              f"(evals {eX})", flush=True)
        if wX and wX > 0:
            lo, hi, st = first_offline(t, 0.5 + EPS, 1.5, T_BASE, T_EXT)
            print(f"          first right-zero strip: [{lo:.1f},{hi:.1f}] "
                  f"({st})", flush=True)

print("\nDone.", flush=True)
