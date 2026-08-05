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
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
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
import com.cokistudios.forkar.data.Category
import com.cokistudios.forkar.data.SupabaseManager
import com.cokistudios.forkar.ui.components.PrimaryButton
import com.cokistudios.forkar.ui.theme.BorderDark
import com.cokistudios.forkar.ui.theme.BorderLight
import com.cokistudios.forkar.ui.theme.CardDark
import com.cokistudios.forkar.ui.theme.CardLight
import com.cokistudios.forkar.ui.theme.IndigoPrimary
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreatePostScreen(
    manager: SupabaseManager,
    onBack: () -> Unit
) {
    val categories = remember { mutableStateListOf<Category>() }
    var selectedCategory by remember { mutableStateOf<Category?>(null) }
    var title by remember { mutableStateOf("") }
    var content by remember { mutableStateOf("") }
    var isLoadingCategories by remember { mutableStateOf(false) }
    var isPublishing by remember { mutableStateOf(false) }

    val coroutineScope = rememberCoroutineScope()
    val context = LocalContext.current
    val isDark = isSystemInDarkTheme()

    LaunchedEffect(Unit) {
        coroutineScope.launch {
            isLoadingCategories = true
            try {
                val list = manager.fetchCategories()
                categories.clear()
                categories.addAll(list)
                if (list.isNotEmpty()) {
                    selectedCategory = list.first()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                isLoadingCategories = false
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Nueva Publicación", fontSize = 18.sp, fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.Close, contentDescription = "Cancelar")
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
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Selecciona una categoría",
                fontWeight = FontWeight.SemiBold,
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.onBackground
            )

            // Category selector list
            if (isLoadingCategories) {
                CircularProgressIndicator(color = IndigoPrimary)
            } else {
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
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
            }

            OutlinedTextField(
                value = title,
                onValueChange = { title = it },
                placeholder = { Text("Título de tu publicación") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            OutlinedTextField(
                value = content,
                onValueChange = { content = it },
                placeholder = { Text("¿De qué quieres hablar?") },
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                shape = RoundedCornerShape(12.dp)
            )

            PrimaryButton(
                text = if (isPublishing) "Publicando..." else "Publicar",
                onClick = {
                    val catId = selectedCategory?.id ?: return@PrimaryButton
                    coroutineScope.launch {
                        isPublishing = true
                        try {
                            manager.createPost(title.trim(), content.trim(), catId)
                            Toast.makeText(context, "Publicación creada", Toast.LENGTH_SHORT).show()
                            onBack()
                        } catch (e: Exception) {
                            Toast.makeText(context, e.message ?: "Error al publicar", Toast.LENGTH_SHORT).show()
                        } finally {
                            isPublishing = false
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = title.isNotBlank() && content.isNotBlank() && selectedCategory != null && !isPublishing
            )
        }
    }
}
