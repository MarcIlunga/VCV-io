/-
Copyright (c) 2024 Marc Ilunga. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Marc Ilunga
-/
import VCVio.UC.Basic
import VCVio.UC.Monad
import VCVio.UC.Serializable
import VCVio.UC.Communication
import VCVio.UC.Functionality
import VCVio.UC.Security

/-!
# Universal Composability (UC) Framework for Lean 4

This module provides a comprehensive UC framework built on top of VCV-io,
enabling formal verification of cryptographic protocols in the Universal Composability model.

## Overview

The UC framework provides:

1. **Core Monad & Context**: The `UC` monad wraps VCV-io's `OracleComp` with session management
   - `UCContext`: Session ID, party ID, adversary reference
   - `LocalState`: Party-local state management
   - `UC α`: The main monad for protocol design

2. **Type-Driven Serialization**: The `Serializable` typeclass
   - Automatic conversion between high-level types and bitstrings
   - Instances for basic types (Nat, Bool, String, pairs, sums, lists, options)
   - Extensible for custom types and algebraic structures

3. **Communication Primitives**:
   - `send`: Send typed messages between parties (auto-serialized)
   - `receive`: Receive and deserialize messages
   - `leak`: Model side-channels and adversary leakage
   - `leakLength`: Common pattern for leaking message lengths

4. **Functionalities & Composition**:
   - `Functionality`: Ideal functionality specifications
   - `Protocol`: Protocol specifications
   - `call_ideal`: Invoke ideal functionalities with automatic SID derivation
   - F-hybrid model support for modular protocol design

5. **Security Definitions**:
   - `Simulator`: Simulator specifications for security proofs
   - `Environment`: Environment/distinguisher model
   - `ucSecure`: UC security definition (Real vs Ideal indistinguishability)
   - Composition theorem (placeholder)

## Design Philosophy

The framework follows a "sandwich model" approach:

- **Level A (Abstract)**: High-level protocol specifications using Mathlib structures
  (Groups, Fields, etc.)
- **Level B (Executable)**: Concrete implementations (potentially in Rust via Aeneas)
- **Level C (Bridge)**: Refinement proofs connecting abstract and executable levels

This enables both rigorous mathematical proofs and verification of real-world implementations.

## Usage Example

```lean
-- Define a simple protocol
def simpleProtocol {spec : OracleSpec ι} : Protocol ι spec := {
  name := "SimpleProtocol"
  numParties := 2
  In := Nat
  Out := Nat
  partyCode := fun pid input => do
    send "party2" input
    return (input + 1)
}

-- Define an ideal functionality
def idealFunc {spec : OracleSpec ι} : Functionality ι spec := {
  name := "IdealF"
  In := Nat
  Out := Nat
  behavior := fun n => return (n * 2)
}

-- Use in F-hybrid model
def hybridProtocol {spec : OracleSpec ι} (F : Functionality ι spec) : Protocol ι spec := {
  name := "HybridProtocol"
  numParties := 2
  In := Nat
  Out := Nat
  partyCode := fun pid input => do
    -- Call ideal functionality
    let result ← call_ideal F input
    -- Use result in protocol
    send "party2" result
    return result
}
```

## Integration with VCV-io

The UC framework leverages VCV-io's foundational components:

- **OracleComp**: The underlying probabilistic monad with oracle access
- **Hardness Assumptions**: DDH, CDH, RSA definitions for reduction proofs
- **Negligible Functions**: For asymptotic security arguments
- **Polynomial Time**: For computational complexity bounds

## Future Work

- Automated simulator generation tactics
- Refinement tooling for connecting to executable code (Aeneas integration)
- Library of standard ideal functionalities (F_ZK, F_COM, F_AUTH, etc.)
- Example protocols (CGGMP21, threshold signatures, etc.)
- Integration with Mathlib's algebraic structures

## References

- Ran Canetti, "Universally Composable Security: A New Paradigm for Cryptographic Protocols"
- VCV-io: Verified Cryptography via Indexed Oracles
- FCF: Foundational Cryptography Framework (Coq)
-/

-- Re-export main definitions for convenience
namespace UC

-- Core types
export UC.SessionID
export UC.PartyId
export UC.AdversaryRef
export UC.UCContext
export UC.LocalState

-- Monad operations
export UC.UC
export UC.getSessionID
export UC.getPartyID
export UC.getAdversary
export UC.getLocalState
export UC.modifyLocalState
export UC.freshSubSessionID

-- Serialization
export UC.Serializable
export UC.natToBits
export UC.bitsToNat

-- Communication
export UC.send
export UC.receive
export UC.leak
export UC.leakLength
export UC.sendWithLeak
export UC.Message
export UC.MessageTag
export UC.LeakageEvent

-- Functionalities
export UC.Functionality
export UC.Protocol
export UC.call_ideal
export UC.call_ideal_with_leak
export UC.compose
export UC.parallel

-- Security
export UC.Simulator
export UC.Adversary
export UC.Environment
export UC.ucSecure
export UC.deriveSimulator

end UC
