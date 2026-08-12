# The Two-Thirds Theorem in Cl(N,N): Hyperbolic Zero Pairs, Outward Bivectors, and Inertia Counting

**Tracy McSheery, with Claude (Anthropic) — August 12, 2026**

**Status: dictionary and reformulation paper.** This document proves no new analytic theorem. It rebuilds, in the split-signature geometric-algebra language of the Geometry-of-the-Sieve program (McSheery 2026a,b), the unconditional result of

> Claude (Anthropic), *"More than two thirds of the zeros of the Riemann zeta function lie on the critical line,"* August 10, 2026. Paper: `https://www-cdn.anthropic.com/564f962e60643842f5fcb4a17c9dbc8f608f1c37.pdf`. Lean 4 formalization: `https://github.com/anthropics/zeta-23-lean` (sorry-free; axioms `propext`, `Classical.choice`, `Quot.sound` only).

hereafter **[Z23]**, which proves unconditionally

$$\liminf_{T\to\infty}\frac{N_0^*(T,2T)}{N(T,2T)} \;\ge\; \frac23, \qquad
\liminf_{T\to\infty}\frac{N_0^s(T,2T)}{N(T,2T)} \;\ge\; \frac23, \qquad
\liminf_{T\to\infty}\frac{N_d(T,2T)}{N(T,2T)} \;\ge\; \frac56,$$

and, with the optimal (Montgomery–Taylor) window,

$$\frac32-\frac{1}{\sqrt2}\cot\frac{1}{\sqrt2} \;=\; 0.67250\ldots \quad\text{(on-line, distinct; and simple-on-line)}, \qquad 0.83625\ldots \quad\text{(distinct)}.$$

This is the largest single improvement in the history of the critical-line proportion problem (Selberg 1942: positive proportion; Levinson 1974: $1/3$; Conrey 1989: $2/5$; Pratt–Robles–Zaharescu–Zeindler 2020: $5/12 = 0.4166\ldots$), by a method that abandons Levinson-style mollifiers entirely. The purpose here is to show that the method is, almost line for line, an **inertia computation in a split-signature Clifford algebra** — the arena the Sieve program has been working in — and to state precisely which of the program's design principles the proof vindicates, which it corrects, and where its ceiling sits.

---

## 1. The one-sentence translation

**[Z23] proves that at least two thirds of the directions of a certain prime-built real quadratic space are positive struts, by showing that the hyperbolic planes — one per off-line zero pair, each carrying an outward bivector with $B^2 = +1$ — are too expensive to fill more than a third of it.**

The single most important structural fact, and the reversal the Sieve program must absorb:

> **In the working proof, the orthogonal hyperbolic planes belong to the *off-line zero pairs*, not to the primes. The primes do not span dimensions; they pay for the metric.**

---

## 2. The arena: Weil's form as a Krein metric

For test functions $f,g \in C_c^2(\mathbb{R})$ define Weil's Hermitian form over the nontrivial zeros $\rho = \beta + i\gamma$ (written $\gamma_\rho = (\rho-\tfrac12)/i$, so $\gamma_\rho \in \mathbb{R}$ iff $\beta = \tfrac12$):

$$W(f,g) \;=\; \sum_{\rho} m_\rho\, \hat f(\gamma_\rho)\,\overline{\hat g(\gamma_\rho)}.$$

Positivity of $W$ on all of $C_c^2$ is *equivalent to RH* (Weil 1952; Bombieri 2000; Yoshida 1992). Unconditionally, $W$ is an **indefinite** Hermitian form — a Krein-space metric. This is exactly the "real Hilbert space with indefinite (Krein) metric" of the Sieve program's Appendix B (McSheery 2026a, §B revision; 2026b, §2), and it is no coincidence: the discovery narrative of [Z23, Appendix C] records that the argument was found by an agent investigating the **Pontryagin index of Weil's form as a Kreĭn-space object**. The upper-bound route it was sent to check was vacuous; the *dual* bookkeeping — counting positive squares by Sylvester's law of inertia — produced the theorem.

By the explicit formula (Weil, in the normalization of [Z23, §2]), the same form is computable from primes:

$$W(f,g) \;=\; \int_{\mathbb{R}} \hat f(\tau)\,\hat g(\tau)\; \nu_X(\tau)\, d\tau,
\qquad \nu_X = \mu + \Pi_X + P_X,$$

where $\mu$ is the archimedean (Stirling) density, $\Pi_X$ the pole term, and

$$P_X(\tau) = -\frac{1}{\pi}\sum_{n \le X}\frac{\Lambda(n)}{\sqrt n}\cos(\tau \log n)$$

