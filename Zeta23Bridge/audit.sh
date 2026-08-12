#!/usr/bin/env bash
# Axiom audit with structural enforcement. The uncovered-file/uncovered-
# theorem drift class appeared three times in review; this script makes it
# impossible: (1) globs every .lean file; (2) diffs declared theorem/lemma
# names against #print axioms directives and FAILS on any gap; (3) only
# then emits the audit lines from the elaborator log. Run after lake build.
set -e
fail=0
for f in *.lean; do
  declared=$(awk '
    /^namespace /{ns[++d]=$2}
    /^end /{if(d>0 && ns[d]==$2) d--}
    /^(theorem|lemma) /{
      name=$2; sub(/[^A-Za-z0-9_.\x27₀-₉²ℕℝℂΑ-ω]+$/,"",name)
      q=""; for(i=1;i<=d;i++) q=q ns[i] "."
      print q name
    }' "$f" | sort -u)
  audited=$(grep -oP "^#print axioms \K.*" "$f" | sort -u || true)
  missing=$(comm -23 <(echo "$declared") <(echo "$audited"))
  if [ -n "$missing" ]; then
    echo "AUDIT GAP in $f:" >&2
    echo "$missing" >&2
    fail=1
  fi
done
if [ $fail -ne 0 ]; then exit 1; fi
for f in *.lean; do lake env lean "$f"; done 2>&1 | grep "depends on"
