import Axioms

-- Test the trajectory claims
#eval Axioms.trajectory 3 0  -- Should be 3
#eval Axioms.trajectory 3 1  -- Should be 10
#eval Axioms.trajectory 3 2  -- Should be 5
#eval Axioms.trajectory 3 3  -- Should be 16
#eval Axioms.trajectory 3 4  -- Should be 8
#eval Axioms.trajectory 3 5  -- Should be 4

-- Claim in mod8_3_descent: trajectory 3 5 < 3?  That's 4 < 3 = FALSE!

#eval Axioms.trajectory 11 5  -- n=11 ≡ 3 (mod 8)
-- Claim: trajectory 11 5 < 11?

#eval Axioms.trajectory 7 5   -- n=7 ≡ 7 (mod 8)  
-- Claim in mod8_7_descent: trajectory 7 5 < 7?