is the prime-power density — the von Mangoldt projector of the Sieve program, now acting as a **metric density**, with sponge horizon $X = (T/2\pi)^\lambda$, $\lambda \le 1$. Note $\nu_X$ is genuinely negative on sets of positive measure: the indefiniteness is real, and everything below is real-algebra bookkeeping of that indefiniteness. Everything is real; no complex structure is used beyond packaging.

## 3. The compression: a finite quadratic space

Fix the window $I = [T, 2T]$, $\ell = \log(T/2\pi)$, $L = \lambda \ell$, and take the Gabor family at critical density,

$$f_k(u) = \varphi(u)\,e^{-i\tau_k u}, \qquad \tau_k = T + \frac{2\pi k}{L}, \quad 0 \le k < d = \Big\lfloor \frac{LT}{2\pi} \Big\rfloor,$$

with $\varphi$ a fixed taper supported in $[-L/2, L/2]$. The Gram matrix

$$G_{kl} = W(f_k, f_l) = \sum_\rho m_\rho\, \hat\varphi(\gamma_\rho - \tau_k)\,\hat\varphi(\gamma_\rho - \tau_l)$$

is **real symmetric** (the zero multiset is invariant under $\rho \mapsto 1-\bar\rho$), of size $d \approx \lambda N$ where $N = N(T,2T)$. The pair $(\mathbb{R}^d, G)$ is a finite real quadratic space of some signature $(n_+, n_-)$; its natural geometric-algebra home is $Cl(n_+, n_-) \subset Cl(N,N)$ for $N$ large. The whole theorem is a two-moment computation of the inertia of this space.

Two features the Sieve program should recognize:

- **The dimensions are frequency samples, not primes.** $d \approx \lambda N$ test functions tile the window at the critical (Nyquist-type) density $2\pi/L$; the Poisson–Gabor identity $\sum_{k\in\mathbb{Z}} \hat\varphi(\tau-\tau_k)\hat\varphi(\tau'-\tau_k) = L\,\Phi(\tau-\tau')$ [Z23, Lemma 2.2] plays the role the orthonormality of prime planes played upstairs. This is the corrected version of "each dimension is a larger prime": the count of usable orthogonal directions is set by *bandwidth times window length*, and the certificate can never exceed $d = \lambda_1 N$ directions [Z23, Prop. 7.4] — a pure dimension count, exactly in the spirit of the sponge's dimension growth, but with samples in place of primes.
- **No orthonormalization is needed or wanted.** The Gram matrix of the family in $L^2$ is badly conditioned (Szegő), but inertia is a coordinate-free invariant of the *form*, so the proof works in raw coefficient coordinates [Z23, Remark 2.3]. Sylvester's law is doing the work that "enforced orthonormality" did rhetorically in the Sieve papers.

### 3.1 Eliminating the imaginary unit: rotor modulation (the Cl(3,3) phase-space move)

One piece of complex packaging remains in the family as written: the modulation $e^{-i\tau_k u}$. It is eliminated by exactly the move of the Cl(3,3) $(+\!+\!+\,-\!-\!-)$ phase-space framework: **the "$i$" of each frequency sample is a compact bivector.** Assign sample $k$ a Euclidean phase plane $H_k = \mathrm{span}\{a_k, b_k\} \cong Cl(2,0)$, $a_k^2 = b_k^2 = +1$, with unit bivector $\mathcal{B}_k = a_k b_k$, $\mathcal{B}_k^2 = -1$, and replace the complex modulation by the rotor

$$e^{-i\tau_k u} \;\longrightarrow\; R_k(u) = \exp(-\mathcal{B}_k\, \tau_k u),$$

