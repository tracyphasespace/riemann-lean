/-
SpongeStage.lean — Stage 1 of the sponge-as-object formalization
(Geometry-of-the-Sieve program, McSheery 2026; companion paper §10–11).

**THE STYLE-LAW** (paper §10, "the fractal is not the function"):
the literal fractions `1/2`, `1/p`, `1 − 1/p`, `∏(1 − 1/p)` DO NOT APPEAR
IN ANY DEFINITION. Definitions carry maps — embeddings, descents, gradings,
group averages, coordinates. Numerals appear only in *lemmas*, as shadows:
cardinalities, floored divisions, totients, Haar weights. If a definition
needs the numeral, the definition is wrongly typed.

**The dictionary** (sponge intuition → classical owner → here):
* "each prime drills a new orthogonal hole"
    → self-embedding ×p (Dedekind: infinite = self-similar);
      independence of remainders (Gauss: CRT)         → `embed`, `orthogonality`
* "if there is any remainder, it wasn't even"
    → residue grading (Gauss: congruences, `ZMod`)    → `grade`, `remainder_obstruction`
* "the doll tower; available contraction"
    → p-adic valuation (Kummer, Hensel)               → `tower`, `descent_count`
* "whole numbers expressed by fractions"
    → ℕ⁺ is the free commutative monoid on the primes
      (Euclid IX.14, Gauss D.A.: unique factorization) → `coordinates_add`, `reconstruction`
* "1/p is an operator, not a fraction"
    → averaging over the dual group (Dirichlet characters;
      the Haar weight of ℤ/p)                          → `haar_projector`
* "the sponge's surviving volume"
    → Euler's totient on one CRT period (Euler, Legendre) → `volume_shadow`
* "the density of a stratum"
    → floored division — the remainder discipline in the
      shadow itself                                    → `density_shadow`
* "even/odd chirality; the ½(1+S) projector"
    → the parity character (Dirichlet mod 2; the grade
      involution of the Clifford even subalgebra)      → `parity_projector`

Stage 2 (not here): the energy variable Q = r² with d/dQ as structural
descent-by-2 (Laplacian/Dirac, Γ(s/2)); the log-linearization T_{log p}
as unitary shifts; the spectral-dimension shadow D_s = 1/2.
-/
import Mathlib.RingTheory.RootsOfUnity.PrimitiveRoots
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Real.Basic
import Mathlib.Data.Nat.Totient
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Nat.Factorization.Basic
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecificLimits.Normed

noncomputable section

namespace Sponge

/-! ### The self-embedding: each prime's doll factory (Dedekind) -/

/-- The `p`-fold self-embedding of the integers: the map whose *image* is
the `p`-stratum. The stratum is defined by the map, not by a predicate —
the doll is made by the factory, not recognized by inspection. -/
def embed (p : ℕ) : ℕ → ℕ := fun n => p * n

/-- The `p`-stratum: the image of the self-embedding. -/
def stratum (p : ℕ) : Set ℕ := Set.range (embed p)

theorem embed_injective {p : ℕ} (hp : p ≠ 0) : Function.Injective (embed p) :=
  fun a b h => Nat.eq_of_mul_eq_mul_left (Nat.pos_of_ne_zero hp) h

/-- The embedding preserves additive structure: the stratum is a genuine
scaled copy of the whole, not merely a subset (Dedekind self-similarity). -/
theorem embed_add (p m n : ℕ) : embed p (m + n) = embed p m + embed p n :=
  Nat.mul_add p m n

/-- The doll factories commute: the sponge's cells are unambiguous. -/
theorem embed_comm (p q n : ℕ) : embed p (embed q n) = embed q (embed p n) := by
  unfold embed
  ring

/-- Divisibility is the *shadow* of membership in the image. -/
theorem mem_stratum_iff {p n : ℕ} : n ∈ stratum p ↔ p ∣ n :=
  ⟨fun ⟨m, hm⟩ => ⟨m, hm.symm⟩, fun ⟨m, hm⟩ => ⟨m, hm.symm⟩⟩

/-- **"If there is any remainder, it wasn't an even integer"** (generalized
to every prime): membership in the stratum is exactness of the descent. -/
theorem remainder_obstruction {p n : ℕ} : n ∈ stratum p ↔ n % p = 0 := by
  rw [mem_stratum_iff, Nat.dvd_iff_mod_eq_zero]

