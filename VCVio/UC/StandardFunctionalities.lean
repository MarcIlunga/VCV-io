/-
Copyright (c) 2024 Marc Ilunga. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Marc Ilunga
-/
import VCVio.UC

/-!
# UC Framework: Standard Ideal Functionalities

This file provides definitions for standard ideal functionalities commonly used
in cryptographic protocol design. These can serve as building blocks for more
complex protocols.

## Included Functionalities

* `F_AUTH` - Authenticated communication
* `F_SEC` - Secure (authenticated + confidential) communication  
* `F_ZK` - Zero-knowledge proof
* `F_COM` - Commitment
* `F_SIG` - Digital signature
* `F_KE` - Key exchange

These are placeholder specifications that can be refined with full implementations.
-/

namespace UC.StandardFunctionalities

open UC

variable {ι : Type*} {spec : OracleSpec ι}

/-! ## Authenticated Communication -/

/-- Input type for authenticated channel functionality -/
inductive F_AUTH_Input (α : Type*)
  | send : PartyId → PartyId → α → F_AUTH_Input α  -- (from, to, message)
  | receive : PartyId → F_AUTH_Input α  -- party requesting to receive

/-- Output type for authenticated channel functionality -/
inductive F_AUTH_Output (α : Type*)
  | sent : F_AUTH_Output α
  | message : PartyId → α → F_AUTH_Output α  -- (from, message)
  | noMessage : F_AUTH_Output α

/-- Ideal functionality for authenticated communication.
Guarantees that messages come from claimed sender, but provides no confidentiality. -/
def F_AUTH (α : Type*) [Serializable α] : Functionality ι spec := {
  name := "F_AUTH"
  In := F_AUTH_Input α
  Out := F_AUTH_Output α
  behavior := fun input => do
    match input with
    | F_AUTH_Input.send from to msg =>
      -- In full implementation, would store message in internal state
      leak "message_sent" (from, to)
      leakLength msg
      return F_AUTH_Output.sent
    | F_AUTH_Input.receive party =>
      -- In full implementation, would retrieve message from internal state
      return F_AUTH_Output.noMessage
}

/-! ## Secure Communication -/

/-- Ideal functionality for secure (authenticated + confidential) communication.
Guarantees both authenticity and confidentiality. -/
def F_SEC (α : Type*) [Serializable α] : Functionality ι spec := {
  name := "F_SEC"
  In := F_AUTH_Input α
  Out := F_AUTH_Output α
  behavior := fun input => do
    match input with
    | F_AUTH_Input.send from to msg =>
      -- Only leak that communication occurred, not the message
      leak "secure_message_sent" (from, to)
      return F_AUTH_Output.sent
    | F_AUTH_Input.receive party =>
      return F_AUTH_Output.noMessage
}

/-! ## Zero-Knowledge Proof -/

/-- Input for zero-knowledge proof functionality -/
structure F_ZK_Input (Statement Witness : Type*) where
  prover : PartyId
  verifier : PartyId
  statement : Statement
  witness : Option Witness  -- Only prover provides witness

/-- Output for zero-knowledge proof functionality -/
inductive F_ZK_Output
  | accepted : F_ZK_Output
  | rejected : F_ZK_Output

/-- Ideal functionality for zero-knowledge proofs.
Verifier learns only whether the statement is true, nothing about the witness. -/
def F_ZK (Statement Witness : Type*) [Serializable Statement] [Serializable Witness]
    (relation : Statement → Witness → Bool) : Functionality ι spec := {
  name := "F_ZK"
  In := F_ZK_Input Statement Witness
  Out := F_ZK_Output
  behavior := fun input => do
    leak "zk_proof_attempt" input.prover
    match input.witness with
    | some w =>
      if relation input.statement w then
        return F_ZK_Output.accepted
      else
        return F_ZK_Output.rejected
    | none =>
      -- Verifier is querying
      return F_ZK_Output.rejected
}

/-! ## Commitment -/

