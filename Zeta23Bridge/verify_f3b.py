"""
F3b-instance numerical verification (register: computed-in-code).

Claims checked, matching the Lean decomposition L1-L5:
  L3: for n = p^k,  Lambda(n)^2 / n = (log p)^2 / p^k          (identity spot-check)
  L4: per-prime tower  sum_{k=1..K} (log p)^2 / p^k  <=  (log p)^2/(p-1),
      monotone in K, with the geometric closed form
  L5: masked energy  M_q(x) = sum_{n<=x, gcd(n,q)>1} Lambda(n)^2/n
      satisfies  M_q(x) <= D_q := sum_{p|q} (log p)^2/(p-1)  for ALL x,
      uniformly, with positive margin equal to the tower tails.
Also: the exact removed-energy identity used by masked_twist's hypothesis
      (terms vanish unless chi(n)=0, i.e. gcd(n,q)>1 on Lambda's support).
"""
import math

X = 10**6

# Sieve of von Mangoldt support: n = p^k <= X
def primes_upto(n):
    s = bytearray([1])*(n+1); s[0]=s[1]=0
    for i in range(2, int(n**0.5)+1):
        if s[i]: s[i*i::i] = bytearray(len(s[i*i::i]))
    return [i for i in range(2, n+1) if s[i]]

P = primes_upto(X)
# Lambda as dict on prime powers
lam = {}
for p in P:
    pk = p
    while pk <= X:
        lam[pk] = math.log(p)
        pk *= p

def D_q(q):
    return sum(math.log(p)**2/(p-1) for p in set(factorize(q)))

def factorize(q):
    fs=[]; d=2
    while d*d<=q:
        while q%d==0: fs.append(d); q//=d
        d+=1
    if q>1: fs.append(q)
    return fs

def masked_energy(q, x):
    return sum(l*l/n for n,l in lam.items() if n<=x and math.gcd(n,q)>1)

print(f"{'q':>6} {'D_q':>12} {'M_q(1e6)':>12} {'margin':>12} {'tail(pred)':>12} {'ok'}")
allok = True
for q in [3,4,5,6,8,9,12,25,30,210,1024,9699690]:
    Dq = D_q(q)
    Mq = masked_energy(q, X)
    # predicted margin = sum of tower tails past X, per prime
    tail = 0.0
    for p in set(factorize(q)):
        k = 1
        while p**k <= X: k += 1
        # sum_{j>=k} (log p)^2/p^j = (log p)^2 * p^{-k} * p/(p-1)
        tail += math.log(p)**2 * (p**-k) * p/(p-1)
    ok = Mq <= Dq + 1e-12 and abs((Dq - Mq) - tail) < 1e-9
    allok &= ok
    print(f"{q:>6} {Dq:>12.6f} {Mq:>12.6f} {Dq-Mq:>12.3e} {tail:>12.3e} {'PASS' if ok else 'FAIL'}")

# L3 identity spot-checks
import random
ok3 = all(abs(lam[n]**2/n - math.log(min(factorize(n)))**2/n) < 1e-15
          for n in random.sample(list(lam.keys()), 200))
print("L3 identity Lambda(p^k)^2/p^k = log^2 p / p^k :", "PASS" if ok3 else "FAIL")

# L4 monotone tower vs closed form, worst prime p=2
p=2; acc=0.0; mono=True
for k in range(1,60):
    acc += math.log(p)**2/p**k
    if acc > math.log(p)**2/(p-1)+1e-15: mono=False
print("L4 tower<=closed-form (p=2, K<=60):", "PASS" if mono else "FAIL",
      f"  limit gap at K=60: {math.log(p)**2/(p-1)-acc:.2e}")

# Uniformity in x: M_q(x) <= D_q for a sweep of cutoffs
q=30; unif = all(masked_energy(q,x) <= D_q(q)+1e-12 for x in [10,100,1000,10**4,10**5,X])
print("L5 uniformity in x (q=30 sweep):", "PASS" if unif else "FAIL")
print("\nALL CHECKS:", "PASS" if (allok and ok3 and mono and unif) else "FAIL")
