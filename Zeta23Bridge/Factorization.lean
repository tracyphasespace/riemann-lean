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

/-! ## Stage F2b: the equality-grade layer, discretely

[Z23] (5.2)'s second form — the integrated second moment
Σ f(n)²/n·(log x − log n) = log³x/6 + O(log²x) — is an asymptotic
*equality*; [Z23] proves it as ∫ M2(t)/t dt. Here it is derived from the
`mertens_energy` field by **finite Abel summation**: a triangular sum
swap, telescoping cubes, and two helper sums (harmonic ≤ 1 + log N,
powered by F1.3's own spacing bound; Σ1/m² ≤ 2). No integrals, no
measure theory — the same elementary toolkit as F2a. -/

/-- The interface forces `f 1 = 0` (1 is not a prime power). -/
theorem apply_one (hf : EulerStiffness f) : f 1 = 0 := by
  by_contra h
  exact not_isPrimePow_one (hf.support_primePow 1 h)

/-- Harmonic bound Σ_{m ≤ N} 1/m ≤ 1 + log N — by induction, each step paid
by the F1.3 spacing bound `freq_spacing`. -/
theorem harmonic_le (N : ℕ) : ∑ m ∈ Ioc 0 N, (1 : ℝ) / m ≤ 1 + Real.log N := by
  induction N with
  | zero => simp
  | succ M ih =>
      rcases Nat.eq_zero_or_pos M with rfl | hM
      · simp
      rw [Finset.sum_Ioc_succ_top (Nat.zero_le _)]
      have hstep := freq_spacing M hM
      have hcast : ((M + 1 : ℕ) : ℝ) = (M : ℝ) + 1 := by push_cast; ring
      rw [hcast]
      linarith

/-- Σ_{m ≤ N} 1/m² ≤ 2 — finite telescoping. -/
theorem inv_sq_le (N : ℕ) : ∑ m ∈ Ioc 0 N, (1 : ℝ) / (m : ℝ) ^ 2 ≤ 2 := by
  have key : ∀ M : ℕ, ∑ m ∈ Ioc 0 (M + 1), (1 : ℝ) / (m : ℝ) ^ 2
      ≤ 2 - 1 / ((M : ℝ) + 1) := by
    intro M
    induction M with
    | zero => norm_num
    | succ K ih =>
        rw [Finset.sum_Ioc_succ_top (Nat.zero_le _)]
        have hK1 : (0 : ℝ) < (K : ℝ) + 1 := by positivity
        have hK2 : (0 : ℝ) < (K : ℝ) + 2 := by positivity
        have hcast : ((K + 1 + 1 : ℕ) : ℝ) = (K : ℝ) + 2 := by push_cast; ring
        rw [hcast]
        have htel : 1 / ((K : ℝ) + 2) ^ 2 ≤ 1 / ((K : ℝ) + 1) - 1 / ((K : ℝ) + 2) := by
          rw [div_sub_div _ _ hK1.ne' hK2.ne',
            div_le_div_iff₀ (by positivity) (by positivity)]
          ring_nf
          nlinarith [sq_nonneg (K : ℝ)]
        have hgoalcast : ((K + 1 : ℕ) : ℝ) = (K : ℝ) + 1 := by push_cast; ring
        rw [hgoalcast, show ((K : ℝ) + 1 + 1) = (K : ℝ) + 2 from by ring]
        linarith
  rcases Nat.eq_zero_or_pos N with rfl | hN
  · simp
  obtain ⟨M, rfl⟩ := Nat.exists_eq_add_of_le hN
  have := key M
  have h1 : (0 : ℝ) < 1 / ((M : ℝ) + 1) := by positivity
  calc ∑ m ∈ Ioc 0 (1 + M), (1 : ℝ) / (m : ℝ) ^ 2
      = ∑ m ∈ Ioc 0 (M + 1), (1 : ℝ) / (m : ℝ) ^ 2 := by rw [Nat.add_comm]
    _ ≤ 2 - 1 / ((M : ℝ) + 1) := key M
    _ ≤ 2 := by linarith

/-- Δ_m = log(m+1) − log m ≤ 1/m. -/
theorem log_succ_sub_le (m : ℕ) (hm : 1 ≤ m) :
    Real.log ((m : ℝ) + 1) - Real.log m ≤ 1 / m := by
  have hmR : (0 : ℝ) < m := by exact_mod_cast hm
  have hratio : (0 : ℝ) < ((m : ℝ) + 1) / m := by positivity
  have h := Real.log_le_sub_one_of_pos hratio
  have hdiv : Real.log (((m : ℝ) + 1) / m) = Real.log ((m : ℝ) + 1) - Real.log m :=
    Real.log_div (by positivity) hmR.ne'
  rw [hdiv] at h
  have harith : ((m : ℝ) + 1) / m - 1 = 1 / m := by
    field_simp
    ring
  linarith [h, harith.symm.le, harith.le]

/-- Telescoping over `Ico`: Σ_{m∈[a,b)} (F(m+1) − F(m)) = F(b) − F(a). -/
theorem telescope_Ico (F : ℕ → ℝ) {a b : ℕ} (hab : a ≤ b) :
    ∑ m ∈ Ico a b, (F (m + 1) - F m) = F b - F a := by
  rw [Finset.sum_Ico_eq_sum_range]
  have h := Finset.sum_range_sub (fun i => F (a + i)) (b - a)
  simp only [← Nat.add_assoc] at h
  rw [Nat.add_sub_cancel' hab] at h
  simpa using h

/-- **The finite Abel swap** (triangular exchange): for any coefficients,
Σ_{n ≤ N} c(n)·(log N − log n) = Σ_{m < N} (Σ_{n ≤ m} c(n))·Δ_m. -/
theorem abel_swap (c : ℕ → ℝ) (N : ℕ) :
    ∑ n ∈ Ioc 0 N, c n * (Real.log N - Real.log n)
      = ∑ m ∈ Ico 1 N, (∑ n ∈ Ioc 0 m, c n)
          * (Real.log ((m : ℝ) + 1) - Real.log m) := by
  have htel : ∀ n ∈ Ioc 0 N,
      Real.log N - Real.log n
        = ∑ m ∈ Ico n N, (Real.log ((m : ℝ) + 1) - Real.log m) := by
    intro n hn
    obtain ⟨_, hnN⟩ := Finset.mem_Ioc.mp hn
    have h := telescope_Ico (fun k : ℕ => Real.log k) hnN
    calc Real.log N - Real.log n
        = ∑ m ∈ Ico n N, (Real.log ((m + 1 : ℕ) : ℝ) - Real.log m) := h.symm
      _ = ∑ m ∈ Ico n N, (Real.log ((m : ℝ) + 1) - Real.log m) := by
          refine Finset.sum_congr rfl fun m _ => ?_
          push_cast
          ring
  calc ∑ n ∈ Ioc 0 N, c n * (Real.log N - Real.log n)
      = ∑ n ∈ Ioc 0 N, ∑ m ∈ Ico n N,
          c n * (Real.log ((m : ℝ) + 1) - Real.log m) := by
        refine Finset.sum_congr rfl fun n hn => ?_
        rw [htel n hn, Finset.mul_sum]
    _ = ∑ m ∈ Ico 1 N, ∑ n ∈ Ioc 0 m,
          c n * (Real.log ((m : ℝ) + 1) - Real.log m) := by
        refine Finset.sum_comm' ?_
        intro n m
        simp only [Finset.mem_Ioc, Finset.mem_Ico]
        omega
    _ = ∑ m ∈ Ico 1 N, (∑ n ∈ Ioc 0 m, c n)
          * (Real.log ((m : ℝ) + 1) - Real.log m) := by
        refine Finset.sum_congr rfl fun m _ => ?_
        rw [← Finset.sum_mul]

/-- Per-step cube comparison: |½a²Δ − (b³−a³)/6| ≤ ½Δ²·b for 0 ≤ a ≤ b. -/
theorem cube_step {a b : ℝ} (ha : 0 ≤ a) (hab : a ≤ b) :
    |a ^ 2 / 2 * (b - a) - (b ^ 3 - a ^ 3) / 6| ≤ (b - a) ^ 2 * b / 2 := by
  have hid : a ^ 2 / 2 * (b - a) - (b ^ 3 - a ^ 3) / 6
      = -((b - a) ^ 2 * (2 * a + b) / 6) := by ring
  have h2ab : (0 : ℝ) ≤ 2 * a + b := by linarith
  have hnn : (0 : ℝ) ≤ (b - a) ^ 2 * (2 * a + b) / 6 :=
    div_nonneg (mul_nonneg (sq_nonneg _) h2ab) (by norm_num)
  rw [hid, abs_neg, abs_of_nonneg hnn]
  nlinarith [sq_nonneg (b - a)]

/-- Per-step square comparison: aΔ ≤ ½(b² − a²) for a ≤ b. -/
theorem sq_step {a b : ℝ} (hab : a ≤ b) :
    a * (b - a) ≤ (b ^ 2 - a ^ 2) / 2 := by
  nlinarith [sq_nonneg (b - a)]

/-- **F2b (integrated second moment)**: from the `mertens_energy` field,
Σ_{n ≤ N} f(n)²/n · (log N − log n) = log³N/6 + O(log²N) — [Z23] (5.2)'s
second form, for any interface-f, by finite Abel summation. -/
theorem integrated_second_moment (hf : EulerStiffness f) :
    ∃ C : ℝ, 0 < C ∧ ∀ N : ℕ, 2 ≤ N →
      |(∑ n ∈ Ioc 0 N, f n ^ 2 / n * (Real.log N - Real.log n))
        - Real.log N ^ 3 / 6| ≤ C * Real.log N ^ 2 := by
  obtain ⟨C₀, hC₀, hME⟩ := hf.mertens_energy
  refine ⟨C₀ / 2 + 3, by positivity, ?_⟩
  intro N hN
  have hNR : (0 : ℝ) < N := by positivity
  have hlogN : (0 : ℝ) < Real.log N := by
    apply Real.log_pos
    exact_mod_cast (by omega : 1 < N)
  have hlog2 : Real.log 2 ≤ Real.log N := by
    apply Real.log_le_log (by norm_num)
    exact_mod_cast hN
  have hl2 : (0.693 : ℝ) < Real.log 2 := by
    have := Real.log_two_gt_d9
    linarith
  -- the swap, with c n = f n²/n
  rw [abel_swap (fun n => f n ^ 2 / n) N]
  set Δ : ℕ → ℝ := fun m => Real.log ((m : ℝ) + 1) - Real.log m with hΔ
  set M2 : ℕ → ℝ := fun m => ∑ n ∈ Ioc 0 m, f n ^ 2 / n with hM2
  -- Δ facts
  have hΔnn : ∀ m ∈ Ico 1 N, 0 ≤ Δ m := by
    intro m hm
    obtain ⟨hm1, _⟩ := Finset.mem_Ico.mp hm
    have : (0 : ℝ) < m := by exact_mod_cast hm1
    have := Real.log_le_log this (by linarith : (m : ℝ) ≤ (m : ℝ) + 1)
    simpa [hΔ] using sub_nonneg.mpr this
  have hlogmono : ∀ m ∈ Ico 1 N, Real.log ((m : ℝ) + 1) ≤ Real.log N := by
    intro m hm
    obtain ⟨_, hmN⟩ := Finset.mem_Ico.mp hm
    apply Real.log_le_log (by positivity)
    have : (m : ℝ) + 1 ≤ N := by exact_mod_cast Nat.succ_le_of_lt hmN
    linarith
  -- the error field at integer cutoffs, all m ∈ Ico 1 N
  have hEm : ∀ m ∈ Ico 1 N, |M2 m - Real.log m ^ 2 / 2| ≤ C₀ * Real.log m := by
    intro m hm
    obtain ⟨hm1, _⟩ := Finset.mem_Ico.mp hm
    rcases Nat.lt_or_ge m 2 with hm2 | hm2
    · interval_cases m
      have h1 : M2 1 = 0 := by
        simp [hM2, apply_one hf]
      rw [h1]
      norm_num [Real.log_one]
    · have h := hME m (by exact_mod_cast hm2)
      rwa [Nat.floor_natCast] at h
  -- decompose the swapped sum
  have hdecomp : ∑ m ∈ Ico 1 N, M2 m * Δ m
      = (∑ m ∈ Ico 1 N, Real.log m ^ 2 / 2 * Δ m)
        + ∑ m ∈ Ico 1 N, (M2 m - Real.log m ^ 2 / 2) * Δ m := by
    rw [← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun m _ => ?_
    ring
  rw [show (∑ m ∈ Ico 1 N, M2 m * Δ m) - Real.log N ^ 3 / 6
      = ((∑ m ∈ Ico 1 N, Real.log m ^ 2 / 2 * Δ m) - Real.log N ^ 3 / 6)
        + ∑ m ∈ Ico 1 N, (M2 m - Real.log m ^ 2 / 2) * Δ m by
    rw [hdecomp]; ring]
  -- main part: telescoping cubes
  have hmain : |(∑ m ∈ Ico 1 N, Real.log m ^ 2 / 2 * Δ m) - Real.log N ^ 3 / 6|
      ≤ (1 + Real.log N) / 2 := by
    have hcube : Real.log N ^ 3 / 6
        = ∑ m ∈ Ico 1 N, (Real.log ((m : ℝ) + 1) ^ 3 - Real.log m ^ 3) / 6 := by
      have h := telescope_Ico (fun k : ℕ => Real.log k ^ 3)
        (by omega : 1 ≤ N)
      have h2 : ∑ m ∈ Ico 1 N, (Real.log ((m : ℝ) + 1) ^ 3 - Real.log m ^ 3)
          = Real.log N ^ 3 - Real.log (1 : ℕ) ^ 3 := by
        rw [← h]
        refine Finset.sum_congr rfl fun m _ => ?_
        push_cast
        ring
      rw [← Finset.sum_div, h2]
      norm_num
    rw [hcube, ← Finset.sum_sub_distrib]
    refine le_trans (Finset.abs_sum_le_sum_abs _ _) ?_
    have hterm : ∀ m ∈ Ico 1 N,
        |Real.log m ^ 2 / 2 * Δ m
          - (Real.log ((m : ℝ) + 1) ^ 3 - Real.log m ^ 3) / 6|
        ≤ 1 / (m : ℝ) / 2 := by
      intro m hm
      obtain ⟨hm1, _⟩ := Finset.mem_Ico.mp hm
      have hmR : (0 : ℝ) < m := by exact_mod_cast hm1
      have hla : (0 : ℝ) ≤ Real.log m := Real.log_natCast_nonneg m
      have hlab : Real.log m ≤ Real.log ((m : ℝ) + 1) :=
        Real.log_le_log hmR (by linarith)
      have h1 := cube_step hla hlab
      have hΔm : Δ m ≤ 1 / m := log_succ_sub_le m hm1
      have hΔmnn : 0 ≤ Δ m := by
        simpa [hΔ] using sub_nonneg.mpr hlab
      have hb : Real.log ((m : ℝ) + 1) ≤ (m : ℝ) := by
        have := Real.log_le_sub_one_of_pos (by positivity : (0:ℝ) < (m : ℝ) + 1)
        linarith
      have hchain : (Δ m) ^ 2 * Real.log ((m : ℝ) + 1) / 2 ≤ 1 / (m : ℝ) / 2 := by
        have h2 : (Δ m) ^ 2 ≤ (1 / (m : ℝ)) ^ 2 := by
          apply sq_le_sq' (by linarith) hΔm
        have h3 : (Δ m) ^ 2 * Real.log ((m : ℝ) + 1)
            ≤ (1 / (m : ℝ)) ^ 2 * (m : ℝ) := by
          apply mul_le_mul h2 hb
            (Real.log_nonneg (by linarith)) (by positivity)
        have h4 : (1 / (m : ℝ)) ^ 2 * (m : ℝ) = 1 / (m : ℝ) := by
          field_simp
        linarith [h3, h4.le, h4.ge]
      calc |Real.log m ^ 2 / 2 * Δ m
            - (Real.log ((m : ℝ) + 1) ^ 3 - Real.log m ^ 3) / 6|
          ≤ (Δ m) ^ 2 * Real.log ((m : ℝ) + 1) / 2 := by
            have h := cube_step hla hlab
            simpa [hΔ] using h
        _ ≤ 1 / (m : ℝ) / 2 := hchain
    refine le_trans (Finset.sum_le_sum hterm) ?_
    have hsub : ∑ m ∈ Ico 1 N, 1 / (m : ℝ) / 2 ≤ (1 + Real.log N) / 2 := by
      rw [← Finset.sum_div]
      gcongr
      calc ∑ m ∈ Ico 1 N, 1 / (m : ℝ)
            ≤ ∑ m ∈ Ioc 0 N, (1 : ℝ) / m := by
              apply Finset.sum_le_sum_of_subset_of_nonneg
              · intro m hm
                simp only [Finset.mem_Ico, Finset.mem_Ioc] at hm ⊢
                omega
              · intro m _ _
                positivity
          _ ≤ 1 + Real.log N := harmonic_le N
    exact hsub
  -- error part: |Σ E·Δ| ≤ C₀·½log²N
  have herr : |∑ m ∈ Ico 1 N, (M2 m - Real.log m ^ 2 / 2) * Δ m|
      ≤ C₀ * Real.log N ^ 2 / 2 := by
    refine le_trans (Finset.abs_sum_le_sum_abs _ _) ?_
    have hterm : ∀ m ∈ Ico 1 N,
        |(M2 m - Real.log m ^ 2 / 2) * Δ m| ≤ C₀ * (Real.log m * Δ m) := by
      intro m hm
      rw [abs_mul, abs_of_nonneg (hΔnn m hm)]
      have h1 := hEm m hm
      have h2 := hΔnn m hm
      calc |M2 m - Real.log m ^ 2 / 2| * Δ m
          ≤ C₀ * Real.log m * Δ m := by
            apply mul_le_mul_of_nonneg_right h1 h2
        _ = C₀ * (Real.log m * Δ m) := by ring
    refine le_trans (Finset.sum_le_sum hterm) ?_
    rw [← Finset.mul_sum, mul_div_assoc]
    apply mul_le_mul_of_nonneg_left _ hC₀.le
    -- Σ log m · Δ m ≤ ½ log²N by telescoping squares
    have hsq : ∑ m ∈ Ico 1 N, Real.log m * Δ m
        ≤ ∑ m ∈ Ico 1 N, (Real.log ((m : ℝ) + 1) ^ 2 - Real.log m ^ 2) / 2 := by
      refine Finset.sum_le_sum fun m hm => ?_
      obtain ⟨hm1, _⟩ := Finset.mem_Ico.mp hm
      have hmR : (0 : ℝ) < m := by exact_mod_cast hm1
      have hlab : Real.log m ≤ Real.log ((m : ℝ) + 1) :=
        Real.log_le_log hmR (by linarith)
      simpa [hΔ] using sq_step hlab
    refine le_trans hsq ?_
    have h2 : ∑ m ∈ Ico 1 N, (Real.log ((m : ℝ) + 1) ^ 2 - Real.log m ^ 2)
        = Real.log N ^ 2 - Real.log (1 : ℕ) ^ 2 := by
      rw [← telescope_Ico (fun k : ℕ => Real.log k ^ 2) (by omega : 1 ≤ N)]
      refine Finset.sum_congr rfl fun m _ => ?_
      push_cast
      ring
    rw [← Finset.sum_div, h2]
    norm_num
  -- assemble
  refine le_trans (abs_add_le _ _) ?_
  have hfinal : (1 + Real.log N) / 2 + C₀ * Real.log N ^ 2 / 2
      ≤ (C₀ / 2 + 3) * Real.log N ^ 2 := by
    have h1 : (1 : ℝ) ≤ Real.log N ^ 2 / (Real.log 2) ^ 2 := by
      rw [le_div_iff₀ (by positivity)]
      nlinarith [hlog2, hl2, hlogN]
    nlinarith [hlog2, hl2, hlogN, sq_nonneg (Real.log N)]
  linarith [hmain, herr, hfinal]

/-! ## Stage F3: the modulus interface (phase-blind by definition)

[Z23] Theorem E reruns the proof for Dirichlet L-functions with
coefficients Λ(n)χ(n); their §7.3 notes the phase factors "enter all
bounds only through |aₙ|". Stage F3 types this per the style-law
(companion paper §11, clause 2): **the concept is modulus + rotor, and
the interface reads only the modulus.** Accordingly `EulerStiffnessC` is
not a new ℂ-carrying structure but a *definition*: a phase-carrying
system (modeled as ℂ-valued — ℂ as shadow, never as carrier) satisfies
the interface iff its modulus, a real object, does. Phase-blindness is
definitional; rotor-invariance (`twist`) is a `funext`; every F1/F2
estimate transfers by `Iff.rfl`-strength reductions. -/

/-- The modulus interface: `g` qualifies iff its modulus satisfies the
real interface. ℂ here is the standard *model* of a modulus-plus-rotor
system; the definition consumes only `‖g n‖`. -/
def EulerStiffnessC (g : ℕ → ℂ) : Prop :=
  EulerStiffness (fun n => ‖g n‖)

/-- The modulus reduction — definitional. -/
theorem EulerStiffnessC.norm {g : ℕ → ℂ} (hg : EulerStiffnessC g) :
    EulerStiffness (fun n => ‖g n‖) := hg

/-- A real interface system, embedded in the model, qualifies. -/
theorem EulerStiffness.toC {f : ℕ → ℝ} (hf : EulerStiffness f) :
    EulerStiffnessC (fun n => (f n : ℂ)) := by
  unfold EulerStiffnessC
  have heq : (fun n => ‖((f n : ℝ) : ℂ)‖) = fun n => f n :=
    funext fun n => by
      rw [Complex.norm_real, Real.norm_of_nonneg (hf.nonneg n)]
  rw [heq]
  exact hf

/-- ζ in the modulus interface. -/
theorem eulerStiffnessC_vonMangoldt :
    EulerStiffnessC (fun n => ((ArithmeticFunction.vonMangoldt n : ℝ) : ℂ)) :=
  EulerStiffness.toC eulerStiffness_vonMangoldt

/-- **Rotor invariance (the Dirichlet shape)**: a unimodular twist — a
rotor per coefficient — preserves the interface *definitionally*: the
moduli are literally the same function. This is the abstract form of
[Z23] §7.3. (A primitive character's vanishing at p ∣ q is
sub-unimodular and is instance-level work: milestone F3b.) -/
theorem EulerStiffnessC.twist {g : ℕ → ℂ} (hg : EulerStiffnessC g)
    (u : ℕ → ℂ) (hu : ∀ n, ‖u n‖ = 1) :
    EulerStiffnessC (fun n => u n * g n) := by
  unfold EulerStiffnessC at hg ⊢
  have heq : (fun n => ‖u n * g n‖) = fun n => ‖g n‖ :=
    funext fun n => by rw [norm_mul, hu n, one_mul]
  rw [heq]
  exact hg

/-- F2a transferred: the sharp √-moment for phase-carrying systems. -/
theorem sum_norm_div_sqrt_le {g : ℕ → ℂ} (hg : EulerStiffnessC g) (n : ℕ) :
    ∑ k ∈ Ioc 0 n, ‖g k‖ / Real.sqrt k
      ≤ 2 * (Real.sqrt 2 + 1) * ((Real.log 4 + 4) * Real.sqrt n) :=
  sum_div_sqrt_le hg.norm n

/-- F2b transferred: the integrated second moment for phase-carrying
systems. -/
theorem integrated_second_momentC {g : ℕ → ℂ} (hg : EulerStiffnessC g) :
    ∃ C : ℝ, 0 < C ∧ ∀ N : ℕ, 2 ≤ N →
      |(∑ n ∈ Ioc 0 N, ‖g n‖ ^ 2 / n * (Real.log N - Real.log n))
        - Real.log N ^ 3 / 6| ≤ C * Real.log N ^ 2 :=
  integrated_second_moment hg.norm

/-- The 6-cell exclusion, modulus form. -/
theorem EulerStiffnessC.apply_six {g : ℕ → ℂ} (hg : EulerStiffnessC g) :
    g 6 = 0 := by
  by_contra h
  exact not_isPrimePow_six
    (hg.norm.support_primePow 6 (norm_ne_zero_iff.mpr h))

/-- **Davenport–Heilbronn is excluded from the modulus interface too**:
the defect 1 + κ² ≠ 0 survives the embedding into the model. -/
theorem dh_not_eulerStiffnessC {f L : ℕ → ℝ} (κ : ℝ)
    (hf2 : f 2 = κ) (hf3 : f 3 = -κ) (hf6 : f 6 = 1)
    (h : LogDerivAt6 f L) :
    ¬ EulerStiffnessC (fun n => (L n : ℂ)) := by
  intro hE
  have h6 : ((L 6 : ℝ) : ℂ) = 0 := hE.apply_six
  have h6R : L 6 = 0 := by exact_mod_cast h6
  exact absurd h6R (ne_of_gt (dh_logDeriv6_pos κ hf2 hf3 hf6 h))

/-! ## Stage F4a: arithmetic closure of the prime side

The remaining coefficient-consuming touchpoints of [Z23] §5, covered:
the **tapered diagonal main term** (Prop 5.6 for general windows — the
heart of tr G̃²) via a sandwich reduction to F2b.1, and the log-weighted
√-moment. With these, *every* step of [Z23] §5 that reads coefficients
routes through an interface-derived theorem; what remains of §5 is
coefficient-free window/archimedean analysis ([Z23] §7.1: "Nothing in
Sections 4–5 used that φ is flat-topped, only [window properties]"). -/

/-- Log-weighted √-moment: Σ f(k)·log k/√k ≤ log n · (F2a bound) —
covers the log-weighted variant of [Z23] Lemma 5.1. -/
theorem sum_mul_log_div_sqrt_le (hf : EulerStiffness f) (n : ℕ) (hn : 1 ≤ n) :
    ∑ k ∈ Ioc 0 n, f k * Real.log k / Real.sqrt k
      ≤ Real.log n * (2 * (Real.sqrt 2 + 1) * ((Real.log 4 + 4) * Real.sqrt n)) := by
  have hstep : ∀ k ∈ Ioc 0 n, f k * Real.log k / Real.sqrt k
      ≤ Real.log n * (f k / Real.sqrt k) := by
    intro k hk
    obtain ⟨hk1, hkn⟩ := Finset.mem_Ioc.mp hk
    have hkR : (0 : ℝ) < k := by exact_mod_cast hk1
    have hlogk : Real.log k ≤ Real.log n :=
      Real.log_le_log hkR (by exact_mod_cast hkn)
    have hsk : (0 : ℝ) < Real.sqrt k :=
      Real.sqrt_pos.mpr hkR
    have h1 : f k * Real.log k ≤ f k * Real.log n :=
      mul_le_mul_of_nonneg_left hlogk (hf.nonneg k)
    calc f k * Real.log k / Real.sqrt k
        ≤ f k * Real.log n / Real.sqrt k :=
          (div_le_div_iff_of_pos_right hsk).mpr h1
      _ = Real.log n * (f k / Real.sqrt k) := by ring
  calc ∑ k ∈ Ioc 0 n, f k * Real.log k / Real.sqrt k
      ≤ ∑ k ∈ Ioc 0 n, Real.log n * (f k / Real.sqrt k) :=
        Finset.sum_le_sum hstep
    _ = Real.log n * ∑ k ∈ Ioc 0 n, f k / Real.sqrt k := by
        rw [Finset.mul_sum]
    _ ≤ Real.log n * (2 * (Real.sqrt 2 + 1) * ((Real.log 4 + 4) * Real.sqrt n)) := by
        apply mul_le_mul_of_nonneg_left (sum_div_sqrt_le hf n)
        exact Real.log_nonneg (by exact_mod_cast hn)

/-- **F4a (the tapered diagonal main term, by sandwich)**: for any window
weight `w` squeezed between the sharp cutoffs at `N` (above) and `M`
(below), the diagonal Σ f(n)²/n·w(n) carries the log³N/6 main term with
defect controlled by log²N and the taper width (log N − log M)·log²N.
This is [Z23] Prop 5.6 / §7.1's general-window diagonal — the heart of
the Frobenius main term — reduced to two applications of F2b.1 plus a
cube-difference bound. No integrals; the window enters only through the
sandwich, exactly as in [Z23] (2.16). -/
theorem tapered_diagonal (hf : EulerStiffness f) :
    ∃ C : ℝ, 0 < C ∧ ∀ (N M : ℕ) (w : ℕ → ℝ), 2 ≤ M → M ≤ N →
      (∀ n, 0 ≤ w n) →
      (∀ n ∈ Ioc 0 N, w n ≤ Real.log N - Real.log n) →
      (∀ n ∈ Ioc 0 M, Real.log M - Real.log n ≤ w n) →
      |(∑ n ∈ Ioc 0 N, f n ^ 2 / n * w n) - Real.log N ^ 3 / 6|
        ≤ C * Real.log N ^ 2
          + (Real.log N - Real.log M) * Real.log N ^ 2 := by
  obtain ⟨C, hC, hI⟩ := integrated_second_moment hf
  refine ⟨C, hC, ?_⟩
  intro N M w hM2 hMN hw0 hwU hwL
  have hN2 : 2 ≤ N := le_trans hM2 hMN
  have hMR : (0 : ℝ) < M := by positivity
  have hlogM : (0 : ℝ) < Real.log M := by
    apply Real.log_pos
    exact_mod_cast (by omega : 1 < M)
  have hlogN : (0 : ℝ) < Real.log N := by
    apply Real.log_pos
    exact_mod_cast (by omega : 1 < N)
  have hlogMN : Real.log M ≤ Real.log N :=
    Real.log_le_log hMR (by exact_mod_cast hMN)
  have hterm_nn : ∀ n ∈ Ioc 0 N, (0 : ℝ) ≤ f n ^ 2 / n := by
    intro n hn
    positivity
  -- upper: replace w by the sharp cutoff at N
  have hupper : ∑ n ∈ Ioc 0 N, f n ^ 2 / n * w n
      ≤ ∑ n ∈ Ioc 0 N, f n ^ 2 / n * (Real.log N - Real.log n) := by
    refine Finset.sum_le_sum fun n hn => ?_
    exact mul_le_mul_of_nonneg_left (hwU n hn) (hterm_nn n hn)
  -- lower: restrict to Ioc 0 M and use the sharp cutoff at M
  have hlower : ∑ n ∈ Ioc 0 M, f n ^ 2 / n * (Real.log M - Real.log n)
      ≤ ∑ n ∈ Ioc 0 N, f n ^ 2 / n * w n := by
    calc ∑ n ∈ Ioc 0 M, f n ^ 2 / n * (Real.log M - Real.log n)
        ≤ ∑ n ∈ Ioc 0 M, f n ^ 2 / n * w n := by
          refine Finset.sum_le_sum fun n hn => ?_
          refine mul_le_mul_of_nonneg_left (hwL n hn) ?_
          positivity
      _ ≤ ∑ n ∈ Ioc 0 N, f n ^ 2 / n * w n := by
          refine Finset.sum_le_sum_of_subset_of_nonneg
            (Finset.Ioc_subset_Ioc le_rfl hMN) ?_
          intro n hn _
          have := hw0 n
          positivity
  have hIN := hI N hN2
  have hIM := hI M hM2
  -- cube difference: log³N − log³M ≤ 3(log N − log M)·log²N
  have hcube : Real.log N ^ 3 - Real.log M ^ 3
      ≤ 3 * ((Real.log N - Real.log M) * Real.log N ^ 2) := by
    nlinarith [sq_nonneg (Real.log N - Real.log M), hlogM.le, hlogMN,
      sq_nonneg (Real.log M), mul_nonneg hlogM.le hlogN.le]
  rw [abs_le]
  constructor
  · -- lower bound on the sum
    have h1 : Real.log M ^ 3 / 6 - C * Real.log M ^ 2
        ≤ ∑ n ∈ Ioc 0 M, f n ^ 2 / n * (Real.log M - Real.log n) := by
      have := abs_le.mp hIM
      linarith [this.1]
    have h2 : C * Real.log M ^ 2 ≤ C * Real.log N ^ 2 := by
      apply mul_le_mul_of_nonneg_left _ hC.le
      nlinarith [hlogM.le, hlogMN]
    nlinarith [h1, hlower, h2, hcube]
  · -- upper bound on the sum
    have := abs_le.mp hIN
    have h3 : (0 : ℝ) ≤ (Real.log N - Real.log M) * Real.log N ^ 2 := by
      apply mul_nonneg _ (sq_nonneg _)
      linarith
    linarith [this.2, hupper]

end Factorization

#print axioms Factorization.sum_sq_le
#print axioms Factorization.sum_div_sqrt_sq_le
#print axioms Factorization.freq_spacing
#print axioms Factorization.psi_nat_le
#print axioms Factorization.sum_div_sqrt_le
#print axioms Factorization.sum_div_sqrt_le_real
#print axioms Factorization.apply_one
#print axioms Factorization.harmonic_le
#print axioms Factorization.inv_sq_le
#print axioms Factorization.log_succ_sub_le
#print axioms Factorization.telescope_Ico
#print axioms Factorization.abel_swap
#print axioms Factorization.cube_step
#print axioms Factorization.sq_step
#print axioms Factorization.integrated_second_moment
#print axioms Factorization.EulerStiffnessC.norm
#print axioms Factorization.EulerStiffness.toC
#print axioms Factorization.eulerStiffnessC_vonMangoldt
#print axioms Factorization.EulerStiffnessC.twist
#print axioms Factorization.sum_norm_div_sqrt_le
#print axioms Factorization.integrated_second_momentC
#print axioms Factorization.dh_not_eulerStiffnessC
#print axioms Factorization.sum_mul_log_div_sqrt_le
#print axioms Factorization.tapered_diagonal
