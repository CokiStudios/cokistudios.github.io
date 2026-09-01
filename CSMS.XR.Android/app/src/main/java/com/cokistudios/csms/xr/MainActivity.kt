package com.cokistudios.csms.xr

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.unit.dp
import com.cokistudios.csms.xr.data.ChatRoom
import com.cokistudios.csms.xr.data.SupabaseManager
import com.cokistudios.csms.xr.ui.*
import com.cokistudios.csms.xr.ui.theme.*

/**
 * MainActivity — Punto de entrada de CSMS XR para Android XR.
 *
 * ARQUITECTURA ESPACIAL:
 * ┌─────────────────────────────────────────────────────────────┐
 * │  [SpatialPanel: Rooms List]  │  [SpatialPanel: Chat]       │
 * │  320dp ancho                 │  Resto del espacio           │
 * │  Izquierda del headset       │  Centro del headset          │
 * └─────────────────────────────────────────────────────────────┘
 *
 * En dispositivos no-XR (teléfonos/tablets) se renderiza como
 * layout de dos columnas normal (lado a lado).
 *
 * NOTA SOBRE JETPACK XR:
 * La API de SpatialPanel y Session.createSpatialEnvironment requiere
 * hardware/emulador XR. En este archivo usamos una arquitectura
 * preparada para XR — cuando se detecta `SpatialCapabilities.isSpatialUiEnabled`
 * se activa el modo spatial; de lo contrario funciona como app 2D normal.
 * 
 * Para activar las APIs XR completas (androidx.xr.compose.spatial.Subspace,
 * SpatialRow, etc.) descomenta las secciones marcadas y ejecuta en emulador XR.
 */
class MainActivity : ComponentActivity() {

    private lateinit var manager: SupabaseManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        manager = SupabaseManager.getInstance(this)

        setContent {
            CSMSXRApp(manager = manager)
        }
    }
}

@Composable
fun CSMSXRApp(manager: SupabaseManager) {
    var isLoggedIn by remember { mutableStateOf(manager.isLoggedIn) }
    var selectedRoom by remember { mutableStateOf<ChatRoom?>(null) }
    // Full Space mode toggle — en XR real esto invoca Session.requestFullSpaceMode()
    var isFullSpace by remember { mutableStateOf(false) }

    com.cokistudios.csms.xr.ui.theme.CSMSXRTheme {
        if (!isLoggedIn) {
            // Pre-auth: pantalla de login centrada
            XRLoginScreen(
                manager = manager,
                onSuccess = { isLoggedIn = true }
            )
        } else {
            /*
             * Layout principal — dos paneles flotantes lado a lado.
             *
             * En Android XR real, este Row se reemplaza por:
             *   Subspace {
             *     SpatialRow {
             *       SpatialPanel(modifier = SubspaceModifier.width(320.dp).height(800.dp)) {
             *           SpatialRoomsPanel(...)
             *       }
             *       SpatialPanel(modifier = SubspaceModifier.fillMaxWidth().height(800.dp)) {
             *           SpatialChatScreen(...)
             *       }
             *     }
             *   }
             *
             * Descomenta y agrega `androidx.xr.compose:compose` al usar emulador XR.
             */
            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(listOf(CokiMidnight, CokiDeepBlue))
                    )
            ) {
                // Panel izquierdo: Lista de salas
                SpatialRoomsPanel(
                    manager = manager,
                    selectedRoomId = selectedRoom?.id,
                    onRoomSelected = { room ->
                        selectedRoom = room
                        // En Full Space mode, cuando se selecciona sala se maximiza el panel de chat
                    }
                )

                // Divisor visual
                Box(
                    modifier = Modifier
                        .fillMaxHeight()
                        .width(1.dp)
                        .background(GlassBorder)
                )

                // Panel derecho: Chat activo
                SpatialChatScreen(
                    manager = manager,
                    room = selectedRoom,
                    isFullSpace = isFullSpace,
                    onRequestFullSpace = { isFullSpace = true },
                    onExitFullSpace = { isFullSpace = false }
                )
            }
        }
    }
}
