package com.cokistudios.csms.xr.data

import com.google.gson.annotations.SerializedName

data class ChatRoom(
    val id: String,
    val name: String,
    @SerializedName("is_group") val isGroup: Boolean = true,
    @SerializedName("created_by") val createdBy: String? = null,
    @SerializedName("created_at") val createdAt: String = ""
)

data class ChatMessage(
    val id: String,
    @SerializedName("room_id") val roomId: String,
    @SerializedName("sender_id") val senderId: String,
    @SerializedName("sender_name") val senderName: String? = null,
    val content: String,
    @SerializedName("created_at") val createdAt: String
) {
    val initials: String
        get() = (senderName ?: senderId).firstOrNull()?.uppercase() ?: "?"
}

data class ChatUser(
    val id: String,
    val email: String?,
    @SerializedName("user_metadata") val userMetadata: UserMeta?
) {
    val displayName: String
        get() = userMetadata?.fullName ?: userMetadata?.name ?: email?.substringBefore("@") ?: "Usuario"
    val initials: String
        get() = displayName.firstOrNull()?.uppercase() ?: "?"
}

data class UserMeta(
    @SerializedName("full_name") val fullName: String?,
    val name: String?,
    @SerializedName("avatar_url") val avatarUrl: String?
)

data class AuthResponse(
    @SerializedName("access_token") val accessToken: String,
    @SerializedName("refresh_token") val refreshToken: String,
    val user: ChatUser
)
