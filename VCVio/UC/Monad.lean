/-
Copyright (c) 2024 Marc Ilunga. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Marc Ilunga
-/
import VCVio.UC.Basic
import VCVio.OracleComp.OracleComp

/-!
# UC Framework: UC Monad

This file defines the UC monad, which is a high-level wrapper around VCV-io's OracleComp.
The UC monad provides protocol designers with an intuitive interface for writing UC protocols
while hiding the complexity of session management and message routing.

## Main Definitions

* `UCContext` - The internal state of the UC framework containing session ID, party ID, and adversary reference
* `LocalState` - Local state maintained by each party
* `UC α` - The primary monad for protocol designers, wrapping OracleComp with context and state
-/

namespace UC

open OracleComp

/-- Local state maintained by each party in a UC protocol. 
Can be extended with protocol-specific state. -/
structure LocalState where
  /-- Internal message buffer for received messages -/
  messageBuffer : List String := []
  /-- Counter for generating unique sub-session IDs -/
  subsessionCounter : Nat := 0

instance : Inhabited LocalState := ⟨{}⟩

/-- The internal context of the UC framework, providing session and party information. -/
structure UCContext where
  /-- The current unique session identifier -/
  sid : SessionID
  /-- ID of the party executing the code -/
  partyId : PartyId
  /-- Reference to the (dummy) adversary -/
  adversary : AdversaryRef

instance : Inhabited UCContext := ⟨{
  sid := default
  partyId := default
  adversary := default
}⟩

/-- The primary monad for protocol designers in the UC framework.
This is a Reader-State-Oracle computation that provides:
- Read-only access to UCContext (session ID, party ID, adversary)
- Mutable LocalState for party-specific state
- Oracle access through the underlying OracleComp monad
-/
abbrev UC {ι : Type*} (spec : OracleSpec ι) (α : Type*) := 
  ReaderT UCContext (StateT LocalState (OracleComp spec)) α

namespace UC

variable {ι : Type*} {spec : OracleSpec ι} {α β : Type*}

/-- Get the current session ID -/
def getSessionID : UC spec SessionID :=
  return (← read).sid

/-- Get the current party ID -/
def getPartyID : UC spec PartyId :=
  return (← read).partyId

/-- Get the adversary reference -/
def getAdversary : UC spec AdversaryRef :=
  return (← read).adversary

/-- Get the current local state -/
def getLocalState : UC spec LocalState :=
  get

/-- Update the local state -/
def modifyLocalState (f : LocalState → LocalState) : UC spec Unit :=
  modify f

/-- Generate a fresh sub-session ID by incrementing the counter and hashing with current SID.
This is used automatically by call_ideal to prevent session collisions. -/
def freshSubSessionID (label : String) : UC spec SessionID := do
  let ctx ← read
  let state ← get
  let newCounter := state.subsessionCounter + 1
  modify fun s => { s with subsessionCounter := newCounter }
  -- In a real implementation, this would be a cryptographic hash
  -- For now, we use a simple string concatenation
  return s!"{ctx.sid}:{label}:{newCounter}"

/-- Run a UC computation with a given context and initial state -/
def run (ctx : UCContext) (initialState : LocalState) (comp : UC spec α) : 
    OracleComp spec (α × LocalState) :=
  (comp ctx).run initialState

/-- Run a UC computation with default initial state -/
def runDefault (ctx : UCContext) (comp : UC spec α) : 
    OracleComp spec (α × LocalState) :=
  run ctx {} comp

end UC

end UC
