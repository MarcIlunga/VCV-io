/-
Copyright (c) 2024. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: VCV-io Contributors

Pure implementation of ChaCha20-Poly1305 AEAD (Authenticated Encryption with
Associated Data) following RFC 8439.

This combines ChaCha20 for encryption and Poly1305 for authentication.
-/

import ChaChaPoly.Impl.ChaCha20
import ChaChaPoly.Impl.Poly1305

namespace ChaChaPoly

/-- Construct the Poly1305 key by encrypting 32 zero bytes with ChaCha20 at counter 0 -/
def generatePoly1305Key (key : BitVec 256) (nonce : BitVec 96) : BitVec 256 :=
  let zeros := ByteArray.mkEmpty 32 |> fun ba =>
    let mut result := ba
    for _ in [0:32] do
      result := result.push 0
    result
  let keystream := ChaCha20.block key nonce 0
  let polyKeyBytes := keystream.extract 0 32
  -- Convert to BitVec 256
  bytesToBitVec256 polyKeyBytes

/-- Convert 32-byte array to BitVec 256 (little-endian) -/
def bytesToBitVec256 (bytes : ByteArray) : BitVec 256 :=
  let mut result : Nat := 0
  for i in [0:32] do
    let byte := if h : i < bytes.size then bytes.data[i].toNat else 0
    result := result + (byte <<< (i * 8))
  BitVec.ofNat 256 result

/-- Convert 12-byte array to BitVec 96 (little-endian) -/
def bytesToBitVec96 (bytes : ByteArray) : BitVec 96 :=
  let mut result : Nat := 0
  for i in [0:12] do
    let byte := if h : i < bytes.size then bytes.data[i].toNat else 0
    result := result + (byte <<< (i * 8))
  BitVec.ofNat 96 result

/-- Pad a ByteArray to a multiple of 16 bytes -/
def padTo16Multiple (bytes : ByteArray) : ByteArray :=
  let remainder := bytes.size % 16
  if remainder == 0 then bytes
  else
    let padLen := 16 - remainder
    let mut result := bytes
    for _ in [0:padLen] do
      result := result.push 0
    result

/-- Convert a 64-bit length to 8-byte little-endian ByteArray -/
def lengthToBytes (len : Nat) : ByteArray :=
  let mut result := ByteArray.mkEmpty 8
  let mut val := len
  for _ in [0:8] do
    result := result.push (val % 256).toUInt8
    val := val / 256
  result

/-- Construct the Poly1305 data to authenticate.
Format: pad16(AAD) || pad16(ciphertext) || len(AAD) as 8 bytes || len(ciphertext) as 8 bytes -/
def constructMacData (aad : ByteArray) (ciphertext : ByteArray) : ByteArray :=
  let paddedAad := padTo16Multiple aad
  let paddedCipher := padTo16Multiple ciphertext
  let aadLen := lengthToBytes aad.size
  let cipherLen := lengthToBytes ciphertext.size
  paddedAad ++ paddedCipher ++ aadLen ++ cipherLen

/-- ChaCha20-Poly1305 AEAD Encryption.
Returns (ciphertext, tag) -/
def encrypt (key : BitVec 256) (nonce : BitVec 96) (plaintext : ByteArray)
    (aad : ByteArray := ByteArray.empty) : (ByteArray × ByteArray) :=
  -- Generate Poly1305 key using counter = 0
  let polyKey := generatePoly1305Key key nonce
  -- Encrypt plaintext using counter = 1
  let ciphertext := ChaCha20.encrypt key nonce 1 plaintext
  -- Construct MAC data and compute tag
  let macData := constructMacData aad ciphertext
  let tag := Poly1305.macBytes polyKey macData
  (ciphertext, tag)

/-- ChaCha20-Poly1305 AEAD Decryption.
Returns `some plaintext` if tag verifies, `none` otherwise. -/
def decrypt (key : BitVec 256) (nonce : BitVec 96) (ciphertext : ByteArray)
    (tag : ByteArray) (aad : ByteArray := ByteArray.empty) : Option ByteArray :=
  -- Generate Poly1305 key using counter = 0
  let polyKey := generatePoly1305Key key nonce
  -- Construct MAC data and verify tag
  let macData := constructMacData aad ciphertext
  let computedTag := Poly1305.macBytes polyKey macData
  if computedTag == tag then
    -- Decrypt ciphertext using counter = 1
    some (ChaCha20.decrypt key nonce 1 ciphertext)
  else
    none

/-- Combined encrypt and tag function for VCV-io compatibility.
Returns (tag, ciphertext) to match the oracle interface. -/
def encryptAndTag (key : BitVec 256) (nonce : BitVec 96) (plaintext : ByteArray)
    (aad : ByteArray := ByteArray.empty) : (BitVec 128 × ByteArray) :=
  let (ciphertext, tagBytes) := encrypt key nonce plaintext aad
  let tag := Poly1305.mac (generatePoly1305Key key nonce)
               (constructMacData aad ciphertext)
  (tag, ciphertext)

end ChaChaPoly
