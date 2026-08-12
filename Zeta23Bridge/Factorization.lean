/-
Factorization.lean — Stages F1 and F2a of the factorization experiment
(`Factorization.md`; ledger §8, production commitment (ii)).

Question: does [Z23]'s two-thirds bound depend on the arithmetic only
through the `EulerStiffness` interface? Stage F1 formalizes the first
layer of the answer: the derived prime-side facts. [Z23] Lemma 5.1
consumes, beyond the interface's five fields, three further estimates;
this file proves the easy grades of all three **from the fields alone** —
no von Mangoldt function, no zeta, no Euler product: any `f` satisfying
the interface inherits them.

* F1.1 `sum_sq_le` — the second moment Σ f(n)² ≤ (log x)·(log 4 + 4)·x
  (from `log_size` × `chebyshev`).
* F1.2 `sum_div_sqrt_sq_le` — the crude √-moment
  (Σ f(n)/√n)² ≤ x · Σ f(n)²/n (Cauchy–Schwarz; with `mertens_energy`
  this yields Σ f/√n ≪ √x·log x — sufficient for every bandwidth λ < 1,
  hence for the 2/3 liminf via λ → 1⁻; the sharp √x endpoint is
  milestone F2 via Abel summation from `chebyshev`).
* F1.3 `freq_spacing` — the Montgomery–Vaughan frequency separation
  log(n+1) − log n ≥ 1/(n+1), from integer support geometry alone
  (the MV inequality itself, `Zeta23/MV`, is coefficient-free).

Everything here is falsification-disciplined: these lemmas hold for any
interface-`f`, and Davenport–Heilbronn has no interface-`f`
(`dh_not_eulerStiffness`), so nothing here applies to it.
-/
import Zeta23Bridge

noncomputable section

namespace Factorization

open Finset Zeta23Bridge

variable {f : ℕ → ℝ}

/-- **F1.1 (derived second moment)**: Σ_{n ≤ x} f(n)² ≤ (log x)·(log 4 + 4)·x.
[Z23] Lemma 5.1's Σ Λ(n)² ≪ x log x, derived from the interface alone:
`log_size` caps each factor, `chebyshev` sums the rest. -/
theorem sum_sq_le (hf : EulerStiffness f) {x : ℝ} (hx : 1 ≤ x) :
    ∑ n ∈ Ioc 0 ⌊x⌋₊, f n ^ 2 ≤ Real.log x * ((Real.log 4 + 4) * x) := by
  have hstep : ∀ n ∈ Ioc 0 ⌊x⌋₊, f n ^ 2 ≤ Real.log x * f n := by
    intro n hn
    obtain ⟨hn0, hnx⟩ := mem_Ioc.mp hn
    have hncast : (n : ℝ) ≤ x :=
      le_trans (Nat.cast_le.mpr hnx) (Nat.floor_le (by linarith))
    have hnpos : (0 : ℝ) < n := by exact_mod_cast hn0
    have hlog : Real.log n ≤ Real.log x := Real.log_le_log hnpos hncast
    have hsize := hf.log_size n
    have hnn := hf.nonneg n
    nlinarith
  calc ∑ n ∈ Ioc 0 ⌊x⌋₊, f n ^ 2
      ≤ ∑ n ∈ Ioc 0 ⌊x⌋₊, Real.log x * f n := sum_le_sum hstep
    _ = Real.log x * ∑ n ∈ Ioc 0 ⌊x⌋₊, f n := by rw [mul_sum]
    _ ≤ Real.log x * ((Real.log 4 + 4) * x) :=
        mul_le_mul_of_nonneg_left (hf.chebyshev x (by linarith))
          (Real.log_nonneg hx)

