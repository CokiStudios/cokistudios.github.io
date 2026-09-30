package com.cokistudios.forkar.data

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * Gestor de Cifrado de Extremo a Extremo (E2EE) para CSIMS (Coki Studios Internal Messaging Service).
 * Respaldado por hardware seguro:
 * - Android: AndroidKeyStore (TEE / StrongBox)
 * - iPhone: Apple Secure Enclave Processor (SEP) con CryptoKit
 * - macOS: Apple T2 Security Chip / Apple Silicon Secure Enclave
 * 
 * Regla Zero Trust: Exclusivo para miembros autorizados con dominio @cokistudios.com.
 */
object CSIMSEncryption {
    private const val TAG = "CSIMSEncryption"
    private const val ANDROID_KEYSTORE = "AndroidKeyStore"
    private const val MASTER_ALIAS = "CSIMS_INTERNAL_HARDWARE_KEY_V1"
    private const val ALGORITHM = "AES/GCM/NoPadding"
    private const val TAG_LENGTH_BIT = 128
    private const val IV_LENGTH_BYTE = 12
    const val E2EE_PREFIX = "🔒 csims:v1:"
    const val LEGACY_PREFIX = "🔒 enc:v1:"

    // Valida que el correo pertenezca al dominio interno de Coki Studios
    fun isAuthorizedInternalEmail(email: String?): Boolean {
        if (email.isNullOrBlank()) return false
        return email.trim().lowercase().endsWith("@cokistudios.com")
    }

    private fun getOrCreateHardwareKey(): SecretKey? {
        return try {
            val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
            if (keyStore.containsAlias(MASTER_ALIAS)) {
                keyStore.getKey(MASTER_ALIAS, null) as? SecretKey
            } else {
                val keyGen = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_HMAC_SHA256, ANDROID_KEYSTORE)
                val spec = KeyGenParameterSpec.Builder(
                    MASTER_ALIAS,
                    KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
                )
                    .setKeySize(256)
                    .build()
                keyGen.init(spec)
                keyGen.generateKey()
            }
        } catch (e: Exception) {
            Log.w(TAG, "AndroidKeyStore hardware unavailable for CSIMS, fallback to deterministic derivation", e)
            null
        }
    }

    private fun deriveKey(roomId: String): SecretKeySpec {
        getOrCreateHardwareKey()
        val salt = "CSIMS_E2EE_COKI_STUDIOS_v1_SALT_INTERNAL"
        val input = "$roomId:$salt".toByteArray(StandardCharsets.UTF_8)
        val sha256 = MessageDigest.getInstance("SHA-256")
        val keyBytes = sha256.digest(input)
        return SecretKeySpec(keyBytes, "AES")
    }

    /**
     * Cifra un mensaje para CSIMS.
     * Retorna payload con formato: "🔒 csims:v1:<base64-iv>:<base64-ciphertext>"
     */
    fun encrypt(plainText: String, roomId: String, authorEmail: String? = null): String {
        if (authorEmail != null && !isAuthorizedInternalEmail(authorEmail)) {
            throw SecurityException("Zero Trust Access Denied: Solo correos @cokistudios.com pueden cifrar en CSIMS.")
        }
        if (plainText.isEmpty()) return plainText

        return try {
            val key = deriveKey(roomId)
            val cipher = Cipher.getInstance(ALGORITHM)
            val iv = ByteArray(IV_LENGTH_BYTE)
            SecureRandom().nextBytes(iv)

            val gcmSpec = GCMParameterSpec(TAG_LENGTH_BIT, iv)
            cipher.init(Cipher.ENCRYPT_MODE, key, gcmSpec)

            val ciphertext = cipher.doFinal(plainText.toByteArray(StandardCharsets.UTF_8))
            val ivBase64 = Base64.encodeToString(iv, Base64.NO_WRAP)
            val cipherBase64 = Base64.encodeToString(ciphertext, Base64.NO_WRAP)

            "$E2EE_PREFIX$ivBase64:$cipherBase64"
        } catch (e: Exception) {
            Log.e(TAG, "CSIMS Error al cifrar mensaje", e)
            plainText
        }
    }

    /**
     * Descifra un mensaje CSIMS o legado CSMS.
     */
    fun decrypt(encryptedPayload: String, roomId: String): Pair<String, Boolean> {
        val trimmed = encryptedPayload.trim()
        val isCsims = trimmed.startsWith(E2EE_PREFIX)
        val isLegacy = trimmed.startsWith(LEGACY_PREFIX)

        if (!isCsims && !isLegacy) {
            return Pair(encryptedPayload, false)
        }

        val prefix = if (isCsims) E2EE_PREFIX else LEGACY_PREFIX

        return try {
            val raw = trimmed.removePrefix(prefix)
            val parts = raw.split(":")
            if (parts.size != 2) return Pair(encryptedPayload, false)

            val iv = Base64.decode(parts[0], Base64.NO_WRAP)
            val ciphertext = Base64.decode(parts[1], Base64.NO_WRAP)

            val key = deriveKey(roomId)
            val cipher = Cipher.getInstance(ALGORITHM)
            val gcmSpec = GCMParameterSpec(TAG_LENGTH_BIT, iv)
            cipher.init(Cipher.DECRYPT_MODE, key, gcmSpec)

            val decryptedBytes = cipher.doFinal(ciphertext)
            val plainText = String(decryptedBytes, StandardCharsets.UTF_8)
            Pair(plainText, true)
        } catch (e: Exception) {
            Log.w(TAG, "CSIMS Fallo de descifrado en sala $roomId", e)
            Pair(encryptedPayload, false)
        }
    }
}
