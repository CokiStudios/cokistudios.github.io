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
import androidx.compose.material.icons.filled.MailOutline
import androidx.compose.material.icons.filled.Search
import com.cokistudios.forkar.ui.components.LiquidGlassTopBar
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
    onLoginRequired: () -> Unit
) {
    var posts = remember { mutableStateListOf<Post>() }
    var categories = remember { mutableStateListOf<Category>() }
    var selectedCategory by remember { mutableStateOf<Category?>(null) }
    var searchQuery by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }

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
                title = "Forkar",
                subtitle = "Comunidad Coki Studios",
                icon = Icons.Default.Home,
                iconColor = IndigoPrimary
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
                LazyColumn(
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.fillMaxSize()
                ) {
                    items(posts) { post ->
                        PostCardView(
                            post = post,
                            onClick = { onPostClick(post) }
                        )
                    }
                }
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
