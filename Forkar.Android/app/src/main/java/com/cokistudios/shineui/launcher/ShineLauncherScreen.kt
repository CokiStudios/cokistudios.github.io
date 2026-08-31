package com.cokistudios.shineui.launcher

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cokistudios.shineui.*

/**
 * ═══════════════════════════════════════════════════════════════
 * SHINE RESPONSIVE ANDROID LAUNCHER (AOSP / Jetpack Compose)
 * Fully responsive for: Phone, Fold (Dual-Screen), Tablet & Desktop
 * Implements: CS Design Guide (p. 2, 4, 7, 10, 15, 16, 17)
 * ═══════════════════════════════════════════════════════════════
 */

data class ShineAppItem(
    val id: String,
    val name: String,
    val icon: ImageVector,
    val color: Color,
    val category: String = "App"
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShineLauncherScreen(
    currentProfile: CSUIProfile = CSUIProfile.XUI,
    onOpenSettings: () -> Unit = {},
    onOpenApp: (String) -> Unit = {}
) {
    var searchQuery by remember { mutableStateOf("") }
    var selectedTab by remember { mutableStateOf("home") } // "home" | "drawer"

    // System Apps from CS Design Guide (Pages 7, 8, 15)
    val installedApps = remember {
        listOf(
            ShineAppItem("cs_id", "Mi CS", Icons.Default.AccountCircle, Color(0xFF6366F1)),
            ShineAppItem("forkar", "Forkar", Icons.Default.Share, Color(0xFF8B5CF6)),
            ShineAppItem("csms", "CSMS", Icons.Default.Email, Color(0xFF38BDF8)),
            ShineAppItem("felte", "Felte Store", Icons.Default.ShoppingCart, Color(0xFFEC4899)),
            ShineAppItem("hiop", "hiOP IDE", Icons.Default.Build, Color(0xFF0EA5E9)),
            ShineAppItem("ui_connect", "UI Connect", Icons.Default.Phone, Color(0xFF10B981)),
            ShineAppItem("lookit", "Look it", Icons.Default.Lock, Color(0xFFF59E0B)),
            ShineAppItem("coki", "COK1 (AI)", Icons.Default.Face, Color(0xFF6366F1)),
            ShineAppItem("settings", "Settings", Icons.Default.Settings, Color(0xFF64748B)),
            ShineAppItem("phify", "Phify", Icons.Default.Call, Color(0xFF14B8A6)),
            ShineAppItem("gallery", "Galería", Icons.Default.Star, Color(0xFFF43F5E)),
            ShineAppItem("media", "Media", Icons.Default.PlayArrow, Color(0xFF8B5CF6))
        )
    }

    val filteredApps = installedApps.filter {
        it.name.contains(searchQuery, ignoreCase = true)
    }

    BoxWithConstraints(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF06090F))
    ) {
        val isWideScreen = maxWidth > 600.dp // Fold unfolded or Tablet
        val isFluiFold = currentProfile == CSUIProfile.FLUI && isWideScreen

        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
        ) {
            // ── 1. BUBBLY DOT TOP NOTCH (Page 17) ──
            BubblyDotNotch(
                title = "Shine OS • Red Coki Conectada",
                isMusicPlaying = true,
                modifier = Modifier.padding(bottom = 12.dp)
            )

            if (isFluiFold) {
                // ── DUAL SCREEN FOLD LAYOUT (FlUI - Page 10) ──
                Row(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Left Screen: Clock, Quick Widgets & Bubbly Telemetry
                    Box(modifier = Modifier.weight(1f)) {
                        LeftScreenFoldWidget(
                            onOpenSettings = onOpenSettings,
                            onOpenApp = onOpenApp
                        )
                    }

                    // Virtual Hinge Divider
                    Box(
                        modifier = Modifier
                            .fillMaxHeight()
                            .width(2.dp)
                            .background(ShineColors.FluiBorder)
                    )

                    // Right Screen: App Grid & Search
                    Box(modifier = Modifier.weight(1f)) {
                        AppGridContainer(
                            apps = filteredApps,
                            searchQuery = searchQuery,
                            onSearchChange = { searchQuery = it },
                            onOpenApp = onOpenApp,
                            profile = currentProfile
                        )
                    }
                }
            } else {
                // ── STANDARD PHONE RESPONSIVE LAYOUT (hi!UI, XUI, Stock) ──
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 20.dp)
                ) {
                    // Home Clock & Welcome Header (Page 16)
                    HomeHeaderWidget(currentProfile)

                    Spacer(modifier = Modifier.height(16.dp))

                    // Search & App Grid
                    AppGridContainer(
                        apps = filteredApps,
                        searchQuery = searchQuery,
                        onSearchChange = { searchQuery = it },
                        onOpenApp = onOpenApp,
                        profile = currentProfile,
                        modifier = Modifier.weight(1f)
                    )

                    // Bottom Dock Bar (Pages 2 & 6)
                    BottomDockBar(
                        onOpenApp = onOpenApp,
                        profile = currentProfile
                    )
                }
            }
        }
    }
}

/**
 * ── HEADER WIDGET WITH FROSTED AQUA A17 GLASS ──
 */
