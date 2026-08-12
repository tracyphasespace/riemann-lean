#!/usr/bin/env bash
# Axiom audit with structural enforcement (hardened, round 5).
# (1) Globs every .lean file. (2) Extracts declared theorem/lemma names —
# including modifier/attribute-prefixed forms (@[...] theorem, private
# lemma, ...) — with namespace tracking, diffs against #print axioms
# directives, FAILS on any gap. (3) Emits the audit lines, then a summary
# line designed to be pasted verbatim into documents (counts in prose
# must be pasted, never typed — review finding, round 5).
set -e
fail=0
total_declared=0
for f in *.lean; do
  declared=$(awk '
    /^namespace /{ns[++d]=$2}
    /^end /{if(d>0 && ns[d]==$2) d--}
    {
      line=$0
      if (line ~ /^(@\[[^]]*\][ \t]+)?((private|protected|nonrec)[ \t]+)*(theorem|lemma)[ \t]/) {
        sub(/^(@\[[^]]*\][ \t]+)?((private|protected|nonrec)[ \t]+)*/,"",line)
        split(line, a, /[ \t]+/)
        name=a[2]
        q=""; for(i=1;i<=d;i++) q=q ns[i] "."
        print q name
      }
    }' "$f" | sort -u)
  audited=$(grep -oP "^#print axioms \K.*" "$f" | sort -u || true)
  missing=$(comm -23 <(echo "$declared") <(echo "$audited"))
  n=$(echo "$declared" | grep -c . || true)
  total_declared=$((total_declared + n))
  if [ -n "$missing" ]; then
    echo "AUDIT GAP in $f:" >&2
    echo "$missing" >&2
    fail=1
  fi
done
if [ $fail -ne 0 ]; then exit 1; fi
out=$(for f in *.lean; do lake env lean "$f"; done 2>&1 | grep -E "depends on axioms|does not depend on any axioms")
echo "$out"
n_out=$(echo "$out" | grep -c . || true)
n_sorry=$(echo "$out" | grep -c "sorryAx" || true)
if [ "$n_out" -ne "$total_declared" ]; then
  echo "# COUNT MISMATCH: $total_declared declared vs $n_out audited" >&2
  exit 1
fi
echo "# SUMMARY: $total_declared theorems, $n_out audited, 0 gaps, $n_sorry sorryAx"
