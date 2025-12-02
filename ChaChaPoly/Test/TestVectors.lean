/-
Copyright (c) 2024. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: VCV-io Contributors

RFC 8439 Test Vectors for ChaCha20 and Poly1305.
These are the official Known Answer Tests (KATs) from the specification.
-/

import ChaChaPoly.Impl.ChaCha20
import ChaChaPoly.Impl.Poly1305
import ChaChaPoly.Impl.AEAD
import ChaChaPoly.Impl.Hex

namespace TestVectors

/-! ## ChaCha20 Quarter Round Test Vector (RFC 8439 Section 2.1.1) -/

/-- Test the quarter round function -/
def testQuarterRound : Bool :=
  let (a, b, c, d) := ChaCha20.quarterRound 0x11111111 0x01020304 0x9b8d6f43 0x01234567
  a == 0xea2a92f4 && b == 0xcb1cf8ce && c == 0x4581472e && d == 0x5881c4bb

/-! ## ChaCha20 Block Function Test Vector (RFC 8439 Section 2.3.2) -/

/-- RFC 8439 Test Vector for ChaCha20 block function -/
def chacha20BlockTestKey : BitVec 256 :=
  Hex.decodeToBitVec256 "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"

def chacha20BlockTestNonce : BitVec 96 :=
  Hex.decodeToBitVec96 "000000090000004a00000000"

def chacha20BlockTestCounter : BitVec 32 := 1

def chacha20BlockExpected : String :=
  "10f1e7e4d13b5915500fdd1fa32071c4c7d1f4c733c068030422aa9ac3d46c4e" ++
  "d2826446079faa0914c2d705d98b02a2b5129cd1de164eb9cbd083e8a2503c4e"

/-- Test the ChaCha20 block function -/
def testChaCha20Block : Bool :=
  let result := ChaCha20.block chacha20BlockTestKey chacha20BlockTestNonce chacha20BlockTestCounter
  Hex.encode result == chacha20BlockExpected

/-! ## Poly1305 MAC Test Vector (RFC 8439 Section 2.5.2) -/

/-- RFC 8439 Test Vector for Poly1305 -/
def poly1305TestKey : BitVec 256 :=
  Hex.decodeToBitVec256 "85d6be7857556d337f4452fe42d506a80103808afb0db2fd4abff6af4149f51b"

def poly1305TestMessage : ByteArray :=
  -- "Cryptographic Forum Research Group"
  Hex.decode "43727970746f6772617068696320466f72756d205265736561726368204772" ++
  Hex.decode "6f7570"

def poly1305ExpectedTag : BitVec 128 :=
  Hex.decodeToBitVec128 "a8061dc1305136c6c22b8baf0c0127a9"

/-- Test the Poly1305 MAC function -/
def testPoly1305Mac : Bool :=
  let computed := Poly1305.mac poly1305TestKey poly1305TestMessage
  computed == poly1305ExpectedTag

/-! ## ChaCha20-Poly1305 AEAD Test Vector (RFC 8439 Section 2.8.2) -/

/-- RFC 8439 Test Vector for AEAD -/
def aeadTestKey : BitVec 256 :=
  Hex.decodeToBitVec256 "808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f"

def aeadTestNonce : BitVec 96 :=
  Hex.decodeToBitVec96 "070000004041424344454647"

def aeadTestPlaintext : ByteArray :=
  -- "Ladies and Gentlemen of the class of '99: If I could offer you only one tip
  --  for the future, sunscreen would be it."
  Hex.decode "4c616469657320616e642047656e746c656d656e206f662074686520636c61" ++
  Hex.decode "7373206f66202739393a204966204920636f756c64206f6666657220796f75" ++
  Hex.decode "206f6e6c79206f6e652074697020666f7220746865206675747572652c2073" ++
  Hex.decode "756e73637265656e20776f756c642062652069742e"

def aeadTestAAD : ByteArray :=
  Hex.decode "50515253c0c1c2c3c4c5c6c7"

def aeadExpectedCiphertext : String :=
  "d31a8d34648e60db7b86afbc53ef7ec2a4aded51296e08fea9e2b5a736ee62d6" ++
  "3dbea45e8ca9671282fafb69da92728b1a71de0a9e060b2905d6a5b67ecd3b36" ++
  "92ddbd7f2d778b8c9803aee328091b58fab324e4fad675945585808b4831d7bc" ++
  "3ff4def08e4b7a9de576d26586cec64b6116"

