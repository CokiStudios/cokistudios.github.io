package com.cokistudios.shineui.settings

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
 * SHINE OS SETTINGS APP (App Config Oficial - Design Guide p.16)
 * Sections: Log in CSID, Home Setup, Lock Screen, Wallpaper & Pers,
 * Privacy & Security, Apps, Experimental, Help & Tips, About X Phone
 * ═══════════════════════════════════════════════════════════════
 */

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShineSettingsScreen(
    currentProfile: CSUIProfile = CSUIProfile.XUI,
    onProfileChange: (CSUIProfile) -> Unit = {},
    onBack: () -> Unit = {}
) {
    val scrollState = rememberScrollState()
    var bubblyDotEnabled by remember { mutableStateOf(true) }
    var highRefreshRate by remember { mutableStateOf(true) } // 120Hz / 240Hz

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Configuración",
                        color = Color.White,
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color(0xFF06090F)
                )
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
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            // ── 1. LOG IN CSID SECTION (Page 16) ──
            ShineGlassCard(profile = currentProfile) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(50.dp)
                            .clip(CircleShape)
                            .background(Color(0x336366F1)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Default.AccountCircle, contentDescription = null, tint = Color(0xFF818CF8), modifier = Modifier.size(30.dp))
                    }
                    Column(modifier = Modifier.weight(1f)) {
                        Text(text = "Log in CS ID", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                        Text(text = "Sincroniza tus datos en la nube de Coki", color = Color(0xFF94A3B8), fontSize = 12.sp)
                    }
                    Icon(Icons.Default.KeyboardArrowRight, contentDescription = null, tint = Color(0xFF64748B))
                }
            }

            // ── 2. SELECCIÓN DE PERFIL DE SISTEMA (hi!UI, Stock, XUI, FlUI) ──
            ShineGlassCard(profile = currentProfile) {
                Text(text = "ENTORNO VISUAL (UI PROFILE)", color = ShineColors.AquaGlow, fontSize = 11.sp, fontWeight = FontWeight.ExtraBold)
                Spacer(modifier = Modifier.height(10.dp))
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    CSUIProfile.values().forEach { profile ->
                        val isSelected = profile == currentProfile
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .clip(RoundedCornerShape(12.dp))
                                .background(if (isSelected) ShineColors.AquaGlow.copy(alpha = 0.25f) else Color(0x22FFFFFF))
                                .border(1.dp, if (isSelected) ShineColors.AquaGlow else Color.Transparent, RoundedCornerShape(12.dp))
                                .clickable { onProfileChange(profile) }
                                .padding(vertical = 10.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = profile.name.replace("_", "!"),
                                color = if (isSelected) Color.White else Color(0xFF94A3B8),
                                fontSize = 11.sp,
                                fontWeight = if (isSelected) FontWeight.Black else FontWeight.Medium
                            )
                        }
                    }
                }
            }

            // ── 3. AJUSTES DEL SISTEMA (Page 16) ──
            SettingsGroup(
                title = "PERSONALIZACIÓN & HOME",
                items = listOf(
                    SettingsOption("Home Setup", "Configura widgets y rejilla del launcher", Icons.Default.Home),
                    SettingsOption("Lock Screen", "Reloj A17, notificaciones y Always-On", Icons.Default.Lock),
                    SettingsOption("Wallpaper & Personalization", "Fondo Frosted Glass Acrílico Aqua A17", Icons.Default.Star)
                ),
                profile = currentProfile
            )

            SettingsGroup(
                title = "PRIVACIDAD & SEGURIDAD",
                items = listOf(
                    SettingsOption("Privacy & Security", "Control de permisos, Look it y biometría", Icons.Default.CheckCircle),
                    SettingsOption("Security & Emergency", "Alertas rápidas y SOS satelital", Icons.Default.Warning)
                ),
                profile = currentProfile
            )

            SettingsGroup(
                title = "SISTEMA & BUBBLY DOT",
                items = listOf(
                    SettingsOption("Bubbly Dot (Dynamic Island)", "Animación de música, llamadas y notch", Icons.Default.Notifications, hasSwitch = true, isChecked = bubblyDotEnabled, onToggle = { bubblyDotEnabled = it }),
                    SettingsOption("Tasa de Refresco Dinámica", "120Hz / 240Hz en pantallas AMOLED", Icons.Default.Refresh, hasSwitch = true, isChecked = highRefreshRate, onToggle = { highRefreshRate = it }),
                    SettingsOption("About X Phone (Información)", "Shine OS 1.0 • Kernel Linux AOSP", Icons.Default.Info)
                ),
                profile = currentProfile
            )
        }
    }
}

data class SettingsOption(
    val title: String,
    val subtitle: String,
    val icon: ImageVector,
    val hasSwitch: Boolean = false,
    val isChecked: Boolean = false,
    val onToggle: (Boolean) -> Unit = {}
)

@Composable
fun SettingsGroup(
    title: String,
    items: List<SettingsOption>,
    profile: CSUIProfile
) {
    ShineGlassCard(profile = profile) {
        Text(
            text = title,
            color = Color(0xFF64748B),
            fontSize = 11.sp,
            fontWeight = FontWeight.ExtraBold,
            letterSpacing = 1.sp
        )
        Spacer(modifier = Modifier.height(10.dp))

        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items.forEach { item ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .clickable { if (item.hasSwitch) item.onToggle(!item.isChecked) }
                        .padding(vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(38.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color(0x2238BDF8)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(item.icon, contentDescription = null, tint = ShineColors.AquaGlow, modifier = Modifier.size(20.dp))
                    }

                    Column(modifier = Modifier.weight(1f)) {
                        Text(text = item.title, color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                        Text(text = item.subtitle, color = Color(0xFF94A3B8), fontSize = 11.sp)
                    }

                    if (item.hasSwitch) {
                        Switch(
                            checked = item.isChecked,
                            onCheckedChange = item.onToggle,
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = Color.White,
                                checkedTrackColor = ShineColors.AquaGlow
                            )
                        )
                    } else {
                        Icon(Icons.Default.KeyboardArrowRight, contentDescription = null, tint = Color(0xFF64748B))
                    }
                }
            }
        }
    }
}
