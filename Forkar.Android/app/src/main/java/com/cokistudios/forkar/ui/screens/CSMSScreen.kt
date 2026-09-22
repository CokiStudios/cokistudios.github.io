package com.cokistudios.forkar.ui.screens

import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
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
    val isMine: Boolean,
    val mediaUrl: String? = null,
    val mediaType: String? = null
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
    var searchQuery by remember { mutableStateOf("") }

    // Dialogs
    var showCreateGroupDialog by remember { mutableStateOf(false) }
    var newGroupName by remember { mutableStateOf("") }
    var showCreateDmDialog by remember { mutableStateOf(false) }
    var dmTargetEmail by remember { mutableStateOf("") }

    // Media Attachments (Photos & Videos)
    var attachedUri by remember { mutableStateOf<Uri?>(null) }
    var isUploadingMedia by remember { mutableStateOf(false) }
    var isSendingMessage by remember { mutableStateOf(false) }

    val chatList = remember { mutableStateListOf<CSMSChat>() }
    val activeMessages = remember { mutableStateListOf<CSMSMessage>() }

    // Media Picker Launcher for Android
    val mediaPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        attachedUri = uri
    }

    val loadRooms: () -> Unit = {
        coroutineScope.launch {
            try {
                val dbRooms = manager.fetchChatRooms()
                chatList.clear()
                if (dbRooms.isEmpty()) {
                    chatList.addAll(
                        listOf(
                            CSMSChat(SupabaseManager.CSMS_COMMUNITY_GLOBAL_ID, "💬 Comunidad Coki Studios Global", "Canal de chat sincronizado Web, iOS, PC & Android", "Ahora", 0, true),
                            CSMSChat(SupabaseManager.CSMS_ECO_HUB_ID, "🌿 Eco Hub Cota & Cundinamarca", "¿Quién se suma al reto de reciclar RAEE hoy?", "10:42 AM", 0, true),
                            CSMSChat(SupabaseManager.CSMS_FORKAR_CARPOOL_ID, "🚗 Forkar Carpooling & Rutas", "Coordina viajes seguros y comparte trayectos ecológicos", "09:15 AM", 0, true)
                        )
                    )
                } else {
                    dbRooms.forEach { obj ->
                        val displayName = if (obj.has("displayName") && !obj.isNull("displayName") && obj.optString("displayName").isNotBlank()) {
                            obj.optString("displayName")
                        } else {
                            obj.optString("name", "Chat CSMS")
                        }
                        val rawId = obj.optString("id")
                        val validId = manager.ensureValidRoomUUID(rawId)
                        chatList.add(
                            CSMSChat(
                                id = validId,
                                name = displayName,
                                lastMessage = "Ver mensajes y multimedia...",
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

    val loadMessages: (String) -> Unit = { roomId: String ->
        coroutineScope.launch {
            try {
                val validRoomId = manager.ensureValidRoomUUID(roomId)
                val dbMsgs = manager.fetchChatMessages(validRoomId)
                activeMessages.clear()
                if (dbMsgs.isEmpty()) {
                    activeMessages.addAll(
                        listOf(
                            CSMSMessage(
                                id = "m-1",
                                senderName = "Sistema CSMS",
                                text = "¡Bienvenido al canal sincronizado Web, iOS, PC y Android! Puedes compartir fotos, videos y mensajes.",
                                time = "10:00 AM",
                                isMine = false
                            )
                        )
                    )
                } else {
                    val myUid = manager.getValidUserUUID()
                    val myAuthId = manager.currentUser?.id
                    dbMsgs.forEach { obj ->
                        val msgUserId = if (obj.has("user_id") && !obj.isNull("user_id") && obj.optString("user_id").isNotBlank()) {
                            obj.optString("user_id")
                        } else {
                            obj.optString("sender_id")
                        }
                        val isMine = (myAuthId != null && msgUserId.equals(myAuthId, ignoreCase = true)) ||
                                     (msgUserId.equals(myUid, ignoreCase = true)) ||
                                     obj.optBoolean("is_local", false)

                        val authorName = when {
                            isMine -> "Tú"
                            obj.has("author_name") && !obj.isNull("author_name") && obj.optString("author_name").isNotBlank() -> obj.optString("author_name")
                            else -> "Usuario CSMS"
                        }

                        val createdAt = obj.optString("created_at")
                        val timeStr = if (createdAt.length >= 16) {
                            try {
                                createdAt.substring(11, 16)
                            } catch (e: Exception) {
                                "Enviado"
                            }
                        } else {
                            "Enviado"
                        }

                        val mUrl = obj.optString("media_url").takeIf { it.isNotBlank() && it != "null" }
                        val mType = obj.optString("media_type").takeIf { it.isNotBlank() && it != "null" }

                        activeMessages.add(
                            CSMSMessage(
                                id = obj.optString("id", java.util.UUID.randomUUID().toString()),
                                senderName = authorName,
                                text = obj.optString("content"),
                                time = timeStr,
                                isMine = isMine,
                                mediaUrl = mUrl,
                                mediaType = mType
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
        while (true) {
            delay(4000)
            if (activeChat == null) {
                loadRooms()
            }
        }
    }

    // Auto sync messages every 2.0s when inside chat
    LaunchedEffect(activeChat) {
        val chat = activeChat
        if (chat != null) {
            coroutineScope.launch {
                manager.joinRoomAsMember(chat.id)
            }
            loadMessages(chat.id)
            while (activeChat?.id == chat.id) {
                delay(2000)
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
                    subtitle = "Coki Messaging Service • Web, PC & Android",
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
                    subtitle = if (activeChat?.isGroup == true) "Canal grupal sincronizado" else "Mensaje directo",
                    icon = Icons.Default.ArrowBack,
                    iconColor = Color.White,
                    onIconClick = { activeChat = null },
                    actions = {
                        IconButton(onClick = { activeChat?.id?.let { loadMessages(it) } }) {
                            Icon(Icons.Default.Refresh, contentDescription = "Recargar mensajes", tint = PurpleAccent)
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
                            showCreateGroupDialog = true
                        }
                    },
                    containerColor = PurpleAccent,
                    contentColor = Color.White,
                    shape = CircleShape
                ) {
                    Icon(Icons.Default.Add, contentDescription = "Nuevo Grupo")
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
                // ── LISTA DE CANALES Y CHATS CSMS (CLON DE WEB & PC) ──
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 16.dp)
                ) {
                    // Barra de Búsqueda de Chats
                    OutlinedTextField(
                        value = searchQuery,
                        onValueChange = { searchQuery = it },
                        placeholder = { Text("Buscar salas o chats CSMS...", fontSize = 13.sp) },
                        leadingIcon = {
                            Icon(Icons.Default.Search, contentDescription = "Buscar", tint = Color.Gray)
                        },
                        trailingIcon = {
                            if (searchQuery.isNotEmpty()) {
                                IconButton(onClick = { searchQuery = "" }) {
                                    Icon(Icons.Default.Clear, contentDescription = "Limpiar", tint = Color.Gray)
                                }
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp),
                        shape = RoundedCornerShape(14.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedTextColor = Color.White,
                            unfocusedTextColor = Color.White,
                            focusedBorderColor = PurpleAccent,
                            unfocusedBorderColor = Color(0xFF334155),
                            focusedContainerColor = Color(0xFF1E293B).copy(alpha = 0.6f),
                            unfocusedContainerColor = Color(0xFF1E293B).copy(alpha = 0.4f)
                        ),
                        singleLine = true
                    )

                    // Botones de acción rápida: + DM y + Grupo
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Card(
                            modifier = Modifier
                                .weight(1f)
                                .clickable {
                                    if (!manager.isLoggedIn) onLoginRequired() else showCreateDmDialog = true
                                },
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFF1E293B).copy(alpha = 0.7f)),
                            border = androidx.compose.foundation.BorderStroke(1.dp, PurpleAccent.copy(alpha = 0.4f))
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 10.dp),
                                horizontalArrangement = Arrangement.Center,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(Icons.Default.Person, contentDescription = null, tint = PurpleAccent, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Nuevo DM", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                            }
                        }

                        Card(
                            modifier = Modifier
                                .weight(1f)
                                .clickable {
                                    if (!manager.isLoggedIn) onLoginRequired() else showCreateGroupDialog = true
                                },
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFF1E293B).copy(alpha = 0.7f)),
                            border = androidx.compose.foundation.BorderStroke(1.dp, IndigoPrimary.copy(alpha = 0.4f))
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 10.dp),
                                horizontalArrangement = Arrangement.Center,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(Icons.Default.Add, contentDescription = null, tint = IndigoPrimary, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Nuevo Grupo", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                            }
                        }
                    }

                    // Dialog Crear DM
                    AnimatedVisibility(visible = showCreateDmDialog) {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFF1E1B4B)),
                            border = androidx.compose.foundation.BorderStroke(1.2.dp, PurpleAccent)
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("✉️ Iniciar Mensaje Directo (DM)", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 15.sp)
                                Text("Ingresa el correo del usuario registrado en CSMS:", color = Color.LightGray, fontSize = 11.sp, modifier = Modifier.padding(top = 2.dp, bottom = 8.dp))
                                OutlinedTextField(
                                    value = dmTargetEmail,
                                    onValueChange = { dmTargetEmail = it },
                                    placeholder = { Text("ejemplo@cokistudios.com", fontSize = 12.sp) },
                                    modifier = Modifier.fillMaxWidth(),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedTextColor = Color.White,
                                        unfocusedTextColor = Color.White,
                                        focusedBorderColor = PurpleAccent,
                                        unfocusedBorderColor = Color.White.copy(alpha = 0.3f)
                                    ),
                                    singleLine = true
                                )
                                Spacer(modifier = Modifier.height(10.dp))
                                Row(horizontalArrangement = Arrangement.End, modifier = Modifier.fillMaxWidth()) {
                                    IconButton(onClick = { showCreateDmDialog = false }) {
                                        Text("Cancelar", color = Color.Gray, fontSize = 12.sp)
                                    }
                                    Spacer(modifier = Modifier.width(8.dp))
                                    IconButton(onClick = {
                                        if (dmTargetEmail.isNotBlank()) {
                                            coroutineScope.launch {
                                                val roomId = manager.startDirectMessage(dmTargetEmail)
                                                if (roomId != null) {
                                                    Toast.makeText(context, "Conversación iniciada", Toast.LENGTH_SHORT).show()
                                                    loadRooms()
                                                    activeChat = CSMSChat(roomId, dmTargetEmail, "", "Ahora", 0, false)
                                                }
                                                dmTargetEmail = ""
                                                showCreateDmDialog = false
                                            }
                                        }
                                    }) {
                                        Text("Chatear", color = PurpleAccent, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                                    }
                                }
                            }
                        }
                    }

                    // Dialog Crear Grupo
                    AnimatedVisibility(visible = showCreateGroupDialog) {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFF1E1B4B)),
                            border = androidx.compose.foundation.BorderStroke(1.2.dp, IndigoPrimary)
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("💬 Crear Nuevo Grupo CSMS Sincronizado", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 15.sp)
                                Spacer(modifier = Modifier.height(8.dp))
                                OutlinedTextField(
                                    value = newGroupName,
                                    onValueChange = { newGroupName = it },
                                    placeholder = { Text("Nombre del grupo (ej: Hackers Cota)", fontSize = 12.sp) },
                                    modifier = Modifier.fillMaxWidth(),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedTextColor = Color.White,
                                        unfocusedTextColor = Color.White,
                                        focusedBorderColor = IndigoPrimary,
                                        unfocusedBorderColor = Color.White.copy(alpha = 0.3f)
                                    ),
                                    singleLine = true
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
                                                val createdId = manager.createGroupChat(newGroupName)
                                                if (createdId != null) {
                                                    Toast.makeText(context, "Grupo CSMS creado", Toast.LENGTH_SHORT).show()
                                                    loadRooms()
                                                    activeChat = CSMSChat(createdId, newGroupName, "", "Ahora", 0, true)
                                                }
                                                newGroupName = ""
                                                showCreateGroupDialog = false
                                            }
                                        }
                                    }) {
                                        Text("Crear", color = IndigoPrimary, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                                    }
                                }
                            }
                        }
                    }

                    val filteredList = chatList.filter {
                        searchQuery.isBlank() || it.name.contains(searchQuery, ignoreCase = true)
                    }

                    LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.padding(top = 4.dp)) {
                        items(filteredList) { chat ->
                            Card(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        activeChat = chat
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
                                                    listOf(
                                                        if (chat.isGroup) IndigoPrimary else PurpleAccent,
                                                        Color(0xFF3B82F6)
                                                    )
                                                )
                                            ),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(
                                            text = chat.name.take(2).uppercase(),
                                            color = Color.White,
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 15.sp
                                        )
                                    }

                                    Spacer(modifier = Modifier.width(14.dp))

                                    Column(modifier = Modifier.weight(1f)) {
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Text(
                                                text = chat.name,
                                                fontSize = 14.sp,
                                                fontWeight = FontWeight.Bold,
                                                color = Color.White,
                                                maxLines = 1
                                            )
                                            Text(
                                                text = chat.time,
                                                fontSize = 10.sp,
                                                color = Color.Gray
                                            )
                                        }

                                        Spacer(modifier = Modifier.height(3.dp))

                                        Text(
                                            text = chat.lastMessage,
                                            fontSize = 12.sp,
                                            color = Color(0xFF94A3B8),
                                            maxLines = 1
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                // ── CONVERSACIÓN ACTIVA CON MULTIMEDIA (FOTOS Y VIDEOS) ──
                val currentChat = activeChat!!
                val listState = rememberLazyListState()

                LaunchedEffect(activeMessages.size) {
                    if (activeMessages.isNotEmpty()) {
                        listState.animateScrollToItem(activeMessages.size - 1)
                    }
                }

                Column(modifier = Modifier.fillMaxSize()) {
                    LazyColumn(
                        state = listState,
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
                                        .fillMaxWidth(if (!msg.mediaUrl.isNullOrBlank()) 0.75f else 0.85f)
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

                                        // Texto del mensaje
                                        if (msg.text.isNotBlank()) {
                                            Text(
                                                text = msg.text,
                                                fontSize = 14.sp,
                                                color = Color.White
                                            )
                                            Spacer(modifier = Modifier.height(4.dp))
                                        }

                                        // Adjunto Multimedia: FOTO O VIDEO NATIVO
                                        if (!msg.mediaUrl.isNullOrBlank()) {
                                            val url = msg.mediaUrl
                                            val isVideo = (msg.mediaType == "video") ||
                                                          url.endsWith(".mp4", true) ||
                                                          url.endsWith(".mov", true) ||
                                                          url.endsWith(".webm", true)

                                            if (isVideo) {
                                                Card(
                                                    modifier = Modifier
                                                        .fillMaxWidth()
                                                        .height(160.dp)
                                                        .clickable {
                                                            try {
                                                                val intent = Intent(Intent.ACTION_VIEW).apply {
                                                                    setDataAndType(Uri.parse(url), "video/*")
                                                                }
                                                                context.startActivity(intent)
                                                            } catch (e: Exception) {
                                                                context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                                                            }
                                                        },
                                                    shape = RoundedCornerShape(10.dp),
                                                    colors = CardDefaults.cardColors(containerColor = Color.Black.copy(alpha = 0.5f))
                                                ) {
                                                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                                                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                                            Icon(
                                                                Icons.Default.PlayArrow,
                                                                contentDescription = "Reproducir Video",
                                                                tint = PurpleAccent,
                                                                modifier = Modifier.size(48.dp)
                                                            )
                                                            Text("Reproducir Video CSMS", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.White)
                                                        }
                                                    }
                                                }
                                            } else {
                                                // Foto / Imagen con Coil
                                                AsyncImage(
                                                    model = url,
                                                    contentDescription = "Foto adjunta",
                                                    modifier = Modifier
                                                        .fillMaxWidth()
                                                        .heightIn(max = 220.dp)
                                                        .clip(RoundedCornerShape(10.dp))
                                                        .clickable {
                                                            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                                                        },
                                                    contentScale = ContentScale.Crop
                                                )
                                            }
                                            Spacer(modifier = Modifier.height(4.dp))
                                        }

                                        Text(
                                            text = msg.time,
                                            fontSize = 9.sp,
                                            color = if (isMine) Color.White.copy(alpha = 0.7f) else Color(0xFF94A3B8),
                                            modifier = Modifier.align(Alignment.End)
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Barra de Previsualización de Archivo Adjunto (Foto o Video)
                    if (attachedUri != null) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(Color(0xFF1E1B4B))
                                .padding(horizontal = 14.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("📎 Archivo adjunto listo para enviar", color = PurpleAccent, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                            if (isUploadingMedia) {
                                CircularProgressIndicator(modifier = Modifier.size(16.dp), color = PurpleAccent, strokeWidth = 2.dp)
                                Spacer(modifier = Modifier.width(8.dp))
                            }
                            IconButton(
                                onClick = { attachedUri = null },
                                modifier = Modifier.size(24.dp)
                            ) {
                                Icon(Icons.Default.Clear, contentDescription = "Quitar", tint = Color.Gray, modifier = Modifier.size(16.dp))
                            }
                        }
                    }

                    // Barra Inferior de Entrada (Con botón de adjuntar fotos y videos)
                    val sendMessageAction = {
                        val text = typedMessage.trim()
                        val uri = attachedUri
                        if ((text.isNotBlank() || uri != null) && !isSendingMessage) {
                            isSendingMessage = true
                            coroutineScope.launch {
                                var uploadedUrl: String? = null
                                var uploadedType: String? = null

                                if (uri != null) {
                                    isUploadingMedia = true
                                    val result = manager.uploadMedia(uri, context)
                                    if (result != null) {
                                        uploadedUrl = result.first
                                        uploadedType = result.second
                                    }
                                    isUploadingMedia = false
                                }

                                val finalContent = if (text.isNotBlank()) text else {
                                    if (uploadedType == "video") "🎥 Video adjunto" else "📷 Foto adjunta"
                                }

                                manager.sendChatMessage(
                                    rawRoomId = currentChat.id,
                                    content = finalContent,
                                    mediaUrl = uploadedUrl,
                                    mediaType = uploadedType
                                )

                                typedMessage = ""
                                attachedUri = null
                                isSendingMessage = false
                                loadMessages(currentChat.id)
                            }
                        }
                    }

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Color(0xFF0F172A))
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Botón de Adjuntar Fotos y Videos (Galería de Android)
                        IconButton(
                            onClick = {
                                mediaPickerLauncher.launch("*/*")
                            },
                            modifier = Modifier
                                .size(42.dp)
                                .clip(CircleShape)
                                .background(Color(0xFF1E293B))
                        ) {
                            Text("📎", fontSize = 18.sp)
                        }

                        Spacer(modifier = Modifier.width(8.dp))

                        OutlinedTextField(
                            value = typedMessage,
                            onValueChange = { typedMessage = it },
                            placeholder = { Text("Escribe un mensaje en CSMS...", fontSize = 13.sp) },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(24.dp),
                            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
                            keyboardActions = KeyboardActions(onSend = { sendMessageAction() }),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White,
                                focusedBorderColor = PurpleAccent,
                                unfocusedBorderColor = Color.White.copy(alpha = 0.3f),
                                focusedContainerColor = Color(0xFF1E293B).copy(alpha = 0.5f),
                                unfocusedContainerColor = Color(0xFF1E293B).copy(alpha = 0.3f)
                            )
                        )

                        Spacer(modifier = Modifier.width(8.dp))

                        IconButton(
                            onClick = { sendMessageAction() },
                            modifier = Modifier
                                .size(46.dp)
                                .clip(CircleShape)
                                .background(PurpleAccent)
                        ) {
                            if (isSendingMessage || isUploadingMedia) {
                                CircularProgressIndicator(modifier = Modifier.size(20.dp), color = Color.White, strokeWidth = 2.dp)
                            } else {
                                Icon(Icons.Default.Send, contentDescription = "Enviar", tint = Color.White)
                            }
                        }
                    }
                }
            }
        }
    }
}
