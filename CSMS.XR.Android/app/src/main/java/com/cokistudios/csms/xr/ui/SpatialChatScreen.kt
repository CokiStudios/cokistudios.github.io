package com.cokistudios.csms.xr.ui

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cokistudios.csms.xr.data.ChatMessage
import com.cokistudios.csms.xr.data.ChatRoom
import com.cokistudios.csms.xr.data.SupabaseManager
import com.cokistudios.csms.xr.ui.theme.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * SpatialChatScreen — Panel principal de conversación del chat.
 *
 * En Android XR este Composable se coloca como panel central (`SpatialPanel`)
 * en el espacio 3D, centrado frente al usuario con profundidad Z.
 * Incluye modo Full Space para inmersión total (pantalla completa espacial).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SpatialChatScreen(
    manager: SupabaseManager,
    room: ChatRoom?,
    isFullSpace: Boolean = false,
    onRequestFullSpace: () -> Unit = {},
    onExitFullSpace: () -> Unit = {}
) {
    val scope = rememberCoroutineScope()
    var messages by remember { mutableStateOf<List<ChatMessage>>(emptyList()) }
    var isLoading by remember { mutableStateOf(false) }
    var messageInput by remember { mutableStateOf("") }
    var errorMsg by remember { mutableStateOf<String?>(null) }
    val listState = rememberLazyListState()

    // Auto-refresh every 5 seconds
    LaunchedEffect(room?.id) {
        if (room == null) return@LaunchedEffect
        while (true) {
            try {
                val fetched = manager.fetchMessages(room.id)
                if (fetched != messages) {
                    messages = fetched
                    if (fetched.isNotEmpty()) {
                        listState.animateScrollToItem(fetched.lastIndex)
                    }
                }
            } catch (e: Exception) {
                errorMsg = e.message
            }
            delay(5000L)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(CokiMidnight, CokiNavy, CokiDeepBlue)
                )
            )
    ) {
        // Top bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(GlassSurface)
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            if (room != null) {
                Column {
                    Text(
                        room.name,
                        color = TextPrimary,
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp
                    )
                    Text(
                        "${messages.size} mensajes",
                        color = TextSecondary,
                        fontSize = 11.sp
                    )
                }
            } else {
                Text("Selecciona una sala →", color = TextMuted, fontSize = 14.sp)
            }

            // Full Space toggle button
            if (room != null) {
                OutlinedButton(
                    onClick = { if (isFullSpace) onExitFullSpace() else onRequestFullSpace() },
                    border = ButtonDefaults.outlinedButtonBorder.copy(),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = CokiCyan)
                ) {
                    Text(
                        if (isFullSpace) "⬡ Salir del espacio" else "⬡ Espacio completo",
                        fontSize = 11.sp
                    )
                }
            }
        }

        // Messages list
        if (room == null) {
            // Empty state
            Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("⬡", fontSize = 48.sp, color = CokiIndigo.copy(alpha = 0.4f))
                    Spacer(Modifier.height(12.dp))
                    Text("Selecciona una sala de chat", color = TextSecondary, fontSize = 16.sp)
                    Text("desde el panel de la izquierda", color = TextMuted, fontSize = 13.sp)
                }
            }
        } else {
            LazyColumn(
                state = listState,
                modifier = Modifier.weight(1f).padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                contentPadding = PaddingValues(vertical = 12.dp)
            ) {
                items(messages) { msg ->
                    val isMe = msg.senderId == manager.currentUser?.id
                    ChatBubble(msg = msg, isMe = isMe)
                }
            }
        }

        // Error banner
        AnimatedVisibility(visible = errorMsg != null) {
            Text(
                errorMsg ?: "",
                color = UnreadBadge,
                fontSize = 12.sp,
                modifier = Modifier.padding(horizontal = 16.dp)
            )
        }

        // Input bar
        if (room != null) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(GlassSurface)
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedTextField(
                    value = messageInput,
                    onValueChange = { messageInput = it },
                    placeholder = { Text("Escribe un mensaje…", color = TextMuted) },
                    modifier = Modifier.weight(1f),
                    maxLines = 4,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = TextPrimary,
                        unfocusedTextColor = TextPrimary,
                        focusedBorderColor = CokiIndigo,
                        unfocusedBorderColor = GlassBorder,
                        cursorColor = CokiCyan
                    ),
                    shape = RoundedCornerShape(12.dp)
                )

                IconButton(
                    onClick = {
                        val text = messageInput.trim()
                        if (text.isNotBlank()) {
                            scope.launch {
                                try {
                                    manager.sendMessage(room.id, text)
                                    messageInput = ""
                                    messages = manager.fetchMessages(room.id)
                                    if (messages.isNotEmpty()) {
                                        listState.animateScrollToItem(messages.lastIndex)
                                    }
                                } catch (e: Exception) {
                                    errorMsg = e.message
                                }
                            }
                        }
                    },
                    modifier = Modifier
                        .size(48.dp)
                        .background(
                            Brush.linearGradient(listOf(CokiIndigo, CokiPurple)),
                            RoundedCornerShape(12.dp)
                        )
                ) {
                    Icon(Icons.Default.Send, contentDescription = "Enviar",
                        tint = TextPrimary)
                }
            }
        }
    }
}

@Composable
private fun ChatBubble(msg: ChatMessage, isMe: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isMe) Arrangement.End else Arrangement.Start,
        verticalAlignment = Alignment.Bottom
    ) {
        if (!isMe) {
            XRAvatarInitials(initials = msg.initials, size = 28.dp, textSize = 11)
            Spacer(Modifier.width(6.dp))
        }

        Column(
            horizontalAlignment = if (isMe) Alignment.End else Alignment.Start
        ) {
            if (!isMe && msg.senderName != null) {
                Text(msg.senderName, color = CokiCyan, fontSize = 11.sp,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp))
            }
            Box(
                modifier = Modifier
                    .background(
                        if (isMe) Brush.linearGradient(listOf(CokiIndigo, CokiPurple))
                        else Brush.linearGradient(listOf(GlassSurface, GlassDark)),
                        RoundedCornerShape(
                            topStart = 16.dp, topEnd = 16.dp,
                            bottomStart = if (isMe) 16.dp else 4.dp,
                            bottomEnd = if (isMe) 4.dp else 16.dp
                        )
                    )
                    .padding(horizontal = 14.dp, vertical = 10.dp)
                    .widthIn(max = 360.dp)
            ) {
                Text(msg.content, color = TextPrimary, fontSize = 14.sp)
            }
        }

        if (isMe) {
            Spacer(Modifier.width(6.dp))
            XRAvatarInitials(initials = msg.initials, size = 28.dp, textSize = 11)
        }
    }
}
