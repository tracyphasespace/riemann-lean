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
