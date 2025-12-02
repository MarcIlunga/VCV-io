/-
ChaCha20-Poly1305 AEAD (Authenticated Encryption with Associated Data) bindings.

This module provides bindings to the libsodium implementation of ChaCha20-Poly1305,
a modern authenticated encryption algorithm combining the ChaCha20 stream cipher
with the Poly1305 MAC.
-/

namespace ChaCha20Poly1305

-- Constants for key, nonce, and authentication tag sizes
@[extern "chacha20_poly1305_keybytes"]
opaque keyBytes : USize

@[extern "chacha20_poly1305_noncebytes"]
opaque nonceBytes : USize

@[extern "chacha20_poly1305_abytes"]
opaque aBytes : USize

/-- 
Encrypt a message using ChaCha20-Poly1305 AEAD.

Parameters:
- message: The plaintext to encrypt
- ad: Additional authenticated data (may be empty)
- nonce: The nonce (must be unique for each encryption with the same key)
- key: The secret key

Returns the ciphertext (including authentication tag) on success.
-/
def encrypt (message : ByteArray) (ad : ByteArray) (nonce : ByteArray) (key : ByteArray) : IO (Option ByteArray) := do
  -- Validate input sizes
  if key.size != keyBytes.toNat then
    IO.eprintln s!"Error: Key must be {keyBytes} bytes"
    return none
  if nonce.size != nonceBytes.toNat then
    IO.eprintln s!"Error: Nonce must be {nonceBytes} bytes"
    return none
  
  -- Allocate buffer for ciphertext (message + auth tag)
  let ciphertext_max_len := message.size + aBytes.toNat
  let mut ciphertext := ByteArray.mkEmpty ciphertext_max_len
  
  -- Note: Actual FFI call would be made here
  -- For now, this is a placeholder that should be connected to the C++ implementation
  IO.eprintln "ChaCha20-Poly1305 encrypt called"
  return some ciphertext

/-- 
Decrypt a ciphertext using ChaCha20-Poly1305 AEAD.

Parameters:
- ciphertext: The ciphertext to decrypt (including authentication tag)
- ad: Additional authenticated data (must match what was used during encryption)
- nonce: The nonce (must match what was used during encryption)
- key: The secret key

Returns the plaintext on success, or none if authentication fails.
-/
def decrypt (ciphertext : ByteArray) (ad : ByteArray) (nonce : ByteArray) (key : ByteArray) : IO (Option ByteArray) := do
  -- Validate input sizes
  if key.size != keyBytes.toNat then
    IO.eprintln s!"Error: Key must be {keyBytes} bytes"
    return none
  if nonce.size != nonceBytes.toNat then
    IO.eprintln s!"Error: Nonce must be {nonceBytes} bytes"
    return none
  if ciphertext.size < aBytes.toNat then
    IO.eprintln s!"Error: Ciphertext too short"
    return none
  
  -- Allocate buffer for plaintext
  let message_max_len := ciphertext.size - aBytes.toNat
  let mut message := ByteArray.mkEmpty message_max_len
  
  -- Note: Actual FFI call would be made here
  -- For now, this is a placeholder that should be connected to the C++ implementation
  IO.eprintln "ChaCha20-Poly1305 decrypt called"
  return some message

end ChaCha20Poly1305
