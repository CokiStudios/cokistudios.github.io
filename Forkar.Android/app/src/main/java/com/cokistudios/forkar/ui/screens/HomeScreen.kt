package com.cokistudios.forkar.ui.screens

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
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.MailOutline
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Share
import com.cokistudios.forkar.ui.components.LiquidGlassTopBar
import com.cokistudios.forkar.ui.components.ChannelBadge
import com.cokistudios.forkar.ui.components.InternalCsToolsSheet
import com.cokistudios.forkar.ui.theme.PurpleAccent
import com.cokistudios.forkar.BuildConfig
import com.cokistudios.forkar.R
import com.google.firebase.appdistribution.FirebaseAppDistribution
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.SubcomposeAsyncImage
import com.cokistudios.forkar.data.Category
import com.cokistudios.forkar.data.Post
import com.cokistudios.forkar.data.SupabaseManager
import com.cokistudios.forkar.ui.components.CircleAvatarPlaceholder
import com.cokistudios.forkar.ui.theme.BorderDark
import com.cokistudios.forkar.ui.theme.BorderLight
import com.cokistudios.forkar.ui.theme.CardDark
import com.cokistudios.forkar.ui.theme.CardLight
import com.cokistudios.forkar.ui.theme.IndigoPrimary
import com.cokistudios.forkar.ui.theme.PurpleAccent2
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    manager: SupabaseManager,
    onPostClick: (Post) -> Unit,
    onCreatePostClick: () -> Unit,
    onLoginRequired: () -> Unit,
    onNavigateToCSMS: () -> Unit = {}
) {
    var posts = remember { mutableStateListOf<Post>() }
    var categories = remember { mutableStateListOf<Category>() }
    var selectedCategory by remember { mutableStateOf<Category?>(null) }
    var searchQuery by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var showInternalTools by remember { mutableStateOf(false) }
    var internalTabSelected by remember { androidx.compose.runtime.mutableIntStateOf(0) } // 0: Muro Interno CS, 1: Feed Público

    val coroutineScope = rememberCoroutineScope()
    val isDark = isSystemInDarkTheme()

    val loadData = {
        coroutineScope.launch {
            isLoading = true
            try {
                val catList = manager.fetchCategories()
                categories.clear()
                categories.addAll(catList)

                val postList = manager.fetchPosts(
                    categoryId = selectedCategory?.id,
                    query = searchQuery.ifBlank { null }
                )
                posts.clear()
                posts.addAll(postList)
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                isLoading = false
            }
        }
    }

    LaunchedEffect(selectedCategory, searchQuery) {
        val postList = manager.fetchPosts(
            categoryId = selectedCategory?.id,
            query = searchQuery.ifBlank { null }
        )
        posts.clear()
        posts.addAll(postList)
    }

    LaunchedEffect(Unit) {
        loadData()
    }

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            LiquidGlassTopBar(
                title = when {
                    BuildConfig.IS_INTERNAL_CS -> "Forkar CS"
                    BuildConfig.IS_QA -> "Forkar QA"
                    else -> "Forkar"
                },
                subtitle = when {
                    BuildConfig.IS_INTERNAL_CS -> "Red Social Interna Coki Studios"
                    BuildConfig.IS_QA -> "Canal de Pruebas & Feedback"
                    else -> "Comunidad Coki Studios"
                },
                icon = Icons.Default.Home,
                iconColor = if (BuildConfig.IS_INTERNAL_CS) Color(0xFFA78BFA) else IndigoPrimary,
                actions = {
                    ChannelBadge(
                        onClick = {
                            if (BuildConfig.IS_INTERNAL_CS) {
                                showInternalTools = true
                            } else if (BuildConfig.IS_QA) {
                                try {
                                    FirebaseAppDistribution.getInstance().startFeedback(R.string.additional_form_text)
                                } catch (e: Exception) {
                                    e.printStackTrace()
                                }
                            }
                        }
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    IconButton(onClick = onNavigateToCSMS) {
                        Box(contentAlignment = Alignment.TopEnd) {
                            Icon(
                                imageVector = Icons.Default.Email,
                                contentDescription = "CSMS Chat",
                                tint = PurpleAccent,
                                modifier = Modifier.size(24.dp)
                            )
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .clip(CircleShape)
                                    .background(Color(0xFF10B981))
                            )
                        }
                    }
                }
            )
        },


        floatingActionButton = {
            FloatingActionButton(
                onClick = {
                    if (manager.isLoggedIn) {
                        onCreatePostClick()
                    } else {
                        onLoginRequired()
                    }
                },
                containerColor = IndigoPrimary,
                contentColor = Color.White,
                shape = CircleShape
            ) {
                Icon(Icons.Default.Add, contentDescription = "Crear publicación")
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Internal CS Social Feed Switcher
            if (BuildConfig.IS_INTERNAL_CS) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 4.dp)
                        .clip(RoundedCornerShape(14.dp))
                        .background(Color(0xFF1E1833))
                        .border(1.dp, Color(0xFF8B5CF6).copy(alpha = 0.4f), RoundedCornerShape(14.dp))
                        .padding(3.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(11.dp))
                            .background(if (internalTabSelected == 0) Color(0xFF7C3AED) else Color.Transparent)
                            .clickable { internalTabSelected = 0 }
                            .padding(vertical = 7.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Lock, contentDescription = null, tint = Color.White, modifier = Modifier.size(13.dp))
                            Spacer(modifier = Modifier.width(5.dp))
                            Text("Muro Interno CS", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .clip(RoundedCornerShape(11.dp))
                            .background(if (internalTabSelected == 1) Color(0xFF7C3AED) else Color.Transparent)
                            .clickable { internalTabSelected = 1 }
                            .padding(vertical = 7.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Share, contentDescription = null, tint = Color.White.copy(alpha = 0.8f), modifier = Modifier.size(13.dp))
                            Spacer(modifier = Modifier.width(5.dp))
                            Text("Feed Global", color = Color.White.copy(alpha = 0.8f), fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }

            // Search Bar
            SearchBarView(
                query = searchQuery,
                onQueryChange = { searchQuery = it }
            )

            // Categories horizontal list
            LazyRow(
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                item {
                    val isSelected = selectedCategory == null
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(20.dp))
                            .background(if (isSelected) IndigoPrimary else if (isDark) CardDark else CardLight)
                            .border(
                                1.dp,
                                if (isSelected) Color.Transparent else if (isDark) BorderDark else BorderLight,
                                RoundedCornerShape(20.dp)
                            )
                            .clickable { selectedCategory = null }
                            .padding(vertical = 8.dp, horizontal = 16.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "Todos",
                            color = if (isSelected) Color.White else MaterialTheme.colorScheme.onBackground,
                            fontWeight = FontWeight.Bold,
                            fontSize = 13.sp
                        )
                    }
                }

                items(categories) { category ->
                    val isSelected = selectedCategory?.id == category.id
                    val catColor = try {
                        Color(android.graphics.Color.parseColor(category.color))
                    } catch (e: Exception) {
                        IndigoPrimary
                    }

                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(20.dp))
                            .background(if (isSelected) catColor else if (isDark) CardDark else CardLight)
                            .border(
                                1.dp,
                                if (isSelected) Color.Transparent else if (isDark) BorderDark else BorderLight,
                                RoundedCornerShape(20.dp)
                            )
                            .clickable { selectedCategory = category }
                            .padding(vertical = 8.dp, horizontal = 16.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .clip(CircleShape)
                                    .background(catColor)
                            )
                            Text(
                                text = category.name,
                                color = if (isSelected) Color.White else MaterialTheme.colorScheme.onBackground,
                                fontWeight = FontWeight.Bold,
                                fontSize = 13.sp
                            )
                        }
                    }
                }
            }

            // Feed Content
            if (isLoading && posts.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = IndigoPrimary)
                }
            } else if (posts.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Text(
                            text = "No hay publicaciones",
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp,
                            color = MaterialTheme.colorScheme.onBackground
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Sé el primero en compartir algo en Forkar.",
                            fontSize = 14.sp,
                            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                        )
                    }
                }
            } else {
                val filteredPosts = remember(posts, internalTabSelected) {
                    when {
                        BuildConfig.IS_INTERNAL_CS && internalTabSelected == 0 -> {
                            val internalList = posts.filter { post ->
                                post.content.contains("[🔒 CS Internal]") ||
                                post.title.contains("[CS]") ||
                                post.content.contains("#cs-internal") ||
                                post.content.contains("#dev-builds") ||
                                post.content.contains("#anuncios")
                            }
                            if (internalList.isNotEmpty()) internalList else posts
                        }
                        BuildConfig.IS_INTERNAL_CS && internalTabSelected == 1 -> {
                            posts.filter { !it.content.contains("[🔒 CS Internal]") }
                        }
                        !BuildConfig.IS_INTERNAL_CS -> {
                            posts.filter { !it.content.contains("[🔒 CS Internal]") && !it.content.contains("#cs-internal") }
                        }
                        else -> posts
                    }
                }

                LazyColumn(
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.fillMaxSize()
                ) {
                    items(filteredPosts) { post ->
                        PostCardView(
                            post = post,
                            onClick = { onPostClick(post) }
                        )
                    }
                }
            }

            if (showInternalTools) {
                InternalCsToolsSheet(
                    manager = manager,
                    onDismiss = { showInternalTools = false },
                    onNavigateToCSMS = onNavigateToCSMS
                )
            }
        }
    }
}

