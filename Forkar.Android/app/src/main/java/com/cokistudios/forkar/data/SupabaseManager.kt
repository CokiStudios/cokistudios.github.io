package com.cokistudios.forkar.data

import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
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
    private val managerScope = CoroutineScope(Dispatchers.IO)

    val baseURL = "https://cmkumxprmmhuinxfppxl.supabase.co"
    val anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ"

    val appVersion = "2.0"

    var currentUser by mutableStateOf<SupabaseUser?>(null)
        private set

    var sessionToken by mutableStateOf<String?>(null)
        private set

    var refreshToken by mutableStateOf<String?>(null)
        private set

    val isLoggedIn: Boolean
        get() = sessionToken != null

    fun getRestEndpoint(): String = "$baseURL/rest/v1/"

    val deviceHash: String
        get() {
            val existing = sharedPrefs.getString("forkar_device_hash", null)
            if (existing != null) return existing
            val newHash = java.util.UUID.randomUUID().toString().replace("-", "") + java.util.UUID.randomUUID().toString().substring(0, 8)
            sharedPrefs.edit().putString("forkar_device_hash", newHash).apply()
            return newHash
        }

    fun isJwtExpired(token: String?): Boolean {
        if (token.isNullOrBlank()) return true
        val parts = token.split(".")
        if (parts.size != 3) return true
        return try {
            val payloadBytes = android.util.Base64.decode(
                parts[1],
                android.util.Base64.URL_SAFE or android.util.Base64.NO_PADDING or android.util.Base64.NO_WRAP
            )
            val payload = JSONObject(String(payloadBytes, Charsets.UTF_8))
            val exp = payload.optLong("exp", 0L)
            if (exp == 0L) false else (exp * 1000L) <= System.currentTimeMillis()
        } catch (e: Exception) {
            true // If corrupted, treat as expired
        }
    }

    private fun isJwtNearExpiry(token: String?): Boolean {
        if (token.isNullOrBlank()) return true
        val parts = token.split(".")
        if (parts.size != 3) return true
        return try {
            val payloadBytes = android.util.Base64.decode(
                parts[1],
                android.util.Base64.URL_SAFE or android.util.Base64.NO_PADDING or android.util.Base64.NO_WRAP
            )
            val payload = JSONObject(String(payloadBytes, Charsets.UTF_8))
            val exp = payload.optLong("exp", 0L)
            if (exp == 0L) false else (exp * 1000L) <= (System.currentTimeMillis() + 300_000L) // 5 minutes margin
        } catch (e: Exception) {
            true
        }
    }

    private fun emergencyResetSession() {
        try {
            sessionToken = null
            refreshToken = null
            currentUser = null
            sharedPrefs.edit()
                .remove("supabase_session_token")
                .remove("supabase_refresh_token")
                .remove("supabase_current_user")
                .apply()
        } catch (e: Exception) {
            Log.e("SupabaseManager", "Emergency reset error", e)
        }
    }

    private fun performDataSanitization() {
        val storedSanityVersion = sharedPrefs.getInt("data_sanity_version", 0)

        // Read saved session info
        sessionToken = sharedPrefs.getString("supabase_session_token", null)
        refreshToken = sharedPrefs.getString("supabase_refresh_token", null)
        val userJson = sharedPrefs.getString("supabase_current_user", null)

        // 1. Validate stored user JSON safely
        if (userJson != null) {
            try {
                val parsed = gson.fromJson(userJson, SupabaseUser::class.java)
                if (parsed != null && !parsed.id.isNullOrBlank()) {
                    currentUser = parsed
                } else {
                    Log.w("SupabaseManager", "Auto-heal: SupabaseUser has invalid or missing id, clearing")
                    sharedPrefs.edit().remove("supabase_current_user").apply()
                    currentUser = null
                }
            } catch (e: Exception) {
                Log.e("SupabaseManager", "Auto-heal: Error decoding stored user JSON, clearing", e)
                sharedPrefs.edit().remove("supabase_current_user").apply()
                currentUser = null
            }
        }

        // 2. Validate token format and expiration
        val token = sessionToken
        if (token != null) {
            val isInvalidFormat = token.startsWith("device_hash_session_") || token.count { it == '.' } != 2
            val expired = isJwtExpired(token)

            if (isInvalidFormat || expired) {
                Log.w("SupabaseManager", "Auto-heal: Stored token is invalid or expired (expired=$expired). Purging from active session.")
                sessionToken = null
                sharedPrefs.edit().remove("supabase_session_token").apply()

                if (refreshToken != null) {
                    // Try to refresh session pro-actively in background
                    managerScope.launch {
                        refreshAuthSession()
                    }
                } else {
                    // If no refresh token exists, fully wipe user to prevent inconsistent partial state
                    currentUser = null
                    sharedPrefs.edit().remove("supabase_current_user").apply()
                }
            } else {
                // Token is valid and alive. If close to expiry (< 5 min), proactively refresh
                if (refreshToken != null && isJwtNearExpiry(token)) {
                    managerScope.launch {
                        refreshAuthSession()
                    }
                }
            }
        } else if (refreshToken != null) {
            // No session token but have refresh token -> attempt refresh
            managerScope.launch {
                refreshAuthSession()
            }
        }

        if (storedSanityVersion < 4) {
            sharedPrefs.edit().putInt("data_sanity_version", 4).apply()
        }
    }

    init {
        try {
            performDataSanitization()
        } catch (t: Throwable) {
            Log.e("SupabaseManager", "Critical failure during init data sanitization, emergency resetting session", t)
            emergencyResetSession()
        }
    }

    fun saveSession(token: String?, user: SupabaseUser?, refresh: String? = null) {
        // Ensure Compose states are updated on Main thread safely
        val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
        mainHandler.post {
            sessionToken = token
            currentUser = user
            if (refresh != null) {
                refreshToken = refresh
            } else if (token == null) {
                refreshToken = null
            }
        }

        sharedPrefs.edit().apply {
            if (token != null) {
                putString("supabase_session_token", token)
            } else {
                remove("supabase_session_token")
            }
            if (refresh != null) {
                putString("supabase_refresh_token", refresh)
            } else if (token == null) {
                remove("supabase_refresh_token")
            }
            if (user != null) {
                putString("supabase_current_user", gson.toJson(user))
            } else {
                remove("supabase_current_user")
            }
            apply()
        }

        if (user != null && user.email != null) {
            managerScope.launch {
                bindDeviceHash(user.id, user.email)
            }
        }
    }

    suspend fun refreshAuthSession(): Boolean = withContext(Dispatchers.IO) {
        val currentRefresh = refreshToken ?: return@withContext false
        try {
            val path = "/auth/v1/token"
            val queryParams = mapOf("grant_type" to "refresh_token")
            val json = JSONObject().apply {
                put("refresh_token", currentRefresh)
            }
            val body = json.toString().toRequestBody("application/json".toMediaType())
            val request = makeRequest(path, "POST", body, queryParams, forceAnon = true)

            client.newCall(request).execute().use { response ->
                val responseBody = response.body?.string() ?: ""
                if (response.isSuccessful && responseBody.isNotBlank()) {
                    val authResponse = gson.fromJson(responseBody, SupabaseAuthResponse::class.java)
                    saveSession(authResponse.accessToken, authResponse.user, authResponse.refreshToken)
                    return@withContext true
                } else if (response.code in 400..499) {
                    // Si el refresh token caducó o no es válido, cerrar sesión limpiamente sin bloquear la app
                    Log.w("SupabaseManager", "Refresh token invalid/expired (${response.code}). Logging out cleanly.")
                    logout()
                }
            }
        } catch (e: Exception) {
            Log.w("SupabaseManager", "Failed to refresh token: ${e.message}")
        }
        return@withContext false
    }

    fun logout() {
        managerScope.launch {
            unbindDeviceHash()
        }
        saveSession(null, null, null)
    }

    suspend fun bindDeviceHash(userId: String, email: String): Unit = withContext(Dispatchers.IO) {
        try {
            val path = "/rest/v1/user_device_hashes"
            val queryParams = mapOf("on_conflict" to "device_hash")
            val bodyJson = JSONObject().apply {
                put("device_hash", deviceHash)
                put("user_id", userId.lowercase())
                put("user_email", email)
            }
            val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
            val request = makeRequest(path, "POST", body, queryParams)
            client.newCall(request).execute().use { response ->
                Log.d("SupabaseManager", "Device hash bound: ${response.code}")
            }
        } catch (e: Exception) {
            Log.w("SupabaseManager", "Error binding device hash", e)
        }
    }

    suspend fun unbindDeviceHash(): Unit = withContext(Dispatchers.IO) {
        try {
            val currentHash = deviceHash
            val path = "/rest/v1/user_device_hashes"
            val queryParams = mapOf("device_hash" to "eq.$currentHash")
            val request = makeRequest(path, "DELETE", queryParams = queryParams)
            client.newCall(request).execute().use { response ->
                Log.d("SupabaseManager", "Device hash unbound: ${response.code}")
            }
        } catch (e: Exception) {
            Log.w("SupabaseManager", "Error unbinding device hash", e)
        }
    }

    suspend fun restoreSessionFromDeviceHash(): Unit = withContext(Dispatchers.IO) {
        // Desactivado: Crear tokens falsos 'device_hash_session_' provocaba que Supabase
        // retornara 401 en todas las APIs autenticadas y obligaba al usuario a "borrar datos de la app".
        // La sesión se mantiene de manera segura exclusivamente con JWTs reales y refresh_token.
    }


    private fun makeRequest(
        path: String,
        method: String = "GET",
        body: RequestBody? = null,
        queryParams: Map<String, String> = emptyMap(),
        forceAnon: Boolean = false
    ): Request {
        val urlBuilder = ("$baseURL$path").toHttpUrlOrNull()!!.newBuilder()
        queryParams.forEach { (name, value) ->
            urlBuilder.addQueryParameter(name, value)
        }

        val requestBuilder = Request.Builder()
            .url(urlBuilder.build())
            .header("apikey", anonKey)

        val token = sessionToken
        if (!forceAnon && token != null && !token.startsWith("device_hash_session_") && token.count { it == '.' } == 2 && !isJwtExpired(token)) {
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
            if (response.code == 401 || message.lowercase().contains("jwt") || message.lowercase().contains("token")) {
                Log.w("SupabaseManager", "verifyResponse: 401/JWT error detected, auto-healing with logout()")
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
        val request = makeRequest(path, "POST", body, queryParams, forceAnon = true)

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
            saveSession(authResponse.accessToken, authResponse.user, authResponse.refreshToken)
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
        val request = makeRequest(path, "POST", body, forceAnon = true)

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
        val request = makeRequest(path, "GET", queryParams = queryParams, forceAnon = true)
        try {
            client.newCall(request).execute().use { response ->
                val responseBody = response.body?.string() ?: ""
                if (response.isSuccessful && responseBody.isNotBlank()) {
                    val type = object : TypeToken<List<Category>>() {}.type
                    gson.fromJson<List<Category>>(responseBody, type) ?: emptyList()
                } else {
                    emptyList()
                }
            }
        } catch (e: Exception) {
            Log.w("SupabaseManager", "Error fetching categories: ${e.message}")
            emptyList()
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
        try {
            client.newCall(request).execute().use { response ->
                var responseBody = response.body?.string() ?: ""
                if (response.code == 401) {
                    Log.w("SupabaseManager", "401 on fetchPosts. Auto-healing: clearing session and retrying with anonKey")
                    logout()
                    val fallbackReq = makeRequest(path, "GET", queryParams = queryParams, forceAnon = true)
                    client.newCall(fallbackReq).execute().use { fallbackResp ->
                        if (fallbackResp.isSuccessful) {
                            responseBody = fallbackResp.body?.string() ?: ""
                        }
                    }
                }
                if (responseBody.isNotBlank()) {
                    val type = object : TypeToken<List<Post>>() {}.type
                    gson.fromJson<List<Post>>(responseBody, type) ?: emptyList()
                } else {
                    emptyList()
                }
            }
        } catch (e: Exception) {
            Log.w("SupabaseManager", "Error fetching posts: ${e.message}")
            emptyList()
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
    suspend fun loginWithToken(accessToken: String, refresh: String? = null) = withContext(Dispatchers.IO) {
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
                saveSession(accessToken, user, refresh)
            }
        }
    }

    suspend fun handleOAuthCallback(url: String) {
        val params = mutableMapOf<String, String>()

        // 1. Fragment (#access_token=...&refresh_token=...)
        val fragment = if (url.contains("#")) url.substringAfter("#") else ""
        if (fragment.isNotEmpty()) {
            fragment.split("&").forEach { pair ->
                val parts = pair.split("=")
                if (parts.size == 2) {
                    try {
                        params[parts[0]] = java.net.URLDecoder.decode(parts[1], "UTF-8")
                    } catch (e: Exception) {
                        params[parts[0]] = parts[1]
                    }
                }
            }
        }

        // 2. Query (?access_token=... o ?code=...)
        val query = if (url.contains("?")) url.substringAfter("?").substringBefore("#") else ""
        if (query.isNotEmpty()) {
            query.split("&").forEach { pair ->
                val parts = pair.split("=")
                if (parts.size == 2) {
                    try {
                        params[parts[0]] = java.net.URLDecoder.decode(parts[1], "UTF-8")
                    } catch (e: Exception) {
                        params[parts[0]] = parts[1]
                    }
                }
            }
        }

        val accessToken = params["access_token"] ?: throw IOException("Token de acceso no encontrado en redirección")
        val refreshToken = params["refresh_token"]
        loginWithToken(accessToken, refreshToken)
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

    // MARK: - Forkar Eco Hub API
    suspend fun fetchEcoActions(): List<EcoAction> = withContext(Dispatchers.IO) {
        val path = "/rest/v1/forkman_eco_actions"
        val queryParams = mapOf("select" to "*", "order" to "created_at.desc")
        val request = makeRequest(path, queryParams = queryParams)
        client.newCall(request).execute().use { response ->
            val body = response.body?.string() ?: ""
            verifyResponse(response, body)
            val type = object : TypeToken<List<EcoAction>>() {}.type
            gson.fromJson(body, type) ?: emptyList()
        }
    }

    suspend fun fetchUserEcoImpact(userId: String? = null): Pair<Double, Int> = withContext(Dispatchers.IO) {
        val targetUserId = userId ?: currentUser?.id
        val path = "/rest/v1/forkman_user_eco"
        val queryParams = if (targetUserId != null) {
            mapOf("select" to "*", "user_id" to "eq.$targetUserId")
        } else {
            mapOf("select" to "*", "order" to "created_at.desc", "limit" to "50")
        }
        val request = makeRequest(path, queryParams = queryParams)
        client.newCall(request).execute().use { response ->
            val body = response.body?.string() ?: ""
            if (!response.isSuccessful || body.isBlank()) return@withContext Pair(0.0, 0)
            val type = object : TypeToken<List<UserEcoImpact>>() {}.type
            val list: List<UserEcoImpact> = gson.fromJson(body, type) ?: emptyList()
            val totalCo2 = list.sumOf { it.co2Saved }
            val totalPts = list.sumOf { it.pointsEarned }
            Pair(totalCo2, totalPts)
        }
    }

    suspend fun hasRedeemedEcoToday(userId: String): Boolean = withContext(Dispatchers.IO) {
        val path = "/rest/v1/forkman_user_eco"
        val todayStart = java.text.SimpleDateFormat("yyyy-MM-dd'T'00:00:00.000'Z'", java.util.Locale.US).apply {
            timeZone = java.util.TimeZone.getTimeZone("UTC")
        }.format(java.util.Date())

        val queryParams = mapOf(
            "select" to "id,created_at",
            "user_id" to "eq.$userId",
            "created_at" to "gte.$todayStart"
        )
        val request = makeRequest(path, queryParams = queryParams)
        client.newCall(request).execute().use { response ->
            val body = response.body?.string() ?: ""
            if (!response.isSuccessful || body.isBlank()) return@withContext false
            val array = JSONArray(body)
            array.length() > 0
        }
    }

    suspend fun logUserEcoImpact(actionId: String, co2Saved: Double, pointsEarned: Int): Boolean = withContext(Dispatchers.IO) {
        val user = currentUser ?: throw IOException("Inicia sesión para registrar impacto ecológico")

        if (hasRedeemedEcoToday(user.id)) {
            throw IOException("Solo puedes redimir 1 reto ecológico por día. ¡Vuelve mañana!")
        }

        val path = "/rest/v1/forkman_user_eco"
        val isUuid = actionId.matches(Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"))

        val bodyJson = JSONObject().apply {
            put("user_id", user.id)
            if (isUuid) {
                put("action_id", actionId)
            }
            put("co2_saved", co2Saved)
            put("points_earned", pointsEarned)
        }
        val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
        val request = makeRequest(path, "POST", body)

        client.newCall(request).execute().use { response ->
            if (response.isSuccessful) {
                true
            } else {
                // Fallback sin action_id por si hay restricción de FK o ID de NFC no guardado en la tabla de acciones
                val fallbackJson = JSONObject().apply {
                    put("user_id", user.id)
                    put("co2_saved", co2Saved)
                    put("points_earned", pointsEarned)
                }
                val fallbackBody = fallbackJson.toString().toRequestBody("application/json".toMediaType())
                val fallbackReq = makeRequest(path, "POST", fallbackBody)
                client.newCall(fallbackReq).execute().use { r -> r.isSuccessful }
            }
        }
    }

    suspend fun fetchEcoMapPoints(): List<EcoMapPoint> = withContext(Dispatchers.IO) {
        val path = "/rest/v1/forkman_eco_map_points"
        val queryParams = mapOf("select" to "*", "order" to "name.asc")
        val request = makeRequest(path, queryParams = queryParams)
        client.newCall(request).execute().use { response ->
            val body = response.body?.string() ?: ""
            verifyResponse(response, body)
            val type = object : TypeToken<List<EcoMapPoint>>() {}.type
            gson.fromJson(body, type) ?: emptyList()
        }
    }

    // MARK: - CSMS / Chat API
    fun getValidUserUUID(): String {
        val uid = currentUser?.id
        if (!uid.isNullOrBlank() && uid.matches(Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"))) {
            return uid.lowercase()
        }
        val hash = deviceHash.padEnd(32, '0').take(32)
        return "${hash.substring(0,8)}-${hash.substring(8,12)}-4${hash.substring(13,16)}-a${hash.substring(17,20)}-${hash.substring(20,32)}".lowercase()
    }

    fun ensureValidRoomUUID(roomId: String): String {
        return when (roomId) {
            "csms-global" -> CSMS_COMMUNITY_GLOBAL_ID
            "csms-eco" -> CSMS_ECO_HUB_ID
            "csms-forkar" -> CSMS_FORKAR_CARPOOL_ID
            else -> {
                if (roomId.matches(Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"))) {
                    roomId.lowercase()
                } else {
                    CSMS_COMMUNITY_GLOBAL_ID
                }
            }
        }
    }

    private fun saveLocalChatMessage(roomId: String, msg: JSONObject) {
        try {
            val key = "csms_cached_messages_$roomId"
            val existing = sharedPrefs.getString(key, null)
            val array = if (existing != null) JSONArray(existing) else JSONArray()
            array.put(msg)
            sharedPrefs.edit().putString(key, array.toString()).apply()
        } catch (e: Exception) {
            Log.w("SupabaseManager", "Error caching local message", e)
        }
    }

    private fun getLocalChatMessages(roomId: String): List<JSONObject> {
        return try {
            val key = "csms_cached_messages_$roomId"
            val existing = sharedPrefs.getString(key, null) ?: return emptyList()
            val array = JSONArray(existing)
            val list = mutableListOf<JSONObject>()
            for (i in 0 until array.length()) {
                list.add(array.getJSONObject(i))
            }
            list
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun fetchChatRooms(): List<JSONObject> = withContext(Dispatchers.IO) {
        val path = "/rest/v1/chat_rooms"
        val queryParams = mapOf("select" to "*", "order" to "created_at.desc")
        val request = makeRequest(path, queryParams = queryParams)
        val list = mutableListOf<JSONObject>()
        val seenIds = mutableSetOf<String>()

        try {
            client.newCall(request).execute().use { response ->
                val body = response.body?.string() ?: ""
                if (response.isSuccessful && body.isNotBlank()) {
                    val array = JSONArray(body)
                    for (i in 0 until array.length()) {
                        val obj = array.getJSONObject(i)
                        val id = obj.optString("id")
                        var roomName = obj.optString("name")
                        val isGroup = obj.optBoolean("is_group", true)
                        if (roomName.isBlank() || roomName == "null") {
                            roomName = if (isGroup) "Grupo CSMS" else "Chat Directo"
                        }
                        obj.put("displayName", roomName)
                        if (id.isNotBlank()) {
                            seenIds.add(id.lowercase())
                        }
                        list.add(obj)
                    }
                }
            }
        } catch (e: Exception) {
            Log.w("SupabaseManager", "Error fetching chat rooms from Supabase", e)
        }

        // Always ensure canonical official channels exist in the room list
        val canonicalRooms = listOf(
            Triple(CSMS_COMMUNITY_GLOBAL_ID, "💬 Comunidad Coki Studios Global", true),
            Triple(CSMS_ECO_HUB_ID, "🌿 Eco Hub Cota & Cundinamarca", true),
            Triple(CSMS_FORKAR_CARPOOL_ID, "🚗 Forkar Carpooling & Rutas", true)
        )

        for ((id, name, isGroup) in canonicalRooms) {
            if (!seenIds.contains(id.lowercase())) {
                val canonObj = JSONObject().apply {
                    put("id", id)
                    put("name", name)
                    put("displayName", name)
                    put("is_group", isGroup)
                    put("created_at", "2026-09-20T00:00:00Z")
                }
                list.add(0, canonObj)
                seenIds.add(id.lowercase())
            }
        }

        list
    }

    suspend fun joinRoomAsMember(rawRoomId: String, memberId: String? = null, memberName: String? = null): Boolean = withContext(Dispatchers.IO) {
        try {
            val roomId = ensureValidRoomUUID(rawRoomId)
            val uid = memberId ?: getValidUserUUID()
            val user = currentUser
            val name = memberName ?: user?.userMetadata?.fullName ?: user?.userMetadata?.name ?: user?.email?.substringBefore("@") ?: "Usuario Android"
            val path = "/rest/v1/chat_room_members"
            val bodyJson = JSONObject().apply {
                put("room_id", roomId)
                put("user_id", uid)
                put("user_name", name)
            }
            val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
            val request = makeRequest(path, "POST", body)
            client.newCall(request).execute().use { response ->
                response.isSuccessful
            }
        } catch (e: Exception) {
            false
        }
    }

    suspend fun uploadMedia(uri: Uri, context: Context): Pair<String, String>? = withContext(Dispatchers.IO) {
        val uid = getValidUserUUID()
        val resolver = context.contentResolver
        val mimeType = resolver.getType(uri) ?: "application/octet-stream"
        val isVideo = mimeType.startsWith("video/")
        val ext = when {
            mimeType.contains("png") -> "png"
            mimeType.contains("webp") -> "webp"
            mimeType.contains("gif") -> "gif"
            mimeType.contains("mp4") -> "mp4"
            mimeType.contains("mov") -> "mov"
            mimeType.contains("webm") -> "webm"
            isVideo -> "mp4"
            else -> "jpg"
        }
        val mediaType = if (isVideo) "video" else "image"
        val filename = "$uid/${System.currentTimeMillis()}_${java.util.UUID.randomUUID().toString().take(6)}.$ext"

        val bytes = try {
            resolver.openInputStream(uri)?.use { it.readBytes() }
        } catch (e: Exception) {
            null
        } ?: return@withContext null

        val body = bytes.toRequestBody(mimeType.toMediaType())

        // Intentar csms-media y fallback a forkar-media (igual que Web)
        val buckets = listOf("csms-media", "forkar-media")
        for (bucket in buckets) {
            val path = "/storage/v1/object/$bucket/$filename"
            val request = Request.Builder()
                .url("$baseURL$path")
                .header("apikey", anonKey)
                .header("Authorization", if (sessionToken != null) "Bearer $sessionToken" else "Bearer $anonKey")
                .header("Content-Type", mimeType)
                .header("x-upsert", "true")
                .header("cache-control", "3600")
                .post(body)
                .build()

            try {
                client.newCall(request).execute().use { response ->
                    if (response.isSuccessful) {
                        val publicUrl = "$baseURL/storage/v1/object/public/$bucket/$filename"
                        return@withContext Pair(publicUrl, mediaType)
                    }
                }
            } catch (e: Exception) {
                Log.w("SupabaseManager", "Error subiendo media a bucket $bucket", e)
            }
        }
        null
    }

    suspend fun startDirectMessage(targetEmail: String): String? = withContext(Dispatchers.IO) {
        val email = targetEmail.trim().lowercase()
        if (email.isBlank()) return@withContext null
        val myUid = getValidUserUUID()
        val myName = currentUser?.userMetadata?.fullName ?: currentUser?.userMetadata?.name ?: currentUser?.email?.substringBefore("@") ?: "Usuario Android"

        var targetUserId: String? = null
        var targetUserName: String = email

        try {
            val path = "/rest/v1/profiles"
            val req = makeRequest(path, queryParams = mapOf("select" to "*", "email" to "ilike.$email", "limit" to "1"))
            client.newCall(req).execute().use { resp ->
                val body = resp.body?.string() ?: ""
                if (resp.isSuccessful && body.isNotBlank()) {
                    val arr = JSONArray(body)
                    if (arr.length() > 0) {
                        val prof = arr.getJSONObject(0)
                        targetUserId = prof.optString("id")
                        targetUserName = prof.optString("full_name", email)
                    }
                }
            }
        } catch (e: Exception) {
            // ignore
        }

        val roomPath = "/rest/v1/chat_rooms"
        val roomJson = JSONObject().apply {
            put("name", targetUserName)
            put("is_group", false)
            put("created_by", myUid)
        }
        val roomBody = roomJson.toString().toRequestBody("application/json".toMediaType())
        val roomReq = makeRequest(roomPath, "POST", roomBody)
        var newRoomId: String? = null
        try {
            client.newCall(roomReq).execute().use { resp ->
                val body = resp.body?.string() ?: ""
                if (resp.isSuccessful && body.isNotBlank()) {
                    val arr = JSONArray(body)
                    if (arr.length() > 0) {
                        newRoomId = arr.getJSONObject(0).optString("id")
                    }
                }
            }
        } catch (e: Exception) {
            Log.w("SupabaseManager", "Error creating DM room", e)
        }

        val roomId = newRoomId ?: java.util.UUID.randomUUID().toString()
        joinRoomAsMember(roomId, myUid, myName)
        if (targetUserId != null) {
            joinRoomAsMember(roomId, targetUserId!!, targetUserName)
        } else {
            joinRoomAsMember(roomId, "00000000-0000-0000-0000-000000000000", targetUserName)
        }
        roomId
    }

    suspend fun createGroupChat(name: String): String? = withContext(Dispatchers.IO) {
        val user = currentUser
        val createdBy = getValidUserUUID()
        val authorName = user?.userMetadata?.fullName ?: user?.userMetadata?.name ?: user?.email?.substringBefore("@") ?: "Usuario Android"
        val path = "/rest/v1/chat_rooms"
        val bodyJson = JSONObject().apply {
            put("name", name)
            put("is_group", true)
            put("created_by", createdBy)
        }
        val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
        val request = makeRequest(path, "POST", body)
        var createdRoomId: String? = null
        try {
            client.newCall(request).execute().use { response ->
                val resBody = response.body?.string() ?: ""
                if (response.isSuccessful && resBody.isNotBlank()) {
                    try {
                        val arr = JSONArray(resBody)
                        if (arr.length() > 0) {
                            createdRoomId = arr.getJSONObject(0).optString("id")
                        }
                    } catch (e: Exception) {
                        // ignore
                    }
                }
            }
        } catch (e: Exception) {
            // ignore
        }

        val roomId = createdRoomId ?: java.util.UUID.randomUUID().toString()
        joinRoomAsMember(roomId, createdBy, authorName)
        roomId
    }

    suspend fun fetchChatMessages(rawRoomId: String): List<JSONObject> = withContext(Dispatchers.IO) {
        val roomId = ensureValidRoomUUID(rawRoomId)
        val path = "/rest/v1/chat_messages"
        val queryParams = mapOf(
            "select" to "*",
            "room_id" to "eq.$roomId",
            "order" to "created_at.asc"
        )
        val request = makeRequest(path, queryParams = queryParams)
        val remoteList = mutableListOf<JSONObject>()
        try {
            client.newCall(request).execute().use { response ->
                val body = response.body?.string() ?: ""
                if (response.isSuccessful && body.isNotBlank()) {
                    val array = JSONArray(body)
                    for (i in 0 until array.length()) {
                        remoteList.add(array.getJSONObject(i))
                    }
                }
            }
        } catch (e: Exception) {
            Log.w("SupabaseManager", "Error fetching remote chat messages", e)
        }

        val localList = getLocalChatMessages(roomId)
        val combined = mutableListOf<JSONObject>()
        val seenContents = mutableSetOf<String>()

        for (m in remoteList) {
            val id = m.optString("id")
            val content = m.optString("content")
            seenContents.add("$id-$content")
            combined.add(m)
        }
        for (m in localList) {
            val id = m.optString("id")
            val content = m.optString("content")
            if (!seenContents.contains("$id-$content")) {
                combined.add(m)
            }
        }
        combined
    }

    suspend fun sendChatMessage(
        rawRoomId: String,
        content: String,
        mediaUrl: String? = null,
        mediaType: String? = null
    ): Boolean = withContext(Dispatchers.IO) {
        val roomId = ensureValidRoomUUID(rawRoomId)
        val user = currentUser
        val senderId = getValidUserUUID()
        val authorName = user?.userMetadata?.fullName ?: user?.userMetadata?.name ?: user?.email?.substringBefore("@") ?: "Usuario CSMS"
        val nowIso = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply {
            timeZone = java.util.TimeZone.getTimeZone("UTC")
        }.format(java.util.Date())
        val localMsgId = java.util.UUID.randomUUID().toString()

        val localMsgObj = JSONObject().apply {
            put("id", localMsgId)
            put("room_id", roomId)
            put("user_id", senderId)
            put("sender_id", senderId)
            put("author_name", authorName)
            put("content", content)
            if (!mediaUrl.isNullOrBlank()) put("media_url", mediaUrl)
            if (!mediaType.isNullOrBlank()) put("media_type", mediaType)
            put("created_at", nowIso)
            put("is_local", true)
        }

        saveLocalChatMessage(roomId, localMsgObj)

        val path = "/rest/v1/chat_messages"
        val bodyJson = JSONObject().apply {
            put("room_id", roomId)
            put("user_id", senderId)
            put("sender_id", senderId)
            put("author_name", authorName)
            put("content", content)
            if (!mediaUrl.isNullOrBlank()) put("media_url", mediaUrl)
            if (!mediaType.isNullOrBlank()) put("media_type", mediaType)
        }
        val body = bodyJson.toString().toRequestBody("application/json".toMediaType())
        val request = makeRequest(path, "POST", body)
        try {
            client.newCall(request).execute().use { response ->
                Log.d("SupabaseManager", "sendChatMessage remote result code: ${response.code}")
            }
        } catch (e: Exception) {
            Log.w("SupabaseManager", "Failed to send chat message remotely", e)
        }
        true
    }

    companion object {
        const val CSMS_COMMUNITY_GLOBAL_ID = "00000000-0000-4000-8000-000000000001"
        const val CSMS_ECO_HUB_ID = "00000000-0000-4000-8000-000000000002"
        const val CSMS_FORKAR_CARPOOL_ID = "00000000-0000-4000-8000-000000000003"

        @Volatile
        private var instance: SupabaseManager? = null

        fun getInstance(context: Context): SupabaseManager {
            return instance ?: synchronized(this) {
                instance ?: SupabaseManager(context.applicationContext).also { instance = it }
            }
        }
    }
}
