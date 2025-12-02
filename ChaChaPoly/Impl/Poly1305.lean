/-
Copyright (c) 2024. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: VCV-io Contributors

Pure implementation of Poly1305 MAC following RFC 8439.
This implementation uses BitVec for deterministic computation.
It is designed to pass KATs (Known Answer Tests) and lift cleanly into VCV-io.

The MAC uses field arithmetic over GF(2^130 - 5), implemented using BitVec.
-/

namespace Poly1305

/-- The prime modulus: 2^130 - 5 -/
def p : Nat := (1 <<< 130) - 5

/-- Clamp the 128-bit r value according to RFC 8439.
Certain bits must be cleared to ensure the key is in a specific form. -/
def clamp (r : BitVec 128) : BitVec 128 :=
  r &&& 0x0ffffffc0ffffffc0ffffffc0fffffff

/-- Convert a little-endian ByteArray to a natural number.
First byte is least significant (index 0 = LSB). -/
def bytesToNat (bytes : ByteArray) : Nat :=
  let mut result : Nat := 0
  for h : i in [0:bytes.size] do
    result := result + bytes.data[i].toNat * (256 ^ i)
  result

/-- Convert a natural number to little-endian ByteArray of specified size -/
def natToBytes (n : Nat) (size : Nat) : ByteArray :=
  let mut result := ByteArray.mkEmpty size
  let mut val := n
  for _ in [0:size] do
    result := result.push (val % 256).toUInt8
    val := val / 256
  result

/-- Extract r (lower 128 bits) from the 256-bit key -/
def extractR (key : BitVec 256) : BitVec 128 :=
  key.extractLsb' 0 128

/-- Extract s (upper 128 bits) from the 256-bit key -/
def extractS (key : BitVec 256) : BitVec 128 :=
  key.extractLsb' 128 128

/-- Convert a 128-bit value to natural number -/
def toNat128 (v : BitVec 128) : Nat := v.toNat

/-- Convert a natural number to 128-bit value (truncated) -/
def fromNat128 (n : Nat) : BitVec 128 := BitVec.ofNat 128 n

/-- Process one 16-byte block of the message.
acc_new = (acc + block) * r mod p -/
def processBlock (acc : Nat) (r : Nat) (block : ByteArray) (isFinal : Bool) : Nat :=
  let n := bytesToNat block
  -- Add high bit (2^128) if not final block or if block is full
  let n := if isFinal && block.size < 16 then n else n + (1 <<< (block.size * 8))
  let acc := acc + n
  (acc * r) % p

/-- Pad a ByteArray to 16 bytes with zeros -/
def padTo16 (bytes : ByteArray) : ByteArray :=
  if bytes.size >= 16 then bytes.extract 0 16
  else
    let mut result := bytes
    for _ in [0:16 - bytes.size] do
      result := result.push 0
    result

/-- Process all message blocks and return the final accumulator -/
def processMessage (msg : ByteArray) (r : Nat) : Nat :=
  let blockSize : Nat := 16
  let numFullBlocks := msg.size / blockSize
  let mut acc : Nat := 0

  -- Process full 16-byte blocks
  for i in [0:numFullBlocks] do
    let start := i * blockSize
    let block := msg.extract start (start + blockSize)
    acc := processBlock acc r block false

  -- Process final partial block if any
  let remainder := msg.size % blockSize
  if remainder > 0 then
    let start := numFullBlocks * blockSize
    let block := msg.extract start msg.size
    acc := processBlock acc r block true

  acc

/-- Poly1305 MAC computation.
Returns a 128-bit tag for the given message and key. -/
def mac (key : BitVec 256) (msg : ByteArray) : BitVec 128 :=
  let r := clamp (extractR key)
  let s := extractS key
  let rNat := r.toNat
  let sNat := s.toNat

  -- Process all message blocks
  let acc := processMessage msg rNat

  -- Final step: tag = (acc + s) mod 2^128
  let tag := (acc + sNat) % (1 <<< 128)
  fromNat128 tag

/-- Convert a 128-bit tag to a 16-byte ByteArray (little-endian) -/
def tagToBytes (tag : BitVec 128) : ByteArray :=
  natToBytes tag.toNat 16

/-- Compute MAC and return as ByteArray -/
def macBytes (key : BitVec 256) (msg : ByteArray) : ByteArray :=
  tagToBytes (mac key msg)

end Poly1305