/-- **F1.2 (crude √-moment, Cauchy–Schwarz)**:
(Σ_{n ≤ x} f(n)/√n)² ≤ x · Σ_{n ≤ x} f(n)²/n.
Paired with the `mertens_energy` field this gives Σ f/√n ≪ √x·log x,
which suffices for all bandwidths λ < 1 (Factorization.md, F0 verdict,
qualification 1). Pure Cauchy–Schwarz: no field is even consumed here —
the interface is needed only when the right side is evaluated. -/
theorem sum_div_sqrt_sq_le {x : ℝ} (hx : 0 ≤ x) :
    (∑ n ∈ Ioc 0 ⌊x⌋₊, f n / Real.sqrt n) ^ 2
      ≤ x * ∑ n ∈ Ioc 0 ⌊x⌋₊, f n ^ 2 / n := by
  have h := Finset.sum_mul_sq_le_sq_mul_sq (Ioc 0 ⌊x⌋₊)
    (fun n => f n / Real.sqrt n) (fun _ => 1)
  simp only [mul_one, one_pow] at h
  have hsq : ∀ n ∈ Ioc 0 ⌊x⌋₊, (f n / Real.sqrt n) ^ 2 = f n ^ 2 / n := by
    intro n hn
    have hn0 : 0 < n := (mem_Ioc.mp hn).1
    have hncast : (0 : ℝ) < n := by exact_mod_cast hn0
    rw [div_pow, Real.sq_sqrt hncast.le]
  have hcard : (∑ _n ∈ Ioc 0 ⌊x⌋₊, (1 : ℝ)) ≤ x := by
    rw [Finset.sum_const, Nat.card_Ioc, Nat.sub_zero, nsmul_eq_mul, mul_one]
    exact le_trans (Nat.floor_le hx) le_rfl
  calc (∑ n ∈ Ioc 0 ⌊x⌋₊, f n / Real.sqrt n) ^ 2
      ≤ (∑ n ∈ Ioc 0 ⌊x⌋₊, (f n / Real.sqrt n) ^ 2)
        * ∑ _n ∈ Ioc 0 ⌊x⌋₊, (1 : ℝ) := h
    _ = (∑ n ∈ Ioc 0 ⌊x⌋₊, f n ^ 2 / n) * ∑ _n ∈ Ioc 0 ⌊x⌋₊, (1 : ℝ) := by
        rw [Finset.sum_congr rfl hsq]
    _ ≤ (∑ n ∈ Ioc 0 ⌊x⌋₊, f n ^ 2 / n) * x := by
        apply mul_le_mul_of_nonneg_left hcard
        exact Finset.sum_nonneg fun n hn => by positivity
    _ = x * ∑ n ∈ Ioc 0 ⌊x⌋₊, f n ^ 2 / n := mul_comm _ _

/-- **F1.3 (Montgomery–Vaughan frequency separation)**: consecutive integer
log-frequencies satisfy log(n+1) − log n ≥ 1/(n+1). This is the only
support-geometry input the MV Hilbert inequality ([Z23] Lemma 5.2, already
formalized coefficient-free in `Zeta23/MV`) requires; it holds for *any*
integer-supported system — `support_primePow` is stronger than needed. -/
theorem freq_spacing (n : ℕ) (hn : 1 ≤ n) :
    1 / ((n : ℝ) + 1) ≤ Real.log ((n : ℝ) + 1) - Real.log n := by
  have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
  have hn1pos : (0 : ℝ) < (n : ℝ) + 1 := by linarith
  have hratio : (0 : ℝ) < (n : ℝ) / ((n : ℝ) + 1) := by positivity
  have hlog := Real.log_le_sub_one_of_pos hratio
  have hdiv : Real.log ((n : ℝ) / ((n : ℝ) + 1))
      = Real.log n - Real.log ((n : ℝ) + 1) :=
    Real.log_div hnpos.ne' hn1pos.ne'
  rw [hdiv] at hlog
  have harith : (n : ℝ) / ((n : ℝ) + 1) - 1 = -(1 / ((n : ℝ) + 1)) := by
    field_simp
    ring
  rw [harith] at hlog
  linarith

/-! ## Stage F2a: the sharp √-moment by dyadic descent

[Z23] Lemma 5.1's Σ Λ(n)/√n ≤ 3√x is the estimate whose crude
(Cauchy–Schwarz) grade costs the λ = 1 endpoint. [Z23] proves it by Abel
summation against ψ; here the interface version is proved by **dyadic
descent** instead — the top half-block pays (√2/√n)·`chebyshev`, the
bottom half recurses — no integral, no measure theory, finite sums only.
The constant 2(√2+1)(log 4 + 4) is worse than [Z23]'s 3 and harmless:
their Lemma 5.2 remark notes any absolute constant suffices. The proof
is the program's own collapse operator (companion paper §12, Rung 4):
iterate "halve and pay" until the sum jams at zero. -/

