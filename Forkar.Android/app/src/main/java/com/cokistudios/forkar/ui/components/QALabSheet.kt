package com.cokistudios.forkar.ui.components

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cokistudios.forkar.BuildConfig
import com.cokistudios.forkar.R
import com.cokistudios.forkar.data.QALabManager
import com.cokistudios.forkar.data.SupabaseManager
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QALabSheet(
    manager: SupabaseManager,
    onDismiss: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val qaManager = remember { QALabManager.getInstance(context) }
    var isPinging by remember { mutableStateOf(false) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = Color(0xFF141419),
        dragHandle = {
            Box(
                modifier = Modifier
                    .padding(vertical = 12.dp)
                    .width(44.dp)
                    .height(4.dp)
                    .background(Color.White.copy(alpha = 0.25f), RoundedCornerShape(2.dp))
            )
        }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 6.dp)
                .verticalScroll(rememberScrollState())
        ) {
            // Header
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(Color(0x28F59E0B)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "🧪",
                        fontSize = 20.sp
                    )
                }
                Spacer(modifier = Modifier.width(12.dp))
                Column {
                    Text(
                        text = "Forkar QA Lab",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                    Text(
                        text = "Entorno Staging de Nuevas Funciones",
                        fontSize = 12.sp,
                        color = Color(0xFFF59E0B)
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Build Identification Card
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFF1E1E26), RoundedCornerShape(12.dp))
                    .border(1.dp, Color(0xFFF59E0B).copy(alpha = 0.25f), RoundedCornerShape(12.dp))
                    .padding(14.dp)
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "ESTADO DE AISLAMIENTO",
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Black,
                            color = Color(0xFFF59E0B),
                            letterSpacing = 1.sp
                        )
                        Box(
                            modifier = Modifier
                                .background(Color(0x2210B981), RoundedCornerShape(6.dp))
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        ) {
                            Text(
                                text = "100% AISLADO DE RETAIL",
                                fontSize = 9.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF34D399)
                            )
                        }
                    }

                    Text(
                        text = "Paquete: ${context.packageName}",
                        color = Color.White.copy(alpha = 0.85f),
                        fontSize = 12.sp,
                        fontFamily = FontFamily.Monospace
                    )
                    Text(
                        text = "Versión: ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})",
                        color = Color.White.copy(alpha = 0.85f),
                        fontSize = 12.sp,
                        fontFamily = FontFamily.Monospace
                    )
                    Text(
                        text = "Canal: ${BuildConfig.CHANNEL_NAME.uppercase()} • Firebase App ID Configurado",
                        color = Color.White.copy(alpha = 0.6f),
                        fontSize = 11.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Latency Benchmark Section
            Text(
                text = "DIAGNÓSTICO DE RED Y LATENCIA",
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White.copy(alpha = 0.5f),
                letterSpacing = 0.8.sp
            )
            Spacer(modifier = Modifier.height(8.dp))

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFF1E1E26), RoundedCornerShape(12.dp))
                    .padding(14.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Text(
                            text = "Ping a Servidor Supabase",
                            color = Color.White,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                        val ping = qaManager.lastMeasuredLatencyMs
                        val pingColor = when {
                            ping < 0 -> Color.Gray
                            ping < 180 -> Color(0xFF34D399)
                            ping < 450 -> Color(0xFFFBBF24)
                            else -> Color(0xFFF87171)
                        }
                        Text(
                            text = if (ping < 0) "Sin medir todavía" else "$ping ms de latencia REST",
                            color = pingColor,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }

                    OutlinedButton(
                        onClick = {
                            coroutineScope.launch {
                                isPinging = true
                                qaManager.measureLatency(manager.getRestEndpoint())
                                isPinging = false
                            }
                        },
                        enabled = !isPinging,
                        shape = RoundedCornerShape(8.dp),
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = Color(0xFFF59E0B)
                        )
                    ) {
                        if (isPinging) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(14.dp),
                                color = Color(0xFFF59E0B),
                                strokeWidth = 2.dp
                            )
                        } else {
                            Icon(Icons.Default.PlayArrow, contentDescription = null, modifier = Modifier.size(14.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Medir", fontSize = 12.sp)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(18.dp))

            // Feature Flags Section
            Text(
                text = "FEATURE FLAGS EXPERIMENTALES",
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White.copy(alpha = 0.5f),
                letterSpacing = 0.8.sp
            )
            Spacer(modifier = Modifier.height(8.dp))

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFF1E1E26), RoundedCornerShape(12.dp))
                    .padding(horizontal = 14.dp, vertical = 6.dp)
            ) {
                // Feature 1: Audio / Voice Notes
                QAFeatureToggleRow(
                    icon = "🎙️",
                    title = "Notas de Voz / Grabadora",
                    subtitle = "Probar interfaz de grabación de audio en nueva publicación",
                    checked = qaManager.audioNotesExperimentEnabled,
                    onCheckedChange = { qaManager.updateAudioNotesExperiment(it) }
                )

                Divider(color = Color.White.copy(alpha = 0.08f))

                // Feature 2: Live Sync Polling
                QAFeatureToggleRow(
                    icon = "⚡",
                    title = "Live Sync en Tiempo Real",
                    subtitle = "Auto-refresco de feed cada 12s simulando WebSocket",
                    checked = qaManager.realtimeSyncEnabled,
                    onCheckedChange = { qaManager.updateRealtimeSync(it) }
                )

                Divider(color = Color.White.copy(alpha = 0.08f))

                // Feature 3: Latency Inspector in TopBar
                QAFeatureToggleRow(
                    icon = "⏱️",
                    title = "Monitor de Latencia en Barra",
                    subtitle = "Píldora con ms de respuesta visible en el header",
                    checked = qaManager.latencyInspectorEnabled,
                    onCheckedChange = { qaManager.updateLatencyInspector(it) }
                )

                Divider(color = Color.White.copy(alpha = 0.08f))

                // Feature 4: Scope posts as QA Test
                QAFeatureToggleRow(
                    icon = "🏷️",
                    title = "Etiquetar Posts como [QA Test]",
                    subtitle = "Añade [🧪 QA Test] automáticamente al crear publicaciones",
                    checked = qaManager.tagQaPostsByDefault,
                    onCheckedChange = { qaManager.updateTagQaPostsByDefault(it) }
                )

                Divider(color = Color.White.copy(alpha = 0.08f))

                // Feature 5: Filter only QA Posts
                QAFeatureToggleRow(
                    icon = "🔍",
                    title = "Filtrar solo Posts de QA",
                    subtitle = "Oculta posts de retail en el feed principal de QA",
                    checked = qaManager.filterOnlyQaPosts,
                    onCheckedChange = { qaManager.updateFilterOnlyQaPosts(it) }
                )

                Divider(color = Color.White.copy(alpha = 0.08f))

                // Feature 6: Watermark
                QAFeatureToggleRow(
                    icon = "🔖",
                    title = "Marca de Agua QA en Pantalla",
                    subtitle = "Muestra 'Forkar QA Staging' flotante en la interfaz",
                    checked = qaManager.watermarkEnabled,
                    onCheckedChange = { qaManager.updateWatermark(it) }
                )
            }

            Spacer(modifier = Modifier.height(18.dp))

            // Action Buttons
            Text(
                text = "ACCIONES DE TESTER",
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White.copy(alpha = 0.5f),
                letterSpacing = 0.8.sp
            )
            Spacer(modifier = Modifier.height(8.dp))

            // Firebase Feedback Button
            OutlinedButton(
                onClick = {
                    try {
                        com.google.firebase.appdistribution.FirebaseAppDistribution.getInstance()
                            .startFeedback(R.string.additional_form_text)
                        onDismiss()
                    } catch (e: Exception) {
                        Toast.makeText(context, "Error abriendo feedback: ${e.message}", Toast.LENGTH_SHORT).show()
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(10.dp),
                colors = ButtonDefaults.outlinedButtonColors(
                    contentColor = Color(0xFFF59E0B)
                )
            ) {
                Icon(Icons.Default.Info, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("Enviar Captura / Feedback a Firebase", fontWeight = FontWeight.SemiBold)
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Clear Cache Button
            OutlinedButton(
                onClick = {
                    qaManager.clearTestCache(context)
                    Toast.makeText(context, "Caché de prueba eliminada exitosamente", Toast.LENGTH_SHORT).show()
                },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(10.dp),
                colors = ButtonDefaults.outlinedButtonColors(
                    contentColor = Color.White.copy(alpha = 0.7f)
                )
            ) {
                Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("Limpiar Caché Local de QA")
            }

            Spacer(modifier = Modifier.height(28.dp))
        }
    }
}

@Composable
private fun QAFeatureToggleRow(
    icon: String,
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = icon, fontSize = 18.sp)
        Spacer(modifier = Modifier.width(10.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                color = Color.White,
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = subtitle,
                color = Color.White.copy(alpha = 0.6f),
                fontSize = 11.sp
            )
        }
        Spacer(modifier = Modifier.width(8.dp))
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White,
                checkedTrackColor = Color(0xFFF59E0B),
                uncheckedThumbColor = Color.LightGray,
                uncheckedTrackColor = Color.DarkGray
            )
        )
    }
}
