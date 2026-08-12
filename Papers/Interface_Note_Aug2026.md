# A machine-checked arithmetic factorization of the [Z23] prime side through a five-condition modulus interface, stable under finite Euler-factor deletion and unimodular twisting

*Working title — provisional pending external review of this note.*
*Draft v0.1, 2026-08-12. Repo: github.com/tracyphasespace/riemann-lean (`Zeta23Bridge/`). DOI (v1 record): 10.5281/zenodo.21907491.*

**Question.** [Z23] proves unconditionally that more than two thirds of the
nontrivial zeros of ζ lie on the critical line, with a machine-checked Lean 4
formalization (`anthropics/zeta-23-lean`, tag v1.0). We asked a dependency
question about its prime side: *does the argument read the von Mangoldt
coefficients only through a small explicit interface?*

**The interface.** `EulerStiffness f` (Lean 4, built against [Z23] v1.0,
Mathlib pin `51e6992e`) imposes five conditions: prime-power support;
nonnegativity; f(n) ≤ log n; the Mertens second moment
Σ_{n≤x} f(n)²/n = ½log²x + O(log x); and a Chebyshev bound
Σ_{n≤x} f(n) ≤ (log 4 + 4)x. A complex version is defined by
`EulerStiffnessC g := EulerStiffness ‖g‖` — phase-blind by construction.

**Results** (all kernel-checked; audit line pasted from the enforcing
script, which globs every file, diffs declared-vs-audited names, and fails
on any gap: `# SUMMARY: 88 theorems, 88 audited, 0 gaps, 0 sorryAx`; every
theorem verifies on `[propext, Classical.choice, Quot.sound]`):

1. **Coverage.** Every identified coefficient-reading step of [Z23] §5 is
   derived from the five conditions alone — no ζ, no Euler product. In the
   strongest form (`chebyshevMertens_of_interface`), the interface
   constructs [Z23]'s own consuming type `Zeta23.ChebyshevMertens` — the
   structure through which their formalization reads *all* coefficient
   information — with **five of its six fields interface-derived** at their
   literal statements, including the real-cutoff integrated second moment
   (`cheb2b`) that feeds their window sandwich. The single residue is
   named, not hidden: field `cheb1b` hardcodes Σ_{n≤x} Λ(n)/√n ≤ 3√x, a
   constant sharper than the interface's Chebyshev field supplies (we reach
   2(√2+1)(log 4+4) by dyadic descent); it enters as an explicit
   hypothesis, discharged by [Z23]'s own proof.
2. **Stability.** Membership in the complex interface is stable under
   unimodular twisting (a one-line consequence of phase-blindness) and
   finite Euler-factor deletion (`euler_factor_deletion`), with explicit
   defect constant D_Q = Σ_{p∈Q} log²p/(p−1). Consequently every Dirichlet
   character twist inhabits: `dirichlet_inhabitant` proves
   `EulerStiffnessC (χ(n)Λ(n))` for every χ mod q, q ≠ 0 — any character,
   primitivity not needed, per-character (no uniformity in q claimed).
3. **Exclusion.** The Davenport–Heilbronn coefficient system is excluded by
   an exact defect identity at n = 6 — Λ_DH(6) = (1+κ²)log 6, a sum of
   squares, no numerics — and the exclusion survives the passage to the
   complex interface. It is the standing negative control: any abstract
   theorem that would apply to D-H is wrong by construction.

So the class has the shape: **ζ inhabits; Λχ inhabits for every Dirichlet
character; Davenport–Heilbronn is excluded** — a stable arithmetic class,
not a predicate reverse-engineered around ζ.

**Status statement (canonical, and the limits of the claim).** Three
precision rules bound everything above. (1) *Sufficiency, not necessity*:
no minimality claim; no condition has been shown unweakenable. (2)
*Enumeration is not kernel-verified*: the kernel certifies each identified
touchpoint is covered; that the touchpoint list is exhaustive is a
human/AI audit of [Z23] §5. (3) *Correspondence is not kernel-verified*
except where stated: the chief identification row (their Prop 5.6 window
diagonal) **is** now kernel-closed via `cheb2b_of_interface` at their
literal field statement; the remaining rows at audit level are the
composed cross-term bounds. Nothing here strengthens, weakens, or
re-proves the [Z23] theorem; the analytic side (completed-function
package, window analysis, rank–trace mechanism) is consumed as-is.

**Provenance.** The formal development and this note were produced by AI
sessions directed by T. McSheery, with iterated review by independent AI
reviewers; no human peer review has yet occurred. The audit scripts and CI
are in the repo; all counts in this note are pasted from tool output,
never typed.

**References.** [Z23] "More than two thirds of the zeros of the Riemann
zeta function lie on the critical line," Anthropic, Aug 2026, and its Lean
formalization `anthropics/zeta-23-lean` (tag v1.0). [MV07] Montgomery &
Vaughan, *Multiplicative Number Theory I*, §2.2 (Chebyshev–Mertens
estimates; the paper's [lem:cheb] source). Montgomery & Vaughan, *Hilbert's
inequality*, J. LMS (1974) (the coefficient-free bilinear input).
