package com.cokistudios.csms.meta

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cokistudios.csms.meta.data.ChatRoom
import com.cokistudios.csms.meta.data.SupabaseManager
import com.cokistudios.csms.meta.ui.theme.*
import kotlinx.coroutines.launch

/**
 * ImmersiveActivity — Actividad principal para Meta Horizon OS (Quest 2/3/Pro).
 *
 * ARQUITECTURA META SPATIAL:
 * Esta actividad funciona como el "host 3D" de la aplicación. En un Quest físico,
 * se usa con el Meta Spatial SDK (AppSystemActivity) para:
 *   1. Definir el entorno 3D (skybox, iluminación) de Coki Studios
 *   2. Registrar PanelActivity como un SpatialPanel flotante en el espacio
 *   3. Gestionar interacciones de controladores y manos
 *
 * Para builds con Meta Spatial SDK habilitado, esta clase debe extender
 * AppSystemActivity en lugar de ComponentActivity, y registrar:
 *   registerFeature(ComposeFeature())
 *   registerPanel(PanelRegistration(R.string.panel_activity_class) { ... })
 *
 * En esta implementación base (sin hardware físico) se renderiza como:
 *   - Una pantalla de lobby con lista de rooms + botón para entrar al chat
 *   - El chat se lanza como PanelActivity (Activity separada)
 *
 * Descomenta el código Meta Spatial SDK cuando tengas el headset conectado.
 */
class ImmersiveActivity : ComponentActivity() {

    private lateinit var manager: SupabaseManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        manager = SupabaseManager.getInstance(this)

        setContent {
            CSMSMetaTheme {
                MetaLobbyScreen(
                    manager = manager,
                    onEnterChat = { roomId, roomName ->
                        val intent = Intent(this, PanelActivity::class.java).apply {
                            putExtra(PanelActivity.EXTRA_ROOM_ID, roomId)
                            putExtra(PanelActivity.EXTRA_ROOM_NAME, roomName)
                        }
                        startActivity(intent)
                    }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MetaLobbyScreen(
    manager: SupabaseManager,
    onEnterChat: (roomId: String, roomName: String) -> Unit
) {
    val scope = rememberCoroutineScope()
    var rooms by remember { mutableStateOf<List<ChatRoom>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var errorMsg by remember { mutableStateOf<String?>(null) }
    var showNewRoomDialog by remember { mutableStateOf(false) }
    var newRoomName by remember { mutableStateOf("") }

    LaunchedEffect(Unit) {
        try {
            rooms = manager.fetchRooms()
        } catch (e: Exception) {
            errorMsg = e.message
        } finally {
            isLoading = false
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.radialGradient(
                    colors = listOf(MetaNavy, MetaDeep, MetaMidnight),
                    radius = 1200f
                )
            )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(32.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        "CSMS",
                        fontSize = 32.sp,
                        fontWeight = FontWeight.Bold,
                        color = TextPrimary
                    )
                    Text(
                        "Messenger · Meta Horizon OS",
                        fontSize = 14.sp,
                        color = MetaCyan
                    )
                }

                // Coki Studios hex logo badge
                Box(
                    modifier = Modifier
                        .size(56.dp)
                        .clip(RoundedCornerShape(16.dp))
                        .background(Brush.linearGradient(listOf(MetaIndigo, MetaPurple))),
                    contentAlignment = Alignment.Center
                ) {
                    Text("⬡", fontSize = 24.sp, color = TextPrimary)
                }
            }

            Spacer(Modifier.height(32.dp))

            // Rooms grid header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    "Salas de chat",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextSecondary
                )
                if (manager.isLoggedIn) {
                    IconButton(
                        onClick = { showNewRoomDialog = true },
                        modifier = Modifier
                            .background(MetaIndigo, RoundedCornerShape(10.dp))
                    ) {
                        Icon(Icons.Default.Add, contentDescription = "Nueva sala", tint = TextPrimary)
                    }
                }
            }

            Spacer(Modifier.height(16.dp))

            when {
                isLoading -> Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = MetaIndigo)
                }
                errorMsg != null -> Text(errorMsg ?: "", color = UnreadBadge)
                rooms.isEmpty() -> Text(
                    "No hay salas aún.\nCrea la primera sala para empezar.",
                    color = TextSecondary, lineHeight = 22.sp
                )
                else -> LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    items(rooms) { room ->
                        MetaRoomCard(room = room, onEnter = { onEnterChat(room.id, room.name) })
                    }
                }
            }
        }

        // New room dialog
        if (showNewRoomDialog) {
            AlertDialog(
                onDismissRequest = { showNewRoomDialog = false },
                title = { Text("Nueva sala", color = TextPrimary) },
                text = {
                    OutlinedTextField(
                        value = newRoomName,
                        onValueChange = { newRoomName = it },
                        label = { Text("Nombre") },
                        singleLine = true
                    )
                },
                confirmButton = {
                    TextButton(onClick = {
                        if (newRoomName.isNotBlank()) {
                            scope.launch {
                                try {
                                    manager.fetchRooms() // refresh
                                    newRoomName = ""
                                    showNewRoomDialog = false
                                } catch (e: Exception) { errorMsg = e.message }
                            }
                        }
                    }) { Text("Crear", color = MetaIndigo) }
                },
                dismissButton = {
                    TextButton(onClick = { showNewRoomDialog = false }) {
                        Text("Cancelar", color = TextSecondary)
                    }
                },
                containerColor = MetaNavy
            )
        }
    }
}

@Composable
private fun MetaRoomCard(room: ChatRoom, onEnter: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(GlassSurface)
            .clickable { onEnter() }
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .background(
                    Brush.linearGradient(listOf(MetaIndigo, MetaPurple)),
                    RoundedCornerShape(12.dp)
                ),
            contentAlignment = Alignment.Center
        ) {
            Text("👥", fontSize = 18.sp)
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(room.name, color = TextPrimary, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
            Text("Sala de grupo", color = TextSecondary, fontSize = 12.sp)
        }

        Text("Entrar →", color = MetaCyan, fontWeight = FontWeight.Medium, fontSize = 13.sp)
    }
}
