/-
Copyright (c) 2024. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: VCV-io Contributors

Pure implementation of ChaCha20 stream cipher following RFC 8439.
This implementation uses BitVec 32 and ByteArray for deterministic computation.
It is designed to pass KATs (Known Answer Tests) and lift cleanly into VCV-io.
-/

namespace ChaCha20

/-- The ChaCha20 state is a 4x4 matrix of 32-bit words, represented as a flat vector.
Layout:
  [0] [1] [2] [3]    - Constants
  [4] [5] [6] [7]    - Key (first 128 bits)
  [8] [9] [10][11]   - Key (second 128 bits)
  [12][13][14][15]   - Counter + Nonce
-/
abbrev State := Vector (BitVec 32) 16

/-- The ChaCha20 constant "expand 32-byte k" in little-endian encoding -/
def constants : Vector (BitVec 32) 4 :=
  #v[0x61707865, 0x3320646e, 0x79622d32, 0x6b206574]

/-- The Quarter Round: Pure bit manipulation on four 32-bit words.
This is the core mixing function of ChaCha20. -/
def quarterRound (a b c d : BitVec 32) : (BitVec 32 × BitVec 32 × BitVec 32 × BitVec 32) :=
  let a := a + b; let d := (d ^^^ a).rotateLeft 16
  let c := c + d; let b := (b ^^^ c).rotateLeft 12
  let a := a + b; let d := (d ^^^ a).rotateLeft 8
  let c := c + d; let b := (b ^^^ c).rotateLeft 7
  (a, b, c, d)

/-- Apply quarter round at specific indices in the state -/
def applyQuarterRound (state : State) (i j k l : Fin 16) : State :=
  let (a', b', c', d') := quarterRound state[i] state[j] state[k] state[l]
  state.set i a' |>.set j b' |>.set k c' |>.set l d'

/-- Column round: Apply quarter rounds to columns -/
def columnRound (state : State) : State :=
  state
  |> fun s => applyQuarterRound s 0 4 8  12
  |> fun s => applyQuarterRound s 1 5 9  13
  |> fun s => applyQuarterRound s 2 6 10 14
  |> fun s => applyQuarterRound s 3 7 11 15

/-- Diagonal round: Apply quarter rounds to diagonals -/
def diagonalRound (state : State) : State :=
  state
  |> fun s => applyQuarterRound s 0 5 10 15
  |> fun s => applyQuarterRound s 1 6 11 12
  |> fun s => applyQuarterRound s 2 7 8  13
  |> fun s => applyQuarterRound s 3 4 9  14

/-- Double round: One column round followed by one diagonal round -/
def doubleRound (state : State) : State :=
  diagonalRound (columnRound state)

/-- Apply n double rounds to the state -/
def applyDoubleRounds (state : State) (n : Nat) : State :=
  match n with
  | 0 => state
  | n + 1 => applyDoubleRounds (doubleRound state) n

/-- Convert a 256-bit key to 8 32-bit words (little-endian) -/
def keyToWords (key : BitVec 256) : Vector (BitVec 32) 8 :=
  #v[key.extractLsb' 0 32,   key.extractLsb' 32 32,
     key.extractLsb' 64 32,  key.extractLsb' 96 32,
     key.extractLsb' 128 32, key.extractLsb' 160 32,
     key.extractLsb' 192 32, key.extractLsb' 224 32]

/-- Convert a 96-bit nonce to 3 32-bit words (little-endian) -/
def nonceToWords (nonce : BitVec 96) : Vector (BitVec 32) 3 :=
  #v[nonce.extractLsb' 0 32, nonce.extractLsb' 32 32, nonce.extractLsb' 64 32]

/-- Initialize the ChaCha20 state from key, nonce, and counter -/
def initState (key : BitVec 256) (nonce : BitVec 96) (counter : BitVec 32) : State :=
  let keyWords := keyToWords key
  let nonceWords := nonceToWords nonce
  #v[constants[0], constants[1], constants[2], constants[3],
     keyWords[0],  keyWords[1],  keyWords[2],  keyWords[3],
     keyWords[4],  keyWords[5],  keyWords[6],  keyWords[7],
     counter,      nonceWords[0], nonceWords[1], nonceWords[2]]

/-- Add two states element-wise -/
def addStates (a b : State) : State :=
  #v[a[0] + b[0],   a[1] + b[1],   a[2] + b[2],   a[3] + b[3],
     a[4] + b[4],   a[5] + b[5],   a[6] + b[6],   a[7] + b[7],
     a[8] + b[8],   a[9] + b[9],   a[10] + b[10], a[11] + b[11],
     a[12] + b[12], a[13] + b[13], a[14] + b[14], a[15] + b[15]]

/-- Serialize a 32-bit word to bytes in little-endian order -/
def word32ToBytes (w : BitVec 32) : ByteArray :=
  ByteArray.mk #[w.extractLsb' 0 8  |>.toNat.toUInt8,
                 w.extractLsb' 8 8  |>.toNat.toUInt8,
                 w.extractLsb' 16 8 |>.toNat.toUInt8,
                 w.extractLsb' 24 8 |>.toNat.toUInt8]

/-- Serialize the state to a 64-byte keystream block (little-endian) -/
def stateToBytes (state : State) : ByteArray :=
  let mut result := ByteArray.empty
  for i in [0:16] do
    result := result ++ word32ToBytes state[i]!
  result

/-- The ChaCha20 block function: Maps Key/Nonce/Counter to a 64-byte keystream.
Applies 20 rounds (10 double rounds), then adds the initial state. -/
def block (key : BitVec 256) (nonce : BitVec 96) (counter : BitVec 32) : ByteArray :=
  let initial := initState key nonce counter
  let final := applyDoubleRounds initial 10  -- 10 double rounds = 20 rounds
  let result := addStates final initial
  stateToBytes result

/-- XOR two byte arrays of equal length.
If arrays have different sizes, result is truncated to the shorter length.
This is intentional for XOR-ing plaintext chunks with keystream. -/
def xorBytes (a b : ByteArray) : ByteArray :=
  ByteArray.mk (Array.zipWith a.data b.data fun x y => x ^^^ y)

/-- ChaCha20 encryption/decryption (same operation due to XOR).
Encrypts plaintext using key, nonce, starting from given counter.
Note: counter + numBlocks should not exceed 2^32 for proper operation. -/
def encrypt (key : BitVec 256) (nonce : BitVec 96) (counter : Nat) (plaintext : ByteArray) :
    ByteArray :=
  let blockSize : Nat := 64
  let numBlocks := (plaintext.size + blockSize - 1) / blockSize
  let mut result := ByteArray.empty
  for i in [0:numBlocks] do
    -- Counter wraps at 2^32 per RFC 8439
    let blockCounter : BitVec 32 := BitVec.ofNat 32 (counter + i)
    let keystream := block key nonce blockCounter
    let start := i * blockSize
    let endPos := min ((i + 1) * blockSize) plaintext.size
    let chunk := plaintext.extract start endPos
    let encryptedChunk := xorBytes chunk (keystream.extract 0 chunk.size)
    result := result ++ encryptedChunk
  result

/-- Decrypt is the same as encrypt for ChaCha20 -/
def decrypt := encrypt

end ChaCha20
