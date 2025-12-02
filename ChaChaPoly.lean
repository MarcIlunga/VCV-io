/-
Copyright (c) 2024. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: VCV-io Contributors

Main import file for ChaCha20-Poly1305 implementation.

This library provides a pure, deterministic implementation of ChaCha20-Poly1305
AEAD following RFC 8439. It is designed with a dual-layer architecture:

1. **Impl Layer (Pure)**: Uses BitVec 32 and ByteArray for deterministic computation.
   No dependencies on VCV-io framework. Passes RFC 8439 KATs (Known Answer Tests).

2. **Spec Layer (VCV-io Extensible)**: Wraps Impl functions into OracleComp monad
   and defines algebraic refinement theorems for security proofs.

Usage:
- Import `ChaChaPoly` for the full library including VCV-io integration
- Import `ChaChaPoly.Impl.ChaCha20` for just the ChaCha20 cipher
- Import `ChaChaPoly.Impl.Poly1305` for just the Poly1305 MAC
- Import `ChaChaPoly.Impl.AEAD` for the combined AEAD construction
- Import `ChaChaPoly.Test.TestVectors` for RFC 8439 test vectors
-/

-- Pure Implementation Layer
import ChaChaPoly.Impl.ChaCha20
import ChaChaPoly.Impl.Poly1305
import ChaChaPoly.Impl.AEAD
import ChaChaPoly.Impl.Hex

-- Test Infrastructure (test vectors only, Runner has main)
import ChaChaPoly.Test.TestVectors

-- VCV-io Spec Layer (commented out by default to allow pure usage)
-- import ChaChaPoly.Spec.VCVioExtensibility
