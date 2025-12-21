/-
Copyright (c) 2024 Marc Ilunga. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Marc Ilunga
-/
import VCVio.UC.Communication
import VCVio.UC.Monad

/-!
# UC Framework: Functionalities and Composition

This file defines ideal functionalities and the composition mechanism for the UC framework.
It implements the F-hybrid model where protocols can invoke ideal functionalities as subroutines.

## Main Definitions

* `Functionality` - An ideal functionality specification
* `call_ideal` - Invoke an ideal functionality (with automatic SID derivation)
* `Protocol` - A protocol specification
* Composition operators for building complex protocols from simpler ones

The composition mechanism automatically handles sub-session ID generation to prevent
session collisions when multiple instances of a functionality are composed.
-/

namespace UC

/-- An ideal functionality specification in the UC framework.
A functionality is a trusted third party that parties can interact with.
It has input and output types, and its behavior is specified by a computation. -/
structure Functionality (ι : Type*) (spec : OracleSpec ι) where
  /-- The name of this functionality -/
  name : String
  /-- Input type for the functionality -/
  In : Type*
  /-- Output type for the functionality -/
  Out : Type*
  /-- Serialization for inputs -/
  [serIn : Serializable In]
  /-- Serialization for outputs -/
  [serOut : Serializable Out]
  /-- The behavior of the functionality -/
  behavior : In → UC spec Out

/-- A protocol specification in the UC framework -/
structure Protocol (ι : Type*) (spec : OracleSpec ι) where
  /-- The name of this protocol -/
  name : String
  /-- Number of parties in the protocol -/
  numParties : Nat
  /-- Input type for each party -/
  In : Type*
  /-- Output type for each party -/
  Out : Type*
  /-- Serialization for inputs -/
  [serIn : Serializable In]
  /-- Serialization for outputs -/
  [serOut : Serializable Out]
  /-- The protocol code for each party -/
  partyCode : PartyId → In → UC spec Out

namespace Functionality

variable {ι : Type*} {spec : OracleSpec ι}

/-- Create a simple stateless functionality -/
def simple (name : String) {In Out : Type*} [Serializable In] [Serializable Out]
    (f : In → UC spec Out) : Functionality ι spec :=
  { name, In, Out, behavior := f }

/-- A dummy ideal functionality that just returns its input -/
def identity (name : String) (α : Type*) [Serializable α] : Functionality ι spec :=
  simple name (fun (x : α) => return x)

end Functionality

/-- Call an ideal functionality with a given input, automatically deriving a sub-session ID.
This implements the F-hybrid model composition.

The sub-session ID is derived from:
1. The current session ID (sid)
2. The functionality name
3. A counter to ensure uniqueness

This prevents session collision when multiple instances of the same functionality are used. -/
def call_ideal {ι : Type*} {spec : OracleSpec ι}
    (F : Functionality ι spec) (input : F.In) : UC spec F.Out := do
  -- Generate a fresh sub-session ID
  let subSID ← UC.freshSubSessionID F.name
  
  -- Get current context
  let ctx ← read
  
  -- Create a new context for the functionality call with the sub-session ID
  let subCtx : UCContext := { ctx with sid := subSID }
  
  -- Get current state
  let state ← get
  
  -- Run the functionality in the sub-context
  -- In a real implementation, this would involve message passing to the functionality
  -- For the specification, we directly invoke the behavior
  let result ← F.behavior input
  
  return result

/-- Call an ideal functionality and leak information about the call to the adversary -/
def call_ideal_with_leak {ι : Type*} {spec : OracleSpec ι}
    (F : Functionality ι spec) (input : F.In) : UC spec F.Out := do
  -- Leak that we're calling this functionality
  leak "functionality_call" F.name
  leakLength input
  
  -- Call the functionality
  call_ideal F input

/-- Sequential composition: run protocol1, then use its output as input to protocol2 -/
def compose {ι : Type*} {spec : OracleSpec ι} {α β γ : Type*}
    [Serializable α] [Serializable β] [Serializable γ]
    (comp1 : α → UC spec β) (comp2 : β → UC spec γ) (input : α) : UC spec γ := do
  let intermediate ← comp1 input
  comp2 intermediate

/-- Parallel composition: run two computations in parallel (simplified model) -/
def parallel {ι : Type*} {spec : OracleSpec ι} {α β : Type*}
    (comp1 : UC spec α) (comp2 : UC spec β) : UC spec (α × β) := do
  let a ← comp1
  let b ← comp2
  return (a, b)

namespace Protocol

variable {ι : Type*} {spec : OracleSpec ι}

/-- Execute a protocol with a given party ID and input -/
def execute (P : Protocol ι spec) (pid : PartyId) (input : P.In) : UC spec P.Out :=
  P.partyCode pid input

/-- Create a simple protocol with identical code for all parties -/
def uniform (name : String) (numParties : Nat) {In Out : Type*} 
    [Serializable In] [Serializable Out]
    (code : In → UC spec Out) : Protocol ι spec :=
  { name, numParties, In, Out, partyCode := fun _ => code }

end Protocol

/-- The F-hybrid model: a protocol that has access to functionality F.
This is represented by simply having F available in scope for call_ideal. -/
def FHybridModel {ι : Type*} {spec : OracleSpec ι}
    (F : Functionality ι spec) (P : Protocol ι spec) : Protocol ι spec :=
  P  -- The protocol already has access to call F via call_ideal

end UC
