package com.cokistudios.forkar.data

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
import okhttp3.Response
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException

class SupabaseManager private constructor(context: Context) {

    private val sharedPrefs: SharedPreferences = context.getSharedPreferences("supabase_prefs", Context.MODE_PRIVATE)
    private val client = OkHttpClient()
    private val gson = Gson()

    val baseURL = "https://cmkumxprmmhuinxfppxl.supabase.co"
    val anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"

    var currentUser by mutableStateOf<SupabaseUser?>(null)
        private set

    var sessionToken by mutableStateOf<String?>(null)
        private set

    val isLoggedIn: Boolean
        get() = sessionToken != null

    init {
        sessionToken = sharedPrefs.getString("supabase_session_token", null)
        val userJson = sharedPrefs.getString("supabase_current_user", null)
        if (userJson != null) {
            try {
                currentUser = gson.fromJson(userJson, SupabaseUser::class.java)
            } catch (e: Exception) {
                Log.e("SupabaseManager", "Error decoding stored user", e)
            }
        }
    }

    private fun saveSession(token: String?, user: SupabaseUser?) {
        sessionToken = token
        currentUser = user
        sharedPrefs.edit().apply {
            if (token != null) {
                putString("supabase_session_token", token)
            } else {
                remove("supabase_session_token")
            }
            if (user != null) {
                putString("supabase_current_user", gson.toJson(user))
            } else {
                remove("supabase_current_user")
            }
            apply()
        }
    }

    fun logout() {
        saveSession(null, null)
    }

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

        val token = sessionToken
        if (token != null) {
            requestBuilder.header("Authorization", "Bearer $token")
        } else {
            requestBuilder.header("Authorization", "Bearer $anonKey")
        }

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

    private fun verifyResponse(response: Response, responseBody: String) {
        if (!response.isSuccessful) {
            var message = "Request failed with code ${response.code}"
            try {
                val errorObj = JSONObject(responseBody)
                message = errorObj.optString("message", errorObj.optString("msg", errorObj.optString("error_description", message)))
            } catch (e: Exception) {
                // Ignore parsing errors
            }
            if (response.code == 401 || message.lowercase().contains("jwt")) {
                logout()
            }
            throw IOException(message)
        }
    }

