/-
Copyright (c) 2024. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: VCV-io Contributors

VCV-io Extensibility Layer for ChaCha20-Poly1305.

This file provides the "lifting" interface for making the pure implementation
compatible with VCV-io's OracleComp monad and security proofs.

Key design principles:
1. The Impl layer functions remain pure and unmonadic
2. This Spec layer wraps them for use in OracleComp
3. Algebraic refinement theorems connect BitVec to ZMod p
-/

import VCVio
import ChaChaPoly.Impl.ChaCha20
import ChaChaPoly.Impl.Poly1305
import ChaChaPoly.Impl.AEAD

namespace ChaChaPoly.Spec

open OracleSpec OracleComp

/-! ## Oracle Specification for AEAD -/

/-- Input type for AEAD encryption oracle: (nonce, plaintext, aad) -/
structure AEADInput where
  nonce : BitVec 96
  plaintext : ByteArray
  aad : ByteArray := ByteArray.empty
  deriving DecidableEq

/-- Output type for AEAD encryption oracle: (tag, ciphertext) -/
structure AEADOutput where
  tag : BitVec 128
  ciphertext : ByteArray
  deriving DecidableEq

/-! ## Real World Oracle -/

/-- The Real World AEAD Oracle using the pure Impl functions.
This lifts the deterministic implementation into OracleComp. -/
def Real_AEAD_Oracle (k : BitVec 256) (input : AEADInput) : ProbComp AEADOutput :=
  -- Pure computation lifted into the monad
  let (tag, ciphertext) := ChaChaPoly.encryptAndTag k input.nonce input.plaintext input.aad
  pure { tag := tag, ciphertext := ciphertext }

/-- Real World decryption oracle -/
def Real_AEAD_Decrypt_Oracle (k : BitVec 256) (ciphertext : ByteArray)
    (tag : ByteArray) (nonce : BitVec 96) (aad : ByteArray := ByteArray.empty) :
    ProbComp (Option ByteArray) :=
  pure (ChaChaPoly.decrypt k nonce ciphertext tag aad)

/-! ## Algebraic Refinement Hooks -/

/-- The prime used in Poly1305: 2^130 - 5 -/
def poly1305_prime : ℕ := Poly1305.p

/-- Theorem stub: The Poly1305 accumulator step corresponds to field arithmetic.
This is the key algebraic refinement needed for the Degabriele-Günther proof. -/
theorem impl_is_field_op (acc r : ℕ) (block : ByteArray) :
    Poly1305.processBlock acc r block false =
    (acc + Poly1305.bytesToNat block + (1 <<< (block.size * 8))) * r % Poly1305.p := by
  sorry -- To be proved formally in VCV-io layer

/-- Theorem stub: Clamping preserves the required algebraic structure -/
theorem clamp_preserves_field_structure (r : BitVec 128) :
    (Poly1305.clamp r).toNat < 2^128 := by
  sorry -- To be proved formally

/-! ## Security Game Interface -/

/-- IND-CPA security game for AEAD encryption.
The adversary queries the encryption oracle and tries to distinguish. -/
def IND_CPA_Game (k : BitVec 256) : OracleComp unifSpec Unit := do
  -- This is a stub for the full security game
  -- The actual game would involve:
  -- 1. Adversary makes encryption queries
  -- 2. Adversary receives challenge ciphertext
  -- 3. Adversary tries to guess the encrypted message
  pure ()

/-! ## Compositional Properties -/

/-- The ChaCha20 block function is deterministic -/
theorem chacha20_block_deterministic (key : BitVec 256) (nonce : BitVec 96) (counter : BitVec 32) :
    ChaCha20.block key nonce counter = ChaCha20.block key nonce counter := rfl

/-- The Poly1305 MAC is deterministic -/
theorem poly1305_mac_deterministic (key : BitVec 256) (msg : ByteArray) :
    Poly1305.mac key msg = Poly1305.mac key msg := rfl

/-- Encryption followed by decryption returns the original plaintext
(functional correctness, assuming valid tag) -/
theorem encrypt_decrypt_roundtrip (key : BitVec 256) (nonce : BitVec 96)
    (plaintext : ByteArray) (aad : ByteArray) :
    let (ciphertext, tag) := ChaChaPoly.encrypt key nonce plaintext aad
    ChaChaPoly.decrypt key nonce ciphertext tag aad = some plaintext := by
  sorry -- Functional correctness proof

end ChaChaPoly.Spec
