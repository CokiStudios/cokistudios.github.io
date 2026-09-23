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
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import com.cokistudios.forkar.BuildConfig
import com.cokistudios.forkar.data.QALabManager
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.ui.text.font.FontFamily
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
    var isInternalPost by remember { mutableStateOf(BuildConfig.IS_INTERNAL_CS) }

    val coroutineScope = rememberCoroutineScope()
    val context = LocalContext.current
    val isDark = isSystemInDarkTheme()

    val qaManager = remember { if (BuildConfig.IS_QA) QALabManager.getInstance(context) else null }
    var isQaStagingPost by remember { mutableStateOf(qaManager?.tagQaPostsByDefault ?: true) }
    var simulatedAudioDuration by remember { mutableStateOf<Int?>(null) }

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

            if (BuildConfig.IS_INTERNAL_CS) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color(0xFF201938))
                        .border(1.dp, Color(0xFF8B5CF6).copy(alpha = 0.5f), RoundedCornerShape(12.dp))
                        .clickable { isInternalPost = !isInternalPost }
                        .padding(horizontal = 14.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Lock,
                        contentDescription = null,
                        tint = if (isInternalPost) Color(0xFFA78BFA) else Color.Gray,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(10.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Exclusivo para el equipo de Coki Studios",
                            fontWeight = FontWeight.Bold,
                            fontSize = 12.sp,
                            color = Color.White
                        )
                        Text(
                            text = if (isInternalPost) "Solo visible en el Muro Interno CS" else "Visible en el Feed Global de Forkar",
                            fontSize = 11.sp,
                            color = Color.White.copy(alpha = 0.6f)
                        )
                    }
                    Switch(
                        checked = isInternalPost,
                        onCheckedChange = { isInternalPost = it },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = Color.White,
                            checkedTrackColor = Color(0xFF7C3AED)
                        )
                    )
                }
            }

            if (BuildConfig.IS_QA) {
                // QA Staging Isolation Banner & Switch
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color(0xFF241C10))
                        .border(1.dp, Color(0xFFF59E0B).copy(alpha = 0.5f), RoundedCornerShape(12.dp))
                        .clickable { isQaStagingPost = !isQaStagingPost }
                        .padding(horizontal = 14.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("🧪", fontSize = 20.sp)
                    Spacer(modifier = Modifier.width(10.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Aislamiento de Staging QA",
                            fontWeight = FontWeight.Bold,
                            fontSize = 12.sp,
                            color = Color(0xFFF59E0B)
                        )
                        Text(
                            text = if (isQaStagingPost) "Etiquetado como [🧪 QA Test] (Aislado de Retail)" else "Publicación sin etiqueta de prueba",
                            fontSize = 11.sp,
                            color = Color.White.copy(alpha = 0.7f)
                        )
                    }
                    Switch(
                        checked = isQaStagingPost,
                        onCheckedChange = { isQaStagingPost = it },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = Color.White,
                            checkedTrackColor = Color(0xFFF59E0B)
                        )
                    )
                }

                // Experimental Feature: Audio Notes Simulator
                if (qaManager?.audioNotesExperimentEnabled == true) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(Color(0xFF1E1E26))
                            .border(1.dp, Color(0xFF38BDF8).copy(alpha = 0.4f), RoundedCornerShape(12.dp))
                            .padding(12.dp)
                    ) {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text("🎙️", fontSize = 16.sp)
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = "Función Experimental: Nota de Audio",
                                        color = Color(0xFF38BDF8),
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold
                                    )
                                }
                                Text(
                                    text = "QA LAB PREVIEW",
                                    fontSize = 9.sp,
                                    fontWeight = FontWeight.Black,
                                    color = Color(0xFF38BDF8),
                                    letterSpacing = 1.sp
                                )
                            }

                            if (simulatedAudioDuration == null) {
                                OutlinedButton(
                                    onClick = {
                                        simulatedAudioDuration = 18
                                        Toast.makeText(context, "Nota de voz de 18s simulada para prueba", Toast.LENGTH_SHORT).show()
                                    },
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(8.dp),
                                    colors = ButtonDefaults.outlinedButtonColors(
                                        contentColor = Color(0xFF38BDF8)
                                    )
                                ) {
                                    Icon(Icons.Default.PlayArrow, contentDescription = null, modifier = Modifier.size(16.dp))
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text("Simular Grabación de Audio (18s)", fontSize = 12.sp)
                                }
                            } else {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .background(Color(0x3338BDF8), RoundedCornerShape(8.dp))
                                        .padding(horizontal = 12.dp, vertical = 8.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(Icons.Default.PlayArrow, contentDescription = null, tint = Color(0xFF38BDF8), modifier = Modifier.size(18.dp))
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Text("|||ı|ı||ı|ı||||ı| 0:${simulatedAudioDuration}s", color = Color.White, fontSize = 12.sp, fontFamily = FontFamily.Monospace)
                                    }
                                    IconButton(
                                        onClick = { simulatedAudioDuration = null },
                                        modifier = Modifier.size(24.dp)
                                    ) {
                                        Icon(Icons.Default.Close, contentDescription = "Quitar audio", tint = Color.LightGray, modifier = Modifier.size(16.dp))
                                    }
                                }
                            }
                        }
                    }
                }
            }

            PrimaryButton(
                text = if (isPublishing) "Publicando..." else "Publicar",
                onClick = {
                    val catId = selectedCategory?.id ?: return@PrimaryButton
                    coroutineScope.launch {
                        isPublishing = true
                        try {
                            val prefix = when {
                                BuildConfig.IS_INTERNAL_CS && isInternalPost -> "[🔒 CS Internal] "
                                BuildConfig.IS_QA && isQaStagingPost -> "[🧪 QA Test] "
                                else -> ""
                            }
                            val audioSuffix = if (simulatedAudioDuration != null) {
                                "\n\n[🎙️ Audio Memo: 0:${simulatedAudioDuration}s]"
                            } else ""

                            val finalContent = "$prefix${content.trim()}$audioSuffix"
                            val finalTitle = if (BuildConfig.IS_QA && isQaStagingPost && !title.startsWith("[🧪")) {
                                "[🧪 QA] ${title.trim()}"
                            } else {
                                title.trim()
                            }

                            manager.createPost(finalTitle, finalContent, catId)
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
