package com.cokistudios.csms.meta

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cokistudios.csms.meta.data.ChatMessage
import com.cokistudios.csms.meta.data.SupabaseManager
import com.cokistudios.csms.meta.ui.theme.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * PanelActivity — Pantalla de chat Compose que se muestra como panel 2D
 * dentro del entorno 3D de ImmersiveActivity en Meta Horizon OS.
 *
 * En Meta Spatial SDK, esta Activity se registra como un SpatialPanel
 * flotante en el espacio 3D con posición y tamaño definidos en ImmersiveActivity.
 * El usuario puede mover, escalar y anclar el panel usando los controladores del Quest.
 *
 * Para activar el modo full Meta Spatial SDK:
 *   - En el Manifest, agrega: android:process=":panel" a esta Activity
 *   - En ImmersiveActivity, registra:
 *     registerPanel(PanelRegistration(width = 800, height = 600, PanelActivity::class) {
 *         intent = Intent(context, PanelActivity::class.java)
 *     })
 */
class PanelActivity : ComponentActivity() {

    companion object {
        const val EXTRA_ROOM_ID = "extra_room_id"
        const val EXTRA_ROOM_NAME = "extra_room_name"
    }

    private lateinit var manager: SupabaseManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        manager = SupabaseManager.getInstance(this)

        val roomId = intent.getStringExtra(EXTRA_ROOM_ID) ?: ""
        val roomName = intent.getStringExtra(EXTRA_ROOM_NAME) ?: "Chat"

        setContent {
            CSMSMetaTheme {
                MetaChatScreen(
                    manager = manager,
                    roomId = roomId,
                    roomName = roomName,
                    onBack = { finish() }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MetaChatScreen(
    manager: SupabaseManager,
    roomId: String,
    roomName: String,
    onBack: () -> Unit
) {
    val scope = rememberCoroutineScope()
    var messages by remember { mutableStateOf<List<ChatMessage>>(emptyList()) }
    var messageInput by remember { mutableStateOf("") }
    var errorMsg by remember { mutableStateOf<String?>(null) }
    val listState = rememberLazyListState()

    // Auto-refresh every 4 seconds
    LaunchedEffect(roomId) {
        while (true) {
            try {
                val fetched = manager.fetchMessages(roomId)
                if (fetched != messages) {
                    messages = fetched
                    if (fetched.isNotEmpty()) listState.animateScrollToItem(fetched.lastIndex)
                }
            } catch (e: Exception) {
                errorMsg = e.message
            }
            delay(4000L)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(MetaMidnight, MetaNavy)))
    ) {
        // Top bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(GlassSurface)
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            IconButton(onClick = onBack) {
                Icon(Icons.Default.ArrowBack, contentDescription = "Volver",
                    tint = TextPrimary)
            }

            // Room icon
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .background(Brush.linearGradient(listOf(MetaIndigo, MetaPurple)), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(roomName.firstOrNull()?.uppercase() ?: "C", color = TextPrimary,
                    fontWeight = FontWeight.Bold, fontSize = 14.sp)
            }

            Column(modifier = Modifier.weight(1f)) {
                Text(roomName, color = TextPrimary, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                Text("${messages.size} mensajes · En vivo", color = MetaCyan, fontSize = 11.sp)
            }
        }

        // Messages
        LazyColumn(
            state = listState,
            modifier = Modifier.weight(1f).padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
            contentPadding = PaddingValues(vertical = 16.dp)
        ) {
            items(messages) { msg ->
                val isMe = msg.senderId == manager.currentUser?.id
                MetaChatBubble(msg = msg, isMe = isMe)
            }
        }

        // Error
        errorMsg?.let {
            Text(it, color = UnreadBadge, fontSize = 12.sp,
                modifier = Modifier.padding(horizontal = 16.dp))
        }

        // Input
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(GlassSurface)
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            OutlinedTextField(
                value = messageInput,
                onValueChange = { messageInput = it },
                placeholder = { Text("Escribe un mensaje…", color = TextMuted) },
                modifier = Modifier.weight(1f),
                maxLines = 3,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = TextPrimary,
                    unfocusedTextColor = TextPrimary,
                    focusedBorderColor = MetaIndigo,
                    unfocusedBorderColor = GlassBorder,
                    cursorColor = MetaCyan
                ),
                shape = RoundedCornerShape(14.dp)
            )

            IconButton(
                onClick = {
                    val text = messageInput.trim()
                    if (text.isNotBlank()) {
                        scope.launch {
                            try {
                                manager.sendMessage(roomId, text)
                                messageInput = ""
                                messages = manager.fetchMessages(roomId)
                                if (messages.isNotEmpty()) listState.animateScrollToItem(messages.lastIndex)
                            } catch (e: Exception) { errorMsg = e.message }
                        }
                    }
                },
                modifier = Modifier
                    .size(50.dp)
                    .background(
                        Brush.linearGradient(listOf(MetaIndigo, MetaPurple)),
                        RoundedCornerShape(14.dp)
                    )
            ) {
                Icon(Icons.Default.Send, contentDescription = "Enviar", tint = TextPrimary)
            }
        }
    }
}

@Composable
private fun MetaChatBubble(msg: ChatMessage, isMe: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isMe) Arrangement.End else Arrangement.Start,
        verticalAlignment = Alignment.Bottom
    ) {
        if (!isMe) {
            // Avatar
            Box(
                modifier = Modifier
                    .size(30.dp)
                    .background(Brush.linearGradient(listOf(MetaIndigo, MetaPurple)), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(msg.initials, color = TextPrimary, fontSize = 11.sp, fontWeight = FontWeight.Bold)
            }
            Spacer(Modifier.width(6.dp))
        }

        Column(horizontalAlignment = if (isMe) Alignment.End else Alignment.Start) {
            if (!isMe && msg.senderName != null) {
                Text(msg.senderName, color = MetaCyan, fontSize = 11.sp,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp))
            }
            Box(
                modifier = Modifier
                    .background(
                        if (isMe)
                            Brush.linearGradient(listOf(MetaIndigo, MetaPurple))
                        else
                            Brush.linearGradient(listOf(GlassSurface, GlassDark)),
                        RoundedCornerShape(
                            topStart = 18.dp, topEnd = 18.dp,
                            bottomStart = if (isMe) 18.dp else 4.dp,
                            bottomEnd = if (isMe) 4.dp else 18.dp
                        )
                    )
                    .padding(horizontal = 16.dp, vertical = 10.dp)
                    .widthIn(max = 340.dp)
            ) {
                Text(msg.content, color = TextPrimary, fontSize = 14.sp, lineHeight = 20.sp)
            }
        }

        if (isMe) {
            Spacer(Modifier.width(6.dp))
            Box(
                modifier = Modifier
                    .size(30.dp)
                    .background(Brush.linearGradient(listOf(MetaPurple, MetaIndigo)), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(msg.initials, color = TextPrimary, fontSize = 11.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
}
