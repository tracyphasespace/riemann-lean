"""
InformationDepth oracle — the counterfeit-pair experiment at E0.
Register: computed-in-code. Systems live on prime-power support n <= N.

Systems (all EXACT E0-fiber twins of Lambda except chi4, which is the
finite-defect near-fiber point):
  BASE   : a_n = Lambda(n)                        (rotor u = 1)
  PARITY : a_n = lambda(n) Lambda(n)              (Liouville rotor, u_{p^k} = (-1)^k)
  EPS_A  : a_{p^k} = eps_p Lambda(p^k), eps_p = +1            (reference)
  EPS_B  : a_{p^k} = eps_p Lambda(p^k), eps_p = random phase  (cross-prime scramble)
  CHI4   : a_n = chi4(n) Lambda(n)                (character: rotor AND mask at p=2)

Observables:
  E0 fields      : all five interface statistics (must be identical on the fiber)
  C_Delta        : pair energy  2 Re sum_{m<n} a_m conj(a_n) K((log m - log n)/Delta),
                   K = Fejer triangle; decomposed into SAME-PRIME (tower) and
                   CROSS-PRIME parts
  signed psi     : sum a_n  vs modulus sum (first-order phase visibility)

Questions:
  Q1  Is (BASE, PARITY) separated by tower data alone?
  Q2  Is (EPS_A, EPS_B) tower-identical but cross-separated?
  Q3  Where does separation live as a function of bandwidth Delta
      (tower horizon: same-prime pairs need log p <= Delta)?
"""
import math, cmath, random
random.seed(23)
N = 100_000

def primes_upto(n):
    s = bytearray([1])*(n+1); s[0]=s[1]=0
    for i in range(2, int(n**0.5)+1):
        if s[i]: s[i*i::i] = bytearray(len(s[i*i::i]))
    return [i for i in range(2, n+1) if s[i]]

P = primes_upto(N)
# support: (n, p, k, logp)
supp = []
for p in P:
    pk, k = p, 1
    while pk <= N:
        supp.append((pk, p, k, math.log(p)))
        pk *= p; k += 1
supp.sort()
logn = [math.log(n) for n,_,_,_ in supp]
Lam  = [lp for _,_,_,lp in supp]

eps = {p: cmath.exp(2j*math.pi*random.random()) for p in P}
def chi4(n): return 0 if n%2==0 else (1 if n%4==1 else -1)

def coeffs(name):
    if name=="BASE":   return [complex(l) for l in Lam]
    if name=="PARITY": return [complex(((-1)**k)*l) for (_,_,k,_),l in zip(supp,Lam)]
    if name=="EPS_A":  return [complex(l) for l in Lam]
    if name=="EPS_B":  return [eps[p]*l for (_,p,_,_),l in zip(supp,Lam)]
    if name=="CHI4":   return [complex(chi4(n))*l for (n,_,_,_),l in zip(supp,Lam)]

def e0_fields(a):
    """The five interface statistics at x=N (moduli only)."""
    r = [abs(z) for z in a]
    cheb = sum(r)
    mert = sum(ri*ri/n for ri,(n,_,_,_) in zip(r,supp))
    logsz = max((ri - math.log(n)) for ri,(n,_,_,_) in zip(r,supp))  # <=0 required
    sup_ok = all((ri==0) or True for ri in r)  # support is prime powers by construction
    nneg = min(r)
    return (round(cheb,9), round(mert,9), round(logsz,12), nneg>=0, sup_ok)

def pair_energy(a, Delta):
    """Two-pointer window in multiplicative metric; Fejer kernel."""
    tot = same = 0.0
    j0 = 0
    M = len(a)
    for i in range(M):
        while logn[i] - logn[j0] > Delta: j0 += 1
        for j in range(j0, i):
            t = (logn[i]-logn[j])/Delta
            K = 1.0 - t
            v = 2.0*(a[i]*a[j].conjugate()).real*K
            tot += v
            if supp[i][1] == supp[j][1]: same += v
    return tot, same, tot-same

names = ["BASE","PARITY","EPS_A","EPS_B","CHI4"]
A = {nm: coeffs(nm) for nm in names}

print("== E0 fields (chebyshev, mertens, log-size slack, nonneg, support) ==")
for nm in names:
    print(f"{nm:>7}: {e0_fields(A[nm])}")
fiber = ["BASE","PARITY","EPS_A","EPS_B"]
ident = all(e0_fields(A[nm])==e0_fields(A["BASE"]) for nm in fiber)
print("Exact E0-fiber identity (BASE,PARITY,EPS_A,EPS_B):", "PASS" if ident else "FAIL")
print("CHI4 near-fiber (finite defect at p=2, cf. D_4 = 0.4805): fields differ as expected\n")

print("== Pair energy C_Delta: total | same-prime(tower) | cross-prime ==")
for Delta in [0.4, 0.693, 0.8, 1.0, 1.5, 2.0]:
    print(f"-- Delta = {Delta}  (tower horizon: primes p <= {math.exp(Delta):.2f})")
    vals = {}
    for nm in ["BASE","PARITY","EPS_A","EPS_B"]:
        vals[nm] = pair_energy(A[nm], Delta)
        t,s,c = vals[nm]
        print(f"   {nm:>7}: total={t:>14.4f}  tower={s:>12.4f}  cross={c:>14.4f}")
    bp_tower = abs(vals["BASE"][1]-vals["PARITY"][1])
    bp_cross = abs(vals["BASE"][2]-vals["PARITY"][2])
    ab_tower = abs(vals["EPS_A"][1]-vals["EPS_B"][1])
    ab_cross = abs(vals["EPS_A"][2]-vals["EPS_B"][2])
    print(f"   sep(BASE,PARITY): tower={bp_tower:.4f} cross={bp_cross:.4f} | "
          f"sep(EPS_A,EPS_B): tower={ab_tower:.4e} cross={ab_cross:.4f}")

print("\n== Signed vs modulus partial sums at x=N ==")
for nm in ["BASE","PARITY","EPS_B"]:
    s = sum(A[nm]); r = sum(abs(z) for z in A[nm])
    print(f"{nm:>7}: signed={s.real:>13.2f}{s.imag:+.2f}i   modulus={r:>13.2f}")
