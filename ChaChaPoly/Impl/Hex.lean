/-
Copyright (c) 2024. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: VCV-io Contributors

Hexadecimal encoding/decoding utilities for test vectors.
-/

namespace Hex

/-- Convert a single hex character to its value (0-15) -/
def charToNibble (c : Char) : Option Nat :=
  if '0' ≤ c ∧ c ≤ '9' then some (c.toNat - '0'.toNat)
  else if 'a' ≤ c ∧ c ≤ 'f' then some (c.toNat - 'a'.toNat + 10)
  else if 'A' ≤ c ∧ c ≤ 'F' then some (c.toNat - 'A'.toNat + 10)
  else none

/-- Convert a nibble (0-15) to a hex character -/
def nibbleToChar (n : Nat) : Char :=
  if n < 10 then Char.ofNat ('0'.toNat + n)
  else Char.ofNat ('a'.toNat + n - 10)

/-- Decode a hexadecimal string to ByteArray -/
def decode (s : String) : ByteArray :=
  let chars := s.toList
  let rec go : List Char → ByteArray → ByteArray
    | [], acc => acc
    | [_], acc => acc  -- Odd number of chars, ignore last
    | c1 :: c2 :: rest, acc =>
      match charToNibble c1, charToNibble c2 with
      | some h, some l => go rest (acc.push ((h * 16 + l).toUInt8))
      | _, _ => go rest acc  -- Skip invalid chars
  go chars ByteArray.empty

/-- Encode a ByteArray to hexadecimal string -/
def encode (bytes : ByteArray) : String :=
  bytes.data.foldl (init := "") fun acc byte =>
    let h := (byte.toNat / 16)
    let l := (byte.toNat % 16)
    acc.push (nibbleToChar h) |>.push (nibbleToChar l)

/-- Decode a hex string to BitVec 256 (little-endian interpretation of bytes) -/
def decodeToBitVec256 (s : String) : BitVec 256 :=
  let bytes := decode s
  let mut result : Nat := 0
  for i in [0:32] do
    let byte := if h : i < bytes.size then bytes.data[i].toNat else 0
    result := result + (byte <<< (i * 8))
  BitVec.ofNat 256 result

/-- Decode a hex string to BitVec 128 (little-endian interpretation of bytes) -/
def decodeToBitVec128 (s : String) : BitVec 128 :=
  let bytes := decode s
  let mut result : Nat := 0
  for i in [0:16] do
    let byte := if h : i < bytes.size then bytes.data[i].toNat else 0
    result := result + (byte <<< (i * 8))
  BitVec.ofNat 128 result

/-- Decode a hex string to BitVec 96 (little-endian interpretation of bytes) -/
def decodeToBitVec96 (s : String) : BitVec 96 :=
  let bytes := decode s
  let mut result : Nat := 0
  for i in [0:12] do
    let byte := if h : i < bytes.size then bytes.data[i].toNat else 0
    result := result + (byte <<< (i * 8))
  BitVec.ofNat 96 result

/-- Convert a natural number to little-endian ByteArray of specified size -/
private def natToBytes (n : Nat) (size : Nat) : ByteArray :=
  let mut result := ByteArray.mkEmpty size
  let mut val := n
  for _ in [0:size] do
    result := result.push (val % 256).toUInt8
    val := val / 256
  result

/-- Encode a BitVec 128 to hex string (little-endian) -/
def encodeBitVec128 (v : BitVec 128) : String :=
  let bytes := natToBytes v.toNat 16
  encode bytes

end Hex