@Composable
fun HomeHeaderWidget(profile: CSUIProfile) {
    ShineGlassCard(profile = profile) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Coki Studios",
                    color = ShineColors.AquaGlow,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.ExtraBold,
                    letterSpacing = 1.2.sp
                )
                Text(
                    text = "Welcome to Shine OS",
                    color = Color.White,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            Box(
                modifier = Modifier
                    .clip(CircleShape)
                    .background(Color(0x2238BDF8))
                    .border(1.dp, ShineColors.AquaGlow, CircleShape)
                    .padding(horizontal = 12.dp, vertical = 6.dp)
            ) {
                Text(
                    text = profile.name,
                    color = ShineColors.AquaGlow,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Black
                )
            }
        }
    }
}

/**
 * ── APP GRID & SEARCH CONTAINER ──
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppGridContainer(
    apps: List<ShineAppItem>,
    searchQuery: String,
    onSearchChange: (String) -> Unit,
    onOpenApp: (String) -> Unit,
    profile: CSUIProfile,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        // Search Input (Frosted Search Bar)
        OutlinedTextField(
            value = searchQuery,
            onValueChange = onSearchChange,
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(Color(0x330F172A)),
            placeholder = { Text("Buscar en Shine OS...", color = Color(0xFF64748B), fontSize = 13.sp) },
            leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = ShineColors.AquaGlow) },
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = ShineColors.AquaGlow,
                unfocusedBorderColor = Color(0x33FFFFFF),
                focusedTextColor = Color.White,
                unfocusedTextColor = Color.White
            ),
            singleLine = true
        )

        // Responsive Grid of Apps
        LazyVerticalGrid(
            columns = GridCells.Adaptive(minSize = 72.dp),
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.spacedBy(16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            contentPadding = PaddingValues(vertical = 8.dp)
        ) {
            items(apps) { app ->
                AppIconItem(app = app, onClick = { onOpenApp(app.id) })
            }
        }
    }
}

/**
 * ── INDIVIDUAL FROSTED GLASS APP ICON ITEM (Design Guide Page 4) ──
 */
@Composable
fun AppIconItem(
    app: ShineAppItem,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .clip(RoundedCornerShape(14.dp))
            .clickable { onClick() }
            .padding(6.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Frosted Glass Icon Shape
        Box(
            modifier = Modifier
                .size(54.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(
                    Brush.verticalGradient(
                        listOf(app.color.copy(alpha = 0.35f), Color(0xCC0F172A))
                    )
                )
                .border(1.2.dp, app.color.copy(alpha = 0.6f), RoundedCornerShape(16.dp))
                .shadow(10.dp, RoundedCornerShape(16.dp), spotColor = app.color),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = app.icon,
                contentDescription = app.name,
                tint = Color.White,
                modifier = Modifier.size(26.dp)
            )
        }

        Spacer(modifier = Modifier.height(6.dp))

        Text(
            text = app.name,
            color = Color(0xFFE2E8F0),
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center
        )
    }
}

/**
 * ── BOTTOM DOCK BAR (Tasker Style - Page 6) ──
 */
@Composable
fun BottomDockBar(
    onOpenApp: (String) -> Unit,
    profile: CSUIProfile
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp),
        contentAlignment = Alignment.Center
    ) {
        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(26.dp))
                .background(Color(0xDD0F172A))
                .border(1.2.dp, Color(0x33FFFFFF), RoundedCornerShape(26.dp))
                .shadow(16.dp, RoundedCornerShape(26.dp), spotColor = ShineColors.AquaGlow)
                .padding(horizontal = 20.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            val dockApps = listOf(
                Pair("phify", Icons.Default.Call),
                Pair("csms", Icons.Default.Email),
                Pair("forkar", Icons.Default.Share),
                Pair("settings", Icons.Default.Settings)
            )

            dockApps.forEach { (id, icon) ->
                Box(
                    modifier = Modifier
                        .size(42.dp)
                        .clip(CircleShape)
                        .background(Color(0x3338BDF8))
                        .clickable { onOpenApp(id) },
                    contentAlignment = Alignment.Center
                ) {
                    Icon(icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(22.dp))
                }
            }
        }
    }
}

/**
 * ── FOLD DUAL-SCREEN LEFT WIDGET (Page 8 & 10) ──
 */
@Composable
fun LeftScreenFoldWidget(
    onOpenSettings: () -> Unit,
    onOpenApp: (String) -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        ShineGlassCard(profile = CSUIProfile.FLUI) {
            Text(
                text = "FLUI DUAL DISPLAY",
                color = ShineColors.FluiMagenta,
                fontSize = 11.sp,
                fontWeight = FontWeight.ExtraBold
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Shine Fold Active",
                color = Color.White,
                fontSize = 22.sp,
                fontWeight = FontWeight.Black
            )
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = "Panel de productividad expandido. Desliza para multiventana.",
                color = Color(0xFF94A3B8),
                fontSize = 12.sp,
                lineHeight = 16.sp
            )
        }

        ShineGlassCard(profile = CSUIProfile.FLUI) {
            Text(
                text = "ACCIONES RÁPIDAS",
                color = Color(0xFFCBD5E1),
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(12.dp))
            ShineButton(
                text = "Abrir Configuración (Settings)",
                onClick = onOpenSettings,
                profile = CSUIProfile.FLUI,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(8.dp))
            ShineButton(
                text = "Conectar a Shinebook (UI Connect)",
                onClick = { onOpenApp("ui_connect") },
                profile = CSUIProfile.FLUI,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}