@Composable
fun SearchBarView(
    query: String,
    onQueryChange: (String) -> Unit
) {
    val isDark = isSystemInDarkTheme()
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        placeholder = { Text("Buscar en Forkar...") },
        leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(Icons.Default.Clear, contentDescription = "Limpiar")
                }
            }
        },
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        shape = RoundedCornerShape(12.dp),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = IndigoPrimary,
            unfocusedBorderColor = if (isDark) BorderDark else BorderLight,
            focusedContainerColor = if (isDark) CardDark else CardLight,
            unfocusedContainerColor = if (isDark) CardDark else CardLight
        ),
        singleLine = true
    )
}

@Composable
fun PostCardView(
    post: Post,
    onClick: () -> Unit
) {
    val isDark = isSystemInDarkTheme()
    val bgColor = if (isDark) CardDark else CardLight
    val borderColor = if (isDark) BorderDark else BorderLight

    val catColor = try {
        Color(android.graphics.Color.parseColor(post.category?.color ?: "#4f46e5"))
    } catch (e: Exception) {
        IndigoPrimary
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(bgColor)
            .border(1.dp, borderColor, RoundedCornerShape(16.dp))
            .clickable { onClick() }
            .padding(16.dp)
    ) {
        // Header
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth()
        ) {
            if (post.authorAvatar != null) {
                SubcomposeAsyncImage(
                    model = post.authorAvatar,
                    contentDescription = null,
                    modifier = Modifier
                        .size(32.dp)
                        .clip(CircleShape),
                    loading = { CircleAvatarPlaceholder(post.initials) },
                    error = { CircleAvatarPlaceholder(post.initials) }
                )
            } else {
                CircleAvatarPlaceholder(post.initials, size = 32.dp)
            }

            Spacer(modifier = Modifier.width(10.dp))

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = post.authorName,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 13.sp,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Text(
                    text = post.formattedDate,
                    fontSize = 11.sp,
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
                )
            }

            // Category tag
            if (post.content.contains("[🔒 CS Internal]") || post.content.contains("#cs-internal")) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(8.dp))
                        .background(Color(0x338B5CF6))
                        .padding(horizontal = 6.dp, vertical = 3.dp)
                ) {
                    Text(
                        text = "🔒 CS Team",
                        color = Color(0xFFC084FC),
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
                Spacer(modifier = Modifier.width(6.dp))
            }
            if (post.category != null) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(10.dp))
                        .background(catColor.copy(alpha = 0.15f))
                        .padding(vertical = 4.dp, horizontal = 10.dp)
                ) {
                    Text(
                        text = post.category.name,
                        color = catColor,
                        fontWeight = FontWeight.Bold,
                        fontSize = 10.sp
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Body
        Text(
            text = post.title,
            fontWeight = FontWeight.Bold,
            fontSize = 16.sp,
            color = MaterialTheme.colorScheme.onBackground,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = post.content,
            fontSize = 13.sp,
            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f),
            maxLines = 3,
            overflow = TextOverflow.Ellipsis
        )

        // Photo / Media Attachment preview
        if (!post.imageUrl.isNullOrBlank()) {
            Spacer(modifier = Modifier.height(10.dp))
            SubcomposeAsyncImage(
                model = post.imageUrl,
                contentDescription = "Post Image",
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
                    .clip(RoundedCornerShape(12.dp)),
                contentScale = androidx.compose.ui.layout.ContentScale.Crop,
                loading = {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(if (isDark) Color(0xFF1E293B) else Color(0xFFE2E8F0)),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(
                            color = IndigoPrimary,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                },
                error = {
                    // Fallback silently if image fails to load
                }
            )
        }

        Spacer(modifier = Modifier.height(12.dp))
        Divider(color = borderColor)
        Spacer(modifier = Modifier.height(12.dp))

        // Stats Footer
        Row(
            horizontalArrangement = Arrangement.spacedBy(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.FavoriteBorder,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                )
                Text(
                    text = "${post.likesCount}",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                )
            }

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.MailOutline,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                )
                Text(
                    text = "${post.commentsCount}",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                )
            }
        }
    }
}
