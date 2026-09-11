package com.cokistudios.shinemaps.data

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException
import java.util.UUID

data class CSIDUser(
    val id: String,
    val email: String,
    val name: String
) {
    val initial: String
        get() = if (name.isNotBlank()) name.take(1).uppercase() else email.take(1).uppercase()
}

class CSIDManager private constructor(context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences("csid_auth_prefs", Context.MODE_PRIVATE)
    private val httpClient = OkHttpClient()

    private val baseUrl = "https://cmkumxprmmhuinxfppxl.supabase.co"
    private val anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"

    var currentUser: CSIDUser? = null
        private set

    val isLoggedIn: Boolean
        get() = prefs.getString("csid_token", null) != null && currentUser != null

    val deviceHash: String
        get() {
            val existing = prefs.getString("csid_device_hash", null)
            if (existing != null) return existing
            val newHash = UUID.randomUUID().toString().replace("-", "")
            prefs.edit().putString("csid_device_hash", newHash).apply()
            return newHash
        }

    init {
        val savedId = prefs.getString("csid_user_id", null)
        val savedEmail = prefs.getString("csid_user_email", null)
        val savedName = prefs.getString("csid_user_name", null)
        if (!savedId.isNullOrBlank() && !savedEmail.isNullOrBlank()) {
            currentUser = CSIDUser(
                id = savedId,
                email = savedEmail,
                name = savedName ?: savedEmail.substringBefore("@")
            )
        }
    }

    suspend fun login(email: String, pass: String): Result<CSIDUser> = withContext(Dispatchers.IO) {
        try {
            val url = "$baseUrl/auth/v1/token?grant_type=password"
            val bodyJson = JSONObject().apply {
                put("email", email.trim())
                put("password", pass)
            }
            val request = Request.Builder()
                .url(url)
                .header("apikey", anonKey)
                .header("Content-Type", "application/json")
                .post(bodyJson.toString().toRequestBody("application/json".toMediaType()))
                .build()

            val response = httpClient.newCall(request).execute()
            val resStr = response.body?.string() ?: ""

            if (!response.isSuccessful) {
                val errorMsg = try {
                    val obj = JSONObject(resStr)
                    obj.optString("error_description", obj.optString("msg", "Error de autenticación"))
                } catch (e: Exception) {
                    "Error al conectar con CS ID"
                }
                return@withContext Result.failure(IOException(errorMsg))
            }

            val json = JSONObject(resStr)
            val accessToken = json.optString("access_token")
            val refreshToken = json.optString("refresh_token")
            val userObj = json.getJSONObject("user")
            val userId = userObj.optString("id")
            val userEmail = userObj.optString("email", email.trim())

            var userName = userEmail.substringBefore("@")
            val meta = userObj.optJSONObject("user_metadata")
            if (meta != null) {
                userName = meta.optString("full_name", meta.optString("name", userName))
            }

            val user = CSIDUser(userId, userEmail, userName)
            saveSession(accessToken, refreshToken, user)
            bindDeviceHash(userId, userEmail)

            Result.success(user)
        } catch (e: Exception) {
            Log.e("CSIDManager", "Login exception", e)
            Result.failure(e)
        }
    }

    suspend fun signUp(email: String, pass: String, name: String): Result<CSIDUser> = withContext(Dispatchers.IO) {
        try {
            val url = "$baseUrl/auth/v1/signup"
            val metaJson = JSONObject().apply {
                put("full_name", name.trim())
                put("name", name.trim())
                put("role", "user")
                put("company", "Coki Studios")
            }
            val bodyJson = JSONObject().apply {
                put("email", email.trim())
                put("password", pass)
                put("options", JSONObject().apply {
                    put("data", metaJson)
                    put("email_redirect_to", "https://cokistudios.github.io/coki-confirm.html")
                })
            }

            val request = Request.Builder()
                .url(url)
                .header("apikey", anonKey)
                .header("Content-Type", "application/json")
                .post(bodyJson.toString().toRequestBody("application/json".toMediaType()))
                .build()

            val response = httpClient.newCall(request).execute()
            val resStr = response.body?.string() ?: ""

            if (!response.isSuccessful) {
                val errorMsg = try {
                    val obj = JSONObject(resStr)
                    obj.optString("msg", obj.optString("message", "Error al crear cuenta CS ID"))
                } catch (e: Exception) {
                    "Error al crear cuenta CS ID"
                }
                return@withContext Result.failure(IOException(errorMsg))
            }

            // Auto-login after sign-up
            login(email, pass)
        } catch (e: Exception) {
            Log.e("CSIDManager", "SignUp exception", e)
            Result.failure(e)
        }
    }

    private fun saveSession(token: String, refresh: String, user: CSIDUser) {
        currentUser = user
        prefs.edit()
            .putString("csid_token", token)
            .putString("csid_refresh_token", refresh)
            .putString("csid_user_id", user.id)
            .putString("csid_user_email", user.email)
            .putString("csid_user_name", user.name)
            .apply()
    }

    fun logout() {
        currentUser = null
        prefs.edit()
            .remove("csid_token")
            .remove("csid_refresh_token")
            .remove("csid_user_id")
            .remove("csid_user_email")
            .remove("csid_user_name")
            .apply()
    }

    private fun bindDeviceHash(userId: String, email: String) {
        try {
            val url = "$baseUrl/rest/v1/user_device_hashes"
            val bodyJson = JSONObject().apply {
                put("device_hash", deviceHash)
                put("user_id", userId.lowercase())
                put("user_email", email)
            }
            val request = Request.Builder()
                .url(url)
                .header("apikey", anonKey)
                .header("Authorization", "Bearer $anonKey")
                .header("Content-Type", "application/json")
                .header("Prefer", "resolution=merge-duplicates")
                .post(bodyJson.toString().toRequestBody("application/json".toMediaType()))
                .build()
            httpClient.newCall(request).execute().close()
        } catch (e: Exception) {
            Log.w("CSIDManager", "bindDeviceHash failed: ${e.message}")
        }
    }

    companion object {
        @Volatile
        private var INSTANCE: CSIDManager? = null

        fun getInstance(context: Context): CSIDManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: CSIDManager(context.applicationContext).also { INSTANCE = it }
            }
        }
    }
}
