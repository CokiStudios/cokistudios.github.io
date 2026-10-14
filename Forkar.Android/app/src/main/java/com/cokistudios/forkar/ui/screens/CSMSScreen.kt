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
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.withStyle
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
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.AlertDialog
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
import androidx.compose.material3.TextButton
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
import com.cokistudios.forkar.data.CokiGeminiAssistant
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
    val isGroup: Boolean = true,
    val avatar: String? = null,
    val canDelete: Boolean = false
)

data class CSMSMessage(
    val id: String,
    val senderName: String,
    val text: String,
    val time: String,
    val isMine: Boolean,
    val mediaUrl: String? = null,
    val mediaType: String? = null,
    val isEncrypted: Boolean = false
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
    var chatToDelete by remember { mutableStateOf<CSMSChat?>(null) }
    var isDeletingChat by remember { mutableStateOf(false) }

    // Coki with Gemini Intelligence Chat Summarization
    var showSummaryDialog by remember { mutableStateOf(false) }
    var summaryText by remember { mutableStateOf("") }
    var isSummarizing by remember { mutableStateOf(false) }

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
                        val displayAvatar = obj.optString("displayAvatar").takeIf { it.isNotBlank() && it != "null" }
                        val canDelete = obj.optBoolean("canDelete", false)
                        chatList.add(
                            CSMSChat(
                                id = validId,
                                name = displayName,
                                lastMessage = "Ver mensajes y multimedia...",
                                time = "Reciente",
                                unreadCount = 0,
                                isGroup = obj.optBoolean("is_group", true),
                                avatar = displayAvatar,
                                canDelete = canDelete
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
                                text = "¡Bienvenido al canal sincronizado Web, iOS, PC y Android! Puedes compartir fotos, videos y mensajes con cifrado.",
                                time = "10:00 AM",
                                isMine = false,
                                isEncrypted = true
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
                        val isEncrypted = obj.optBoolean("is_encrypted", false)

                        activeMessages.add(
                            CSMSMessage(
                                id = obj.optString("id", java.util.UUID.randomUUID().toString()),
                                senderName = authorName,
                                text = obj.optString("content"),
                                time = timeStr,
                                isMine = isMine,
                                mediaUrl = mUrl,
                                mediaType = mType,
                                isEncrypted = isEncrypted
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
                    subtitle = if (activeChat?.isGroup == true) "Canal grupal • 🔒 Cifrado E2EE" else "Mensaje directo • 🔒 Cifrado E2EE",
                    icon = Icons.Default.ArrowBack,
                    iconColor = Color.White,
                    onIconClick = { activeChat = null },
                    actions = {
                        IconButton(onClick = {
                            coroutineScope.launch {
                                isSummarizing = true
                                showSummaryDialog = true
                                val texts = activeMessages.map { it.text }
                                val roomName = activeChat?.name ?: "Chat"
                                summaryText = CokiGeminiAssistant.summarizeChat(texts, roomName)
                                isSummarizing = false
                            }
                        }) {
                            Text("✨", fontSize = 18.sp)
                        }
                        IconButton(onClick = { activeChat?.id?.let { loadMessages(it) } }) {
                            Icon(Icons.Default.Refresh, contentDescription = "Recargar mensajes", tint = PurpleAccent)
                        }
                        if (activeChat?.canDelete == true) {
                            IconButton(onClick = { chatToDelete = activeChat }) {
                                Icon(Icons.Default.Delete, contentDescription = "Eliminar sala", tint = Color(0xFFEF4444))
                            }
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

                    val hasTestRooms = chatList.any { 
                        it.name.equals("TEST", ignoreCase = true) || 
                        it.name.equals("Hello", ignoreCase = true) ||
                        it.name.startsWith("Test", ignoreCase = true)
                    }
                    if (hasTestRooms) {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 6.dp),
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFF7F1D1D).copy(alpha = 0.45f)),
                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFEF4444).copy(alpha = 0.6f))
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 14.dp, vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
                                    Text("🧹", fontSize = 16.sp)
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Column {
                                        Text(
                                            "Grupos de prueba detectados",
                                            color = Color.White,
                                            fontSize = 12.sp,
                                            fontWeight = FontWeight.Bold
                                        )
                                        Text(
                                            "Limpia los grupos 'TEST' y 'Hello' de Supabase",
                                            color = Color(0xFFCBD5E1),
                                            fontSize = 10.sp
                                        )
                                    }
                                }
                                TextButton(
                                    onClick = {
                                        coroutineScope.launch {
                                            val count = manager.purgeTestRooms()
                                            Toast.makeText(context, "Se purgaron $count salas de prueba", Toast.LENGTH_SHORT).show()
                                            loadRooms()
                                        }
                                    }
                                ) {
                                    Text("Limpiar", color = Color(0xFFFCA5A5), fontWeight = FontWeight.Bold, fontSize = 12.sp)
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
                                    if (!chat.avatar.isNullOrBlank()) {
                                        AsyncImage(
                                            model = chat.avatar,
                                            contentDescription = chat.name,
                                            modifier = Modifier
                                                .size(46.dp)
                                                .clip(CircleShape),
                                            contentScale = ContentScale.Crop
                                        )
                                    } else {
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

                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Text(
                                                text = chat.lastMessage,
                                                fontSize = 12.sp,
                                                color = Color(0xFF94A3B8),
                                                maxLines = 1,
                                                modifier = Modifier.weight(1f)
                                            )
                                            if (chat.canDelete) {
                                                IconButton(
                                                    onClick = { chatToDelete = chat },
                                                    modifier = Modifier.size(24.dp)
                                                ) {
                                                    Icon(
                                                        imageVector = Icons.Default.Delete,
                                                        contentDescription = "Eliminar sala",
                                                        tint = Color(0xFFEF4444).copy(alpha = 0.8f),
                                                        modifier = Modifier.size(16.dp)
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if (chatToDelete != null) {
                        val target = chatToDelete!!
                        AlertDialog(
                            onDismissRequest = { if (!isDeletingChat) chatToDelete = null },
                            title = { Text("Eliminar sala CSMS", fontWeight = FontWeight.Bold, color = Color.White) },
                            text = {
                                Text(
                                    "¿Deseas eliminar permanentemente la sala '${target.name}' de Supabase?",
                                    color = Color(0xFFCBD5E1),
                                    fontSize = 13.sp
                                )
                            },
                            confirmButton = {
                                TextButton(
                                    onClick = {
                                        isDeletingChat = true
                                        coroutineScope.launch {
                                            val success = manager.deleteChatRoom(target.id)
                                            if (success) {
                                                Toast.makeText(context, "Sala eliminada", Toast.LENGTH_SHORT).show()
                                                chatList.removeAll { it.id == target.id }
                                                if (activeChat?.id == target.id) {
                                                    activeChat = null
                                                }
                                            } else {
                                                Toast.makeText(context, "No se pudo eliminar", Toast.LENGTH_SHORT).show()
                                            }
                                            isDeletingChat = false
                                            chatToDelete = null
                                        }
                                    },
                                    enabled = !isDeletingChat
                                ) {
                                    if (isDeletingChat) {
                                        CircularProgressIndicator(modifier = Modifier.size(16.dp), color = Color.Red, strokeWidth = 2.dp)
                                    } else {
                                        Text("Eliminar", color = Color(0xFFEF4444), fontWeight = FontWeight.Bold)
                                    }
                                }
                            },
                            dismissButton = {
                                TextButton(onClick = { chatToDelete = null }, enabled = !isDeletingChat) {
                                    Text("Cancelar", color = Color.Gray)
                                }
                            },
                            containerColor = Color(0xFF0F172A)
                        )
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
                            val isCokiAI = msg.senderName.contains("Coki with", ignoreCase = true)
                            val currentUserName = manager.currentUser?.userMetadata?.displayName ?: ""
                            val isUserMentioned = !isMine && currentUserName.isNotBlank() && msg.text.contains("@$currentUserName", ignoreCase = true)

                            val bubbleBrush = if (isCokiAI) {
                                Brush.linearGradient(listOf(Color(0xFF0F172A), Color(0xFF1E1B4B)))
                            } else if (isMine) {
                                Brush.linearGradient(listOf(IndigoPrimary, PurpleAccent))
                            } else {
                                Brush.linearGradient(listOf(Color(0xFF1E293B), Color(0xFF0F172A)))
                            }

                            val bubbleBorder = if (isCokiAI) {
                                androidx.compose.foundation.BorderStroke(1.5.dp, Brush.horizontalGradient(listOf(Color(0xFF8B5CF6), Color(0xFF38BDF8), Color(0xFF10B981))))
                            } else if (isUserMentioned) {
                                androidx.compose.foundation.BorderStroke(1.5.dp, Color(0xFFF59E0B))
                            } else if (isMine) {
                                androidx.compose.foundation.BorderStroke(1.dp, PurpleAccent.copy(alpha = 0.6f))
                            } else {
                                androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF334155))
                            }

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
                                        .background(bubbleBrush)
                                        .border(bubbleBorder, RoundedCornerShape(16.dp))
                                        .padding(horizontal = 14.dp, vertical = 10.dp)
                                        .fillMaxWidth(if (!msg.mediaUrl.isNullOrBlank()) 0.78f else 0.85f)
                                ) {
                                    Column {
                                        if (isCokiAI) {
                                            Row(
                                                verticalAlignment = Alignment.CenterVertically,
                                                modifier = Modifier.padding(bottom = 6.dp)
                                            ) {
                                                Text("🤖", fontSize = 13.sp)
                                                Spacer(modifier = Modifier.width(4.dp))
                                                Text(
                                                    text = "Coki with Gemini Intelligence",
                                                    fontSize = 11.sp,
                                                    fontWeight = FontWeight.Bold,
                                                    color = Color(0xFF38BDF8)
                                                )
                                                Spacer(modifier = Modifier.width(6.dp))
                                                Box(
                                                    modifier = Modifier
                                                        .clip(RoundedCornerShape(6.dp))
                                                        .background(Color(0xFF0369A1).copy(alpha = 0.5f))
                                                        .padding(horizontal = 6.dp, vertical = 2.dp)
                                                ) {
                                                    Text("AI COPILOT", fontSize = 8.sp, fontWeight = FontWeight.ExtraBold, color = Color(0xFFBAE6FD))
                                                }
                                            }
                                        } else if (!isMine) {
                                            Row(
                                                verticalAlignment = Alignment.CenterVertically,
                                                horizontalArrangement = Arrangement.SpaceBetween,
                                                modifier = Modifier
                                                    .fillMaxWidth()
                                                    .padding(bottom = 4.dp)
                                            ) {
                                                Text(
                                                    text = msg.senderName,
                                                    fontSize = 11.sp,
                                                    fontWeight = FontWeight.Bold,
                                                    color = PurpleAccent
                                                )
                                                if (isUserMentioned) {
                                                    Box(
                                                        modifier = Modifier
                                                            .clip(RoundedCornerShape(6.dp))
                                                            .background(Color(0xFF78350F).copy(alpha = 0.85f))
                                                            .border(0.5.dp, Color(0xFFF59E0B), RoundedCornerShape(6.dp))
                                                            .padding(horizontal = 6.dp, vertical = 2.dp)
                                                    ) {
                                                        Text("📢 Te mencionó", fontSize = 9.sp, fontWeight = FontWeight.Bold, color = Color(0xFFFDE68A))
                                                    }
                                                }
                                            }
                                        }

                                        // Texto del mensaje con formato enriquecido para @menciones y /comandos
                                        if (msg.text.isNotBlank()) {
                                            val annotatedText = remember(msg.text) {
                                                buildAnnotatedString {
                                                    val words = msg.text.split(" ")
                                                    for (idx in words.indices) {
                                                        val w = words[idx]
                                                        if (w.startsWith("@") && w.length > 1) {
                                                            val color = if (w.equals("@Coki", ignoreCase = true)) Color(0xFF38BDF8) else Color(0xFFFBBF24)
                                                            withStyle(SpanStyle(color = color, fontWeight = FontWeight.Bold)) {
                                                                append(w)
                                                            }
                                                        } else if (w.startsWith("/") && w.length > 1) {
                                                            withStyle(SpanStyle(color = Color(0xFFA78BFA), fontWeight = FontWeight.Bold)) {
                                                                append(w)
                                                            }
                                                        } else {
                                                            append(w)
                                                        }
                                                        if (idx < words.size - 1) append(" ")
                                                    }
                                                }
                                            }
                                            Text(
                                                text = annotatedText,
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

                                        Row(
                                            verticalAlignment = Alignment.CenterVertically,
                                            modifier = Modifier.align(Alignment.End)
                                        ) {
                                            if (msg.isEncrypted) {
                                                Text(
                                                    text = "🔒 ",
                                                    fontSize = 8.sp,
                                                    color = if (isMine) Color.White.copy(alpha = 0.85f) else PurpleAccent
                                                )
                                            }
                                            Text(
                                                text = msg.time,
                                                fontSize = 9.sp,
                                                color = if (isMine) Color.White.copy(alpha = 0.7f) else Color(0xFF94A3B8)
                                            )
                                        }
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

                    // Menciones y Comandos Activos en CSMS
                    val lastToken = typedMessage.substringAfterLast(" ", typedMessage)
                    val chatMembers = remember(activeMessages) {
                        activeMessages.map { it.senderName }
                            .filter { it.isNotBlank() && !it.contains("Coki", ignoreCase = true) }
                            .distinct()
                    }

                    class MentionItem(val label: String, val insertText: String, val icon: String, val isAI: Boolean = false)

                    val mentionSuggestions = remember(typedMessage, chatMembers) {
                        if (lastToken.startsWith("/")) {
                            val q = lastToken.removePrefix("/").lowercase()
                            listOf(
                                MentionItem("/Coki", "/Coki ", "🤖", isAI = true),
                                MentionItem("/Genimg", "/Genimg ", "🎨", isAI = true)
                            ).filter { it.label.lowercase().contains(q) }
                        } else if (lastToken.startsWith("@")) {
                            val q = lastToken.removePrefix("@").lowercase()
                            val list = mutableListOf<MentionItem>()
                            list.add(MentionItem("@Coki", "@Coki ", "🤖", isAI = true))
                            chatMembers.forEach { member ->
                                list.add(MentionItem("@$member", "@$member ", "👤", isAI = false))
                            }
                            list.add(MentionItem("@todos", "@todos ", "📢", isAI = false))
                            list.filter { it.label.lowercase().contains(q) }
                        } else {
                            emptyList()
                        }
                    }

                    // Sugerencias Flotantes para @menciones y /comandos
                    if (mentionSuggestions.isNotEmpty()) {
                        LazyRow(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(Color(0xFF0F172A))
                                .padding(horizontal = 12.dp, vertical = 6.dp),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            items(mentionSuggestions) { sug ->
                                Card(
                                    modifier = Modifier.clickable {
                                        val before = typedMessage.substringBeforeLast(lastToken)
                                        typedMessage = before + sug.insertText
                                    },
                                    shape = RoundedCornerShape(12.dp),
                                    colors = CardDefaults.cardColors(
                                        containerColor = if (sug.isAI) Color(0xFF1E1B4B) else Color(0xFF1E293B)
                                    ),
                                    border = androidx.compose.foundation.BorderStroke(
                                        1.dp,
                                        if (sug.isAI) PurpleAccent else Color(0xFF334155)
                                    )
                                ) {
                                    Row(
                                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                                    ) {
                                        Text(sug.icon, fontSize = 12.sp)
                                        Text(
                                            sug.label,
                                            color = if (sug.isAI) Color(0xFFBAE6FD) else Color.White,
                                            fontSize = 12.sp,
                                            fontWeight = FontWeight.SemiBold
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Barra Inferior de Entrada (Con botón de adjuntar fotos y videos, magia IA y envío)
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

                                val isCokiCommand = text.startsWith("/Coki", ignoreCase = true)
                                val isCokiMention = text.contains("@Coki", ignoreCase = true)
                                val isGenImgCommand = text.startsWith("/Genimg", ignoreCase = true)

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

                                if (isCokiCommand || isCokiMention) {
                                    val query = if (isCokiCommand) {
                                        text.replaceFirst(Regex("^/Coki\\s*", RegexOption.IGNORE_CASE), "")
                                    } else {
                                        text.replace(Regex("@Coki\\s*", RegexOption.IGNORE_CASE), "")
                                    }.trim()

                                    val recentContext = activeMessages.takeLast(6).joinToString("\n") { "${it.senderName}: ${it.text}" }
                                    val aiReply = CokiGeminiAssistant.askCokiAI(query, recentContext)

                                    manager.sendChatMessage(
                                        rawRoomId = currentChat.id,
                                        content = aiReply,
                                        customAuthor = "Coki with Gemini Intelligence"
                                    )
                                    loadMessages(currentChat.id)
                                } else if (isGenImgCommand) {
                                    val notice = "🎨 El comando /Genimg está conectado con la API ImagePlayground nativa de Apple Intelligence en iOS 27, iPadOS 27 y macOS 27. En Android 17, puedes adjuntar fotos y creaciones usando el botón 📎 de multimedia."
                                    manager.sendChatMessage(
                                        rawRoomId = currentChat.id,
                                        content = notice,
                                        customAuthor = "Coki with Gemini Intelligence"
                                    )
                                    loadMessages(currentChat.id)
                                }
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

                        Spacer(modifier = Modifier.width(6.dp))

                        // Botón Rápido de Magia IA (/Coki y @mención)
                        IconButton(
                            onClick = {
                                if (!typedMessage.startsWith("/Coki ")) {
                                    typedMessage = "/Coki $typedMessage"
                                }
                            },
                            modifier = Modifier
                                .size(42.dp)
                                .clip(CircleShape)
                                .background(Color(0xFF1E1B4B))
                                .border(1.dp, PurpleAccent.copy(alpha = 0.5f), CircleShape)
                        ) {
                            Text("✨", fontSize = 16.sp)
                        }

                        Spacer(modifier = Modifier.width(6.dp))

                        OutlinedTextField(
                            value = typedMessage,
                            onValueChange = { typedMessage = it },
                            placeholder = { Text("Mensaje, @mención o /Coki...", fontSize = 13.sp) },
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

        // Coki with Gemini Intelligence Chat Summary Dialog
        if (showSummaryDialog) {
            AlertDialog(
                onDismissRequest = { showSummaryDialog = false },
                title = {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text("🤖", fontSize = 20.sp)
                        Text(
                            text = "Coki with Gemini Intelligence",
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                },
                text = {
                    if (isSummarizing) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 16.dp),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            CircularProgressIndicator(color = PurpleAccent, modifier = Modifier.size(24.dp), strokeWidth = 2.dp)
                            Spacer(modifier = Modifier.width(12.dp))
                            Text("Resumiendo con Gemini Nano...", color = Color.White, fontSize = 13.sp)
                        }
                    } else {
                        Text(
                            text = summaryText,
                            fontSize = 13.sp,
                            lineHeight = 18.sp,
                            color = Color(0xFFE2E8F0)
                        )
                    }
                },
                confirmButton = {
                    TextButton(onClick = { showSummaryDialog = false }) {
                        Text("Cerrar", color = PurpleAccent, fontWeight = FontWeight.Bold)
                    }
                },
                containerColor = Color(0xFF0F172A)
            )
        }
    }
}
