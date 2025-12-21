/-
Copyright (c) 2024 Marc Ilunga. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Marc Ilunga
-/
import VCVio.OracleComp.OracleComp
import Mathlib.Data.Nat.Basic

/-!
# UC Framework: Basic Types

This file defines the basic types for the Universal Composability (UC) framework,
including session identifiers, party identifiers, and adversary references.

These types form the foundation for the UC monad and protocol specifications.
-/

namespace UC

/-- Session identifier for UC protocols. Used to uniquely identify protocol sessions
and prevent session collisions in composed protocols. -/
def SessionID : Type := String

/-- Party identifier in UC protocols. Identifies individual parties participating in a protocol. -/
def PartyId : Type := String

/-- Reference to the adversary in UC protocols. 
In the UC model, the adversary is typically the "dummy adversary" that just forwards messages. -/
def AdversaryRef : Type := Unit

instance : Inhabited SessionID := ⟨""⟩
instance : Inhabited PartyId := ⟨""⟩
instance : Inhabited AdversaryRef := ⟨()⟩

instance : DecidableEq SessionID := String.instDecidableEq
instance : DecidableEq PartyId := String.instDecidableEq

end UC
