package com.cokistudios.forkar.ui.screens

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.SubcomposeAsyncImage
import com.cokistudios.forkar.data.Comment
import com.cokistudios.forkar.data.Post
import com.cokistudios.forkar.data.SupabaseManager
import com.cokistudios.forkar.ui.components.CircleAvatarPlaceholder
import com.cokistudios.forkar.ui.theme.BorderDark
import com.cokistudios.forkar.ui.theme.BorderLight
import com.cokistudios.forkar.ui.theme.CardDark
import com.cokistudios.forkar.ui.theme.CardLight
import com.cokistudios.forkar.ui.theme.IndigoPrimary
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PostDetailScreen(
    post: Post,
    manager: SupabaseManager,
    onBack: () -> Unit,
    onLoginRequired: () -> Unit
) {
    val comments = remember { mutableStateListOf<Comment>() }
    var newCommentText by remember { mutableStateOf("") }
    var isLiked by remember { mutableStateOf(false) }
    var isFollowingAuthor by remember { mutableStateOf(false) }
    var likesCount by remember { mutableStateOf(post.likesCount) }
    var isLoadingComments by remember { mutableStateOf(false) }

    val coroutineScope = rememberCoroutineScope()
    val context = LocalContext.current
    val isDark = isSystemInDarkTheme()
    val borderColor = if (isDark) BorderDark else BorderLight

    val loadPostDetails = {
        coroutineScope.launch {
            isLoadingComments = true
            try {
                val list = manager.fetchComments(post.id)
                comments.clear()
                comments.addAll(list)

                if (manager.isLoggedIn) {
                    isLiked = manager.checkIfLiked(post.id)
                    isFollowingAuthor = manager.checkFollowStatus(post.userId)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                isLoadingComments = false
            }
        }
    }

    LaunchedEffect(Unit) {
        loadPostDetails()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Publicación", fontSize = 18.sp, fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Atrás")
                    }
                },
                actions = {
                    IconButton(onClick = {
                        coroutineScope.launch {
                            try {
                                manager.reportPost(post.id, "Spam/Contenido inapropiado")
                                Toast.makeText(context, "Publicación reportada", Toast.LENGTH_SHORT).show()
                            } catch (e: Exception) {
                                Toast.makeText(context, e.message ?: "Error al reportar", Toast.LENGTH_SHORT).show()
                            }
                        }
                    }) {
                        Icon(Icons.Default.Warning, contentDescription = "Reportar", tint = Color.Red.copy(alpha = 0.7f))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    titleContentColor = MaterialTheme.colorScheme.onBackground
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
                .padding(paddingValues)
        ) {
            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Post Card Header Details
                item {
                    Column(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        // Author header with Follow
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            if (post.authorAvatar != null) {
                                SubcomposeAsyncImage(
                                    model = post.authorAvatar,
                                    contentDescription = null,
                                    modifier = Modifier
                                        .size(44.dp)
                                        .clip(CircleShape),
                                    loading = { CircleAvatarPlaceholder(post.initials, size = 44.dp, textSize = 16) },
                                    error = { CircleAvatarPlaceholder(post.initials, size = 44.dp, textSize = 16) }
                                )
                            } else {
                                CircleAvatarPlaceholder(post.initials, size = 44.dp, textSize = 16)
                            }

                            Spacer(modifier = Modifier.width(12.dp))

                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = post.authorName,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 15.sp,
                                    color = MaterialTheme.colorScheme.onBackground
                                )
                                Text(
                                    text = post.formattedDate,
                                    fontSize = 12.sp,
                                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
                                )
                            }

                            if (manager.isLoggedIn && post.userId != manager.currentUser?.id) {
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(if (isFollowingAuthor) Color.Transparent else IndigoPrimary)
                                        .border(
                                            1.dp,
                                            if (isFollowingAuthor) borderColor else Color.Transparent,
                                            RoundedCornerShape(12.dp)
                                        )
                                        .clickable {
                                            coroutineScope.launch {
                                                try {
                                                    val following = manager.toggleFollow(post.userId)
                                                    isFollowingAuthor = following
                                                } catch (e: Exception) {
                                                    Toast.makeText(context, e.message, Toast.LENGTH_SHORT).show()
                                                }
                                            }
                                        }
                                        .padding(vertical = 6.dp, horizontal = 14.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = if (isFollowingAuthor) "Siguiendo" else "Seguir",
                                        color = if (isFollowingAuthor) MaterialTheme.colorScheme.onBackground else Color.White,
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 12.sp
                                    )
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(16.dp))

                        // Post details
                        if (post.category != null) {
                            val catColor = try {
                                Color(android.graphics.Color.parseColor(post.category.color))
                            } catch (e: Exception) {
                                IndigoPrimary
                            }

                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(10.dp))
                                    .background(catColor.copy(alpha = 0.15f))
                                    .padding(vertical = 4.dp, horizontal = 12.dp)
                            ) {
                                Text(
                                    text = post.category.name,
                                    color = catColor,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 11.sp
                                )
                            }
                            Spacer(modifier = Modifier.height(10.dp))
                        }

                        Text(
                            text = post.title,
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onBackground
                        )

                        Spacer(modifier = Modifier.height(12.dp))

                        Text(
                            text = post.content,
                            fontSize = 15.sp,
                            lineHeight = 22.sp,
                            color = MaterialTheme.colorScheme.onBackground
                        )

                        // Full Post Photo
                        if (!post.imageUrl.isNullOrBlank()) {
                            Spacer(modifier = Modifier.height(14.dp))
                            SubcomposeAsyncImage(
                                model = post.imageUrl,
                                contentDescription = "Post Photo",
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(16.dp)),
                                contentScale = androidx.compose.ui.layout.ContentScale.FillWidth,
                                loading = {
                                    Box(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .height(220.dp)
                                            .background(if (isDark) Color(0xFF1E293B) else Color(0xFFE2E8F0)),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        CircularProgressIndicator(
                                            color = IndigoPrimary,
                                            modifier = Modifier.size(28.dp)
                                        )
                                    }
                                }
                            )
                        }

                        Spacer(modifier = Modifier.height(16.dp))

                        // Like Action Row
                        Row {
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(12.dp))
                                    .background(if (isDark) CardDark else CardLight)
                                    .border(1.dp, borderColor, RoundedCornerShape(12.dp))
                                    .clickable {
                                        if (manager.isLoggedIn) {
                                            coroutineScope.launch {
                                                try {
                                                    val liked = manager.toggleLike(post.id)
                                                    isLiked = liked
                                                    likesCount += if (liked) 1 else -1
                                                } catch (e: Exception) {
                                                    Toast.makeText(context, e.message, Toast.LENGTH_SHORT).show()
                                                }
                                            }
                                        } else {
                                            onLoginRequired()
                                        }
                                    }
                                    .padding(vertical = 8.dp, horizontal = 16.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Icon(
                                        imageVector = if (isLiked) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                                        contentDescription = null,
                                        tint = if (isLiked) Color.Red else MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                                    )
                                    Text(
                                        text = "$likesCount Likes",
                                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.8f),
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 13.sp
                                    )
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(20.dp))
                        Divider(color = borderColor)
                        Spacer(modifier = Modifier.height(10.dp))

                        Text(
                            text = "Comentarios (${comments.size})",
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onBackground
                        )
                    }
                }

                // Loading Comments view
                if (isLoadingComments) {
                    item {
                        Box(
                            modifier = Modifier.fillMaxWidth().padding(vertical = 20.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator(color = IndigoPrimary)
                        }
                    }
                } else if (comments.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier.fillMaxWidth().padding(vertical = 20.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "Aún no hay comentarios",
                                fontSize = 14.sp,
                                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
                            )
                        }
                    }
                } else {
                    items(comments) { comment ->
                        CommentRowView(comment = comment, manager = manager)
                    }
                }
            }

            // Bottom Compose comment bar
            Divider(color = borderColor)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.surface)
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedTextField(
                    value = newCommentText,
                    onValueChange = { newCommentText = it },
                    placeholder = { Text("Escribe un comentario...") },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = IndigoPrimary,
                        unfocusedBorderColor = borderColor,
                        focusedContainerColor = Color.Black.copy(alpha = 0.05f),
                        unfocusedContainerColor = Color.Black.copy(alpha = 0.05f)
                    ),
                    singleLine = true
                )

                IconButton(
                    onClick = {
                        if (manager.isLoggedIn) {
                            coroutineScope.launch {
                                try {
                                    val c = manager.createComment(post.id, newCommentText.trim())
                                    comments.add(c)
                                    newCommentText = ""
                                } catch (e: Exception) {
                                    Toast.makeText(context, e.message ?: "Error al publicar", Toast.LENGTH_SHORT).show()
                                }
                            }
                        } else {
                            onLoginRequired()
                        }
                    },
                    enabled = newCommentText.isNotBlank(),
                    modifier = Modifier
                        .size(40.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(if (newCommentText.isNotBlank()) IndigoPrimary else Color.Gray.copy(alpha = 0.5f))
                ) {
                    Icon(
                        imageVector = Icons.Default.Send,
                        contentDescription = "Enviar",
                        tint = Color.White,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
        }
    }
}