/-- The interface Chebyshev bound at integer cutoffs. -/
theorem psi_nat_le (hf : EulerStiffness f) (n : ℕ) :
    ∑ k ∈ Ioc 0 n, f k ≤ (Real.log 4 + 4) * n := by
  have h := hf.chebyshev n (Nat.cast_nonneg n)
  rwa [Nat.floor_natCast] at h

/-- **F2a (sharp √-moment, dyadic descent)**:
Σ_{k ≤ n} f(k)/√k ≤ 2(√2+1)·(log 4 + 4)·√n, from the `chebyshev` and
`nonneg` fields alone. Closes the λ = 1 endpoint left open by the crude
grade F1.2 (see Factorization.md, F0 verdict, qualification 1). -/
theorem sum_div_sqrt_le (hf : EulerStiffness f) (n : ℕ) :
    ∑ k ∈ Ioc 0 n, f k / Real.sqrt k
      ≤ 2 * (Real.sqrt 2 + 1) * ((Real.log 4 + 4) * Real.sqrt n) := by
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · simp
    have hC : (0 : ℝ) ≤ Real.log 4 + 4 := by
      have := Real.log_nonneg (by norm_num : (1 : ℝ) ≤ 4)
      linarith
    have hs2 : (0 : ℝ) < Real.sqrt 2 := Real.sqrt_pos.mpr (by norm_num)
    have hss : Real.sqrt 2 * Real.sqrt 2 = 2 :=
      Real.mul_self_sqrt (by norm_num)
    have hsn : (0 : ℝ) < Real.sqrt n :=
      Real.sqrt_pos.mpr (by exact_mod_cast hn)
    have hsplit : Ioc 0 (n / 2) ∪ Ioc (n / 2) n = Ioc 0 n :=
      Finset.Ioc_union_Ioc_eq_Ioc (Nat.zero_le _) (Nat.div_le_self n 2)
    have hdisj : Disjoint (Ioc 0 (n / 2)) (Ioc (n / 2) n) :=
      Finset.Ioc_disjoint_Ioc_of_le le_rfl
    rw [← hsplit, Finset.sum_union hdisj]
    -- top block: every k > n/2 has n ≤ 2k, hence 1/√k ≤ √2/√n
    have htop : ∑ k ∈ Ioc (n / 2) n, f k / Real.sqrt k
        ≤ Real.sqrt 2 * ((Real.log 4 + 4) * Real.sqrt n) := by
      have hbound : ∀ k ∈ Ioc (n / 2) n,
          f k / Real.sqrt k ≤ Real.sqrt 2 / Real.sqrt n * f k := by
        intro k hk
        obtain ⟨hk1, _⟩ := Finset.mem_Ioc.mp hk
        have hkpos : 0 < k := lt_of_le_of_lt (Nat.zero_le _) hk1
        have h2k : (n : ℝ) ≤ 2 * k := by
          have : n ≤ 2 * k := by omega
          exact_mod_cast this
        have hsk : (0 : ℝ) < Real.sqrt k :=
          Real.sqrt_pos.mpr (by exact_mod_cast hkpos)
        have hcmp : Real.sqrt n ≤ Real.sqrt 2 * Real.sqrt k := by
          rw [← Real.sqrt_mul (by norm_num : (0:ℝ) ≤ 2)]
          exact Real.sqrt_le_sqrt h2k
        have h1k : 1 / Real.sqrt k ≤ Real.sqrt 2 / Real.sqrt n := by
          rw [div_le_div_iff₀ hsk hsn]
          linarith
        calc f k / Real.sqrt k = 1 / Real.sqrt k * f k := by ring
          _ ≤ Real.sqrt 2 / Real.sqrt n * f k :=
              mul_le_mul_of_nonneg_right h1k (hf.nonneg k)
      calc ∑ k ∈ Ioc (n / 2) n, f k / Real.sqrt k
          ≤ ∑ k ∈ Ioc (n / 2) n, Real.sqrt 2 / Real.sqrt n * f k :=
            Finset.sum_le_sum hbound
        _ = Real.sqrt 2 / Real.sqrt n * ∑ k ∈ Ioc (n / 2) n, f k := by
            rw [Finset.mul_sum]
        _ ≤ Real.sqrt 2 / Real.sqrt n * ∑ k ∈ Ioc 0 n, f k := by
            apply mul_le_mul_of_nonneg_left _ (by positivity)
            exact Finset.sum_le_sum_of_subset_of_nonneg
              (Finset.Ioc_subset_Ioc (Nat.zero_le _) le_rfl)
              (fun k _ _ => hf.nonneg k)
        _ ≤ Real.sqrt 2 / Real.sqrt n * ((Real.log 4 + 4) * n) := by
            apply mul_le_mul_of_nonneg_left (psi_nat_le hf n) (by positivity)
        _ = Real.sqrt 2 * ((Real.log 4 + 4) * Real.sqrt n) := by
            have h1 : Real.sqrt 2 / Real.sqrt n * ((Real.log 4 + 4) * (n : ℝ))
                = Real.sqrt 2 * (Real.log 4 + 4) * ((n : ℝ) / Real.sqrt n) := by
              ring
            rw [h1, Real.div_sqrt]
            ring
    -- bottom block: recurse on n/2 and compare √(n/2) ≤ √n/√2
    have hbot : ∑ k ∈ Ioc 0 (n / 2), f k / Real.sqrt k
        ≤ 2 * (Real.sqrt 2 + 1) * ((Real.log 4 + 4) * (Real.sqrt n / Real.sqrt 2)) := by
      refine le_trans (ih (n / 2) (Nat.div_lt_self hn one_lt_two)) ?_
      have hle : Real.sqrt (n / 2 : ℕ) ≤ Real.sqrt n / Real.sqrt 2 := by
        rw [← Real.sqrt_div (Nat.cast_nonneg n)]
        exact Real.sqrt_le_sqrt (Nat.cast_div_le)
      have hK : (0 : ℝ) ≤ 2 * (Real.sqrt 2 + 1) := by positivity
      apply mul_le_mul_of_nonneg_left _ hK
      exact mul_le_mul_of_nonneg_left hle hC
    refine le_trans (add_le_add hbot htop) (le_of_eq ?_)
    have hfe : 2 * (Real.sqrt 2 + 1) * (Real.sqrt n / Real.sqrt 2)
        + Real.sqrt 2 * Real.sqrt n = 2 * (Real.sqrt 2 + 1) * Real.sqrt n := by
      field_simp
      nlinarith [hss, hsn.le, hs2.le]
    calc 2 * (Real.sqrt 2 + 1) * ((Real.log 4 + 4) * (Real.sqrt n / Real.sqrt 2))
          + Real.sqrt 2 * ((Real.log 4 + 4) * Real.sqrt n)
        = (Real.log 4 + 4) * (2 * (Real.sqrt 2 + 1) * (Real.sqrt n / Real.sqrt 2)
            + Real.sqrt 2 * Real.sqrt n) := by ring
      _ = (Real.log 4 + 4) * (2 * (Real.sqrt 2 + 1) * Real.sqrt n) := by rw [hfe]
      _ = 2 * (Real.sqrt 2 + 1) * ((Real.log 4 + 4) * Real.sqrt n) := by ring