/-! ### The grading: the remainder as a group element, not a number (Gauss) -/

/-- The `p`-grade of an integer: its residue, typed in the group `ZMod p` —
a digit of the doll tower, never a numeral. -/
def grade (p n : ℕ) : ZMod p := (n : ZMod p)

theorem grade_eq_zero_iff {p n : ℕ} :
    grade p n = 0 ↔ n ∈ stratum p := by
  rw [mem_stratum_iff]
  exact ZMod.natCast_eq_zero_iff n p

/-! ### The tower: iterated exact descent (Kummer, Hensel) -/

/-- The `k`-th floor of the `p`-tower: the image of the `p^k`-fold embedding. -/
def tower (p k : ℕ) : Set ℕ := Set.range (embed (p ^ k))

/-- The floors nest: each is strictly inside the last *by construction* —
the Russian dolls whose nesting needs no inspection. -/
theorem tower_nested (p k : ℕ) : tower p (k + 1) ⊆ tower p k := by
  rintro n ⟨m, rfl⟩
  exact ⟨p * m, by unfold embed; ring⟩

/-- **The valuation is the descent count**: how many floors down the exact
descent carries `n` before the first remainder — `∂_{log p} log n = v_p(n)`
(Collatz §17.1), here typed as tower membership. -/
theorem descent_count {p : ℕ} (hp : p.Prime) {n : ℕ} (hn : n ≠ 0) (k : ℕ) :
    n ∈ tower p k ↔ k ≤ n.factorization p := by
  rw [show tower p k = stratum (p ^ k) from rfl, mem_stratum_iff]
  exact (hp.pow_dvd_iff_le_factorization hn)

/-! ### Orthogonality: the cells close (Gauss, CRT) -/

/-- **Orthogonality of the prime axes**: the joint stratum of coprime
moduli is the product stratum — the sponge's cells are rectangular. This
is the Chinese Remainder Theorem in image form. -/
theorem orthogonality {p q : ℕ} (hpq : Nat.Coprime p q) :
    stratum p ∩ stratum q = stratum (p * q) := by
  ext n
  simp only [Set.mem_inter_iff, mem_stratum_iff]
  constructor
  · rintro ⟨hpn, hqn⟩
    exact hpq.mul_dvd_of_dvd_of_dvd hpn hqn
  · intro h
    exact ⟨(dvd_mul_right p q).trans h, (dvd_mul_left q p).trans h⟩

/-! ### The coordinates: the generative act (Euclid, Gauss) -/

/-- The prime-coordinate system of an integer: its valuation vector.
`ℕ⁺` **is** the free commutative monoid on the primes; this is the
coordinate chart. -/
def coordinates (n : ℕ) : ℕ →₀ ℕ := n.factorization

/-- Multiplication of integers is *addition of coordinate vectors*: the
whole numbers compose linearly in the prime basis. -/
theorem coordinates_add {a b : ℕ} (ha : a ≠ 0) (hb : b ≠ 0) :
    coordinates (a * b) = coordinates a + coordinates b :=
  Nat.factorization_mul ha hb

/-- Every integer is reconstructed from its coordinates: the chart is
faithful ("whole numbers expressed by fractions", typed). -/
theorem reconstruction {n : ℕ} (hn : n ≠ 0) :
    (coordinates n).prod (· ^ ·) = n :=
  Nat.prod_factorization_pow_eq_self hn

/-! ### The averaging operator: 1/p as Haar weight (Dirichlet) -/

/-- The character sum of the `p`-stratum against an abstract primitive
`p`-th root of unity. **No fraction appears**: the root is a group
element, the sum is over the dual group. -/
def charSum (ζ : ℂ) (p n : ℕ) : ℂ := ∑ k ∈ Finset.range p, ζ ^ (k * n)

