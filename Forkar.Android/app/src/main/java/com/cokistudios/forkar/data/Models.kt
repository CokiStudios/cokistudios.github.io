package com.cokistudios.forkar.data

import com.google.gson.annotations.SerializedName
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

data class Category(
    val id: String,
    val name: String,
    val slug: String,
    val description: String?,
    val color: String,
    @SerializedName("created_at") val createdAt: String?
)

data class Post(
    val id: String,
    @SerializedName("user_id") val userId: String,
    @SerializedName("author_name") val authorName: String,
    @SerializedName("author_avatar") val authorAvatar: String?,
    @SerializedName("category_id") val categoryId: String?,
    val title: String,
    val content: String,
    @SerializedName("likes_count") val likesCount: Int = 0,
    @SerializedName("comments_count") val commentsCount: Int = 0,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("updated_at") val updatedAt: String?,
    val category: Category?
) {
    val initials: String
        get() = authorName.firstOrNull()?.uppercase() ?: "?"

    val formattedDate: String
        get() {
            return try {
                // Parse ISO 8601 string (e.g. 2026-07-10T05:43:00.000Z or similar)
                val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()).apply {
                    timeZone = TimeZone.getTimeZone("UTC")
                }
                val cleanDateStr = createdAt.substringBefore(".") // Remove milliseconds for simpler parsing
                val date = format.parse(cleanDateStr) ?: Date()
                val diff = Date().time - date.time
                val seconds = diff / 1000
                val minutes = seconds / 60
                val hours = minutes / 60
                val days = hours / 24

                when {
                    seconds < 60 -> "hace poco"
                    minutes < 60 -> "${minutes}m"
                    hours < 24 -> "${hours}h"
                    else -> "${days}d"
                }
            } catch (e: Exception) {
                "hace poco"
            }
        }
}

data class Comment(
    val id: String,
    @SerializedName("post_id") val postId: String,
    @SerializedName("user_id") val userId: String,
    @SerializedName("author_name") val authorName: String,
    @SerializedName("author_avatar") val authorAvatar: String?,
    val content: String,
    @SerializedName("created_at") val createdAt: String
) {
    val initials: String
        get() = authorName.firstOrNull()?.uppercase() ?: "?"

    val formattedDate: String
        get() {
            return try {
                val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()).apply {
                    timeZone = TimeZone.getTimeZone("UTC")
                }
                val cleanDateStr = createdAt.substringBefore(".")
                val date = format.parse(cleanDateStr) ?: Date()
                val diff = Date().time - date.time
                val seconds = diff / 1000
                val minutes = seconds / 60
                val hours = minutes / 60
                val days = hours / 24

                when {
                    seconds < 60 -> "hace poco"
                    minutes < 60 -> "${minutes}m"
                    hours < 24 -> "${hours}h"
                    else -> "${days}d"
                }
            } catch (e: Exception) {
                "hace poco"
            }
        }
}

data class SupabaseUser(
    val id: String,
    val email: String?,
    @SerializedName("user_metadata") val userMetadata: UserMetadata?
)

data class UserMetadata(
    @SerializedName("full_name") val fullName: String?,
    val name: String?,
    @SerializedName("avatar_url") val avatarUrl: String?,
    val picture: String?,
    val company: String?,
    val role: String?
) {
    val displayName: String
        get() = fullName ?: name ?: "Usuario"
}

data class SupabaseAuthResponse(
    @SerializedName("access_token") val accessToken: String,
    @SerializedName("token_type") val tokenType: String,
    @SerializedName("expires_in") val expiresIn: Int,
    @SerializedName("refresh_token") val refreshToken: String,
    val user: SupabaseUser
)
