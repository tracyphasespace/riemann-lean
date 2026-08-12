#!/usr/bin/env bash
# Mechanically regenerates the axiom audit for EVERY .lean file in this
# directory. Globbed, not listed: review found the same file twice
# uncovered (ledger v1.2: appendix drift; F4a report: Factorization.lean
# outside the chain of custody), so a new file can never again be
# silently missed. Each file ends with `#print axioms` directives for
# every prose-referenced theorem; this script extracts those directives'
# output from the elaborator log. Run after `lake build`.
set -e
for f in *.lean; do
  lake env lean "$f"
done 2>&1 | grep "depends on"
