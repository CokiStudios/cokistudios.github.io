package com.cokistudios.forkar.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.SubcomposeAsyncImage
import com.cokistudios.forkar.data.Post
import com.cokistudios.forkar.data.SupabaseManager
import com.cokistudios.forkar.ui.components.CircleAvatarPlaceholder
import com.cokistudios.forkar.ui.components.PrimaryButton
import com.cokistudios.forkar.ui.components.SecondaryButton
import com.cokistudios.forkar.ui.theme.IndigoPrimary
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    manager: SupabaseManager,
    onLoginClick: () -> Unit,
    onPostClick: (Post) -> Unit
) {
    val coroutineScope = rememberCoroutineScope()
    val currentUser = manager.currentUser

    var followersCount by remember { mutableStateOf(0) }
    var followingCount by remember { mutableStateOf(0) }
    val userPosts = remember { mutableStateListOf<Post>() }
    var isLoadingStats by remember { mutableStateOf(false) }

    val loadProfileData = {
        if (currentUser != null) {
            coroutineScope.launch {
                isLoadingStats = true
                try {
                    val stats = manager.getFollowStats(currentUser.id)
                    followersCount = stats.first
                    followingCount = stats.second

                    val list = manager.fetchPosts(userId = currentUser.id)
                    userPosts.clear()
                    userPosts.addAll(list)
                } catch (e: Exception) {
                    e.printStackTrace()
                } finally {
                    isLoadingStats = false
                }
            }
        }
    }

    LaunchedEffect(currentUser) {
        loadProfileData()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Mi Perfil", fontSize = 18.sp, fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    titleContentColor = MaterialTheme.colorScheme.onBackground
                )
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
                .padding(paddingValues)
        ) {
            if (currentUser == null) {
                // Non-logged-in placeholder
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    CircleAvatarPlaceholder(
                        initials = "?",
                        size = 80.dp,
                        textSize = 28
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Mi Perfil de Forkar",
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onBackground
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = "Inicia sesión para ver tus estadísticas, publicaciones y configurar tu cuenta.",
                        fontSize = 14.sp,
                        textAlign = TextAlign.Center,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                    PrimaryButton(
                        text = "Iniciar Sesión",
                        onClick = onLoginClick,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            } else {
                // Logged-in profile details
                val metadata = currentUser.userMetadata
                val displayName = metadata?.displayName ?: currentUser.email?.substringBefore("@") ?: "Usuario"
                val company = metadata?.company ?: "Coki Studios"
                val initials = displayName.firstOrNull()?.uppercase() ?: "?"

                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Header Stats
                    item {
                        Column(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            if (metadata?.avatarUrl != null || metadata?.picture != null) {
                                val url = metadata.avatarUrl ?: metadata.picture
                                SubcomposeAsyncImage(
                                    model = url,
                                    contentDescription = null,
                                    modifier = Modifier
                                        .size(80.dp)
                                        .clip(CircleShape),
                                    loading = { CircleAvatarPlaceholder(initials, size = 80.dp, textSize = 28) },
                                    error = { CircleAvatarPlaceholder(initials, size = 80.dp, textSize = 28) }
                                )
                            } else {
                                CircleAvatarPlaceholder(initials, size = 80.dp, textSize = 28)
                            }

                            Spacer(modifier = Modifier.height(12.dp))

                            Text(
                                text = displayName,
                                fontSize = 20.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onBackground
                            )

                            Text(
                                text = company,
                                fontSize = 13.sp,
                                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                            )

                            Spacer(modifier = Modifier.height(16.dp))

                            // Stats Counter
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceEvenly
                            ) {
                                ProfileStatItem(count = "${userPosts.size}", label = "Posts")
                                ProfileStatItem(count = "$followersCount", label = "Seguidores")
                                ProfileStatItem(count = "$followingCount", label = "Siguiendo")
                            }

                            Spacer(modifier = Modifier.height(16.dp))
                            Divider()
                            Spacer(modifier = Modifier.height(10.dp))
                        }
                    }

                    // User Posts list
                    if (isLoadingStats) {
                        item {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 20.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                CircularProgressIndicator(color = IndigoPrimary)
                            }
                        }
                    } else if (userPosts.isEmpty()) {
                        item {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 40.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = "No has publicado nada aún",
                                    fontSize = 14.sp,
                                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
                                )
                            }
                        }
                    } else {
                        items(userPosts) { post ->
                            PostCardView(post = post, onClick = { onPostClick(post) })
                        }
                    }

                    // Logout item
                    item {
                        Spacer(modifier = Modifier.height(20.dp))
                        SecondaryButton(
                            text = "Cerrar sesión",
                            onClick = { manager.logout() },
                            modifier = Modifier.fillMaxWidth()
                        )
                        Spacer(modifier = Modifier.height(40.dp))
                    }
                }
            }
        }
    }
}

@Composable
fun ProfileStatItem(
    count: String,
    label: String
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = count,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground
        )
        Text(
            text = label,
            fontSize = 12.sp,
            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
        )
    }
}
