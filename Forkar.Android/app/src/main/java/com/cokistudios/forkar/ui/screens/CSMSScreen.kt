package com.cokistudios.forkar.ui.screens

import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cokistudios.forkar.data.SupabaseManager
import com.cokistudios.forkar.ui.components.LiquidGlassTopBar
import com.cokistudios.forkar.ui.theme.IndigoPrimary
import com.cokistudios.forkar.ui.theme.PurpleAccent
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

data class CSMSChat(
    val id: String,
    val name: String,
    val lastMessage: String,
    val time: String,
    val unreadCount: Int = 0,
    val isGroup: Boolean = true
)

data class CSMSMessage(
    val id: String,
    val senderName: String,
    val text: String,
    val time: String,
    val isMine: Boolean
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CSMSScreen(
    manager: SupabaseManager,
    onLoginRequired: () -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    var activeChat by remember { mutableStateOf<CSMSChat?>(null) }
    var typedMessage by remember { mutableStateOf("") }
    var showCreateGroupDialog by remember { mutableStateOf(false) }
    var newGroupName by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }

    val chatList = remember { mutableStateListOf<CSMSChat>() }
    val activeMessages = remember { mutableStateListOf<CSMSMessage>() }

    val loadRooms = {
        coroutineScope.launch {
            try {
                val dbRooms = manager.fetchChatRooms()
                chatList.clear()
                if (dbRooms.isEmpty()) {
                    chatList.addAll(
                        listOf(
                            CSMSChat("csms-global", "💬 Comunidad Coki Studios Global", "Canal de chat sincronizado Web, iOS & Android 2.0", "Ahora", 0, true),
                            CSMSChat("csms-eco", "🌿 Eco Hub Cota & Cundinamarca", "¿Quién se suma al reto de reciclar RAEE hoy?", "10:42 AM", 0, true)
                        )
                    )
                } else {
                    dbRooms.forEach { obj ->
                        chatList.add(
                            CSMSChat(
                                id = obj.optString("id"),
                                name = obj.optString("name", "Chat de Grupo"),
                                lastMessage = "Ver mensajes compartidos...",
                                time = "Reciente",
                                unreadCount = 0,
                                isGroup = obj.optBoolean("is_group", true)
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                // Fallback
            }
        }
    }

    val loadMessages = { roomId: String ->
        coroutineScope.launch {
            try {
                val dbMsgs = manager.fetchChatMessages(roomId)
                activeMessages.clear()
                if (dbMsgs.isEmpty()) {
                    activeMessages.addAll(
                        listOf(
                            CSMSMessage("m-1", "Sistema CSMS", "¡Bienvenido al canal sincronizado Web, iOS y Android!", "10:00 AM", false)
                        )
                    )
                } else {
                    dbMsgs.forEach { obj ->
                        val senderId = obj.optString("sender_id")
                        val isMine = (manager.currentUser?.id == senderId)
                        activeMessages.add(
                            CSMSMessage(
                                id = obj.optString("id"),
                                senderName = if (isMine) "Tú" else "Usuario",
                                text = obj.optString("content"),
                                time = "Enviado",
                                isMine = isMine
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                // Fallback
            }
        }
    }

    LaunchedEffect(Unit) {
        loadRooms()
    }

    // Auto sync messages every 3.5s when inside chat
    LaunchedEffect(activeChat) {
        val chat = activeChat
        if (chat != null) {
            loadMessages(chat.id)
            while (activeChat?.id == chat.id) {
                delay(3500)
                loadMessages(chat.id)
            }
        }
    }

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            if (activeChat == null) {
                LiquidGlassTopBar(
                    title = "CSMS",
                    subtitle = "Coki Messaging Service Sincronizado",
                    icon = Icons.Default.Email,
                    iconColor = PurpleAccent,
                    actions = {
                        IconButton(onClick = { loadRooms() }) {
                            Icon(Icons.Default.Refresh, contentDescription = "Recargar", tint = PurpleAccent)
                        }
                    }
                )
            } else {
                LiquidGlassTopBar(
                    title = activeChat?.name ?: "Chat CSMS",
                    subtitle = "Sincronizado en tiempo real",
                    icon = Icons.Default.ArrowBack,
                    iconColor = Color.White,
                    actions = {
                        IconButton(onClick = { activeChat = null }) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "Volver", tint = Color.White)
                        }
                    }
                )
            }
        },
        floatingActionButton = {
            if (activeChat == null) {
                FloatingActionButton(
                    onClick = {
                        if (!manager.isLoggedIn) {
                            onLoginRequired()
                        } else {
                            showCreateGroupDialog = !showCreateGroupDialog
                        }
                    },
                    containerColor = PurpleAccent,
                    contentColor = Color.White,
                    shape = CircleShape
                ) {
                    Icon(Icons.Default.Add, contentDescription = "Crear Grupo CSMS")
                }
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (activeChat == null) {
                // ── CHAT LIST VIEW ──
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 16.dp)
                ) {
                    // Create Group Banner Dialog
                    AnimatedVisibility(visible = showCreateGroupDialog) {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFF1E1B4B)),
                            border = androidx.compose.foundation.BorderStroke(1.2.dp, PurpleAccent.copy(alpha = 0.5f))
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("💬 Crear Nuevo Grupo CSMS Sincronizado", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 15.sp)
                                Spacer(modifier = Modifier.height(8.dp))
                                OutlinedTextField(
                                    value = newGroupName,
                                    onValueChange = { newGroupName = it },
                                    placeholder = { Text("Nombre del grupo (ej: Hackers Cota)") },
                                    modifier = Modifier.fillMaxWidth(),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedTextColor = Color.White,
                                        unfocusedTextColor = Color.White,
                                        focusedBorderColor = PurpleAccent,
                                        unfocusedBorderColor = Color.White.copy(alpha = 0.3f)
                                    )
                                )
                                Spacer(modifier = Modifier.height(10.dp))
                                Row(horizontalArrangement = Arrangement.End, modifier = Modifier.fillMaxWidth()) {
                                    IconButton(onClick = { showCreateGroupDialog = false }) {
                                        Text("Cancelar", color = Color.Gray, fontSize = 12.sp)
                                    }
                                    Spacer(modifier = Modifier.width(8.dp))
                                    IconButton(onClick = {
                                        if (newGroupName.isNotBlank()) {
                                            coroutineScope.launch {
                                                val success = manager.createGroupChat(newGroupName)
                                                if (success) {
                                                    Toast.makeText(context, "Grupo CSMS creado", Toast.LENGTH_SHORT).show()
                                                    loadRooms()
                                                }
                                                newGroupName = ""
                                                showCreateGroupDialog = false
                                            }
                                        }
                                    }) {
                                        Text("Crear", color = PurpleAccent, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                                    }
                                }
                            }
                        }
                    }

                    LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.padding(top = 8.dp)) {
                        items(chatList) { chat ->
                            Card(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        if (!manager.isLoggedIn) {
                                            onLoginRequired()
                                        } else {
                                            activeChat = chat
                                        }
                                    },
                                shape = RoundedCornerShape(18.dp),
                                colors = CardDefaults.cardColors(containerColor = Color(0xFF1E293B).copy(alpha = 0.85f)),
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF334155))
                            ) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(16.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(46.dp)
                                            .clip(CircleShape)
                                            .background(
                                                Brush.linearGradient(
                                                    listOf(PurpleAccent.copy(alpha = 0.4f), IndigoPrimary.copy(alpha = 0.2f))
                                                )
                                            )
                                            .border(1.2.dp, PurpleAccent.copy(alpha = 0.6f), CircleShape),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(
                                            text = chat.name.take(2).uppercase(),
                                            fontWeight = FontWeight.Black,
                                            color = Color.White,
                                            fontSize = 16.sp
                                        )
                                    }

                                    Spacer(modifier = Modifier.width(14.dp))

                                    Column(modifier = Modifier.weight(1f)) {
                                        Row(
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically,
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Text(
                                                text = chat.name,
                                                fontWeight = FontWeight.Bold,
                                                color = Color.White,
                                                fontSize = 15.sp
                                            )
                                            Text(
                                                text = chat.time,
                                                fontSize = 11.sp,
                                                color = Color(0xFF94A3B8)
                                            )
                                        }
                                        Spacer(modifier = Modifier.height(4.dp))
                                        Text(
                                            text = chat.lastMessage,
                                            fontSize = 13.sp,
                                            color = Color(0xFFCBD5E1),
                                            maxLines = 1
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                // ── CONVERSATION CHAT VIEW ──
                Column(
                    modifier = Modifier.fillMaxSize()
                ) {
                    LazyColumn(
                        modifier = Modifier
                            .weight(1f)
                            .padding(horizontal = 16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        items(activeMessages) { msg ->
                            val isMine = msg.isMine
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = if (isMine) Arrangement.End else Arrangement.Start
                            ) {
                                Box(
                                    modifier = Modifier
                                        .clip(
                                            RoundedCornerShape(
                                                topStart = 16.dp,
                                                topEnd = 16.dp,
                                                bottomStart = if (isMine) 16.dp else 2.dp,
                                                bottomEnd = if (isMine) 2.dp else 16.dp
                                            )
                                        )
                                        .background(
                                            if (isMine) {
                                                Brush.linearGradient(listOf(IndigoPrimary, PurpleAccent))
                                            } else {
                                                Brush.linearGradient(listOf(Color(0xFF1E293B), Color(0xFF0F172A)))
                                            }
                                        )
                                        .border(
                                            1.dp,
                                            if (isMine) PurpleAccent.copy(alpha = 0.6f) else Color(0xFF334155),
                                            RoundedCornerShape(16.dp)
                                        )
                                        .padding(horizontal = 14.dp, vertical = 10.dp)
                                ) {
                                    Column {
                                        if (!isMine) {
                                            Text(
                                                text = msg.senderName,
                                                fontSize = 11.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = PurpleAccent
                                            )
                                            Spacer(modifier = Modifier.height(2.dp))
                                        }
                                        Text(
                                            text = msg.text,
                                            fontSize = 14.sp,
                                            color = Color.White
                                        )
                                        Spacer(modifier = Modifier.height(4.dp))
                                        Text(
                                            text = msg.time,
                                            fontSize = 9.sp,
                                            color = Color.White.copy(alpha = 0.6f),
                                            modifier = Modifier.align(Alignment.End)
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Bottom Composer Bar
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Color(0xFF0F172A))
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedTextField(
                            value = typedMessage,
                            onValueChange = { typedMessage = it },
                            placeholder = { Text("Escribe un mensaje CSMS...") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(24.dp),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White,
                                focusedBorderColor = PurpleAccent,
                                unfocusedBorderColor = Color.White.copy(alpha = 0.3f)
                            )
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        IconButton(
                            onClick = {
                                val text = typedMessage.trim()
                                val chat = activeChat
                                if (text.isNotBlank() && chat != null) {
                                    coroutineScope.launch {
                                        manager.sendChatMessage(chat.id, text)
                                        typedMessage = ""
                                        loadMessages(chat.id)
                                    }
                                }
                            },
                            modifier = Modifier
                                .size(46.dp)
                                .clip(CircleShape)
                                .background(PurpleAccent)
                        ) {
                            Icon(Icons.Default.Send, contentDescription = "Enviar", tint = Color.White)
                        }
                    }
                }
            }
        }
    }
}
