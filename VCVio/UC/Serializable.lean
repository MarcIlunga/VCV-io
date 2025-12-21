/-
Copyright (c) 2024 Marc Ilunga. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Marc Ilunga
-/
import VCVio.UC.Monad
import Mathlib.Data.Nat.Basic
import Mathlib.Data.List.Basic

/-!
# UC Framework: Serialization

This file defines the Serializable typeclass for type-driven serialization in the UC framework.
The framework uses this typeclass under the hood to satisfy the "UC-on-tapes" definition
while allowing protocol designers to work with high-level types.

## Main Definitions

* `Serializable α` - Typeclass for types that can be serialized to/from bit strings
* Instances for basic types (Nat, Bool, String, Unit, Prod, Sum, List, Option)

The serialization mechanism allows the UC framework to automatically handle the conversion
between high-level types (Groups, Fields, etc.) and the low-level bitstring representation
required by the formal UC definition.
-/

namespace UC

/-- A type is Serializable if it can be converted to and from a list of booleans (bitstring).
This typeclass is used throughout the UC framework to automatically handle serialization
of messages and protocol data. -/
class Serializable (α : Type*) where
  /-- Convert a value to a bitstring -/
  toBits : α → List Bool
  /-- Parse a bitstring to a value, returning none if parsing fails -/
  fromBits : List Bool → Option α
  /-- Round-trip property: fromBits ∘ toBits = some -/
  roundtrip : ∀ (x : α), fromBits (toBits x) = some x

namespace Serializable

/-- Get the size in bits of a serialized value -/
def bitSize {α : Type*} [Serializable α] (x : α) : Nat :=
  (toBits x).length

/-- Default empty bitstring -/
def emptyBits : List Bool := []

end Serializable

/-- Helper function to convert a natural number to bits (little-endian) -/
def natToBits (n : Nat) : List Bool :=
  if n = 0 then [false]
  else
    let rec toBitsAux (m : Nat) (acc : List Bool) : List Bool :=
      if m = 0 then acc
      else toBitsAux (m / 2) ((m % 2 = 1) :: acc)
    toBitsAux n []

/-- Helper function to convert bits to a natural number (little-endian) -/
def bitsToNat (bits : List Bool) : Nat :=
  bits.foldl (fun acc b => 2 * acc + if b then 1 else 0) 0

/-- Unit type serialization (empty bitstring) -/
instance : Serializable Unit where
  toBits _ := []
  fromBits _ := some ()
  roundtrip _ := rfl

/-- Bool serialization (single bit) -/
instance : Serializable Bool where
  toBits b := [b]
  fromBits
    | [b] => some b
    | _ => none
  roundtrip _ := rfl

/-- Natural number serialization -/
instance : Serializable Nat where
  toBits := natToBits
  fromBits bits := some (bitsToNat bits)
  roundtrip n := by
    -- This would need a proper proof, but for the specification we admit it
    sorry

/-- String serialization (via list of characters, each as a Nat) -/
instance : Serializable String where
  toBits s := 
    let chars := s.toList
    -- Encode length first, then each character
    natToBits chars.length ++ (chars.bind fun c => natToBits c.toNat)
  fromBits bits := 
    -- Would need proper parsing logic, simplified for specification
    some "" -- Placeholder
  roundtrip _ := by sorry

/-- Product type serialization -/
instance {α β : Type*} [Serializable α] [Serializable β] : Serializable (α × β) where
  toBits (a, b) := 
    let aBits := Serializable.toBits a
    let bBits := Serializable.toBits b
    -- Encode length of first component, then both components
    natToBits aBits.length ++ aBits ++ bBits
  fromBits bits := do
    -- Would need proper parsing logic
    some (sorry, sorry)
  roundtrip _ := by sorry

/-- Sum type serialization -/
instance {α β : Type*} [Serializable α] [Serializable β] : Serializable (α ⊕ β) where
  toBits
    | Sum.inl a => false :: Serializable.toBits a
    | Sum.inr b => true :: Serializable.toBits b
  fromBits
    | false :: rest => do
      let a ← Serializable.fromBits rest
      return Sum.inl a
    | true :: rest => do
      let b ← Serializable.fromBits rest
      return Sum.inr b
    | _ => none
  roundtrip
    | Sum.inl _ => by sorry
    | Sum.inr _ => by sorry

/-- Option type serialization -/
instance {α : Type*} [Serializable α] : Serializable (Option α) where
  toBits
    | none => [false]
    | some a => true :: Serializable.toBits a
  fromBits
    | false :: _ => some none
    | true :: rest => do
      let a ← Serializable.fromBits rest
      return some a
    | _ => none
  roundtrip
    | none => rfl
    | some _ => by sorry

/-- List serialization -/
instance {α : Type*} [Serializable α] : Serializable (List α) where
  toBits xs :=
    natToBits xs.length ++ (xs.bind Serializable.toBits)
  fromBits bits := do
    -- Would need proper parsing logic
    some []
  roundtrip _ := by sorry

end UC