i.e., work with the real family $\{\varphi(u)\cos(\tau_k u),\; \varphi(u)\sin(\tau_k u)\}_{0\le k<d}$ spanning a $2d$-dimensional real space. A complex Hermitian form of signature $(a,b)$, viewed as a real symmetric form on the underlying real space, has signature $(2a, 2b)$: every count on both sides of the ledger doubles, and every inequality of §§4–6 carries through verbatim with the factor 2 cancelling in the ratios. ([Z23] takes a shortcut to the same place: its $G$ is already real symmetric on $\mathbb{R}^d$ because the zero multiset is invariant under $\rho \mapsto 1-\bar\rho$; the condensed note's window $\varphi_T$ and matrix $W_T$ are real throughout.)

The real picture that results is precisely the mixed-signature phase space of the Cl(3,3) framework, with the two kinds of plane playing the two roles that $(+\!+\!+\,-\!-\!-)$ provides:

| Plane type | Algebra | Bivector | Role |
|---|---|---|---|
| Phase planes $H_k$ (frequency samples) | $Cl(2,0)$, Euclidean | $\mathcal{B}_k^2 = -1$ (rotation) | carry the oscillation $\cos/\sin(\tau_k u)$ — the Zeta Motor's compact rotors |
| Zero-pair planes $H_\rho$ (off-line pairs, §4) | $Cl(1,1)$, split | $B_\rho^2 = +1$ (boost) | carry the instability — the hyperbolic tax |

No element with $x^2 = -1$ is ever adjoined as a scalar: rotations come from compact bivectors, "imaginary" phase evolution is rotor action in a real plane, and the indefiniteness that encodes off-line zeros comes from split bivectors. Everything — test functions, Gram matrix, struts, hyperbolic blocks, inertia counts, prime-side moments — is real. This completes the elimination of complex numbers that the Sieve program's Cl(3,3) treatment prescribed, now wrapped around a theorem rather than a framework.

## 4. The zero side: struts and hyperbolic planes

Split the zeros with ordinates in (a slight enlargement of) the window into:

- $\mathcal{S}$: distinct **on-line** points ($\beta = \tfrac12$), $s = \#\mathcal{S}$, of which $s_1$ simple and $s_2$ multiple;
- $\mathcal{P}$: **off-line pairs** $\{\rho, 1-\bar\rho\}$, $\beta \ne \tfrac12$, $p = \#\mathcal{P}$ (the functional equation pairs them with equal multiplicities);

so that, with multiplicity, $N \ge s_1 + 2s_2 + 2p$. Evaluation at zeros defines a linear map $A: \mathbb{R}^d \to \mathbb{R}^{s} \oplus \mathbb{R}^{2p}$, and the compressed form factors through it:

$$c^\ast G c \;=\; (\mathcal{Q}\circ A)(c), \qquad
\mathcal{Q} \;=\; \underbrace{\perp_{\rho \in \mathcal{S}} \; m_\rho\,\langle x\rangle^2}_{\text{positive struts}} \;\perp\; \underbrace{\perp_{\{\rho,1-\bar\rho\} \in \mathcal{P}} \; 2m_\rho\,xy}_{\text{hyperbolic planes}}.$$

**The strut.** An on-line zero has $\gamma_\rho \in \mathbb{R}$, so its column $u_\rho = (\hat\varphi(\gamma_\rho - \tau_k))_k$ is a *real* vector and contributes $m_\rho u_\rho u_\rho^{\mathsf T} \succeq 0$: a grade-1 positive direction. In calibrated units (the $\widehat G = G/aL^2$ normalization), the full-grid Poisson identity gives each strut trace exactly $m_\rho$ — the struts are unit-stiffness struts.

**The hyperbolic plane.** An off-line pair $\{\rho, 1-\bar\rho\}$ has $\gamma_{1-\bar\rho} = \overline{\gamma_\rho}$, and its two summands combine to the real 2×2 block

$$m_\rho \begin{pmatrix} 0 & 1 \\ 1 & 0 \end{pmatrix}
\quad\text{in coordinates } (x,y) = (\ell_{\gamma_\rho}(c),\, \ell_{\bar\gamma_\rho}(c)),$$

with eigenvalues $\pm m_\rho$: **signature $(1,1)$** — Witt's hyperbolic plane $H$. In geometric-algebra terms this is precisely a split plane $\mathrm{span}\{e_\rho, f_\rho\} \cong Cl(1,1)$ with $e_\rho^2 = +1$, $f_\rho^2 = -1$, **outward bivector** $B_\rho = e_\rho f_\rho$, $B_\rho^2 = +1$ (a boost generator, not a rotation), whose null directions are the two evaluation axes. Distinct pairs occupy $\mathcal{Q}$-orthogonal planes upstairs, so their bivectors commute: $[B_\rho, B_{\rho'}] = 0$. This is the Vanishing Commutator theorem of the Sieve program (McSheery 2026a, Thm 2.1) — **applied to zero pairs instead of primes**. The "ideal gas of free rotors" is real; its particles turned out to be the off-line pairs.

**The two inertia facts.** Upstairs, $\mathcal{Q}$ is an orthogonal (Witt) sum, so trivially

$$n_+(\mathcal{Q}) = s_1 + s_2 + p, \qquad \operatorname{rank}(\text{strut part}) \le s_1 + s_2.$$

Downstairs, the physical matrix is the **shadow** (pull-back) $\mathcal{Q}\circ A$, and the only lemma needed is [Z23, Lemma 3.1]:

$$n_+(\mathcal{Q}\circ A) \;\le\; n_+(\mathcal{Q}),$$

with *no* injectivity or independence assumption on $A$ — coincident heights, near-line pairs, degenerate evaluations are all harmless.

