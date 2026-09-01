package com.cokistudios.csms.meta.data

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

data class ChatRoom(
    val id: String,
    val name: String,
    val isGroup: Boolean = true,
    val createdAt: String = ""
)

data class ChatMessage(
    val id: String,
    val roomId: String,
    val senderId: String,
    val senderName: String? = null,
    val content: String,
    val createdAt: String
) {
    val initials: String get() = (senderName ?: senderId).firstOrNull()?.uppercase() ?: "?"
}

data class ChatUser(
    val id: String,
    val email: String?,
    val displayName: String = email?.substringBefore("@") ?: "Usuario"
) {
    val initials: String get() = displayName.firstOrNull()?.uppercase() ?: "?"
}

class SupabaseManager private constructor(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("csms_meta_prefs", Context.MODE_PRIVATE)
    private val client = OkHttpClient()
    private val gson = Gson()

    val baseURL = "https://cmkumxprmmhuinxfppxl.supabase.co"
    val anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"

    var currentUser by mutableStateOf<ChatUser?>(null)
        private set
    var sessionToken by mutableStateOf<String?>(null)
        private set
    val isLoggedIn get() = sessionToken != null

    companion object {
        @Volatile private var INSTANCE: SupabaseManager? = null
        fun getInstance(ctx: Context): SupabaseManager =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: SupabaseManager(ctx.applicationContext).also { INSTANCE = it }
            }
    }

    init {
        sessionToken = prefs.getString("session_token", null)
        prefs.getString("user_id", null)?.let { id ->
            currentUser = ChatUser(id = id, email = prefs.getString("user_email", null))
        }
    }

    private fun saveSession(token: String?, userId: String?, email: String?) {
        sessionToken = token
        currentUser = if (userId != null) ChatUser(id = userId, email = email) else null
        prefs.edit().apply {
            if (token != null) putString("session_token", token) else remove("session_token")
            if (userId != null) putString("user_id", userId) else remove("user_id")
            if (email != null) putString("user_email", email) else remove("user_email")
            apply()
        }
    }

    fun logout() = saveSession(null, null, null)

    private fun makeRequest(
        path: String, method: String = "GET",
        body: RequestBody? = null, queryParams: Map<String, String> = emptyMap()
    ): Request {
        val urlBuilder = ("$baseURL$path").toHttpUrlOrNull()!!.newBuilder()
        queryParams.forEach { (k, v) -> urlBuilder.addQueryParameter(k, v) }
        val rb = Request.Builder()
            .url(urlBuilder.build())
            .header("apikey", anonKey)
            .header("Authorization", "Bearer ${sessionToken ?: anonKey}")
        if (body != null) {
            rb.header("Content-Type", "application/json")
               .header("Prefer", "return=representation")
               .method(method, body)
        } else {
            if (method != "GET") rb.method(method, "".toRequestBody("application/json".toMediaType()))
            else rb.method("GET", null)
        }
        return rb.build()
    }

    suspend fun login(email: String, password: String) = withContext(Dispatchers.IO) {
        val body = JSONObject().apply { put("email", email); put("password", password) }
            .toString().toRequestBody("application/json".toMediaType())
        client.newCall(makeRequest("/auth/v1/token", "POST", body, mapOf("grant_type" to "password")))
            .execute().use { response ->
                val rb = response.body?.string() ?: ""
                if (!response.isSuccessful) throw IOException(
                    try { JSONObject(rb).optString("error_description", "Login failed") }
                    catch (e: Exception) { "Login failed" }
                )
                val obj = JSONObject(rb)
                val token = obj.getString("access_token")
                val userObj = obj.getJSONObject("user")
                val userId = userObj.getString("id")
                withContext(Dispatchers.Main) { saveSession(token, userId, email) }
            }
    }

    suspend fun signUp(email: String, password: String, name: String) = withContext(Dispatchers.IO) {
        val body = JSONObject().apply {
            put("email", email); put("password", password)
            put("options", JSONObject().apply {
                put("data", JSONObject().apply { put("full_name", name); put("name", name) })
            })
        }.toString().toRequestBody("application/json".toMediaType())
        client.newCall(makeRequest("/auth/v1/signup", "POST", body)).execute().use { response ->
            if (!response.isSuccessful) throw IOException("Registration failed")
        }
        login(email, password)
    }

    suspend fun fetchRooms(): List<ChatRoom> = withContext(Dispatchers.IO) {
        client.newCall(makeRequest("/rest/v1/chat_rooms", queryParams = mapOf(
            "select" to "*", "order" to "created_at.desc"
        ))).execute().use { response ->
            val rb = response.body?.string() ?: ""
            if (!response.isSuccessful || rb.isBlank()) return@withContext emptyList()
            val arr = JSONArray(rb)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                ChatRoom(id = o.getString("id"), name = o.optString("name", "Sala"),
                    isGroup = o.optBoolean("is_group", true), createdAt = o.optString("created_at", ""))
            }
        }
    }

    suspend fun fetchMessages(roomId: String): List<ChatMessage> = withContext(Dispatchers.IO) {
        client.newCall(makeRequest("/rest/v1/chat_messages", queryParams = mapOf(
            "select" to "*", "room_id" to "eq.$roomId", "order" to "created_at.asc"
        ))).execute().use { response ->
            val rb = response.body?.string() ?: ""
            if (!response.isSuccessful || rb.isBlank()) return@withContext emptyList()
            val arr = JSONArray(rb)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                ChatMessage(id = o.getString("id"), roomId = o.getString("room_id"),
                    senderId = o.getString("sender_id"),
                    senderName = o.optString("sender_name").ifBlank { null },
                    content = o.getString("content"), createdAt = o.optString("created_at", ""))
            }
        }
    }

    suspend fun sendMessage(roomId: String, content: String): Boolean = withContext(Dispatchers.IO) {
        val user = currentUser ?: throw IOException("Inicia sesión para enviar mensajes")
        val body = JSONObject().apply {
            put("room_id", roomId); put("sender_id", user.id)
            put("sender_name", user.displayName); put("content", content)
        }.toString().toRequestBody("application/json".toMediaType())
        client.newCall(makeRequest("/rest/v1/chat_messages", "POST", body)).execute().use { it.isSuccessful }
    }
}
