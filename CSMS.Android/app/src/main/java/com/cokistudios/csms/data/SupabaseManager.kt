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

    suspend fun fetchChatRooms(): List<ChatRoomItem> = withContext(Dispatchers.IO) {
        val path = "/rest/v1/chat_rooms"
        val queryParams = mapOf("select" to "*", "order" to "created_at.desc")
        val request = makeRequest(path, queryParams = queryParams)
        client.newCall(request).execute().use { response ->
            val body = response.body?.string() ?: ""
            if (!response.isSuccessful || body.isBlank()) return@withContext emptyList()
            val array = JSONArray(body)
            val list = mutableListOf<ChatRoomItem>()
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                list.add(
                    ChatRoomItem(
                        id = obj.optString("id"),
                        name = obj.optString("name", "Chat de Grupo"),
                        isGroup = obj.optBoolean("is_group", true),
                        createdAt = obj.optString("created_at", "")
                    )
                )
            }
            list
        }
    }

    suspend fun createGroupChat(name: String): Boolean = withContext(Dispatchers.IO) {
        val path = "/rest/v1/chat_rooms"
        val bodyJson = JSONObject().apply {
            put("name", name)
            put("is_group", true)
        }
        val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
        val request = makeRequest(path, "POST", body)
        client.newCall(request).execute().use { response ->
            response.isSuccessful
        }
    }

    suspend fun fetchChatMessages(roomId: String): List<ChatMessageItem> = withContext(Dispatchers.IO) {
        val path = "/rest/v1/chat_messages"
        val queryParams = mapOf(
            "select" to "*",
            "room_id" to "eq.$roomId",
            "order" to "created_at.asc"
        )
        val request = makeRequest(path, queryParams = queryParams)
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
                        senderId = obj.optString("sender_id"),
                        content = obj.optString("content"),
                        createdAt = obj.optString("created_at")
                    )
                )
            }
            list
        }
    }

    suspend fun sendChatMessage(roomId: String, content: String): Boolean = withContext(Dispatchers.IO) {
        val path = "/rest/v1/chat_messages"
        val bodyJson = JSONObject().apply {
            put("room_id", roomId)
            put("sender_id", "my-user")
            put("content", content)
        }
        val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
        val request = makeRequest(path, "POST", body)
        client.newCall(request).execute().use { response ->
            response.isSuccessful
        }
    }

    companion object {
        @Volatile
        private var instance: SupabaseManager? = null

        fun getInstance(context: Context): SupabaseManager {
            return instance ?: synchronized(this) {
                instance ?: SupabaseManager(context.applicationContext).also { instance = it }
            }
        }
    }
}