**This resolves the B.6 spiral objection at the population level.** The June study's spiral counterexample (McSheery 2026b, §B.6) correctly showed that a shadow of a convex outward trajectory can fold — pointwise convexity does not survive projection, which is why O3′ could not be discharged geometrically. The inertia lemma is the statement that survives: **a shadow can fold individual directions, but it can never manufacture more positive directions than the object upstairs possesses.** Positive index is monotone under projection; curvature is not. That is the exact conceptual pivot from the Sieve program's pointwise accounting (O3′, equivalent to RH, open) to the population accounting of [Z23] (unconditional, $2/3$). The outward-bivector design principle — "each new orthogonal plane wraps the existing space and cannot fold back" — is *true in the Witt decomposition upstairs by construction*, and what it buys downstairs is not impossibility of folding but an **inequality**: at most $p$ positive directions can come from the pairs, so at least $n_+ - p$ must come from on-line struts.

## 5. The prime side: the sponge pays the trace

The zeros are never located individually. Instead the two moments of $\widetilde G = G/L$ are computed from the prime side of the explicit formula, unconditionally [Z23, §5], for bandwidth $\lambda \le 1$:

$$\operatorname{tr} \widehat G = N\,(1 + o(1)), \qquad
\|\widehat G\|_F^2 = \Big(\frac{1}{\lambda} + \frac{\lambda}{3}\Big) N\,(1+o(1)).$$

Three ingredients, each with a Sieve-program reading:

1. **Archimedean density** $\mu$: contributes the mean zero density (Riemann–von Mangoldt) — the "volume" of the window in zero units.
2. **Prime diagonal**: the second moment's main arithmetic term is $\displaystyle\frac{T}{\pi}\sum_{n\le X}\frac{\Lambda(n)^2}{n}\,g(\log n) \sim \frac{TL^3}{6\pi}$, driven by $\sum_{n \le X} \Lambda(n)^2/n = \tfrac12 L^2 + O(L)$ — the **log-weighted Mertens energy**. This is the Sieve program's sponge criticality one derivative up: the program's $Q(\tfrac12) = \sum_p p^{-1} = -\log(\text{surviving sponge volume})$ (Mertens II/III; McSheery 2026a §5.4.2) is the unweighted shadow of exactly this sum. The barely-divergent balance at $\sigma = \tfrac12$ — the spectral dimension $D_s = \tfrac12$ — is what makes the second moment come out at order $N$ in calibrated units, i.e., what makes the certificate *finite and positive*. The sponge's volume decay is an ingredient of the working proof; it was never the mechanism.
3. **Off-diagonal coupling**: terms $n \ne m$ couple prime powers through the Hilbert kernel $1/(\log n - \log m)$ and are controlled by the Montgomery–Vaughan inequality — power-saving, *unconditionally*, precisely because $X \le T/2\pi$ (bandwidth $\lambda \le 1$). **This is where the decoupling boundary actually lives**: not in the choice of orthogonal axes, but in how much additive inter-stratum contact the mean-value theorems can see. See §7.

## 6. The accounting: the hyperbolic tax

The elementary engine is the rank–trace inequality [Z23, Lemma 3.2], proved by von Neumann's trace inequality: for real symmetric $P \succeq 0$ of rank $\le r$ and $Q$ with at most $b$ positive eigenvalues,

$$r \;\ge\; 2\operatorname{tr}P + 4\operatorname{tr}Q - 4b - \|P+Q\|_F^2.$$

It is the matrix transplant of Montgomery's integrality step $m^2 \ge 2m - 1$; its refinement (struts-only on the rank side) transplants $m^2 \ge 3m-2$. Read as economics in the calibrated units: **the primes pay total trace $\approx N$ into the space (every zero contributes, wherever it sits); the Frobenius budget caps the eigenvalue mass at $(\tfrac1\lambda + \tfrac\lambda3)N$; each hyperbolic plane refunds at most one positive direction but consumes two zeros of the count $N$.** Settling the books:

$$N_0^*(T,2T) \;\ge\; \Big(4 - 2 - \frac1\lambda - \frac\lambda3\Big) N - o(N) \;=\; \Big(2 - \frac1\lambda - \frac\lambda3\Big) N - o(N) \;\xrightarrow{\;\lambda=1\;}\; \frac{2}{3}N - o(N),$$

with the same bound for simple-on-line zeros (via $m^2 \ge 3m - 2$) and $\tfrac56 N$ for distinct zeros. Optimizing the window profile is a Rayleigh problem whose Euler–Lagrange equation is $v'' + 2v = 0$; the optimizer $v^*(s) = \cos(\sqrt2\, s)$ on $[-\tfrac12,\tfrac12]$ is the Montgomery–Taylor kernel, giving