/-- **The Haar projector**: the character sum detects the stratum, and the
scalar that appears is the *group order* `p` — the inverse Haar weight —
as a multiplication in a lemma, never a fraction in a definition.
(Dirichlet's orthogonality of characters, in its simplest cell.) -/
theorem haar_projector {ζ : ℂ} {p : ℕ} (hp : p.Prime)
    (hζ : IsPrimitiveRoot ζ p) (n : ℕ) :
    charSum ζ p n = if p ∣ n then (p : ℂ) else 0 := by
  unfold charSum
  by_cases h : p ∣ n
  · rw [if_pos h]
    have hζn : ζ ^ n = 1 := (hζ.pow_eq_one_iff_dvd n).mpr h
    have heach : ∀ k, ζ ^ (k * n) = 1 := by
      intro k
      rw [mul_comm, pow_mul, hζn, one_pow]
    rw [Finset.sum_congr rfl fun k _ => heach k]
    simp
  · rw [if_neg h]
    have hcop : Nat.Coprime n p := (hp.coprime_iff_not_dvd.mpr h).symm
    have hprim : IsPrimitiveRoot (ζ ^ n) p := hζ.pow_of_coprime n hcop
    have hsum : ∑ k ∈ Finset.range p, (ζ ^ n) ^ k = 0 :=
      hprim.geom_sum_eq_zero hp.one_lt
    rw [← hsum]
    exact Finset.sum_congr rfl fun k _ => by rw [mul_comm, pow_mul]

/-! ### The shadows: where the numerals are allowed to appear -/

/-- **The density shadow**: the count of the `p`-stratum in a window is
the *floored division* `n / p` — even the shadow keeps the remainder
discipline (it is not the fraction `n·(1/p)`; the remainder is dropped,
not divided). -/
theorem density_shadow (p n : ℕ) :
    ((Finset.range n).filter fun i => p ∣ (i + 1)).card = n / p :=
  Nat.card_multiples n p

/-- **The volume shadow** (Euler, Legendre): on one full CRT period, the
surviving count after drilling all strata of `P` is `∏ (p − 1)` — the
integer form of Mertens' `∏(1 − 1/p)`, with no fraction anywhere: the
"volume" is a totient, the trace of the sieve idempotent. -/
theorem volume_shadow (P : Finset ℕ) (hP : ∀ p ∈ P, p.Prime) :
    (∏ p ∈ P, p).totient = ∏ p ∈ P, (p - 1) := by
  induction P using Finset.cons_induction with
  | empty => simp
  | cons a t hat ih =>
      have ha : a.Prime := hP a (Finset.mem_cons_self a t)
      have ht : ∀ p ∈ t, p.Prime := fun p hp => hP p (Finset.mem_cons_of_mem hp)
      have hcop : Nat.Coprime a (∏ p ∈ t, p) := by
        apply Nat.Coprime.prod_right
        intro q hq
        exact (Nat.coprime_primes ha (ht q hq)).mpr
          (fun hEq => hat (hEq ▸ hq))
      rw [Finset.prod_cons, Finset.prod_cons, Nat.totient_mul hcop,
        Nat.totient_prime ha, ih ht]

/-- **The parity projector** (the `p = 2` Haar average over ℝ): the grade
involution's average detects the even stratum, and the scalar in the lemma
is the group order `2`. This is `½(1 + S)` with the `½` where it belongs —
derived, on the shadow side. It is also the grade projector of the
Clifford even subalgebra: even integers : ℤ :: even multivectors : Cl. -/
theorem parity_projector (n : ℕ) :
    (1 : ℝ) + (-1) ^ n = if Even n then 2 else 0 := by
  rcases Nat.even_or_odd n with h | h
  · rw [if_pos h, h.neg_one_pow]
    norm_num
  · rw [if_neg (Nat.not_even_iff_odd.mpr h), h.neg_one_pow]
    norm_num

end Sponge

#print axioms Sponge.orthogonality
#print axioms Sponge.descent_count
#print axioms Sponge.haar_projector
#print axioms Sponge.density_shadow
#print axioms Sponge.volume_shadow
#print axioms Sponge.parity_projector

/-! ## Stage 2 (tagged for later): the energy variable and the shifts

The energy variable `Q = r²` (the quadratic form, the native coordinate of a
Clifford world) and the log-linearized shifts. Style-law holds: the `2` of
the descent appears in lemmas as the step size and the chain factor; the
`1/2` of `d/dQ = (1/2r)·d/dr` is never written — we state the relation
multiplicatively. Deferred to Stage 2.5: the Dirac square root (`bivector_sq`
in `Zeta23Bridge.lean` is its algebraic seed), `Γ(s/2)` as the radial
measure, theta weight 1/2. -/

namespace Stage2

open Sponge

/-! ### The energy variable: descent by two (Laplace) -/

/-- **Descent by two**: the second derivative — the 1-D Laplacian — lowers
the degree of a homogeneous profile by exactly 2 (sphere to circle). The
step size `2` appears here, in a lemma, as the count of applications. -/
theorem descent_by_two (n : ℕ) (x : ℝ) :
    deriv (deriv (fun y : ℝ => y ^ (n + 2))) x = (n + 2) * (n + 1) * x ^ n := by
  have h1 : deriv (fun y : ℝ => y ^ (n + 2)) = fun y : ℝ => ((n : ℝ) + 2) * y ^ (n + 1) := by
    funext y
    rw [deriv_pow_field]
    push_cast [Nat.add_sub_cancel]
    ring
  rw [h1, deriv_const_mul _ (differentiableAt_pow _), deriv_pow_field]
  have h2 : n + 1 - 1 = n := by omega
  rw [h2]
  push_cast
  ring

/-- **The half-step chain relation**: differentiation in the radial variable
is `2r` times differentiation in the energy variable, stated multiplicatively
— the `1/2` of `d/dQ = (1/2r)·d/dr` never appears. Energy profiles of degree
`m+1` in `Q` are radial profiles of degree `2(m+1)` in `r`; one radial
derivative carries the factor `2r` and one energy-degree step. -/
theorem half_step (m : ℕ) (r : ℝ) :
    deriv (fun x : ℝ => (x ^ 2) ^ (m + 1)) r = 2 * r * ((m + 1) * (r ^ 2) ^ m) := by
  have h : (fun x : ℝ => (x ^ 2) ^ (m + 1)) = fun x => x ^ (2 * (m + 1)) := by
    funext x
    rw [← pow_mul]
  rw [h, deriv_pow_field]
  have h1 : 2 * (m + 1) - 1 = 2 * m + 1 := by omega
  rw [h1, show ((r : ℝ) ^ 2) ^ m = r ^ (2 * m) from (pow_mul r 2 m).symm]
  push_cast
  ring

/-! ### The shifts: the embedding linearized (the Zeta Motor's rails) -/

/-- Translation of a profile: the shift operator `T_a`. -/
def shift (a : ℝ) (f : ℝ → ℝ) : ℝ → ℝ := fun x => f (x - a)

/-- Shifts compose additively: the shift family is a one-parameter group. -/
theorem shift_shift (a b : ℝ) (f : ℝ → ℝ) :
    shift a (shift b f) = shift (a + b) f := by
  funext x
  simp [shift, sub_sub]

/-- The shift family commutes — the operator form of `embed_comm`. -/
theorem shift_comm (a b : ℝ) (f : ℝ → ℝ) :
    shift a (shift b f) = shift b (shift a f) := by
  rw [shift_shift, shift_shift, add_comm]

/-- **The log-linearization**: under `log`, the self-embedding becomes a
translation — the doll factory becomes a rail. This is the bridge from the
sponge's multiplicative strata to the shift operators of the explicit
formula (`T_{log p}` in `K(s,B)`; the Gabor rails of [Z23]). -/
theorem log_linearizes {p n : ℕ} (hp : p ≠ 0) (hn : n ≠ 0) :
    Real.log (embed p n) = Real.log p + Real.log n := by
  unfold Sponge.embed
  push_cast
  exact Real.log_mul (Nat.cast_ne_zero.mpr hp) (Nat.cast_ne_zero.mpr hn)

/-! ### The resolvent: the Euler factor typed (Euler, Neumann) -/

/-- **Sieve × tower = identity**: the complementary sieve factor `(1 − x)`
annihilates the full tower sum to `1` — the Euler factor
`(1 − p^{−s})^{−1}` is the *resolvent* of the descent, its geometric series
the tower's telescope. Stated multiplicatively: no inverse, no fraction;
`x` is the abstract descent weight. -/
theorem sieve_times_tower {x : ℝ} (h : |x| < 1) :
    (1 - x) * ∑' k : ℕ, x ^ k = 1 := by
  have hx : ‖x‖ < 1 := by simpa [Real.norm_eq_abs] using h
  rw [tsum_geometric_of_norm_lt_one hx]
  have hne : (1 : ℝ) - x ≠ 0 := by
    intro h0
    rw [sub_eq_zero] at h0
    rw [← h0] at h
    norm_num at h
  exact mul_inv_cancel₀ hne

end Stage2

#print axioms Stage2.descent_by_two
#print axioms Stage2.half_step
#print axioms Stage2.log_linearizes
#print axioms Stage2.sieve_times_tower

/-! ## Stage 3: the Dimensionality Lesson's formal queue (paper §12)

Six targets accumulated by the lesson, all style-law-compliant: the
numerals and inverses appear only in lemmas, as shadows. -/

namespace Stage3

open Sponge

/-! ### 1. The collapse fixed point (Rung 4: iterated descent jams at the core) -/

/-- Iterated exact descent terminates outside the stratum: the `p`-free
core (`ordCompl`) has a remainder — the collapse's fixed point. -/
theorem collapse_not_mem_stratum {p : ℕ} (hp : p.Prime) {n : ℕ} (hn : n ≠ 0) :
    ordCompl[p] n ∉ stratum p := by
  rw [mem_stratum_iff]
  exact Nat.not_dvd_ordCompl hp hn

/-- The collapse remembers what it stripped: the doll reassembles from its
tower height and its core (`n = p^{v_p(n)} · core`). -/
theorem collapse_reconstruct (p n : ℕ) :
    embed (p ^ n.factorization p) (ordCompl[p] n) = n :=
  Nat.ordProj_mul_ordCompl_eq_self n p

/-! ### 2. The full cascade retracts to the unit (Rung 3: the limit point) -/

/-- An integer surviving **every** prime's sieve is the unit: the
intersection of all stratum-complements is `{1}` — the sponge's limit
point. (Euclid: every `n ≠ 1` has a prime divisor.) -/
theorem cascade_limit {n : ℕ} (h : ∀ p, p.Prime → n ∉ stratum p) : n = 1 := by
  by_contra h1
  obtain ⟨p, hp, hpn⟩ := Nat.exists_prime_and_dvd h1
  exact h p hp (mem_stratum_iff.mpr hpn)

/-! ### 3. The real-rotor telescope (style-law clause 2: de-ℂ-ing the Haar projector) -/

/-- The telescope, in any ring: the sieve factor `(1 − R)` times the tower
sum is `1 − R^p`. No commutativity, no ℂ, no fractions. -/
theorem rotor_telescope {A : Type*} [Ring A] (R : A) (p : ℕ) :
    (1 - R) * ∑ k ∈ Finset.range p, R ^ k = 1 - R ^ p := by
  induction p with
  | zero => simp
  | succ m ih =>
      rw [Finset.sum_range_succ, mul_add, ih, sub_mul, one_mul, ← pow_succ']
      abel

/-- **The ℂ-free Haar annihilation**: a rotor of order `p` (any real
rotation matrix with `R^p = 1`, any ring element) has its tower sum
annihilated by the sieve factor. For a nontrivial rotation `1 − R` is
invertible, forcing `Σ R^k = 0` — Dirichlet orthogonality with no
imaginary unit. The `R = 1` case gives `Σ = p·1`: the group order, the
inverse Haar weight, on the shadow side. -/
theorem rotor_haar_annihilate {A : Type*} [Ring A] {R : A} {p : ℕ}
    (hRp : R ^ p = 1) :
    (1 - R) * ∑ k ∈ Finset.range p, R ^ k = 0 := by
  rw [rotor_telescope, hRp, sub_self]

theorem rotor_haar_identity {A : Type*} [Ring A] (p : ℕ) :
    ∑ k ∈ Finset.range p, (1 : A) ^ k = (p : A) := by
  simp [Finset.sum_const, Finset.card_range, nsmul_eq_mul]

/-! ### 4. The sponge's aperiodicity (Rung 6: `log_independence`) -/

/-- Factorization of a product of distinct prime powers, read at a member
prime: the coordinate comes back out. -/
lemma prod_pow_factorization_apply {P : Finset ℕ} (hP : ∀ p ∈ P, p.Prime)
    (a : ℕ → ℕ) {q : ℕ} (hq : q ∈ P) :
    (∏ p ∈ P, p ^ a p).factorization q = a q := by
  rw [Nat.factorization_prod (fun p hp => pow_ne_zero _ (hP p hp).pos.ne')]
  rw [Finset.sum_apply']
  rw [Finset.sum_eq_single_of_mem q hq]
  · rw [(hP q hq).factorization_pow, Finsupp.single_eq_same]
  · intro p hp hpq
    rw [(hP p hp).factorization_pow]
    simp [Finsupp.single_apply, hpq]

/-- **The sponge is aperiodic** (Kronecker–Weyl input; Rung 6): the
`{log p}` are rationally independent, because a relation
`Σ aₚ·log p = Σ bₚ·log p` exponentiates to an equality of two prime-power
products, and unique factorization reads off `aₚ = bₚ`. The joint winding
never folds; the imaginary plane's shared circle has no license. -/
theorem log_independence {P : Finset ℕ} (hP : ∀ p ∈ P, p.Prime) (a b : ℕ → ℕ)
    (h : ∑ p ∈ P, (a p : ℝ) * Real.log p = ∑ p ∈ P, (b p : ℝ) * Real.log p) :
    ∀ q ∈ P, a q = b q := by
  intro q hq
  set X := ∏ p ∈ P, p ^ a p with hX
  set Y := ∏ p ∈ P, p ^ b p with hY
  have hXpos : 0 < X := Finset.prod_pos fun p hp => pow_pos (hP p hp).pos _
  have hYpos : 0 < Y := Finset.prod_pos fun p hp => pow_pos (hP p hp).pos _
  have hlog : ∀ (c : ℕ → ℕ), Real.log (∏ p ∈ P, p ^ c p : ℕ) =
      ∑ p ∈ P, (c p : ℝ) * Real.log p := by
    intro c
    push_cast
    rw [Real.log_prod (fun p hp =>
      pow_ne_zero _ (Nat.cast_ne_zero.mpr (hP p hp).pos.ne'))]
    exact Finset.sum_congr rfl fun p _ => Real.log_pow _ _
  have hXY : Real.log (X : ℝ) = Real.log (Y : ℝ) := by
    rw [hX, hY, hlog a, hlog b]
    exact h
  have hXYeq : X = Y := by
    have := Real.log_injOn_pos
      (Set.mem_Ioi.mpr (by exact_mod_cast hXpos))
      (Set.mem_Ioi.mpr (by exact_mod_cast hYpos)) hXY
    exact_mod_cast this
  have hfa := prod_pow_factorization_apply hP a hq
  have hfb := prod_pow_factorization_apply hP b hq
  rw [← hX] at hfa
  rw [← hY] at hfb
  rw [← hfa, ← hfb, hXYeq]

/-! ### 5. The fair-split ordering identity (Rung 2: [∂, x] = 1) -/

/-- The two orderings of coordinate-times-derivation, summed: their total
is `2·(x∂) + 1` — the canonical commutator `[∂, x] = 1` in fair-split
form, with the `1` on the shadow side. Halving (a shadow act) yields the
symmetrized dilation `x∂ + ½`, the Berry–Keating generator whose modes
are the critical line; the `½` is never written here. -/
theorem fair_split {f : ℝ → ℝ} {x : ℝ} (hf : DifferentiableAt ℝ f x) :
    x * deriv f x + deriv (fun y => y * f y) x
      = 2 * (x * deriv f x) + f x := by
  have h : deriv (fun y => y * f y) x = 1 * f x + x * deriv f x :=
    ((hasDerivAt_id' x).mul hf.hasDerivAt).deriv
  rw [h]
  ring

/-! ### 6. The product-formula cell (Rung 7: Artin–Whaples) -/

/-- **The product formula, one cell** (Rung 7): the archimedean size of an
integer times the product of its inverse coordinate-powers is `1` — the
archimedean integers as the joint inverse of the `1/prime` norms
(`|n|_p = p^{−v_p(n)}`; Artin–Whaples). The inverses appear only here, in
the lemma, as shadows of the coordinates of `reconstruction`. -/
theorem product_formula {n : ℕ} (hn : n ≠ 0) :
    (n : ℝ) * ∏ p ∈ n.primeFactors, ((p : ℝ) ^ n.factorization p)⁻¹ = 1 := by
  rw [Finset.prod_inv_distrib]
  have hprod : ∏ p ∈ n.primeFactors, ((p : ℝ) ^ n.factorization p)
      = ((∏ p ∈ n.primeFactors, p ^ n.factorization p : ℕ) : ℝ) := by
    push_cast
    rfl
  have hrec : (∏ p ∈ n.primeFactors, p ^ n.factorization p : ℕ) = n := by
    rw [← Nat.support_factorization]
    exact Nat.prod_factorization_pow_eq_self hn
  rw [hprod, hrec]
  exact mul_inv_cancel₀ (Nat.cast_ne_zero.mpr hn)

end Stage3

#print axioms Stage3.collapse_reconstruct
#print axioms Stage3.cascade_limit
#print axioms Stage3.rotor_haar_annihilate
#print axioms Stage3.log_independence
#print axioms Stage3.fair_split
#print axioms Stage3.product_formula
