/-
Factorization.lean — Stage F1 of the factorization experiment
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

end Factorization

#print axioms Factorization.sum_sq_le
#print axioms Factorization.sum_div_sqrt_sq_le
#print axioms Factorization.freq_spacing
