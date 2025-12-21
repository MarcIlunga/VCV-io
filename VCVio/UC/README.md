# Universal Composability (UC) Framework for Lean 4

This directory contains a comprehensive implementation of the Universal Composability (UC) framework in Lean 4, built on top of the VCV-io library.

## Overview

The UC framework provides a formal foundation for proving security of cryptographic protocols in the universal composability model. It bridges the gap between high-level mathematical specifications and low-level implementations through a "sandwich model" approach.

## Architecture

### Core Modules

1. **Basic.lean**: Foundational types
   - `SessionID`: Unique session identifiers
   - `PartyId`: Party identifiers
   - `AdversaryRef`: Adversary references

2. **Monad.lean**: The UC monad
   - `UCContext`: Execution context (session, party, adversary)
   - `LocalState`: Party-local state management
   - `UC α`: Main monad wrapping `ReaderT UCContext (StateT LocalState (OracleComp spec))`
   - Session ID management and sub-session derivation

3. **Serializable.lean**: Type-driven serialization
   - `Serializable α`: Typeclass for bitstring conversion
   - Instances for: Unit, Bool, Nat, String, pairs, sums, options, lists
   - Foundation for the "UC-on-tapes" model

4. **Communication.lean**: Message passing primitives
   - `send`: Type-safe message sending with automatic serialization
   - `receive`: Message receiving with deserialization
   - `leak`: Model adversarial leakage/side-channels
   - `Message`: Structured message types with tags

5. **Functionality.lean**: Ideal functionalities and composition
   - `Functionality`: Ideal functionality specifications
   - `Protocol`: Protocol specifications
   - `call_ideal`: F-hybrid model with automatic SID derivation
   - `compose`, `parallel`: Composition operators

6. **Security.lean**: Security definitions
   - `Simulator`: Simulator specifications
   - `Environment`: Environment/distinguisher
   - `Adversary`: Real-world adversary model
   - `ucSecure`: Main UC security definition
   - Composition theorem (placeholder)

7. **UC.lean**: Main module that re-exports all definitions

8. **Scratch.lean**: Examples and testing workspace

## Design Principles

### 1. Leveraging VCV-io

The framework builds on VCV-io's foundations:
- **OracleComp**: Base probabilistic monad
- **Hardness Assumptions**: DDH, CDH, RSA for reduction proofs
- **Negligible Functions**: For asymptotic security
- **Polynomial Time**: Computational complexity bounds

### 2. Type-Driven Design

The `Serializable` typeclass hides low-level bitstring manipulation:
```lean
-- High-level: work with structured types
def protocol : UC spec Nat := do
  send "alice" 42  -- Automatic serialization

-- Low-level bitstrings handled automatically
```

### 3. Automatic Session Management

Sub-session IDs are automatically derived to prevent collisions:
```lean
def hybridProtocol (F : Functionality) : UC spec Out := do
  -- Automatically generates unique sub-session ID
  let result ← call_ideal F input
  return result
```

### 4. Explicit Side-Channel Modeling

The `leak` primitive allows explicit modeling of information leakage:
```lean
def secureProtocol : UC spec Out := do
  let msg := computeMessage()
  leakLength msg  -- Leak only message length
  send "bob" msg
  return result
```

## Usage Examples

### Example 1: Simple Protocol

```lean
def echoProtocol : Protocol ι spec := {
  name := "Echo"
  numParties := 1
  In := Nat
  Out := Nat
  partyCode := fun _pid input => return input
}
```

### Example 2: Ideal Functionality

```lean
def idealAddition : Functionality ι spec := {
  name := "F_ADD"
  In := Nat × Nat
  Out := Nat
  behavior := fun (a, b) => do
    leak "addition_performed" ()
    return (a + b)
}
```

### Example 3: F-Hybrid Protocol

```lean
def hybridProtocol (F : Functionality ι spec) : Protocol ι spec := {
  name := "HybridProtocol"
  numParties := 2
  In := Nat
  Out := Nat
  partyCode := fun pid input => do
    let result ← call_ideal F input
    send "other_party" result
    return result
}
```

### Example 4: Custom Serializable Type

```lean
structure CryptoKey where
  value : Nat
  deriving Inhabited

instance : Serializable CryptoKey where
  toBits k := natToBits k.value
  fromBits bits := some { value := bitsToNat bits }
  roundtrip _ := by sorry
```

## The Sandwich Model

The framework supports three levels of abstraction:

### Level A: Abstract Mathematical Specification
- High-level protocols using Mathlib structures (Groups, Fields)
- Mathematical security proofs
- Ideal functionalities

### Level B: Executable Implementation
- Concrete implementations (potentially in Rust)
- Optimized for performance
- Real-world cryptographic libraries

### Level C: Refinement Bridge
- Proofs connecting A and B
- Uses Aeneas for Rust → Lean translation
- Ensures implementation correctness

## Security Proofs

UC security follows the Real/Ideal paradigm:

```lean
def ucSecure (P : Protocol) (F : Functionality) : Prop :=
  ∀ (A : Adversary), ∃ (S : Simulator),
    ∀ (Z : Environment),
      -- Real and Ideal executions are indistinguishable
      distinguishingAdvantage P F A S Z ≤ negligible
```

## Future Enhancements

1. **Automated Simulator Generation**: Tactic-based simulator synthesis
2. **Standard Functionality Library**: F_ZK, F_COM, F_AUTH, F_SIG, etc.
3. **Refinement Tooling**: Better Aeneas integration
4. **Example Protocols**: CGGMP21, threshold signatures, MPC protocols
5. **Composition Automation**: Automatic composition theorem application
6. **Integration with Mathlib**: Seamless use of algebraic structures

## References

1. Ran Canetti, "Universally Composable Security: A New Paradigm for Cryptographic Protocols", FOCS 2001
2. Canetti, "Universally Composable Security: A New Paradigm for Cryptographic Protocols" (full version), 2020
3. VCV-io: Verified Cryptography via Indexed Oracles
4. FCF: Foundational Cryptography Framework (Coq)
5. Lean 4 Documentation: https://lean-lang.org/

## Contributing

Contributions are welcome! Areas for contribution:
- Additional ideal functionalities
- Example protocol implementations
- Refinement examples
- Documentation improvements
- Proof automation tactics

## License

This framework is released under the Apache 2.0 license, consistent with VCV-io and Lean 4.
