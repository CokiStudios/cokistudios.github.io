package com.cokistudios.csms.data

import android.content.Context
import com.google.gson.Gson
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

data class ChatRoomItem(
    val id: String,
    val name: String,
    val isGroup: Boolean = true,
    val createdAt: String = ""
)

data class ChatMessageItem(
    val id: String,
    val roomId: String,
    val senderId: String,
    val content: String,
    val createdAt: String
)

class SupabaseManager(context: Context) {
    private val client = OkHttpClient()
    private val gson = Gson()

    val baseURL = "https://cmkumxprmmhuinxfppxl.supabase.co"
    val anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"

    private fun makeRequest(
        path: String,
        method: String = "GET",
        body: RequestBody? = null,
        queryParams: Map<String, String> = emptyMap()
    ): Request {
        val urlBuilder = ("$baseURL$path").toHttpUrlOrNull()!!.newBuilder()
        queryParams.forEach { (name, value) ->
            urlBuilder.addQueryParameter(name, value)
        }

        val requestBuilder = Request.Builder()
            .url(urlBuilder.build())
            .header("apikey", anonKey)
            .header("Authorization", "Bearer $anonKey")

        if (body != null) {
            requestBuilder.header("Content-Type", "application/json")
            requestBuilder.header("Prefer", "return=representation")
            requestBuilder.method(method, body)
        } else {
            if (method != "GET") {
                val emptyBody = "".toRequestBody("application/json".toMediaType())
                requestBuilder.method(method, emptyBody)
            } else {
                requestBuilder.method("GET", null)
            }
        }

        return requestBuilder.build()
    }

    fun getValidUserUUID(): String {
        return "00000000-0000-4000-8000-" + android.os.Build.MODEL.filter { it.isLetterOrDigit() }.padEnd(12, '0').take(12).lowercase()
    }

    fun ensureValidRoomUUID(roomId: String): String {
        return when (roomId) {
            "csms-global" -> CSMS_COMMUNITY_GLOBAL_ID
            "csms-eco" -> CSMS_ECO_HUB_ID
            else -> {
                if (roomId.matches(Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"))) {
                    roomId.lowercase()
                } else {
                    CSMS_COMMUNITY_GLOBAL_ID
                }
            }
        }
    }

    suspend fun fetchChatRooms(): List<ChatRoomItem> = withContext(Dispatchers.IO) {
        val path = "/rest/v1/chat_rooms"
        val queryParams = mapOf("select" to "*", "order" to "created_at.desc")
        val request = makeRequest(path, queryParams = queryParams)
        val list = mutableListOf<ChatRoomItem>()
        val seenIds = mutableSetOf<String>()

        try {
            client.newCall(request).execute().use { response ->
                val body = response.body?.string() ?: ""
                if (response.isSuccessful && body.isNotBlank()) {
                    val array = JSONArray(body)
                    for (i in 0 until array.length()) {
                        val obj = array.getJSONObject(i)
                        val id = obj.optString("id")
                        list.add(
                            ChatRoomItem(
                                id = id,
                                name = obj.optString("name", "Chat de Grupo"),
                                isGroup = obj.optBoolean("is_group", true),
                                createdAt = obj.optString("created_at", "")
                            )
                        )
                        seenIds.add(id.lowercase())
                    }
                }
            }
        } catch (e: Exception) {}

        if (!seenIds.contains(CSMS_COMMUNITY_GLOBAL_ID.lowercase())) {
            list.add(0, ChatRoomItem(CSMS_COMMUNITY_GLOBAL_ID, "💬 Comunidad Coki Studios Global", true, ""))
        }
        if (!seenIds.contains(CSMS_ECO_HUB_ID.lowercase())) {
            list.add(1, ChatRoomItem(CSMS_ECO_HUB_ID, "🌿 Eco Hub Cota & Cundinamarca", true, ""))
        }
        list
    }

    suspend fun createGroupChat(name: String): Boolean = withContext(Dispatchers.IO) {
        val path = "/rest/v1/chat_rooms"
        val bodyJson = JSONObject().apply {
            put("name", name)
            put("is_group", true)
            put("created_by", getValidUserUUID())
        }
        val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
        val request = makeRequest(path, "POST", body)
        try {
            client.newCall(request).execute().use { response ->
                response.isSuccessful
            }
        } catch (e: Exception) {
            false
        }
    }

    suspend fun fetchChatMessages(rawRoomId: String): List<ChatMessageItem> = withContext(Dispatchers.IO) {
        val roomId = ensureValidRoomUUID(rawRoomId)
        val path = "/rest/v1/chat_messages"
        val queryParams = mapOf(
            "select" to "*",
            "room_id" to "eq.$roomId",
            "order" to "created_at.asc"
        )
        val request = makeRequest(path, queryParams = queryParams)
        try {
            client.newCall(request).execute().use { response ->
                val body = response.body?.string() ?: ""
                if (!response.isSuccessful || body.isBlank()) return@withContext emptyList()
                val array = JSONArray(body)
                val list = mutableListOf<ChatMessageItem>()
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    list.add(
                        ChatMessageItem(
                            id = obj.optString("id"),
                            roomId = obj.optString("room_id"),
                            senderId = if (obj.has("user_id")) obj.optString("user_id") else obj.optString("sender_id"),
                            content = obj.optString("content"),
                            createdAt = obj.optString("created_at")
                        )
                    )
                }
                list
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun sendChatMessage(rawRoomId: String, content: String): Boolean = withContext(Dispatchers.IO) {
        val roomId = ensureValidRoomUUID(rawRoomId)
        val path = "/rest/v1/chat_messages"
        val bodyJson = JSONObject().apply {
            put("room_id", roomId)
            put("user_id", getValidUserUUID())
            put("author_name", "Android CSMS")
            put("content", content)
        }
        val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
        val request = makeRequest(path, "POST", body)
        try {
            client.newCall(request).execute().use { response ->
                response.isSuccessful
            }
        } catch (e: Exception) {
            false
        }
    }

    companion object {
        const val CSMS_COMMUNITY_GLOBAL_ID = "00000000-0000-4000-8000-000000000001"
        const val CSMS_ECO_HUB_ID = "00000000-0000-4000-8000-000000000002"

        @Volatile
        private var instance: SupabaseManager? = null

        fun getInstance(context: Context): SupabaseManager {
            return instance ?: synchronized(this) {
                instance ?: SupabaseManager(context.applicationContext).also { instance = it }
            }
        }
    }
}
