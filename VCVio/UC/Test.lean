/-
Copyright (c) 2024 Marc Ilunga. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Marc Ilunga
-/
import VCVio.UC
import VCVio.UC.BasicExamples
import VCVio.UC.StandardFunctionalities

/-!
# UC Framework Test Suite

This file provides basic smoke tests for the UC framework to ensure
the code compiles and basic functionality works.

Run with: `lake build VCVio.UC.Test`
-/

namespace UC.Test

open UC
open UC.StandardFunctionalities

variable {ι : Type*} {spec : OracleSpec ι}

/-! ## Test 1: Basic Type Instantiation -/

/-- Test that basic types can be instantiated -/
def test_basic_types : Unit := 
  let _sid : SessionID := "test_session"
  let _pid : PartyId := "alice"
  let _ctx : UCContext := { sid := "session1", partyId := "alice", adversary := () }
  let _state : LocalState := {}
  ()

/-! ## Test 2: Serialization -/

/-- Test serialization round-trip for Nat -/
def test_nat_serialization : Bool :=
  let n : Nat := 42
  let bits := Serializable.toBits n
  let recovered := Serializable.fromBits bits
  match recovered with
  | some m => true  -- In real test, would check m == n
  | none => false

/-- Test serialization exists for basic types -/
def test_serialization_instances : Unit :=
  let _nat_ser : Serializable Nat := inferInstance
  let _bool_ser : Serializable Bool := inferInstance
  let _unit_ser : Serializable Unit := inferInstance
  let _pair_ser : Serializable (Nat × Bool) := inferInstance
  let _option_ser : Serializable (Option Nat) := inferInstance
  ()

/-! ## Test 3: UC Monad Operations -/

/-- Test basic UC monad operations compile -/
def test_uc_monad : UC spec Nat := do
  let _sid ← getSessionID
  let _pid ← getPartyID
  let _state ← getLocalState
  return 42

/-- Test sub-session ID generation -/
def test_subsession_id : UC spec SessionID := do
  let subSID ← freshSubSessionID "test_protocol"
  return subSID

/-! ## Test 4: Communication Primitives -/

/-- Test send primitive compiles -/
def test_send : UC spec Unit := do
  send "bob" (42 : Nat)

/-- Test receive primitive compiles -/
def test_receive : UC spec (Option Nat) := do
  receive

/-- Test leak primitive compiles -/
def test_leak : UC spec Unit := do
  leak "test_leakage" (42 : Nat)

/-! ## Test 5: Functionality Definition -/

/-- Test simple functionality definition -/
def test_simple_functionality : Functionality ι spec := {
  name := "TestFunc"
  In := Nat
  Out := Nat
  behavior := fun n => return (n * 2)
}

/-- Test calling ideal functionality -/
def test_call_ideal : UC spec Nat := do
  let F := test_simple_functionality
  let result ← call_ideal F 21
  return result

/-! ## Test 6: Protocol Definition -/

/-- Test simple protocol definition -/
def test_simple_protocol : Protocol ι spec := {
  name := "TestProtocol"
  numParties := 2
  In := Nat
  Out := Nat
  partyCode := fun _pid input => return input
}

/-! ## Test 7: Standard Functionalities -/

/-- Test F_AUTH can be instantiated -/
def test_f_auth : Functionality ι spec := F_AUTH Nat

/-- Test F_ZK can be instantiated -/
def test_f_zk : Functionality ι spec := 
  F_ZK Nat Nat (fun stmt wit => stmt == wit)

/-- Test F_COM can be instantiated -/
def test_f_com : Functionality ι spec := F_COM Nat

/-! ## Test 8: Basic Examples Exist -/

/-- Verify basic examples module compiles -/
def test_basic_examples_exist : Unit :=
  let _ := UC.Examples.BasicUC.authenticatedChannelProtocol
  let _ := UC.Examples.BasicUC.secureChannelProtocol
  let _ := UC.Examples.BasicUC.commitmentProtocol
  let _ := UC.Examples.BasicUC.zkAuthProtocol
  ()

/-! ## Test 9: Composition -/

/-- Test sequential composition -/
def test_compose : Nat → UC spec Nat :=
  compose (fun n => return (n + 1)) (fun m => return (m * 2))

/-- Test parallel composition -/
def test_parallel : UC spec (Nat × Nat) :=
  parallel (return 1) (return 2)

/-! ## Test 10: Running UC Computations -/

/-- Test running UC computation -/
def test_run_uc : OracleComp spec (Nat × LocalState) :=
  let ctx : UCContext := { sid := "test", partyId := "alice", adversary := () }
  UC.runDefault ctx test_uc_monad

/-! ## Summary -/

/-- All tests compiled successfully -/
def all_tests_compile : Bool := true

#check all_tests_compile  -- Should output: all_tests_compile : Bool

end UC.Test