    // MARK: - Authentication API
    suspend fun login(email: String, password: String) = withContext(Dispatchers.IO) {
        val path = "/auth/v1/token"
        val queryParams = mapOf("grant_type" to "password")
        val json = JSONObject().apply {
            put("email", email)
            put("password", password)
        }
        val body = json.toString().toRequestBody("application/json".toMediaType())
        val request = makeRequest(path, "POST", body, queryParams)

        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: ""
            if (!response.isSuccessful) {
                var message = "Authentication failed"
                try {
                    val errorObj = JSONObject(responseBody)
                    message = errorObj.optString("error_description", errorObj.optString("error", message))
                } catch (e: Exception) {
                    // Ignore
                }
                throw IOException(message)
            }

            val authResponse = gson.fromJson(responseBody, SupabaseAuthResponse::class.java)
            withContext(Dispatchers.Main) {
                saveSession(authResponse.accessToken, authResponse.user)
            }
        }
    }

    suspend fun signUp(email: String, password: String, name: String, company: String? = null) = withContext(Dispatchers.IO) {
        val path = "/auth/v1/signup"

        val metadataJson = JSONObject().apply {
            put("full_name", name)
            put("name", name)
            put("role", "user")
            put("company", if (company.isNullOrBlank()) "Coki Studios" else company)
        }

        val bodyJson = JSONObject().apply {
            put("email", email)
            put("password", password)
            put("options", JSONObject().apply {
                put("data", metadataJson)
                put("email_redirect_to", "https://cokistudios.github.io/coki-confirm.html")
            })
        }

        val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
        val request = makeRequest(path, "POST", body)

        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: ""
            if (!response.isSuccessful) {
                var message = "Registration failed"
                try {
                    val errorObj = JSONObject(responseBody)
                    message = errorObj.optString("msg", errorObj.optString("message", message))
                } catch (e: Exception) {
                    // Ignore
                }
                throw IOException(message)
            }
        }

        // Auto login on successful signup
        login(email, password)
    }

    // MARK: - Categories API
    suspend fun fetchCategories(): List<Category> = withContext(Dispatchers.IO) {
        val path = "/rest/v1/social_categories"
        val queryParams = mapOf(
            "select" to "*",
            "order" to "name.asc"
        )
        val request = makeRequest(path, "GET", queryParams = queryParams)
        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: ""
            verifyResponse(response, responseBody)
            val type = object : TypeToken<List<Category>>() {}.type
            gson.fromJson(responseBody, type)
        }
    }

    // MARK: - Posts API
    suspend fun fetchPosts(categoryId: String? = null, query: String? = null, userId: String? = null): List<Post> = withContext(Dispatchers.IO) {
        val path = "/rest/v1/social_posts"
        val queryParams = mutableMapOf(
            "select" to "*,category:social_categories(id,name,slug,color)",
            "order" to "created_at.desc"
        )

        if (categoryId != null) {
            queryParams["category_id"] = "eq.$categoryId"
        }
        if (userId != null) {
            queryParams["user_id"] = "eq.$userId"
        }
        if (!query.isNullOrBlank()) {
            queryParams["or"] = "(title.ilike.*$query*,content.ilike.*$query*)"
        }

        val request = makeRequest(path, "GET", queryParams = queryParams)
        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: ""
            verifyResponse(response, responseBody)
            val type = object : TypeToken<List<Post>>() {}.type
            gson.fromJson(responseBody, type)
        }
    }

    suspend fun createPost(title: String, content: String, categoryId: String): Post = withContext(Dispatchers.IO) {
        val user = currentUser ?: throw IOException("Inicia sesión para publicar")
        val path = "/rest/v1/social_posts"

        val metadata = user.userMetadata
        val authorName = metadata?.displayName ?: user.email?.substringBefore("@") ?: "Usuario"
        val authorAvatar = metadata?.avatarUrl ?: metadata?.picture

        val bodyJson = JSONObject().apply {
            put("user_id", user.id)
            put("author_name", authorName)
            put("title", title)
            put("content", content)
            put("category_id", categoryId)
            if (authorAvatar != null) {
                put("author_avatar", authorAvatar)
            }
        }

        val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
        val request = makeRequest(path, "POST", body)

        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: ""
            verifyResponse(response, responseBody)
            val type = object : TypeToken<List<Post>>() {}.type
            val posts: List<Post> = gson.fromJson(responseBody, type)
            posts.firstOrNull() ?: throw IOException("Error al crear la publicación")
        }
    }

    suspend fun deletePost(postId: String): Unit = withContext(Dispatchers.IO) {
        val path = "/rest/v1/social_posts"
        val queryParams = mapOf("id" to "eq.$postId")
        val request = makeRequest(path, "DELETE", queryParams = queryParams)

        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: ""
            if (!response.isSuccessful) {
                throw IOException("Error al borrar la publicación")
            }
        }
    }

    // MARK: - Comments API
    suspend fun fetchComments(postId: String): List<Comment> = withContext(Dispatchers.IO) {
        val path = "/rest/v1/social_comments"
        val queryParams = mapOf(
            "select" to "*",
            "post_id" to "eq.$postId",
            "order" to "created_at.asc"
        )
        val request = makeRequest(path, "GET", queryParams = queryParams)
        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: ""
            verifyResponse(response, responseBody)
            val type = object : TypeToken<List<Comment>>() {}.type
            gson.fromJson(responseBody, type)
        }
    }

    suspend fun createComment(postId: String, content: String): Comment = withContext(Dispatchers.IO) {
        val user = currentUser ?: throw IOException("Inicia sesión para comentar")
        val path = "/rest/v1/social_comments"

        val metadata = user.userMetadata
        val authorName = metadata?.displayName ?: user.email?.substringBefore("@") ?: "Usuario"
        val authorAvatar = metadata?.avatarUrl ?: metadata?.picture

        val bodyJson = JSONObject().apply {
            put("post_id", postId)
            put("user_id", user.id)
            put("author_name", authorName)
            put("content", content)
            if (authorAvatar != null) {
                put("author_avatar", authorAvatar)
            }
        }

        val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
        val request = makeRequest(path, "POST", body)

        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: ""
            verifyResponse(response, responseBody)
            val type = object : TypeToken<List<Comment>>() {}.type
            val comments: List<Comment> = gson.fromJson(responseBody, type)
            comments.firstOrNull() ?: throw IOException("Error al publicar comentario")
        }
    }

    // MARK: - Likes API
    suspend fun checkIfLiked(postId: String): Boolean = withContext(Dispatchers.IO) {
        val user = currentUser ?: return@withContext false
        val path = "/rest/v1/social_likes"
        val queryParams = mapOf(
            "select" to "id",
            "post_id" to "eq.$postId",
            "user_id" to "eq.${user.id}"
        )
        val request = makeRequest(path, "GET", queryParams = queryParams)
        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: ""
            verifyResponse(response, responseBody)
            val list = JSONArray(responseBody)
            list.length() > 0
        }
    }

    suspend fun toggleLike(postId: String): Boolean = withContext(Dispatchers.IO) {
        val user = currentUser ?: throw IOException("Inicia sesión para dar like")
        val alreadyLiked = checkIfLiked(postId)
        val path = "/rest/v1/social_likes"

        if (alreadyLiked) {
            val queryParams = mapOf(
                "post_id" to "eq.$postId",
                "user_id" to "eq.${user.id}"
            )
            val request = makeRequest(path, "DELETE", queryParams = queryParams)
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    throw IOException("Error al quitar like")
                }
            }
            false
        } else {
            val bodyJson = JSONObject().apply {
                put("post_id", postId)
                put("user_id", user.id)
            }
            val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
            val request = makeRequest(path, "POST", body)
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    throw IOException("Error al dar like")
                }
            }
            true
        }
    }

    // MARK: - Follows API
    suspend fun checkFollowStatus(targetUserId: String): Boolean = withContext(Dispatchers.IO) {
        val user = currentUser ?: return@withContext false
        if (user.id == targetUserId) return@withContext false

        val path = "/rest/v1/social_follows"
        val queryParams = mapOf(
            "select" to "id",
            "follower_id" to "eq.${user.id}",
            "following_id" to "eq.$targetUserId"
        )
        val request = makeRequest(path, "GET", queryParams = queryParams)
        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: ""
            verifyResponse(response, responseBody)
            val list = JSONArray(responseBody)
            list.length() > 0
        }
    }

    suspend fun getFollowStats(userId: String): Pair<Int, Int> = withContext(Dispatchers.IO) {
        val path = "/rest/v1/social_follows"

        // Followers
        val followersReq = makeRequest(path, "GET", queryParams = mapOf(
            "select" to "id",
            "following_id" to "eq.$userId"
        ))
        var followersCount = 0
        client.newCall(followersReq).execute().use { r ->
            val body = r.body?.string() ?: ""
            if (r.isSuccessful) {
                followersCount = JSONArray(body).length()
            }
        }

        // Following
        val followingReq = makeRequest(path, "GET", queryParams = mapOf(
            "select" to "id",
            "follower_id" to "eq.$userId"
        ))
        var followingCount = 0
        client.newCall(followingReq).execute().use { r ->
            val body = r.body?.string() ?: ""
            if (r.isSuccessful) {
                followingCount = JSONArray(body).length()
            }
        }

        Pair(followersCount, followingCount)
    }

    suspend fun toggleFollow(targetUserId: String): Boolean = withContext(Dispatchers.IO) {
        val user = currentUser ?: throw IOException("Inicia sesión para seguir")
        if (user.id == targetUserId) throw IOException("No puedes seguirte a ti mismo")

        val following = checkFollowStatus(targetUserId)
        val path = "/rest/v1/social_follows"

        if (following) {
            val queryParams = mapOf(
                "follower_id" to "eq.${user.id}",
                "following_id" to "eq.$targetUserId"
            )
            val request = makeRequest(path, "DELETE", queryParams = queryParams)
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    throw IOException("Error al dejar de seguir")
                }
            }
            false
        } else {
            val bodyJson = JSONObject().apply {
                put("follower_id", user.id)
                put("following_id", targetUserId)
            }
            val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
            val request = makeRequest(path, "POST", body)
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    throw IOException("Error al seguir")
                }
            }
            true
        }
    }

    // MARK: - OAuth API
    suspend fun loginWithToken(accessToken: String) = withContext(Dispatchers.IO) {
        val path = "/auth/v1/user"
        val request = Request.Builder()
            .url("$baseURL$path")
            .header("apikey", anonKey)
            .header("Authorization", "Bearer $accessToken")
            .method("GET", null)
            .build()

        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: ""
            if (!response.isSuccessful) {
                throw IOException("Error al obtener perfil de usuario")
            }
            val user = gson.fromJson(responseBody, SupabaseUser::class.java)
            withContext(Dispatchers.Main) {
                saveSession(accessToken, user)
            }
        }
    }

    suspend fun handleOAuthCallback(url: String) {
        val fragment = url.substringAfter("#", "")
        if (fragment.isEmpty()) {
            throw IOException("Enlace de retorno inválido")
        }

        val params = mutableMapOf<String, String>()
        fragment.split("&").forEach { pair ->
            val parts = pair.split("=")
            if (parts.size == 2) {
                params[parts[0]] = parts[1]
            }
        }

        val accessToken = params["access_token"] ?: throw IOException("Token de acceso no encontrado")
        loginWithToken(accessToken)
    }

    // MARK: - Moderation API
    suspend fun reportPost(postId: String, reason: String, details: String? = null): Unit = withContext(Dispatchers.IO) {
        val user = currentUser ?: throw IOException("Inicia sesión para reportar")
        val path = "/rest/v1/social_reports"

        val bodyJson = JSONObject().apply {
            put("reporter_id", user.id)
            put("post_id", postId)
            put("reason", reason)
            if (!details.isNullOrBlank()) {
                put("details", details)
            }
        }

        val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
        val request = makeRequest(path, "POST", body)
        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: ""
            verifyResponse(response, responseBody)
        }
    }

    suspend fun reportComment(commentId: String, reason: String, details: String? = null): Unit = withContext(Dispatchers.IO) {
        val user = currentUser ?: throw IOException("Inicia sesión para reportar")
        val path = "/rest/v1/social_reports"

        val bodyJson = JSONObject().apply {
            put("reporter_id", user.id)
            put("comment_id", commentId)
            put("reason", reason)
            if (!details.isNullOrBlank()) {
                put("details", details)
            }
        }

        val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
        val request = makeRequest(path, "POST", body)
        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string() ?: ""
            verifyResponse(response, responseBody)
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