/-- Input for commitment functionality -/
inductive F_COM_Input (α : Type*)
  | commit : PartyId → α → F_COM_Input α  -- (committer, value)
  | reveal : PartyId → F_COM_Input α  -- committer reveals
  | verify : PartyId → F_COM_Input α  -- verifier checks

/-- Output for commitment functionality -/
inductive F_COM_Output (α : Type*)
  | committed : F_COM_Output α
  | revealed : α → F_COM_Output α
  | notRevealed : F_COM_Output α

/-- Ideal functionality for commitment schemes.
Guarantees hiding (receiver learns nothing before reveal) and binding (committer can't change). -/
def F_COM (α : Type*) [Serializable α] : Functionality ι spec := {
  name := "F_COM"
  In := F_COM_Input α
  Out := F_COM_Output α
  behavior := fun input => do
    match input with
    | F_COM_Input.commit party value =>
      leak "commitment_made" party
      return F_COM_Output.committed
    | F_COM_Input.reveal party =>
      -- In full implementation, would retrieve stored value
      return F_COM_Output.notRevealed
    | F_COM_Input.verify party =>
      return F_COM_Output.notRevealed
}

/-! ## Digital Signature -/

/-- Input for signature functionality -/
inductive F_SIG_Input (Message : Type*)
  | register : PartyId → F_SIG_Input Message  -- Register public key
  | sign : PartyId → Message → F_SIG_Input Message  -- Sign message
  | verify : PartyId → Message → F_SIG_Input Message  -- Verify signature

/-- Output for signature functionality -/
inductive F_SIG_Output (Message : Type*)
  | registered : F_SIG_Output Message
  | signature : F_SIG_Output Message
  | valid : F_SIG_Output Message
  | invalid : F_SIG_Output Message

/-- Ideal functionality for digital signatures.
Guarantees unforgeability: only the signer can create valid signatures. -/
def F_SIG (Message : Type*) [Serializable Message] : Functionality ι spec := {
  name := "F_SIG"
  In := F_SIG_Input Message
  Out := F_SIG_Output Message
  behavior := fun input => do
    match input with
    | F_SIG_Input.register party =>
      leak "key_registration" party
      return F_SIG_Output.registered
    | F_SIG_Input.sign party msg =>
      leak "signing" party
      leakLength msg
      return F_SIG_Output.signature
    | F_SIG_Input.verify party msg =>
      -- In full implementation, would check against stored signatures
      return F_SIG_Output.invalid
}

/-! ## Key Exchange -/

/-- Input for key exchange functionality -/
inductive F_KE_Input
  | init : PartyId → PartyId → F_KE_Input  -- (party1, party2)
  | getKey : PartyId → F_KE_Input  -- party requests key

/-- Output for key exchange functionality (using Nat as placeholder for key type) -/
inductive F_KE_Output
  | initialized : F_KE_Output
  | key : Nat → F_KE_Output  -- Shared key
  | noKey : F_KE_Output

/-- Ideal functionality for key exchange.
Guarantees that parties get the same random key, unknown to adversary. -/
def F_KE : Functionality ι spec := {
  name := "F_KE"
  In := F_KE_Input
  Out := F_KE_Output
  behavior := fun input => do
    match input with
    | F_KE_Input.init p1 p2 =>
      leak "key_exchange_initiated" (p1, p2)
      return F_KE_Output.initialized
    | F_KE_Input.getKey party =>
      -- In full implementation, would sample and store a random key
      return F_KE_Output.noKey
}

/-! ## Utility Functions -/

/-- Helper to compose protocols with standard functionalities -/
def withF_AUTH {α β : Type*} [Serializable α] [Serializable β]
    (protocol : α → UC spec β) : α → UC spec β :=
  fun input => protocol input

/-- Helper to build a protocol using multiple ideal functionalities -/
def withFunctionalities (F_list : List (Functionality ι spec))
    {α : Type*} (protocol : α → UC spec α) : α → UC spec α :=
  protocol

end UC.StandardFunctionalities
