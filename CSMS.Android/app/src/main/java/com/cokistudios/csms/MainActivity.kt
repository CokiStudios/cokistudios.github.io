package com.cokistudios.csms

import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
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
import androidx.compose.material3.Surface
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
import com.cokistudios.csms.data.ChatMessageItem
import com.cokistudios.csms.data.ChatRoomItem
import com.cokistudios.csms.data.SupabaseManager
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val supabaseManager = SupabaseManager.getInstance(this)

        setContent {
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = Color(0xFF06090F)
            ) {
                CSMSAppMainScreen(manager = supabaseManager)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CSMSAppMainScreen(manager: SupabaseManager) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    var activeRoom by remember { mutableStateOf<ChatRoomItem?>(null) }
    var typedMessage by remember { mutableStateOf("") }
    var showCreateGroupDialog by remember { mutableStateOf(false) }
    var newGroupName by remember { mutableStateOf("") }

    val chatList = remember { mutableStateListOf<ChatRoomItem>() }
    val activeMessages = remember { mutableStateListOf<ChatMessageItem>() }

    val loadRooms = {
        coroutineScope.launch {
            try {
                val dbRooms = manager.fetchChatRooms()
                chatList.clear()
                if (dbRooms.isEmpty()) {
                    chatList.addAll(
                        listOf(
                            ChatRoomItem("csms-global", "💬 Comunidad Coki Studios Global", true),
                            ChatRoomItem("csms-eco", "🌿 Eco Hub Cota & Cundinamarca", true)
                        )
                    )
                } else {
                    chatList.addAll(dbRooms)
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
                    activeMessages.add(
                        ChatMessageItem("m-1", roomId, "system", "Bienvenido a CSMS 100% Nativo en Android.", "")
                    )
                } else {
                    activeMessages.addAll(dbMsgs)
                }
            } catch (e: Exception) {
                // Fallback
            }
        }
    }

    LaunchedEffect(Unit) {
        loadRooms()
    }

    LaunchedEffect(activeRoom) {
        val room = activeRoom
        if (room != null) {
            loadMessages(room.id)
            while (activeRoom?.id == room.id) {
                delay(3000)
                loadMessages(room.id)
            }
        }
    }

    Scaffold(
        containerColor = Color(0xFF06090F),
        topBar = {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 6.dp)
                    .clip(RoundedCornerShape(24.dp))
                    .background(
                        Brush.linearGradient(
                            listOf(Color(0xFF0F172A).copy(alpha = 0.95f), Color(0xFF1E1B4B).copy(alpha = 0.90f))
                        )
                    )
                    .border(
                        1.5.dp,
                        Brush.linearGradient(listOf(Color.White.copy(alpha = 0.5f), Color(0xFF8B5CF6).copy(alpha = 0.6f))),
                        RoundedCornerShape(24.dp)
                    )
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        if (activeRoom != null) {
                            IconButton(onClick = { activeRoom = null }) {
                                Icon(Icons.Default.ArrowBack, contentDescription = "Volver", tint = Color.White)
                            }
                            Spacer(modifier = Modifier.width(6.dp))
                        }
                        Column {
                            Text(
                                text = activeRoom?.name ?: "CSMS Android",
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Black,
                                color = Color.White
                            )
                            Text(
                                text = if (activeRoom != null) "Sincronizado en tiempo real" else "Coki Messaging Service Nativo",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFFC7D2FE)
                            )
                        }
                    }

                    if (activeRoom == null) {
                        IconButton(onClick = { loadRooms() }) {
                            Icon(Icons.Default.Refresh, contentDescription = "Recargar", tint = Color(0xFF8B5CF6))
                        }
                    }
                }
            }
        },
        floatingActionButton = {
            if (activeRoom == null) {
                FloatingActionButton(
                    onClick = { showCreateGroupDialog = !showCreateGroupDialog },
                    containerColor = Color(0xFF8B5CF6),
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
            if (activeRoom == null) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 16.dp)
                ) {
                    AnimatedVisibility(visible = showCreateGroupDialog) {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFF1E1B4B)),
                            border = androidx.compose.foundation.BorderStroke(1.2.dp, Color(0xFF8B5CF6).copy(alpha = 0.5f))
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text("💬 Crear Grupo CSMS Nativo", fontWeight = FontWeight.Bold, color = Color.White, fontSize = 15.sp)
                                Spacer(modifier = Modifier.height(8.dp))
                                OutlinedTextField(
                                    value = newGroupName,
                                    onValueChange = { newGroupName = it },
                                    placeholder = { Text("Nombre del grupo (ej: Hackers Cota)") },
                                    modifier = Modifier.fillMaxWidth(),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedTextColor = Color.White,
                                        unfocusedTextColor = Color.White,
                                        focusedBorderColor = Color(0xFF8B5CF6),
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
                                                    Toast.makeText(context, "Grupo creado exitosamente", Toast.LENGTH_SHORT).show()
                                                    loadRooms()
                                                }
                                                newGroupName = ""
                                                showCreateGroupDialog = false
                                            }
                                        }
                                    }) {
                                        Text("Crear", color = Color(0xFF8B5CF6), fontWeight = FontWeight.Bold, fontSize = 13.sp)
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
                                    .clickable { activeRoom = chat },
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
                                            .size(44.dp)
                                            .clip(CircleShape)
                                            .background(
                                                Brush.linearGradient(
                                                    listOf(Color(0xFF8B5CF6).copy(alpha = 0.4f), Color(0xFF4F46E5).copy(alpha = 0.2f))
                                                )
                                            )
                                            .border(1.2.dp, Color(0xFF8B5CF6).copy(alpha = 0.6f), CircleShape),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(
                                            text = chat.name.take(2).uppercase(),
                                            fontWeight = FontWeight.Black,
                                            color = Color.White,
                                            fontSize = 15.sp
                                        )
                                    }

                                    Spacer(modifier = Modifier.width(14.dp))

                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            text = chat.name,
                                            fontWeight = FontWeight.Bold,
                                            color = Color.White,
                                            fontSize = 15.sp
                                        )
                                        Spacer(modifier = Modifier.height(2.dp))
                                        Text(
                                            text = if (chat.isGroup) "Grupo de Chat CSMS" else "Mensaje Directo",
                                            fontSize = 12.sp,
                                            color = Color(0xFFCBD5E1)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                Column(modifier = Modifier.fillMaxSize()) {
                    LazyColumn(
                        modifier = Modifier
                            .weight(1f)
                            .padding(horizontal = 16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        items(activeMessages) { msg ->
                            val isMine = msg.senderId == "my-user"
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
                                                Brush.linearGradient(listOf(Color(0xFF4F46E5), Color(0xFF8B5CF6)))
                                            } else {
                                                Brush.linearGradient(listOf(Color(0xFF1E293B), Color(0xFF0F172A)))
                                            }
                                        )
                                        .border(1.dp, Color(0xFF334155), RoundedCornerShape(16.dp))
                                        .padding(horizontal = 14.dp, vertical = 10.dp)
                                ) {
                                    Text(
                                        text = msg.content,
                                        fontSize = 14.sp,
                                        color = Color.White
                                    )
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
                        OutlinedTextField(
                            value = typedMessage,
                            onValueChange = { typedMessage = it },
                            placeholder = { Text("Escribe un mensaje CSMS...") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(24.dp),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White,
                                focusedBorderColor = Color(0xFF8B5CF6),
                                unfocusedBorderColor = Color.White.copy(alpha = 0.3f)
                            )
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        IconButton(
                            onClick = {
                                val text = typedMessage.trim()
                                val room = activeRoom
                                if (text.isNotBlank() && room != null) {
                                    coroutineScope.launch {
                                        manager.sendChatMessage(room.id, text)
                                        typedMessage = ""
                                        loadMessages(room.id)
                                    }
                                }
                            },
                            modifier = Modifier
                                .size(46.dp)
                                .clip(CircleShape)
                                .background(Color(0xFF8B5CF6))
                        ) {
                            Icon(Icons.Default.Send, contentDescription = "Enviar", tint = Color.White)
                        }
                    }
                }
            }
        }
    }
}
