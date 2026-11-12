package com.cokistudios.forkar.services

import android.content.Context
import android.location.Location
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Log
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Forkar Services (FMS / Forkar Mobile Services)
 * The foundational open system services layer for Shine OS & Android.
 * Operates like GMS (Google Mobile Services), but privacy-first, zero bloat,
 * backed by hardware cryptography, and built for Coki Studios devices.
 */
object ForkarServices {
    private const val TAG = "ForkarServices"
    const val VERSION = "FMS 3.0 (Shine Core)"

    private var appContext: Context? = null
    var isInitialized = false
        private set

    fun initialize(context: Context) {
        if (isInitialized) return
        appContext = context.applicationContext
        isInitialized = true
        Log.i(TAG, "Initialized $VERSION on ${Build.MANUFACTURER} ${Build.MODEL} (${Build.VERSION.RELEASE})")
        
        // Auto-discover external .c2 modules
        val extDir = C2ModuleLoader.getExternalModulesDir()
        extDir.listFiles { f -> f.name.endsWith(".c2") }?.forEach { f ->
            C2ModuleLoader.installC2Package(context, f)
        }
    }

    // ── 1. AUTH & CS ID HARDWARE ATTESTATION ──
    object Auth {
        private const val KEYSTORE_ALIAS = "CSMS_E2EE_COKI_STUDIOS_v1_SALT_FORKAR"
        
        fun hasHardwareKeyStore(): Boolean {
            return try {
                val ks = KeyStore.getInstance("AndroidKeyStore")
                ks.load(null)
                true
            } catch (e: Exception) {
                false
            }
        }

        fun generateOrGetHardwareKey(): SecretKey {
            val ks = KeyStore.getInstance("AndroidKeyStore")
            ks.load(null)
            if (ks.containsAlias(KEYSTORE_ALIAS)) {
                return (ks.getEntry(KEYSTORE_ALIAS, null) as KeyStore.SecretKeyEntry).secretKey
            }

            val kgen = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
            val specBuilder = KeyGenParameterSpec.Builder(
                KEYSTORE_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                try {
                    specBuilder.setIsStrongBoxBacked(true)
                } catch (e: Exception) {
                    // Fallback to TEE if StrongBox not available
                }
            }
            kgen.init(specBuilder.build())
            return kgen.generateKey()
        }
    }

    // ── 2. E2EE MESSAGING SERVICE (CSMS CORE) ──
    object Messaging {
        fun encryptMessage(plainText: String): String {
            val key = Auth.generateOrGetHardwareKey()
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, key)
            val iv = cipher.iv
            val cipherText = cipher.doFinal(plainText.toByteArray(Charsets.UTF_8))
            val b64Iv = android.util.Base64.encodeToString(iv, android.util.Base64.NO_WRAP)
            val b64Cipher = android.util.Base64.encodeToString(cipherText, android.util.Base64.NO_WRAP)
            return "🔒 enc:v1:$b64Iv:$b64Cipher"
        }

        fun decryptMessage(payload: String): String {
            if (!payload.startsWith("🔒 enc:v1:")) return payload
            val parts = payload.removePrefix("🔒 enc:v1:").split(":")
            if (parts.size != 2) return payload
            val iv = android.util.Base64.decode(parts[0], android.util.Base64.NO_WRAP)
            val cipherText = android.util.Base64.decode(parts[1], android.util.Base64.NO_WRAP)
            val key = Auth.generateOrGetHardwareKey()
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, iv))
            return String(cipher.doFinal(cipherText), Charsets.UTF_8)
        }
    }

    // ── 3. LOCATION & SHINE MAPS NAVIGATION PROVIDER ──
    object LocationService {
        var lastKnownLatitude: Double = 4.7110
        var lastKnownLongitude: Double = -74.0721
        var isNavigating: Boolean = false
        var activeDestinationName: String = ""

        fun updateLocation(lat: Double, lon: Double) {
            lastKnownLatitude = lat
            lastKnownLongitude = lon
        }
    }

    // ── 4. ECO TELEMETRY PROVIDER ──
    object EcoTelemetry {
        var co2SavedKg: Double = 14.8
        var ecoScore: Int = 94
        var regenerativePowerKw: Double = 32.5

        fun recordTrip(km: Double, speedAvgKmh: Double): Double {
            val saved = km * 0.12 // kg CO2 saved per km in EV/Eco mode
            co2SavedKg += saved
            return co2SavedKg
        }
    }

    // ── 5. COMPONENT 2 (.c2) PACKAGE MANAGER ──
    object PackageManager {
        fun getInstalledC2Modules(): List<C2Module> {
            val ctx = appContext ?: return emptyList()
            return C2ModuleLoader.listInstalledModules(ctx)
        }

        fun getActiveModule(): C2Module? = C2ModuleLoader.activeModule
    }
}