$$c_1^* = \frac{\sqrt2\,\tan(1/\sqrt2)}{1 + \tfrac{1}{\sqrt2}\tan(1/\sqrt2)} = 0.75329\ldots, \qquad
2 - \frac{1}{c_1^*} = \frac32 - \frac{1}{\sqrt2}\cot\frac{1}{\sqrt2} = 0.67250\ldots, \qquad
\frac{3 - 1/c_1^*}{2} = 0.83625\ldots$$

The same argument runs verbatim for primitive Dirichlet $L$-functions, and for $\xi'$ (where it removes RH from the Farmer–Gonek–Lee 85.84% simple-zeros constant).

**The negative control matches the Sieve program's.** For Davenport–Heilbronn-type functions (functional equation, no Euler product) the coefficient energy $\sum_{n\le x} |c(n)|^2/n$ grows like $x^{1+\delta}$, the mean-value step fails, and the certificate is *empty* [Z23, Remark 7.2(iii)] — under-certification, never over-certification. This is precisely the discrimination that the June study's B.8 harness demanded ("any candidate proof must fail on $\Xi_{DH}$ at $t = 85.6993$ or it is using only symmetry and not the Euler product"), reached independently by both efforts. The Euler product is the load-bearing input in both.

## 7. The Grandfather bridge: local contact vs. uniform accumulation

The Sieve program's Scope statement (McSheery 2026b, "What is not established") argued that the decoupled orthogonal construction is integrable while the zeros carry GUE (coupled) statistics — "the zeros live in the coupling that orthogonality removes." The Collatz work (this repository, `Collatz_Conjecture/PROOF.md` §17) suggests the right refinement: **coupling between prime strata is not absent from a built-up-from-lower-primes structure; it is generated, unavoidably, by additive shifts.** The prime-coordinate differential $\partial_{\log q}\log n = v_q(n)$ is a valuation detector, and the Collatz identity $\partial_{\log 2}\log(3n+1) = v_2(3n+1) \ge 1$ shows the $+1$ forces *every* ascent into binary contact — the Grandfather Paradox: the attempt to escape creates the factors that pull you back.

[Z23] locates exactly where this additive contact enters the zeta problem, and how far it currently reaches:

| | **Collatz (§17)** | **Zeta / [Z23]** |
|---|---|---|
| Orthogonal strata | prime powers $2^k$ (2-adic height) | prime powers $n = p^k \le X$ (log-frequency strata) |
| Local contact, proved unconditionally | $v_2(3n+1) \ge 1$ at every odd step | diagonal second moment $\sum \Lambda(n)^2/n$; off-diagonal tamed by Montgomery–Vaughan at bandwidth $\lambda \le 1$ (BGSTB 2024) |
| What local contact buys | expected descent; almost-all convergence (Tao 2019) | $2/3$ of zeros on the line, $5/6$ distinct — population-level, unconditional |
| Uniform accumulation, open | $B_a > a\log_2 3$ for *all* trajectories ($\equiv$ `geometric_dominance`) | additive correlations $\sum_m (\Lambda*\Lambda)(m)(\Lambda*\Lambda)(m+h)$: Hardy–Littlewood strength, bandwidth $> 1$ |
| What uniform accumulation would buy | full Collatz conjecture | proportion $\to 1$ of simple on-line zeros ([Z23, §7.5(f)]; GLSS 2025 under full pair correlation); already $\ge 13/18$ from the 4th moment hypothesis |
| What even that would *not* buy | — | RH itself: population statements cannot exclude sparse exceptions; "RH is out of reach of the mechanism" [Z23, §7.5(f)] |

So the "downward invisibility" objection folds — **at the population level**. The decoupled (diagonal) part of the additive contact is unconditional and already certifies $2/3$; each increment of proved additive coupling raises the proportion; full coupling would drive it to $1$. What does *not* fold is the pointwise gap: O3′ ("$\operatorname{Re}(\xi'/\xi) > 0$ for $\sigma > \tfrac12$", equivalent to RH) demands control of *every* zero, and no amount of population-level additive-contact information reaches it — just as almost-all valuation accumulation (Tao) does not close `geometric_dominance` for every Collatz trajectory. The two programs share one honest boundary shape: **local contact is a theorem; uniform accumulation is the conjecture.** The quantified ceiling: with bandwidth-one input the inertia method tops out at $0.68185$; supports $\approx 1.04, 1.26, 1.70$ would be needed for $0.70, 0.80, 0.90$ [Z23, Remark 1.1].

## 8. What the Sieve program should take, and what it should retire

