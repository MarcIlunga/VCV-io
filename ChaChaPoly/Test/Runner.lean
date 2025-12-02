/-
Copyright (c) 2024. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: VCV-io Contributors

Test runner for ChaCha20-Poly1305 KAT (Known Answer Tests).
Runs RFC 8439 test vectors and reports results.
-/

import ChaChaPoly.Test.TestVectors

def main : IO Unit := do
  IO.println "============================================"
  IO.println "ChaCha20-Poly1305 KAT Test Runner"
  IO.println "Based on RFC 8439 Test Vectors"
  IO.println "============================================"
  IO.println ""

  let results := TestVectors.runAllTests
  let mut allPassed := true

  for result in results do
    let status := if result.passed then "✓ PASS" else "✗ FAIL"
    IO.println s!"{status}: {result.name}"
    if !result.passed then
      allPassed := false

  IO.println ""
  IO.println "============================================"
  if allPassed then
    IO.println "All tests passed!"
  else
    IO.println "Some tests failed!"
    -- Return non-zero exit code on failure
    IO.Process.exit 1
