# F3b-instance handoff: the second inhabitant, built to burn down

**Deliverable registers (claim-typed per program discipline):**

| Register | Artifact | Status |
|---|---|---|
| verified-by-hand | L3–L5 chain algebra; (1/p)/(1−1/p) = 1/(p−1); k ≤ log₂N range bound | checked |
| computed-in-code | `verify_f3b.py` — 12 moduli to x = 10⁶ incl. q = 9699690; margins ≡ predicted tower tails to 1e-9 | ALL PASS |
| written-not-compiled | `F3bInstance.lean` — full decomposition, 10 numbered sorries | Code-lane queue |

The numeric result stronger than the bound: **margin = tail identically**
(column check in verify_f3b.py). The masked energy doesn't merely sit
under D_q; it equals D_q minus the per-prime geometric tails past x.
The Lean route (exact reindexing, then drop nonneg tails) is therefore
the natural proof, not a lossy estimate.

## Frozen-interface audit (constraint of Factorization.md §F3b)

Consumed: `masked_twist`, `geom_tail_le`, `eulerStiffness_vonMangoldt`,
Mathlib. Interface definitions touched: **none**. Constraint satisfied
at the draft level; if any TODO forces an interface edit, STOP — the
classification is the result.

## Registered scoping (pre-stated so review never adjudicates mid-build)

1. **Per-character claim.** D_q depends on q; no q-uniformity claimed or
   needed for membership.
2. **Primitivity not required.** Any χ mod q has ‖χ(n)‖ ∈ {0,1};
   primitivity belongs to the completed package (functional equation).
3. **q ≠ 0 threading.** `¬Coprime(p^k, q) → p ∣ q` and
   `ZMod.isUnit_iff_coprime` want q ≠ 0; `[NeZero q]` on the main
   theorem, `hq : q ≠ 0` on `masked_energy_le`. q = 1: primeFactors = ∅,
   D₁ = 0, trivial character, reduces to `EulerStiffness.toC` — the
   theorem still holds, mask never fires.
4. **Worst constant is p = 2**: (log 2)²/(2−1) ≈ 0.4805 (matches the
   q ∈ {4, 8, 1024} rows numerically — powers of 2 give identical D_q,
   as they must: D depends only on the radical).

## The 10 sorries, ranked by expected effort

Trivial (name resolution): TODO-1, -2 (`vonMangoldt_apply_pow` or near),
-7 (`sum_image` argument shape), -9 (`MulChar.map_nonunit`).

Routine (short proofs): TODO-3 (`vonMangoldt_ne_zero_iff` +
`isPrimePow_nat_iff`, existential reshuffle), -5 (`Nat.pow_le_pow_left`
+ `Nat.pow_le_iff_le_log`), -6 (prime-power injectivity:
`Nat.Prime.dvd_of_dvd_pow` → `Nat.prime_dvd_prime_iff_eq` →
`Nat.pow_right_injective`).

Real work: TODO-4 (coprimality unfold with q ≠ 0), TODO-10 (the
dichotomy split of the removed-energy sum — suggest a helper lemma:
terms are 0 when ‖χ‖ = 1 by `ring`, else land in the filter; then
`Finset.sum_le_sum` over the filter after `sum_filter_add_sum_filter_not`).

Watch item: TODO-8 (‖χ(unit)‖ = 1). If Mathlib's exact lemma is absent,
the fallback is finite-order → root of unity → `Complex.norm_eq_one` of
roots of unity — self-contained, ~15 lines. This is the only sorry with
any risk of exceeding an hour.

## After it compiles

1. Run `audit.sh` (the file already carries its 6 directives; the count
   assertion will police the rest).
2. Update Factorization.md F3b-instance → DONE with the pasted SUMMARY.
3. The one-pager's second paragraph is now literal: *ζ inhabits
   (`eulerStiffnessC_vonMangoldt`), Λχ inhabits
   (`dirichletChar_eulerStiffnessC`), Davenport–Heilbronn is excluded
   (`dh_not_eulerStiffnessC`).*
