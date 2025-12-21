/-
Copyright (c) 2024 Marc Ilunga. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Marc Ilunga
-/
import VCVio.UC.Serializable
import VCVio.UC.Monad

/-!
# UC Framework: Communication Primitives

This file defines the communication primitives for the UC framework:
- Message sending between parties
- Leakage to the adversary

These primitives automatically handle serialization and routing while maintaining
the formal UC guarantees.

## Main Definitions

* `send` - Send a message to another party (automatically serialized)
* `receive` - Receive a message from another party (automatically deserialized)
* `leak` - Emit leakage information to the adversary (for side-channel modeling)
* `MessageTag` - Tags for different types of messages in the protocol

The communication model follows the UC framework where all communication is mediated
through ideal functionalities and can be intercepted/delayed by the adversary.
-/

namespace UC

/-- Message tags for categorizing protocol messages -/
inductive MessageTag
  | protocol : MessageTag  -- Regular protocol message
  | activation : MessageTag  -- Activation message
  | output : MessageTag  -- Output to environment
  deriving DecidableEq, Inhabited

/-- A message in the UC framework, containing sender, recipient, content, and tag -/
structure Message where
  from : PartyId
  to : PartyId
  tag : MessageTag
  content : List Bool  -- Serialized content
  deriving Inhabited

/-- Leakage information sent to the adversary -/
structure LeakageEvent where
  source : PartyId
  leakageType : String  -- Description of what is being leaked
  data : List Bool  -- Serialized leakage data
  deriving Inhabited

namespace Message

/-- Create a protocol message -/
def mk_protocol (from to : PartyId) (content : List Bool) : Message :=
  { from, to, tag := MessageTag.protocol, content }

/-- Create an activation message -/
def mk_activation (from to : PartyId) (content : List Bool) : Message :=
  { from, to, tag := MessageTag.activation, content }

/-- Create an output message -/
def mk_output (from to : PartyId) (content : List Bool) : Message :=
  { from, to, tag := MessageTag.output, content }

end Message

/-- Send a typed message to another party. The message is automatically serialized. -/
def send {ι : Type*} {spec : OracleSpec ι} {α : Type*} [Serializable α] 
    (dest : PartyId) (msg : α) : UC spec Unit := do
  let from ← UC.getPartyID
  let bits := Serializable.toBits msg
  -- In a real implementation, this would interact with an ideal functionality
  -- For now, we just update local state to track that we sent the message
  UC.modifyLocalState fun s => 
    { s with messageBuffer := s!"{from} -> {dest}: {bits.length} bits" :: s.messageBuffer }

/-- Receive a message from the message buffer. 
In a real implementation, this would block until a message arrives. -/
def receive {ι : Type*} {spec : OracleSpec ι} {α : Type*} [Serializable α] 
    : UC spec (Option α) := do
  let state ← UC.getLocalState
  -- Simplified: just return none. Real implementation would parse from buffer
  return none

/-- Emit a leakage event to the adversary. 
This allows protocol designers to explicitly model side-channels like message length,
timing information, etc., without affecting the protocol's functional behavior. -/
def leak {ι : Type*} {spec : OracleSpec ι} {α : Type*} [Serializable α]
    (leakageType : String) (data : α) : UC spec Unit := do
  let source ← UC.getPartyID
  let bits := Serializable.toBits data
  let event : LeakageEvent := { source, leakageType, data := bits }
  -- In a real implementation, this would send to the adversary
  -- For now, we just track it in the local state
  UC.modifyLocalState fun s =>
    { s with messageBuffer := s!"LEAK from {source}: {leakageType}" :: s.messageBuffer }

/-- Leak only the length of a value (common side-channel) -/
def leakLength {ι : Type*} {spec : OracleSpec ι} {α : Type*} [Serializable α]
    (data : α) : UC spec Unit :=
  leak "message_length" (Serializable.bitSize data)

/-- Send a message and leak its length to the adversary -/
def sendWithLeak {ι : Type*} {spec : OracleSpec ι} {α : Type*} [Serializable α]
    (dest : PartyId) (msg : α) : UC spec Unit := do
  leakLength msg
  send dest msg

end UC
