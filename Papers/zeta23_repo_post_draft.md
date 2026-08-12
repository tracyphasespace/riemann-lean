# DRAFT — issue/discussion post for `anthropics/zeta-23-lean`

**Status: POSTED 2026-08-12 as https://github.com/anthropics/zeta-23-lean/issues/9
(discussions disabled upstream, so filed as an issue). Text below is as posted.**

---

**Title:** Downstream dependency report: an audited bridge project pinned to v1.0, plus an arithmetic-interface experiment over the §5 prime side

**Body:**

We have built a Lean 4 subproject that `require`s this repository at tag
`v1.0` (tag object `82ee6340`, commit `3635e748`, Mathlib pin `51e6992e`,
toolchain `leanprover/lean4:v4.33.0-rc2`) and wanted to (a) report it as a
downstream dependency, and (b) share one result of independent interest to
this repo's authors.

**What the project is.** 88 kernel-checked theorems (no `sorry`; every
declaration verified on `[propext, Classical.choice, Quot.sound]` by an
enforced audit script with a declared-vs-audited count assertion, run in CI).
The mathematical content is a dependency experiment over the paper's §5:

> Does the prime side read the von Mangoldt coefficients only through a small
> explicit interface?

We defined a five-condition predicate `EulerStiffness f` (prime-power
support; nonnegativity; `f(n) ≤ log n`; the Mertens second moment
`Σ f(n)²/n = ½log²x + O(log x)`; a Chebyshev bound `Σ f(n) ≤ Cx`) and proved,
from those conditions alone — no ζ, no Euler product:

- the real-cutoff integrated second moment in the literal statement shape of
  `Zeta23.ChebyshevMertens.cheb2b`;
- the log-damped √-moment in the shape of `cheb1c`;
- an assembly theorem producing your `Zeta23.ChebyshevMertens` structure
  itself, with **five of the six fields interface-derived**. The one residue
  is `cheb1b`: its hardcoded `3√x` is sharper than our interface's Chebyshev
  constant supplies (we reach `2(√2+1)(log 4 + 4)`), so it enters as an
  explicit hypothesis, dischargeable by your own `Chebyshev.lean` proof.

Two side results that may interest you: the interface is *phase-blind by
construction* (a complex version defined as stiffness of the modulus), and it
is stable under finite Euler-factor deletion — so every Dirichlet character
twist `χ(n)Λ(n)` (any modulus, primitivity not needed) inhabits it, with
defect constant `Σ_{p|q} log²p/(p−1)`. The Davenport–Heilbronn counterexample
is excluded by an exact defect identity at `n = 6`, which we use as a
standing negative control.

We claim nothing about the analytic side: the completed-function package,
window analysis, and the rank–trace mechanism are consumed as-is from your
formalization. The experiment record states explicitly what is
kernel-verified and what remains an identification-level audit claim.

**Repo:** https://github.com/tracyphasespace/riemann-lean (subproject
`Zeta23Bridge/`; experiment record `Zeta23Bridge/Factorization.md`; audit
`Zeta23Bridge/audit.sh`).

**One request:** if a future retag or force-move of `v1.0` is ever
contemplated, we'd appreciate a heads-up in this thread, since our lakefile
pins the tag.

Thanks for publishing the formalization — the statement-level honesty of the
`Hypotheses.lean` interfaces is what made an external dependency audit of
this kind possible within days of release.
