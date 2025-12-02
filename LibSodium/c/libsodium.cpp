#include <lean/lean.h>
#include <sodium.h>
#include <string.h>

extern "C" uint32_t my_add(uint32_t a, uint32_t b) {
    return a + b;
}

extern "C" lean_obj_res my_lean_fun() {
    return lean_io_result_mk_ok(lean_box(0));
}

// ChaCha20-Poly1305 encryption
// Returns 0 on success, -1 on failure
extern "C" int chacha20_poly1305_encrypt(
    unsigned char *ciphertext,
    unsigned long long *ciphertext_len,
    const unsigned char *message,
    unsigned long long message_len,
    const unsigned char *ad,
    unsigned long long ad_len,
    const unsigned char *nonce,
    const unsigned char *key
) {
    if (sodium_init() < 0) {
        return -1;
    }
    
    return crypto_aead_chacha20poly1305_ietf_encrypt(
        ciphertext, ciphertext_len,
        message, message_len,
        ad, ad_len,
        NULL, // nsec (not used)
        nonce, key
    );
}

// ChaCha20-Poly1305 decryption
// Returns 0 on success, -1 on failure
extern "C" int chacha20_poly1305_decrypt(
    unsigned char *message,
    unsigned long long *message_len,
    const unsigned char *ciphertext,
    unsigned long long ciphertext_len,
    const unsigned char *ad,
    unsigned long long ad_len,
    const unsigned char *nonce,
    const unsigned char *key
) {
    if (sodium_init() < 0) {
        return -1;
    }
    
    return crypto_aead_chacha20poly1305_ietf_decrypt(
        message, message_len,
        NULL, // nsec (not used)
        ciphertext, ciphertext_len,
        ad, ad_len,
        nonce, key
    );
}

// Get key length
extern "C" size_t chacha20_poly1305_keybytes() {
    return crypto_aead_chacha20poly1305_ietf_KEYBYTES;
}

// Get nonce length
extern "C" size_t chacha20_poly1305_noncebytes() {
    return crypto_aead_chacha20poly1305_ietf_NPUBBYTES;
}

// Get authentication tag length
extern "C" size_t chacha20_poly1305_abytes() {
    return crypto_aead_chacha20poly1305_ietf_ABYTES;
}