/-- F2a at real cutoffs: Σ_{n ≤ x} f(n)/√n ≪ √x, the exact shape [Z23]
Lemma 5.1 consumes. -/
theorem sum_div_sqrt_le_real (hf : EulerStiffness f) {x : ℝ} (hx : 0 ≤ x) :
    ∑ k ∈ Ioc 0 ⌊x⌋₊, f k / Real.sqrt k
      ≤ 2 * (Real.sqrt 2 + 1) * ((Real.log 4 + 4) * Real.sqrt x) := by
  refine le_trans (sum_div_sqrt_le hf ⌊x⌋₊) ?_
  have hC : (0 : ℝ) ≤ Real.log 4 + 4 := by
    have := Real.log_nonneg (by norm_num : (1 : ℝ) ≤ 4)
    linarith
  have hle : Real.sqrt ⌊x⌋₊ ≤ Real.sqrt x :=
    Real.sqrt_le_sqrt (Nat.floor_le hx)
  have hK : (0 : ℝ) ≤ 2 * (Real.sqrt 2 + 1) := by positivity
  exact mul_le_mul_of_nonneg_left (mul_le_mul_of_nonneg_left hle hC) hK

end Factorization

#print axioms Factorization.sum_sq_le
#print axioms Factorization.sum_div_sqrt_sq_le
#print axioms Factorization.freq_spacing
#print axioms Factorization.psi_nat_le
#print axioms Factorization.sum_div_sqrt_le
#print axioms Factorization.sum_div_sqrt_le_real
