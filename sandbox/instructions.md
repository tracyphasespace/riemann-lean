# Sandbox Rules (AI2)

You are only allowed to operate inside this `/sandbox/` directory.

## Hard Rules
1) **Never modify real project files**. Only edit files in `/sandbox/`.
2) **Never run `lake`**, never touch `.lake/` artifacts.
3) **Never run git commands**. This is a proposal-only workflow.
4) **Do not edit `Axioms.proposed.lean`**. It is read-only for this workflow.
5) **Do not convert axioms into theorems or insert `sorry`**. Keep axioms as-is.
6) **Only output proposed proof snippets** (record them in `results.md`).

## Quality Bar (Must Follow)
- Use **real Mathlib lemma names only**. No invented names.
- If a required lemma is missing, say so explicitly in Notes and stop.
- The tactic block must be a **tight sketch** using named lemmas only.
- Do **not** include informal reasoning in the tactic block.
- Lemma names should come from Loogle hits or verified Mathlib knowledge.

## Allowed Targets
- `/home/tracy/development/Riemann/sandbox/Axioms.proposed.lean` (read-only)
- `/home/tracy/development/Riemann/sandbox/results.md` (append only)
- Files under `/sandbox/` for logs/notes only

## Workflow
1) Use the existing sandbox copy:
   - `/home/tracy/development/Riemann/sandbox/Axioms.proposed.lean`
2) Run the scout loop in axiom mode (no build, no edits):
   ```bash
   python3 /home/tracy/development/Riemann/sandbox/grind.py \
     /home/tracy/development/Riemann/sandbox/Axioms.proposed.lean --axioms
   ```
3) For each axiom, append an entry to `results.md` using the strict template:
   - Paste the Goal and Loogle hits verbatim from the scout output.
   - Provide a concrete proof sketch and a lean tactic block.

## Output Format (append to results.md)
- Axiom name / location
- Goal line
- Loogle hits
- Proposed proof sketch (no placeholders)
- Tactic block using named lemmas only
- Notes / assumptions (explicitly list missing lemmas)

No changes should be made outside `/sandbox/`.