**Vindicated (keep, and cite [Z23] as the constructive realization):**
1. The real, indefinite, orthogonal-block ontology: Weil's form as a Krein metric; split-signature $Cl(1,1)$ hyperbolic planes with commuting outward bivectors ($B^2 = +1$) as the fundamental non-positive objects; Sylvester inertia as the invariant that survives projection.
2. The Mertens/sponge criticality of $\sigma = \tfrac12$ as a genuine load-bearing ingredient (it sets the scale of the second moment).
3. The Davenport–Heilbronn negative-control harness (B.8) — independently converged with [Z23]'s controls, for the same reason.
4. The build-up-from-lower-primes (Grandfather) coupling mechanism as the correct account of where GUE coupling lives: in additive inter-stratum contact, present but only partially proved.

**Corrected (retire or reframe):**
1. Primes as the orthogonal dimensions of the zero-side space → primes belong to the *metric*; the orthogonal planes that matter are the off-line pairs; the usable dimension count is bandwidth × window ($d = \lambda_1 N$).
2. Pointwise convexity / O3′ as the working target → it is exactly RH, and provably beyond bandwidth-$\le 1$ information (the certificate is insensitive to $o(N)$ off-line zeros). Keep O3′ as the frontier *marker*, per B.9.
3. "Outward bivectors render off-line zeros geometrically impossible" → outwardness yields an *inertia inequality* ($\ge 2/3$ of the population), not a prohibition. Impossibility-flavored language should not survive in any section (fixed in the June study, rev. 2026-08-12).

**A concrete next step.** The dictionary above is tight enough to formalize: state the strut/hyperbolic-plane decomposition and the inertia pull-back lemma against the `zeta-23-lean` repository's `Zeta23/LinAlg/` and `Zeta23/ZeroSide` modules (their `posIndex_conj_le` *is* the shadow-monotonicity of positive index), producing a machine-checked bridge between the Sieve program's `GeometricBridge.lean` vocabulary and the [Z23] proof. That would make the Cl(N,N) reading citable rather than interpretive.

---

## 9. Update (Aug 12, evening): the bridge is built and verified

The "concrete next step" of §8 is done: `Zeta23Bridge/` (this repository) now contains **ten kernel-checked theorems** against `zeta-23-lean` v1.0, all auditing to `[propext, Classical.choice, Quot.sound]`, no `sorry`:

