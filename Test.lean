import VCVio
import LibSodium

-- Roll a bunch of dice at random.
private def lawLargeNumsTest (trials : ℕ) (die : ℕ) : IO Unit := do
  let n : ℕ := trials * die
  let xs ← OracleComp.replicateTR n $[0..die - 1]
  IO.println ("Rolling " ++ toString n ++ " " ++ toString die ++ "-sided dice:")
  for i in List.range die do
    IO.println <| "▸Num " ++ toString (i + 1) ++ "s: " ++ toString (xs.count i)

-- Test ChaCha20-Poly1305 constants
private def testChaCha20Poly1305Constants : IO Unit := do
  IO.println "ChaCha20-Poly1305 Constants:"
  IO.println <| "  Key size: " ++ toString ChaCha20Poly1305.keyBytes ++ " bytes"
  IO.println <| "  Nonce size: " ++ toString ChaCha20Poly1305.nonceBytes ++ " bytes"
  IO.println <| "  Auth tag size: " ++ toString ChaCha20Poly1305.aBytes ++ " bytes"

-- Test ChaCha20-Poly1305 encryption/decryption (basic test)
private def testChaCha20Poly1305Roundtrip : IO Unit := do
  IO.println "ChaCha20-Poly1305 Roundtrip Test:"
  
  -- Create test data
  let message := ByteArray.mk #[0x48, 0x65, 0x6c, 0x6c, 0x6f] -- "Hello"
  let ad := ByteArray.mk #[0x41, 0x44] -- "AD"
  
  -- Create dummy key and nonce (in real use, these should be randomly generated)
  let key := ByteArray.mk (Array.mkArray ChaCha20Poly1305.keyBytes.toNat 0x42)
  let nonce := ByteArray.mk (Array.mkArray ChaCha20Poly1305.nonceBytes.toNat 0x01)
  
  IO.println <| "  Message size: " ++ toString message.size ++ " bytes"
  IO.println <| "  AD size: " ++ toString ad.size ++ " bytes"
  
  -- Test encryption
  match ← ChaCha20Poly1305.encrypt message ad nonce key with
  | some ciphertext => 
    IO.println "  ✓ Encryption succeeded"
    -- Test decryption
    match ← ChaCha20Poly1305.decrypt ciphertext ad nonce key with
    | some plaintext =>
      IO.println "  ✓ Decryption succeeded"
      if plaintext.size == message.size then
        IO.println "  ✓ Roundtrip test passed (sizes match)"
      else
        IO.println "  ✗ Roundtrip test failed (size mismatch)"
    | none =>
      IO.println "  ✗ Decryption failed"
  | none =>
    IO.println "  ✗ Encryption failed"

def main : IO Unit := do
  IO.println <| "Thanks for running me!"
  IO.println <| "Running an external addition of `1 + 1`:"
  IO.println <| myAdd 1 1
  IO.println <| "----------------------------------------"
  
  -- Run ChaCha20-Poly1305 tests
  testChaCha20Poly1305Constants
  IO.println <| "----------------------------------------"
  testChaCha20Poly1305Roundtrip
  IO.println <| "----------------------------------------"
  
  let trials : ℕ ← (100 + ·) <$> $[0..100]
  let die : ℕ ← (4 + ·) <$> $[0..4]
  lawLargeNumsTest trials die
