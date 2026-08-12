#!/usr/bin/env bash
# Mechanically regenerates the ledger's Appendix A.
# Each .lean file ends with `#print axioms` directives for every theorem the
# ledger's prose references; this script extracts those directives' output
# from the elaborator log. Run from Zeta23Bridge/ after `lake build`.
set -e
{ lake env lean Zeta23Bridge.lean; lake env lean SpongeStage.lean; } 2>&1 | grep "depends on"
