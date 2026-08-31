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
 * MY CS (MI CS) — GESTOR DE IDENTIDAD Y DISPOSITIVOS COKI STUDIOS
 * Based on CS Design Guide (Pages 3, 7, 14, 16)
 * ═══════════════════════════════════════════════════════════════
 */

data class CokiDeviceItem(
    val id: String,
    val name: String,
    val model: String,
    val battery: Int,
    val isOnline: Boolean,
    val icon: ImageVector
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MyCSScreen(
    profile: CSUIProfile = CSUIProfile.XUI,
    onBack: () -> Unit = {}
) {
    val scrollState = rememberScrollState()
    
    // Connected Ecosystem Devices
    val devices = remember {
        listOf(
            CokiDeviceItem("d1", "Shine Phone 1A", "Flagship XUI (Snapdragon Elite X)", 88, true, Icons.Default.Phone),
            CokiDeviceItem("d2", "Shinebook 14", "Shine OS (Birdside Linux)", 94, true, Icons.Default.Home),
            CokiDeviceItem("d3", "Shine Poortloop", "Holo Looping OoS 1.0 (Handheld)", 76, true, Icons.Default.Star),
            CokiDeviceItem("d4", "Shine Clocked", "Wear Manage v1.0", 62, false, Icons.Default.DateRange)
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Mi CS", color = Color.White, fontWeight = FontWeight.Bold) },
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
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // ── 1. CS ID PROFILE CARD ──
            ShineGlassCard(profile = profile) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(60.dp)
                            .clip(CircleShape)
                            .background(Color(0x336366F1))
                            .border(1.5.dp, ShineColors.AquaGlow, CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Default.AccountCircle, contentDescription = null, tint = Color.White, modifier = Modifier.size(36.dp))
                    }

                    Column(modifier = Modifier.weight(1f)) {
                        Text(text = "Angel Helium", color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                        Text(text = "angel@cokistudios.com", color = ShineColors.AquaGlow, fontSize = 12.sp)
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(text = "CS ID: CS-984210 • Cuenta Verificada", color = Color(0xFF94A3B8), fontSize = 11.sp)
                    }
                }
            }

            // ── 2. ECOSYSTEM CLOUD STORAGE ──
            ShineGlassCard(profile = profile) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(text = "COKI CLOUD STORAGE", color = Color(0xFF94A3B8), fontSize = 11.sp, fontWeight = FontWeight.ExtraBold)
                    Text(text = "18.4 GB / 64 GB", color = ShineColors.AquaGlow, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                }
                Spacer(modifier = Modifier.height(10.dp))
                LinearProgressIndicator(
                    progress = 0.28f,
                    modifier = Modifier.fillMaxWidth().height(8.dp).clip(CircleShape),
                    color = ShineColors.AquaGlow,
                    trackColor = Color(0x33FFFFFF)
                )
            }

            // ── 3. MIS DISPOSITIVOS SHINE CONECTADOS ──
            Text(
                text = "MIS DISPOSITIVOS CONECTADOS",
                color = Color(0xFF64748B),
                fontSize = 11.sp,
                fontWeight = FontWeight.ExtraBold,
                letterSpacing = 1.sp
            )

            devices.forEach { dev ->
                ShineGlassCard(profile = profile) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(44.dp)
                                .clip(RoundedCornerShape(12.dp))
                                .background(Color(0x2238BDF8)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(dev.icon, contentDescription = null, tint = ShineColors.AquaGlow, modifier = Modifier.size(24.dp))
                        }

                        Column(modifier = Modifier.weight(1f)) {
                            Text(text = dev.name, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 14.sp)
                            Text(text = dev.model, color = Color(0xFF94A3B8), fontSize = 11.sp)
                        }

                        Column(horizontalAlignment = Alignment.End) {
                            Text(
                                text = "${dev.battery}%",
                                color = if (dev.battery > 20) Color(0xFF10B981) else Color(0xFFEF4444),
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.sp
                            )
                            Text(
                                text = if (dev.isOnline) "En línea" else "Inactivo",
                                color = if (dev.isOnline) ShineColors.AquaGlow else Color(0xFF64748B),
                                fontSize = 10.sp
                            )
                        }
                    }
                }
            }
        }
    }
}
