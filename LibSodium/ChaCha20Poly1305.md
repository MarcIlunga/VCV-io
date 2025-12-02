# ChaCha20-Poly1305 AEAD Implementation

This module provides Lean 4 bindings to the libsodium implementation of ChaCha20-Poly1305, a modern Authenticated Encryption with Associated Data (AEAD) algorithm.

## Overview

ChaCha20-Poly1305 is a high-speed AEAD construction that combines:
- **ChaCha20**: A stream cipher for encryption
- **Poly1305**: A MAC (Message Authentication Code) for authentication

This implementation uses the IETF variant of ChaCha20-Poly1305 as specified in RFC 8439.

## Features

- **Constant-time operations**: Uses libsodium's constant-time implementation to prevent timing attacks
- **Type-safe bindings**: Lean type system ensures correct usage
- **Easy-to-use API**: Simple encrypt/decrypt functions

## Constants

```lean
ChaCha20Poly1305.keyBytes    -- 32 bytes (256 bits)
ChaCha20Poly1305.nonceBytes  -- 12 bytes (96 bits)
ChaCha20Poly1305.aBytes      -- 16 bytes (128 bits) for authentication tag
```

## Usage

### Encryption

```lean
def message : ByteArray := ByteArray.mk #[0x48, 0x65, 0x6c, 0x6c, 0x6f]  -- "Hello"
def ad : ByteArray := ByteArray.mk #[0x41, 0x44]  -- Additional data
def key : ByteArray := -- 32 bytes of key material
def nonce : ByteArray := -- 12 bytes of unique nonce

match ← ChaCha20Poly1305.encrypt message ad nonce key with
| some ciphertext => IO.println "Encryption successful!"
| none => IO.println "Encryption failed!"
```

### Decryption

```lean
match ← ChaCha20Poly1305.decrypt ciphertext ad nonce key with
| some plaintext => IO.println "Decryption and authentication successful!"
| none => IO.println "Decryption or authentication failed!"
```

## Security Considerations

1. **Never reuse a nonce with the same key**: Each encryption must use a unique nonce
2. **Key management**: Keys should be securely generated and stored
3. **Additional data (AD)**: The AD must match between encryption and decryption
4. **Authentication**: Decryption failure indicates either corruption or tampering

## Testing

The ChaCha20-Poly1305 implementation is tested in multiple ways:

1. **Unit tests** in `Test.lean`:
   - Constant size verification
   - Roundtrip encryption/decryption tests

2. **CI Pipeline** (`.github/workflows/chacha-poly1305.yml`):
   - Build verification
   - Security checks
   - Lint checks
   - Integration tests

To run tests locally:

```bash
lake build test
lake exe test
```

## CI Pipeline

The CI pipeline automatically runs on:
- Pushes to main branch
- Pull requests to main branch
- Changes to ChaCha20-Poly1305 related files

Jobs included:
- **check-chacha-poly1305**: Builds and tests the implementation
- **lint-chacha-poly1305**: Verifies code structure and presence of required functions
- **security-check**: Ensures security best practices are followed

## Implementation Details

The C++ implementation (`LibSodium/c/libsodium.cpp`) provides:
- `chacha20_poly1305_encrypt`: Encrypts plaintext with authentication
- `chacha20_poly1305_decrypt`: Decrypts and verifies ciphertext
- `chacha20_poly1305_keybytes`: Returns required key size
- `chacha20_poly1305_noncebytes`: Returns required nonce size
- `chacha20_poly1305_abytes`: Returns authentication tag size

These are exposed to Lean through FFI bindings in `LibSodium/ChaCha20Poly1305.lean`.

## Dependencies

- **libsodium**: The underlying cryptographic library
- **Lean 4**: Version 4.24.0-rc1 or compatible

## References

- [RFC 8439: ChaCha20 and Poly1305 for IETF Protocols](https://tools.ietf.org/html/rfc8439)
- [libsodium documentation](https://doc.libsodium.org/)
