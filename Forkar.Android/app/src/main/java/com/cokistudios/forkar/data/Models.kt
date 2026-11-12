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
    @SerializedName("image_url") val imageUrl: String? = null,
    @SerializedName("video_url") val videoUrl: String? = null,
    @SerializedName("created_at") val createdAt: String,
    @SerializedName("updated_at") val updatedAt: String?,
    val category: Category?
) {
    val initials: String
        get() = (authorName as? String)?.firstOrNull()?.uppercase() ?: "?"

    val formattedDate: String
        get() {
            return try {
                val rawDate = createdAt as? String ?: return "hace poco"
                // Parse ISO 8601 string (e.g. 2026-07-10T05:43:00.000Z or similar)
                val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()).apply {
                    timeZone = TimeZone.getTimeZone("UTC")
                }
                val cleanDateStr = rawDate.substringBefore(".") // Remove milliseconds for simpler parsing
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
        get() = (authorName as? String)?.firstOrNull()?.uppercase() ?: "?"

    val formattedDate: String
        get() {
            return try {
                val rawDate = createdAt as? String ?: return "hace poco"
                val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()).apply {
                    timeZone = TimeZone.getTimeZone("UTC")
                }
                val cleanDateStr = rawDate.substringBefore(".")
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
    val role: String?,
    @SerializedName("favorite_categories") val favoriteCategories: List<String>? = null,
    @SerializedName("has_passkey") val hasPasskey: Boolean = false,
    @SerializedName("migrated_v2") val migratedV2: Boolean = false
) {
    val displayName: String
        get() = fullName ?: name ?: "Usuario"
}

data class SupabaseAuthResponse(
    @SerializedName("access_token") val accessToken: String,
    @SerializedName("token_type") val tokenType: String,
    @SerializedName("expires_in") val expiresIn: Int,
    @SerializedName("refresh_token") val refreshToken: String? = null,
    val user: SupabaseUser
)

data class EcoAction(
    val id: String,
    val title: String,
    val description: String,
    @SerializedName("co2_impact") val co2Impact: Double = 1.0,
    val category: String = "General",
    @SerializedName("created_at") val createdAt: String? = null
) {
    val pointsEarned: Int
        get() = (co2Impact * 20).toInt()
}

data class UserEcoImpact(
    val id: String,
    @SerializedName("user_id") val userId: String,
    @SerializedName("action_id") val actionId: String?,
    @SerializedName("co2_saved") val co2Saved: Double = 0.0,
    @SerializedName("points_earned") val pointsEarned: Int = 0,
    @SerializedName("created_at") val createdAt: String? = null,
    val action: EcoAction? = null
)

data class EcoMapPoint(
    val id: String,
    val name: String,
    val description: String?,
    val latitude: Double,
    val longitude: Double,
    @SerializedName("point_type") val pointType: String = "verde",
    val color: String = "#10b981"
)

typealias ForkmanEcoAction = EcoAction
typealias ForkmanEcoMapPoint = EcoMapPoint

data class SocialLike(
    val id: String,
    @SerializedName("post_id") val postId: String,
    @SerializedName("user_id") val userId: String,
    @SerializedName("created_at") val createdAt: String? = null
)

data class SocialFollow(
    val id: String,
    @SerializedName("follower_id") val followerId: String,
    @SerializedName("following_id") val followingId: String,
    @SerializedName("created_at") val createdAt: String? = null
)

// MARK: - CSMS Canonical Protected Rooms

object CSMSCanonicalRooms {
    const val COMMUNITY_GLOBAL = "00000000-0000-4000-8000-000000000001"
    const val ECO_HUB = "00000000-0000-4000-8000-000000000002"
    const val FORKAR_CARPOOL = "00000000-0000-4000-8000-000000000003"

    val protectedIds: Set<String> = setOf(
        COMMUNITY_GLOBAL.lowercase(),
        ECO_HUB.lowercase(),
        FORKAR_CARPOOL.lowercase(),
        // Compatibilidad con identificadores legacy
        "00000000-0000-0000-0000-000000000001",
        "00000000-0000-0000-0000-000000000002",
        "00000000-0000-0000-0000-000000000003"
    )

    fun isProtected(roomId: String): Boolean {
        return protectedIds.contains(roomId.trim().lowercase())
    }
}

// MARK: - CSIMS Canonical Protected Internal Rooms (Zero Trust: @cokistudios.com only)

object CSIMSCanonicalRooms {
    const val GENERAL_COKI = "10000000-0000-0000-0000-000000000001"
    const val ENG_FORKAR = "10000000-0000-0000-0000-000000000002"
    const val SECURITY_OPS = "10000000-0000-0000-0000-000000000003"
    const val DESIGN_SYSTEM = "10000000-0000-0000-0000-000000000004"

    val internalIds: Set<String> = setOf(
        GENERAL_COKI.lowercase(),
        ENG_FORKAR.lowercase(),
        SECURITY_OPS.lowercase(),
        DESIGN_SYSTEM.lowercase()
    )

    fun isInternalRoom(roomId: String): Boolean {
        return internalIds.contains(roomId.trim().lowercase())
    }
}

data class ChatRoomMemberBasic(
    @SerializedName("user_id") val userId: String,
    @SerializedName("user_name") val userName: String?,
    @SerializedName("user_avatar") val userAvatar: String?
)