- **Layers 1–3** (commits `6c37bcc`): `bivector_commute` (Vanishing Commutator vs Mathlib's `CliffordAlgebra`, any signature), `bivector_sq_neg_one`/`bivector_sq_one` (rotor vs boost), `posIndex_hypBlock`/`negIndex_hypBlock` (the off-line-pair block has signature (1,1)), `strut_hyperbolic_shadow_bound` (n₊ ≤ s + p), `shadow_posIndex_le` (inertia monotone under shadows).
- **Layer 4** (`40f6033`): `EulerStiffness` — the Euler product's quantitative shadow as a Prop-structure (prime-power support, log-size, Mertens energy, Chebyshev) — with the ζ instance `eulerStiffness_vonMangoldt` *proved* from Mathlib + `Zeta23.Cheb`.
- **Layer 5** (`6118c2b`): the exact Davenport–Heilbronn negative control. The defect identity `Λ_f(6) = (c(6) − c(2)c(3))·log 6` (the n = 6 log-derivative coefficient **is** the multiplicativity defect); for the D-H pattern the defect is `1 + κ²` — a sum of squares, positive for *every real κ*, no numerics — hence `dh_not_eulerStiffness`. The ζ contrast `zeta_logDerivAt6` (same recursion, zero defect, Λ(6) = 0) closes the pair. The B.8 harness is now machine-checked on both sides, and Grade Orthogonality (Thm 5.3 of the Sieve paper) acquires its converse weapon: *whenever composite generation fails, the failure is forced into the stiffness function at exactly that composite.*

## 10. What the dictionary still does not capture: the fractal is not the function

A critique from the author (McSheery, Aug 12) that this paper should record rather than deflect: everything formalized above — `EulerStiffness` included — is the **operational trace** of the Euler product, not the object. The four fields of `EulerStiffness` are measurements: a support pattern, a growth bound, two asymptotic budgets. But *Euler's intuition is not the list of Euler's provable consequences*: the intuition is the generative act — the integers **are** the product lattice of the primes; the sponge **is** a geometric object, whose zero volume, whose dimension 1/2, whose outwardness are intrinsic properties of a *construction*, not summary statistics of a *series*. A fractal is defined by its generating process; a function by its values. `∑ p^{−2σ}` is the measurement of the sponge, not the sponge. Nothing in this bridge — or in Mathlib — is the sponge.

This is a real gap and not a rhetorical one. The historical pattern for closing such gaps is not "collect more consequences" but **make the ontology native**: build the formal object in which the intuition is a definition rather than a metaphor (schemes did this for "space = its functions"; nonstandard analysis for infinitesimals; noncommutative geometry for quantum spaces). The test of an ontology is whether nativization yields proofs — or at least proof-shapes — unreachable from the operational trace alone.

Concrete program (the honest continuation of this paper):

1. **Define the sponge as a formal object**, not a series: the filtered system of sieve stages `S_k` (the integer lattice after sieving by the first k primes, each stage adding one orthogonal plane in Cl(k,k)), with its inclusion maps; the sponge is the limit object, carrying (a) the counting measure trace and (b) the J-norm energy functional as *structure*, not as afterthoughts.
2. **Prove the Mertens–Menger bridge as a statement about the object**: that the volume functional and the energy functional on the sponge are related by `Q(1/2) = −log(vol)` — currently two series identities; natively, one isomorphism.
3. **The native test**: re-derive one known zero-side statement *inside* the sponge frame without translating back to Dirichlet series at any step. If the frame is right, something — plausibly the bandwidth cap `d = λN` of §3, which is a dimension count — should become *definitional* rather than technical.
4. **Frame-leakage review**: every native derivation gets an adversarial pass asking only one question — *where did a Dirichlet series smuggle back in?* — with Davenport–Heilbronn as the standing control (its sponge, if one tries to build it, must fail to close at the 6-cell; Layer 5 is the algebraic shadow of that failure).

Until step 3 produces something, the fractal-object view remains a promissory note and this paper's dictionary remains what it honestly says it is: a translation of a theorem that was found, and can be fully stated, in the function frame.

## 11. SpongeStage, Stage 1: the sponge as an object, under the style-law (Aug 12, night)

Step 1 of §10 is now real code: `Zeta23Bridge/SpongeStage.lean` — kernel-checked (standard axioms only, no `sorry`) under the **style-law**:

> The literal fractions `1/2`, `1/p`, `1 − 1/p`, `∏(1 − 1/p)` do not appear in any definition. Definitions carry maps — embeddings, descents, gradings, group averages, coordinates. Numerals appear only in lemmas, as shadows (cardinalities, floored divisions, totients, Haar weights). If a definition needs the numeral, the definition is wrongly typed.

**Second clause (added Aug 12, from the dimensionality lesson): there is no imaginary axis.** The symbol `i` may not appear in definitions. "s = σ + it" is the shadow of a *commuting boost–rotor pair* — a non-compact damping generator (B² = +1) and a compact phase generator (B² = −1), generators of different classes that the complex plane flattens into one, erasing exactly the unitary/non-unitary distinction that matters. A "zero" is the simultaneous vanishing of two real quadratures (a real norm hitting the origin); the "imaginary parts" of zeros are the *real, measured* rotor rates γ (the crutch names the known thing imaginary and the mystery real — backwards); "on the line vs off the line" is the representation-type dichotomy *principal series vs complementary series* (Selberg — whose eigenvalue-¼ conjecture, ¼ = s(1−s) at the mirror, is the same type-statement about the modular surface); the trivial zeros are the pure-boost modes of the archimedean doll; RH, typed: **every mode of the sponge is a pure rotor about the mirror — no complementary contamination.** Complex numbers may appear in lemmas and computations as shadows (ℂ is the theorem that the even subalgebra of Cl(2,0) casts a field-shaped shadow — a result, not a foundation), never as the carrier of a concept. *Known residue in the formal layer:* `charSum` currently takes values in ℂ; the compliant retyping is a real rotor R with R^p = 1, via the telescope (1−R)·Σ R^k = 1−R^p = 0 — one lemma, tagged for Stage 2.5.

The sponge's intuitions, their classical owners, and their Lean names — the author supplies the structure, the dead mathematicians supply the rigor:

| Sponge intuition (McSheery) | Classical owner | Lean theorem |
|---|---|---|
| Each prime drills a new orthogonal hole; the stratum is a scaled copy of everything | Dedekind (infinite = self-similar); the stratum defined as the **image of a map**, not a predicate | `embed`, `stratum`, `embed_add`, `embed_comm` |
| "If there is any remainder, it wasn't an even integer" (for every prime) | Gauss, *Disquisitiones*: congruences; the remainder typed as a **group element** of `ZMod p`, never a numeral | `remainder_obstruction`, `grade`, `grade_eq_zero_iff` |
| The doll tower; nesting by construction; "available contraction" | Kummer, Hensel: the p-adic valuation as **exact-descent count** | `tower`, `tower_nested`, `descent_count` |
| The cells close; prime axes are independent | Gauss: Chinese Remainder Theorem, in image form: `stratum p ∩ stratum q = stratum (p·q)` | `orthogonality` |
| "Whole numbers expressed by fractions" — the generative act | Euclid IX.14 / Gauss: ℕ⁺ **is** the free commutative monoid on the primes; multiplication of integers = **addition of coordinate vectors** | `coordinates`, `coordinates_add`, `reconstruction` |
| "1/p is an operator, not a fraction" | Dirichlet: character orthogonality; the scalar in the lemma is the **group order** (inverse Haar weight), by way of an abstract primitive root — no fraction anywhere | `charSum`, `haar_projector` |
| The sponge's surviving volume | Euler, Legendre: on one CRT period the survivor count **is** `∏(p−1)` — a totient, the trace of the sieve idempotent; Mertens' `∏(1−1/p)` is its shadow | `volume_shadow` |
| Density of a stratum | floored division `n / p` — even the shadow keeps the remainder discipline (the remainder is dropped, not divided) | `density_shadow` |
| Even/odd chirality; the ½(1+S) projector; the Clifford even grade | Dirichlet's parity character; the grade involution — the `2` appears in the lemma as the group order | `parity_projector` |

Two things worth recording about what the style-law *did* during construction. First, it forced the stratum to be defined as `Set.range (embed p)` — the image of the factory — with divisibility demoted to a lemma (`mem_stratum_iff`): the doll is made, not recognized. Second, it turned out that even the shadows keep structure when typed honestly: the density shadow is the *floored* division `n / p` (ℕ-division — remainder dropped, not divided), and the volume shadow is the integer `∏(p−1)` (a totient), so the familiar fractions `1/p` and `∏(1−1/p)` never appear even in the lemmas — they would only arise at the final, deliberate act of decategorification into ℝ, which Stage 1 declines to perform.

**Stage 2 (next):** the energy variable `Q = r²` with `d/dQ` as structural descent-by-2 (Laplacian → Dirac → the Clifford necessity; Γ(s/2) as the object's radial measure); the log-linearization `T_{log p}` as unitary shifts (the resolvent reading of the Euler factor); the spectral-dimension shadow `D_s = 1/2` as a theorem about the object. **Stage 3:** the native test of §10 — re-derive one zero-side statement inside the sponge frame, with the D-H control standing guard (its sponge must fail to close at the 6-cell; `dh_not_eulerStiffness` is the algebraic shadow of that failure).

---

## References

- **[Z23]** Claude (Anthropic), *More than two thirds of the zeros of the Riemann zeta function lie on the critical line*, Aug 10 2026. PDF: `www-cdn.anthropic.com/564f962e60643842f5fcb4a17c9dbc8f608f1c37.pdf`; Lean: `github.com/anthropics/zeta-23-lean`; provenance appendix and transcripts linked from the Anthropic announcement.
- S. A. C. Baluyot, D. A. Goldston, A. I. Suriajaya, C. L. Turnage-Butterbaugh, *An unconditional Montgomery theorem for pair correlation of zeros of the Riemann zeta-function*, Acta Arith. **214** (2024), 357–376.
- D. A. Goldston, A. I. Suriajaya, *Zeta zeros on the critical line*, arXiv:2511.20059 (2025); *Zeta zeros in a narrow vertical box*, arXiv:2603.28104 (2026).
- D. A. Goldston, J. Lee, J. Schettler, A. I. Suriajaya, *Pair correlation conjecture I: simple and critical zeros*, arXiv:2503.15449 (2025).
- E. Bombieri, *Remarks on Weil's quadratic functional in the theory of prime numbers, I*, Rend. Lincei (9) **11** (2000), 183–233.
- H. L. Montgomery, *The pair correlation of zeros of the zeta function*, Proc. Sympos. Pure Math. **24** (1973); H. L. Montgomery (–Taylor kernel), ICM Vancouver 1974 proceedings (1975).
- A. Chirre, F. Gonçalves, D. de Laat, *Pair correlation estimates … via semidefinite programming*, Adv. Math. **361** (2020).
- K. Pratt, N. Robles, A. Zaharescu, D. Zeindler, *More than five-twelfths of the zeros of ζ are on the critical line*, Res. Math. Sci. **7** (2020).
- T. Tao, *Almost all orbits of the Collatz map attain almost bounded values*, Forum Math. Pi (2019).
- T. McSheery, *The Geometry of the Sieve* (Feb 14 2026 FINAL, this directory) [2026a]; *June Riemann Study* (June 10 2026, rev. Aug 12 2026, this directory) [2026b]; `Collatz_Conjecture/PROOF.md` §17 (this repository).
