package com.cokistudios.csms.xr.ui

import androidx.compose.animation.*
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cokistudios.csms.xr.data.ChatRoom
import com.cokistudios.csms.xr.data.SupabaseManager
import com.cokistudios.csms.xr.ui.theme.*
import kotlinx.coroutines.launch

/**
 * SpatialRoomsPanel — Panel flotante de lista de salas de chat.
 *
 * En Android XR este Composable se envuelve en un SpatialPanel en MainActivity,
 * quedando posicionado a la izquierda del espacio como panel auxiliar.
 * En dispositivos no-XR funciona como una columna lateral normal.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SpatialRoomsPanel(
    manager: SupabaseManager,
    selectedRoomId: String?,
    onRoomSelected: (ChatRoom) -> Unit
) {
    val scope = rememberCoroutineScope()
    var rooms by remember { mutableStateOf<List<ChatRoom>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var showCreateDialog by remember { mutableStateOf(false) }
    var newRoomName by remember { mutableStateOf("") }
    var errorMsg by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        try {
            rooms = manager.fetchRooms()
        } catch (e: Exception) {
            errorMsg = e.message
        } finally {
            isLoading = false
        }
    }

    Column(
        modifier = Modifier
            .fillMaxHeight()
            .width(320.dp)
            .background(
                Brush.verticalGradient(listOf(CokiDeepBlue, CokiMidnight))
            )
            .padding(16.dp)
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            XRPanelHeader(
                title = "CSMS XR",
                subtitle = "Salas de chat"
            )
            if (manager.isLoggedIn) {
                IconButton(
                    onClick = { showCreateDialog = true },
                    modifier = Modifier
                        .background(CokiIndigo, RoundedCornerShape(12.dp))
                ) {
                    Icon(Icons.Default.Add, contentDescription = "Nueva sala",
                        tint = TextPrimary)
                }
            }
        }

        Spacer(Modifier.height(16.dp))
        HorizontalDivider(color = GlassBorder, thickness = 0.5.dp)
        Spacer(Modifier.height(12.dp))

        when {
            isLoading -> {
                Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = CokiIndigo)
                }
            }
            errorMsg != null -> {
                Text(errorMsg ?: "", color = UnreadBadge, fontSize = 13.sp)
            }
            rooms.isEmpty() -> {
                Text("No hay salas aún.\nCrea una nueva sala para empezar.",
                    color = TextSecondary, fontSize = 13.sp, lineHeight = 20.sp)
            }
            else -> {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(rooms) { room ->
                        RoomItem(
                            room = room,
                            isSelected = room.id == selectedRoomId,
                            onClick = { onRoomSelected(room) }
                        )
                    }
                }
            }
        }
    }

    // Create room dialog
    if (showCreateDialog) {
        AlertDialog(
            onDismissRequest = { showCreateDialog = false },
            title = { Text("Nueva sala", color = TextPrimary) },
            text = {
                OutlinedTextField(
                    value = newRoomName,
                    onValueChange = { newRoomName = it },
                    label = { Text("Nombre de la sala") },
                    singleLine = true
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    if (newRoomName.isNotBlank()) {
                        scope.launch {
                            try {
                                manager.createRoom(newRoomName.trim())
                                rooms = manager.fetchRooms()
                                newRoomName = ""
                                showCreateDialog = false
                            } catch (e: Exception) {
                                errorMsg = e.message
                            }
                        }
                    }
                }) { Text("Crear", color = CokiIndigo) }
            },
            dismissButton = {
                TextButton(onClick = { showCreateDialog = false }) {
                    Text("Cancelar", color = TextSecondary)
                }
            },
            containerColor = CokiNavy
        )
    }
}

@Composable
private fun RoomItem(
    room: ChatRoom,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val bgColor = if (isSelected)
        Brush.horizontalGradient(listOf(CokiIndigo.copy(alpha = 0.4f), CokiPurple.copy(alpha = 0.2f)))
    else
        Brush.horizontalGradient(listOf(GlassSurface, GlassSurface))

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(bgColor, RoundedCornerShape(12.dp))
            .clickable { onClick() }
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        // Icon
        Box(
            modifier = Modifier
                .size(36.dp)
                .background(
                    if (isSelected) CokiIndigo else GlassSurface,
                    RoundedCornerShape(10.dp)
                ),
            contentAlignment = Alignment.Center
        ) {
            Text("👥", fontSize = 16.sp)
        }

        // Name
        Text(
            text = room.name,
            color = if (isSelected) TextPrimary else TextSecondary,
            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
            fontSize = 14.sp,
            modifier = Modifier.weight(1f)
        )

        // Selected indicator dot
        if (isSelected) {
            Box(
                modifier = Modifier
                    .size(6.dp)
                    .background(CokiCyan, RoundedCornerShape(50))
            )
        }
    }
}
