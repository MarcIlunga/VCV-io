/-
Copyright (c) 2024 Marc Ilunga. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Marc Ilunga
-/
import VCVio.UC

/-!
# UC Framework: Scratch File for Testing

This file is a workspace for testing ideas and experimenting with the UC framework.
It demonstrates how to use the framework components and can be used to prototype
new protocols and functionalities.
-/

namespace UC.Examples

open UC

variable {ι : Type*} {spec : OracleSpec ι}

/-! ## Example 1: Simple Echo Protocol -/

/-- A simple echo protocol that just returns its input -/
def echoProtocol : Protocol ι spec := {
  name := "Echo"
  numParties := 1
  In := Nat
  Out := Nat
  partyCode := fun _pid input => return input
}

/-! ## Example 2: Addition Protocol -/

/-- A protocol where two parties add their inputs -/
def additionProtocol : Protocol ι spec := {
  name := "Addition"
  numParties := 2
  In := Nat
  Out := Nat
  partyCode := fun pid input => do
    if pid == "party1" then
      -- Party 1 sends its input to party 2
      send "party2" input
      return input
    else
      -- Party 2 receives and adds
      let maybeReceived ← receive
      match maybeReceived with
      | some (other : Nat) => return other + input
      | none => return input
}

/-! ## Example 3: Ideal Functionality for Secure Addition -/

/-- Ideal functionality for secure addition: takes two inputs, returns sum to both parties -/
def idealAddition : Functionality ι spec := {
  name := "F_ADD"
  In := Nat × Nat  -- Pair of inputs
  Out := Nat       -- Sum
  behavior := fun (a, b) => do
    let sum := a + b
    -- Leak only that computation happened, not the values
    leak "addition_performed" ()
    return sum
}

/-! ## Example 4: Using call_ideal -/

/-- A protocol that uses the ideal addition functionality -/
def protocolWithIdealAdd (F : Functionality ι spec) : Protocol ι spec := {
  name := "ProtocolWithIdealAdd"
  numParties := 2
  In := Nat
  Out := Nat
  partyCode := fun pid input => do
    -- Call the ideal functionality
    -- Note: In a real protocol, we'd need to collect both inputs first
    let result ← call_ideal F (input, input + 1)
    return result
}

/-! ## Example 5: Testing Serialization -/

/-- Example of using serialization -/
def serializationExample : UC spec Unit := do
  let n : Nat := 42
  let bits := Serializable.toBits n
  
  -- Send the number to another party
  send "alice" n
  
  -- Leak the length
  leakLength n
  
  return ()

/-! ## Example 6: Composing Protocols -/

/-- First protocol: doubles input -/
def doubleProtocol : Nat → UC spec Nat :=
  fun n => return (2 * n)

/-- Second protocol: adds 10 to input -/
def add10Protocol : Nat → UC spec Nat :=
  fun n => return (n + 10)

/-- Composed protocol: double then add 10 -/
def composedProtocol : Nat → UC spec Nat :=
  compose doubleProtocol add10Protocol

/-! ## Example 7: Parallel Execution -/

/-- Example of parallel execution of two computations -/
def parallelExample : UC spec (Nat × Nat) := do
  let comp1 : UC spec Nat := return 42
  let comp2 : UC spec Nat := return 100
  parallel comp1 comp2

/-! ## Example 8: Stateful Protocol -/

/-- A protocol that uses local state to count invocations -/
def statefulProtocol : Protocol ι spec := {
  name := "Stateful"
  numParties := 1
  In := Unit
  Out := Nat
  partyCode := fun _pid _input => do
    let state ← getLocalState
    let count := state.subsessionCounter
    modifyLocalState fun s => { s with subsessionCounter := s.subsessionCounter + 1 }
    return count
}

/-! ## Example 9: Session ID Management -/

/-- Example showing session ID management -/
def sessionExample : UC spec String := do
  let sid ← getSessionID
  let pid ← getPartyID
  
  -- Generate a sub-session ID
  let subSID ← freshSubSessionID "test_protocol"
  
  return s!"Current: {sid}, Party: {pid}, Sub: {subSID}"

/-! ## Example 10: Custom Serializable Type -/

/-- Custom type for a cryptographic key -/
structure CryptoKey where
  value : Nat
  deriving Inhabited

/-- Serialization instance for CryptoKey -/
instance : Serializable CryptoKey where
  toBits k := natToBits k.value
  fromBits bits := some { value := bitsToNat bits }
  roundtrip _ := by sorry

/-- Protocol using custom type -/
def keyExchangeProtocol : Protocol ι spec := {
  name := "KeyExchange"
  numParties := 2
  In := CryptoKey
  Out := CryptoKey
  partyCode := fun pid key => do
    send "other_party" key
    return key
}

/-! ## Notes and Ideas

This scratch file demonstrates:

1. ✓ Basic protocol definitions
2. ✓ Using communication primitives (send, receive, leak)
3. ✓ Defining ideal functionalities
4. ✓ Calling ideal functionalities with call_ideal
5. ✓ Serialization of different types
6. ✓ Protocol composition (sequential and parallel)
7. ✓ Stateful protocols using LocalState
8. ✓ Session ID management and sub-session derivation
9. ✓ Custom types with Serializable instances

Next steps for implementation:
- Add more sophisticated ideal functionalities (F_ZK, F_COM, F_AUTH)
- Implement real security proofs using the Security module
- Add refinement examples connecting to executable code
- Integrate with VCV-io's hardness assumptions for reduction proofs
- Add tooling for automated simulator generation

-/

end UC.Examples