def aeadExpectedTag : String :=
  "1ae10b594f09e26a7e902ecbd0600691"

/-- Test the AEAD encryption function -/
def testAEADEncrypt : Bool :=
  let (ciphertext, tag) := ChaChaPoly.encrypt aeadTestKey aeadTestNonce aeadTestPlaintext aeadTestAAD
  let cipherHex := Hex.encode ciphertext
  let tagHex := Hex.encode tag
  cipherHex == aeadExpectedCiphertext && tagHex == aeadExpectedTag

/-- Test the AEAD decryption function -/
def testAEADDecrypt : Bool :=
  let ciphertext := Hex.decode aeadExpectedCiphertext
  let tag := Hex.decode aeadExpectedTag
  match ChaChaPoly.decrypt aeadTestKey aeadTestNonce ciphertext tag aeadTestAAD with
  | some plaintext => plaintext == aeadTestPlaintext
  | none => false

/-! ## Additional ChaCha20 Test Vector (RFC 8439 Section 2.4.2) -/

/-- Test vector for ChaCha20 encryption -/
def chacha20EncryptTestKey : BitVec 256 :=
  Hex.decodeToBitVec256 "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"

def chacha20EncryptTestNonce : BitVec 96 :=
  Hex.decodeToBitVec96 "000000000000004a00000000"

def chacha20EncryptTestPlaintext : ByteArray :=
  -- "Ladies and Gentlemen of the class of '99: If I could offer you only one tip
  --  for the future, sunscreen would be it."
  Hex.decode "4c616469657320616e642047656e746c656d656e206f662074686520636c61" ++
  Hex.decode "7373206f66202739393a204966204920636f756c64206f6666657220796f75" ++
  Hex.decode "206f6e6c79206f6e652074697020666f7220746865206675747572652c2073" ++
  Hex.decode "756e73637265656e20776f756c642062652069742e"

def chacha20ExpectedCiphertext : String :=
  "6e2e359a2568f98041ba0728dd0d6981e97e7aec1d4360c20a27afccfd9fae0b" ++
  "f91b65c5524733ab8f593dabcd62b3571639d624e65152ab8f530c359f0861d8" ++
  "07ca0dbf500d6a6156a38e088a22b65e52bc514d16ccf806818ce91ab7793736" ++
  "5af90bbf74a35be6b40b8eedf2785e42874d"

def testChaCha20Encrypt : Bool :=
  let result := ChaCha20.encrypt chacha20EncryptTestKey chacha20EncryptTestNonce 1 chacha20EncryptTestPlaintext
  Hex.encode result == chacha20ExpectedCiphertext

/-! ## Poly1305 Key Generation Test Vector (RFC 8439 Section 2.6.2) -/

def polyKeyGenTestKey : BitVec 256 :=
  Hex.decodeToBitVec256 "808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f"

def polyKeyGenTestNonce : BitVec 96 :=
  Hex.decodeToBitVec96 "000000000001020304050607"

def polyKeyGenExpected : String :=
  "8ad5a08b905f81cc815040274ab29471a833b637e3fd0da508dbb8e2fdd1a646"

def testPoly1305KeyGen : Bool :=
  let result := ChaChaPoly.generatePoly1305Key polyKeyGenTestKey polyKeyGenTestNonce
  let bytes := Poly1305.natToBytes result.toNat 32
  Hex.encode bytes == polyKeyGenExpected
where
  Poly1305.natToBytes (n : Nat) (size : Nat) : ByteArray :=
    let mut result := ByteArray.mkEmpty size
    let mut val := n
    for _ in [0:size] do
      result := result.push (val % 256).toUInt8
      val := val / 256
    result

/-! ## Run All Tests -/

/-- Structure to hold test results -/
structure TestResult where
  name : String
  passed : Bool
  deriving Repr

/-- Run all test vectors and return results -/
def runAllTests : Array TestResult :=
  #[
    { name := "Quarter Round", passed := testQuarterRound },
    { name := "ChaCha20 Block", passed := testChaCha20Block },
    { name := "Poly1305 MAC", passed := testPoly1305Mac },
    { name := "ChaCha20 Encrypt", passed := testChaCha20Encrypt },
    { name := "Poly1305 Key Gen", passed := testPoly1305KeyGen },
    { name := "AEAD Encrypt", passed := testAEADEncrypt },
    { name := "AEAD Decrypt", passed := testAEADDecrypt }
  ]

/-- Check if all tests pass -/
def allTestsPass : Bool :=
  runAllTests.all (·.passed)

end TestVectors