@Composable
fun CommentRowView(
    comment: Comment,
    manager: SupabaseManager
) {
    val isDark = isSystemInDarkTheme()
    val bgColor = if (isDark) CardDark else CardLight
    val borderColor = if (isDark) BorderDark else BorderLight
    val coroutineScope = rememberCoroutineScope()
    val context = LocalContext.current

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(bgColor)
            .border(1.dp, borderColor, RoundedCornerShape(12.dp))
            .padding(12.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth()
        ) {
            if (comment.authorAvatar != null) {
                SubcomposeAsyncImage(
                    model = comment.authorAvatar,
                    contentDescription = null,
                    modifier = Modifier
                        .size(24.dp)
                        .clip(CircleShape),
                    loading = { CircleAvatarPlaceholder(comment.initials, size = 24.dp, textSize = 10) },
                    error = { CircleAvatarPlaceholder(comment.initials, size = 24.dp, textSize = 10) }
                )
            } else {
                CircleAvatarPlaceholder(comment.initials, size = 24.dp, textSize = 10)
            }

            Spacer(modifier = Modifier.width(8.dp))

            Text(
                text = comment.authorName,
                fontWeight = FontWeight.Bold,
                fontSize = 12.sp,
                color = MaterialTheme.colorScheme.onBackground,
                modifier = Modifier.weight(1f)
            )

            Text(
                text = comment.formattedDate,
                fontSize = 10.sp,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
            )

            Spacer(modifier = Modifier.width(4.dp))

            IconButton(
                onClick = {
                    coroutineScope.launch {
                        try {
                            manager.reportComment(comment.id, "Spam/Comentario ofensivo")
                            Toast.makeText(context, "Comentario reportado", Toast.LENGTH_SHORT).show()
                        } catch (e: Exception) {
                            Toast.makeText(context, e.message, Toast.LENGTH_SHORT).show()
                        }
                    }
                },
                modifier = Modifier.size(20.dp)
            ) {
                Icon(Icons.Default.Warning, contentDescription = "Reportar", tint = Color.Red.copy(alpha = 0.5f), modifier = Modifier.size(12.dp))
            }
        }

        Spacer(modifier = Modifier.height(6.dp))

        Text(
            text = comment.content,
            fontSize = 13.sp,
            color = MaterialTheme.colorScheme.onBackground,
            modifier = Modifier.padding(start = 32.dp)
        )
    }
}
