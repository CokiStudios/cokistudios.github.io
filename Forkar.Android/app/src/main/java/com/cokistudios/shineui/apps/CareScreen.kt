package com.cokistudios.shineui.apps

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cokistudios.shineui.*

/**
 * ═══════════════════════════════════════════════════════════════
 * CARE (SHINE CARE) — OPTIMIZADOR DE RENDIMIENTO, BATERÍA Y SALUD DEL DISPOSITIVO
 * Based on CS Design Guide (Pages 3, 7, 15)
 * Features: RAM Cleaner, Battery Saver, Cache Purge, Security Health
 * ═══════════════════════════════════════════════════════════════
 */

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CareScreen(
    profile: CSUIProfile = CSUIProfile.XUI,
    onBack: () -> Unit = {}
) {
    val scrollState = rememberScrollState()
    var isOptimizing by remember { mutableStateOf(false) }
    var healthScore by remember { mutableStateOf(92) }
    var ramUsedGb by remember { mutableStateOf(3.4f) }
    val totalRamGb = 8.0f

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Shine Care", color = Color.White, fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF06090F))
            )
        },
        containerColor = Color(0xFF06090F)
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(scrollState)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // ── 1. CIRCULAR HEALTH SCORE CARD ──
            ShineGlassCard(profile = profile) {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 10.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Box(
                        modifier = Modifier
                            .size(130.dp)
                            .clip(CircleShape)
                            .background(Color(0x2210B981))
                            .border(3.dp, Color(0xFF10B981), CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = "$healthScore",
                                color = Color.White,
                                fontSize = 38.sp,
                                fontWeight = FontWeight.Black
                            )
                            Text(
                                text = "EXCELENTE",
                                color = Color(0xFF10B981),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.ExtraBold
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                    Text(text = "Tu dispositivo está protegido y optimizado.", color = Color(0xFF94A3B8), fontSize = 13.sp)

                    Spacer(modifier = Modifier.height(16.dp))
                    ShineButton(
                        text = if (isOptimizing) "Optimizando..." else "Optimizar Ahora",
                        onClick = {
                            isOptimizing = true
                            ramUsedGb = 2.1f
                            healthScore = 100
                            isOptimizing = false
                        },
                        profile = profile,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }

            // ── 2. ESTADÍSTICAS EN TIEMPO REAL (RAM, ALMACENAMIENTO, BATERÍA) ──
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Tarjeta RAM
                Box(modifier = Modifier.weight(1f)) {
                    ShineGlassCard(profile = profile) {
                        Text(text = "MEMORIA RAM", color = Color(0xFF94A3B8), fontSize = 10.sp, fontWeight = FontWeight.ExtraBold)
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(text = "${String.format("%.1f", ramUsedGb)} / ${totalRamGb.toInt()} GB", color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.height(6.dp))
                        LinearProgressIndicator(
                            progress = ramUsedGb / totalRamGb,
                            modifier = Modifier.fillMaxWidth().height(6.dp).clip(CircleShape),
                            color = ShineColors.AquaGlow,
                            trackColor = Color(0x33FFFFFF)
                        )
                    }
                }

                // Tarjeta Batería
                Box(modifier = Modifier.weight(1f)) {
                    ShineGlassCard(profile = profile) {
                        Text(text = "BATERÍA", color = Color(0xFF94A3B8), fontSize = 10.sp, fontWeight = FontWeight.ExtraBold)
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(text = "88% • 18h rest.", color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.height(6.dp))
                        LinearProgressIndicator(
                            progress = 0.88f,
                            modifier = Modifier.fillMaxWidth().height(6.dp).clip(CircleShape),
                            color = Color(0xFF10B981),
                            trackColor = Color(0x33FFFFFF)
                        )
                    }
                }
            }

            // ── 3. HERRAMIENTAS DE MANTENIMIENTO ──
            Text(
                text = "HERRAMIENTAS DE MANTENIMIENTO",
                color = Color(0xFF64748B),
                fontSize = 11.sp,
                fontWeight = FontWeight.ExtraBold,
                letterSpacing = 1.sp,
                modifier = Modifier.fillMaxWidth()
            )

            val tools = listOf(
                Pair("Limpieza de Caché del Sistema", Icons.Default.Delete),
                Pair("Diagnóstico de Sensores y Pantalla", Icons.Default.CheckCircle),
                Pair("Escaneo Antivirus con Look it", Icons.Default.Lock),
                Pair("Aceleración de Juegos (Looping Boost)", Icons.Default.Star)
            )

            tools.forEach { (title, icon) ->
                ShineGlassCard(profile = profile) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .background(Color(0x2210B981)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(icon, contentDescription = null, tint = Color(0xFF10B981), modifier = Modifier.size(22.dp))
                        }

                        Text(text = title, color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, modifier = Modifier.weight(1f))
                        Icon(Icons.Default.KeyboardArrowRight, contentDescription = null, tint = Color(0xFF64748B))
                    }
                }
            }
        }
    }
}
