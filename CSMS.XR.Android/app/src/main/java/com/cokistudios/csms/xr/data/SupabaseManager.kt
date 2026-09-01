package com.cokistudios.csms.xr.data

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException

class SupabaseManager private constructor(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("csms_xr_prefs", Context.MODE_PRIVATE)
    private val client = OkHttpClient()
    private val gson = Gson()

    val baseURL = "https://cmkumxprmmhuinxfppxl.supabase.co"
    val anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"

    var currentUser by mutableStateOf<ChatUser?>(null)
        private set
    var sessionToken by mutableStateOf<String?>(null)
        private set

    val isLoggedIn: Boolean get() = sessionToken != null

    companion object {
        @Volatile private var INSTANCE: SupabaseManager? = null
        fun getInstance(context: Context): SupabaseManager =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: SupabaseManager(context.applicationContext).also { INSTANCE = it }
            }
    }

    init {
        sessionToken = prefs.getString("session_token", null)
        prefs.getString("current_user", null)?.let { json ->
            try { currentUser = gson.fromJson(json, ChatUser::class.java) } catch (e: Exception) {
                Log.e("SupabaseManager", "Error restoring user", e)
            }
        }
    }

    private fun saveSession(token: String?, user: ChatUser?) {
        sessionToken = token
        currentUser = user
        prefs.edit().apply {
            if (token != null) putString("session_token", token) else remove("session_token")
            if (user != null) putString("current_user", gson.toJson(user)) else remove("current_user")
            apply()
        }
    }

    fun logout() = saveSession(null, null)

    private fun makeRequest(
        path: String,
        method: String = "GET",
        body: RequestBody? = null,
        queryParams: Map<String, String> = emptyMap()
    ): Request {
        val urlBuilder = ("$baseURL$path").toHttpUrlOrNull()!!.newBuilder()
        queryParams.forEach { (k, v) -> urlBuilder.addQueryParameter(k, v) }

        val rb = Request.Builder()
            .url(urlBuilder.build())
            .header("apikey", anonKey)
            .header("Authorization", "Bearer ${sessionToken ?: anonKey}")

        if (body != null) {
            rb.header("Content-Type", "application/json")
            rb.header("Prefer", "return=representation")
            rb.method(method, body)
        } else {
            if (method != "GET") rb.method(method, "".toRequestBody("application/json".toMediaType()))
            else rb.method("GET", null)
        }
        return rb.build()
    }

    // MARK: - Auth
    suspend fun login(email: String, password: String) = withContext(Dispatchers.IO) {
        val body = JSONObject().apply {
            put("email", email); put("password", password)
        }.toString().toRequestBody("application/json".toMediaType())
        val req = makeRequest("/auth/v1/token", "POST", body,
            mapOf("grant_type" to "password"))
        client.newCall(req).execute().use { response ->
            val rb = response.body?.string() ?: ""
            if (!response.isSuccessful) {
                val msg = try { JSONObject(rb).optString("error_description", "Auth failed") }
                catch (e: Exception) { "Auth failed" }
                throw IOException(msg)
            }
            val ar = gson.fromJson(rb, AuthResponse::class.java)
            withContext(Dispatchers.Main) { saveSession(ar.accessToken, ar.user) }
        }
    }

    suspend fun signUp(email: String, password: String, name: String) = withContext(Dispatchers.IO) {
        val body = JSONObject().apply {
            put("email", email); put("password", password)
            put("options", JSONObject().apply {
                put("data", JSONObject().apply {
                    put("full_name", name); put("name", name)
                })
            })
        }.toString().toRequestBody("application/json".toMediaType())
        val req = makeRequest("/auth/v1/signup", "POST", body)
        client.newCall(req).execute().use { response ->
            val rb = response.body?.string() ?: ""
            if (!response.isSuccessful) {
                val msg = try { JSONObject(rb).optString("msg", "Registration failed") }
                catch (e: Exception) { "Registration failed" }
                throw IOException(msg)
            }
        }
        login(email, password)
    }

    // MARK: - Chat Rooms
    suspend fun fetchRooms(): List<ChatRoom> = withContext(Dispatchers.IO) {
        val req = makeRequest("/rest/v1/chat_rooms", queryParams = mapOf(
            "select" to "*", "order" to "created_at.desc"
        ))
        client.newCall(req).execute().use { response ->
            val rb = response.body?.string() ?: ""
            if (!response.isSuccessful || rb.isBlank()) return@withContext emptyList()
            val type = object : TypeToken<List<ChatRoom>>() {}.type
            gson.fromJson(rb, type) ?: emptyList()
        }
    }

    suspend fun createRoom(name: String): Boolean = withContext(Dispatchers.IO) {
        val user = currentUser ?: throw IOException("Inicia sesión para crear salas")
        val body = JSONObject().apply {
            put("name", name); put("is_group", true); put("created_by", user.id)
        }.toString().toRequestBody("application/json".toMediaType())
        val req = makeRequest("/rest/v1/chat_rooms", "POST", body)
        client.newCall(req).execute().use { it.isSuccessful }
    }

    // MARK: - Messages
    suspend fun fetchMessages(roomId: String): List<ChatMessage> = withContext(Dispatchers.IO) {
        val req = makeRequest("/rest/v1/chat_messages", queryParams = mapOf(
            "select" to "*",
            "room_id" to "eq.$roomId",
            "order" to "created_at.asc"
        ))
        client.newCall(req).execute().use { response ->
            val rb = response.body?.string() ?: ""
            if (!response.isSuccessful || rb.isBlank()) return@withContext emptyList()
            val type = object : TypeToken<List<ChatMessage>>() {}.type
            gson.fromJson(rb, type) ?: emptyList()
        }
    }

    suspend fun sendMessage(roomId: String, content: String): Boolean = withContext(Dispatchers.IO) {
        val user = currentUser ?: throw IOException("Inicia sesión para enviar mensajes")
        val body = JSONObject().apply {
            put("room_id", roomId)
            put("sender_id", user.id)
            put("sender_name", user.displayName)
            put("content", content)
        }.toString().toRequestBody("application/json".toMediaType())
        val req = makeRequest("/rest/v1/chat_messages", "POST", body)
        client.newCall(req).execute().use { it.isSuccessful }
    }
}
