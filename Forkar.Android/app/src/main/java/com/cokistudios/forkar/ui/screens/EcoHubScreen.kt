package com.cokistudios.forkar.ui.screens

import android.widget.Toast
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.TabRowDefaults
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
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
import com.cokistudios.forkar.data.EcoAction
import com.cokistudios.forkar.data.EcoMapPoint
import com.cokistudios.forkar.data.SupabaseManager
import com.cokistudios.forkar.ui.components.LiquidGlassTopBar
import com.cokistudios.forkar.ui.theme.CardDark
import com.cokistudios.forkar.ui.theme.IndigoPrimary
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EcoHubScreen(
    manager: SupabaseManager,
    onLoginRequired: () -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    var selectedTab by remember { mutableIntStateOf(0) }
    var co2Saved by remember { mutableDoubleStateOf(0.0) }
    var pointsEarned by remember { mutableIntStateOf(0) }

    val ecoActions = remember { mutableStateListOf<EcoAction>() }
    val mapPoints = remember { mutableStateListOf<EcoMapPoint>() }
    var isLoading by remember { mutableStateOf(false) }

    val loadData = {
        coroutineScope.launch {
            isLoading = true
            try {
                val (totalCo2, totalPts) = manager.fetchUserEcoImpact()
                co2Saved = totalCo2
                pointsEarned = totalPts

                val actions = manager.fetchEcoActions()
                ecoActions.clear()
                ecoActions.addAll(actions.ifEmpty {
                    listOf(
                        EcoAction("default-1", "🚴 Usar Transporte Sostenible", "Bicicleta o caminata en tus traslados diarios", 1.5, "Transporte"),
                        EcoAction("default-2", "♻️ Separación de Residuos", "Reciclar en punto verde municipal", 2.0, "Reciclaje"),
                        EcoAction("default-3", "🔌 Ahorro Energético RAEE", "Entrega de electrónicos en desuso", 3.5, "Energía")
                    )
                })

                val points = manager.fetchEcoMapPoints()
                mapPoints.clear()
                mapPoints.addAll(points.ifEmpty {
                    listOf(
                        EcoMapPoint("m-1", "Centro de Acopio Municipal", "Cra. 3 #5-20, Cota (Lun-Vie 8am-5pm)", 4.811, -74.102, "municipal", "#10b981"),
                        EcoMapPoint("m-2", "Punto Verde Parque Principal", "Parque Principal de Cota (Todos los días)", 4.812, -74.101, "verde", "#3b82f6"),
                        EcoMapPoint("m-3", "Punto RAEE Electrónicos", "Carrera 4 No. 12 - 63 (Lun-Vie 7:30am-5:30pm)", 4.814, -74.103, "raee", "#f97316")
                    )
                })
            } catch (e: Exception) {
                Toast.makeText(context, "Error cargando Eco Hub: ${e.message}", Toast.LENGTH_SHORT).show()
            } finally {
                isLoading = false
            }
        }
    }

    LaunchedEffect(Unit) {
        loadData()
    }

    Scaffold(
        containerColor = Color.Transparent,
        topBar = {
            LiquidGlassTopBar(
                title = "Forkar Eco Hub",
                subtitle = "Impacto CO₂ & Puntos de Reciclaje",
                icon = Icons.Default.Star,
                iconColor = Color(0xFF10B981),
                actions = {
                    IconButton(onClick = { loadData() }) {
                        Icon(Icons.Default.Refresh, contentDescription = "Recargar", tint = Color(0xFF10B981))
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp)
        ) {
            // ── IMPACT SUMMARY CARD ──
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(
                    containerColor = Color(0xFF1E293B).copy(alpha = 0.85f)
                ),
                elevation = CardDefaults.cardElevation(defaultElevation = 6.dp),
                border = androidx.compose.foundation.BorderStroke(1.2.dp, Color(0xFF10B981).copy(alpha = 0.4f))
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            Brush.horizontalGradient(
                                colors = listOf(Color(0xFF10B981).copy(alpha = 0.30f), Color(0xFF6366F1).copy(alpha = 0.20f))
                            )
                        )
                        .padding(20.dp)
                ) {
                    Column {
                        Text(
                            text = "MI IMPACTO EN FORKAR",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.ExtraBold,
                            color = Color(0xFF34D399),
                            letterSpacing = 1.sp
                        )

                        Spacer(modifier = Modifier.height(8.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = String.format("%.1f kg", co2Saved),
                                    fontSize = 32.sp,
                                    fontWeight = FontWeight.Black,
                                    color = Color.White
                                )
                                Text(
                                    text = "CO₂ Ahorrado",
                                    fontSize = 13.sp,
                                    color = Color(0xFFCBD5E1)
                                )
                            }

                            Column(horizontalAlignment = Alignment.End) {
                                Text(
                                    text = "$pointsEarned pts",
                                    fontSize = 26.sp,
                                    fontWeight = FontWeight.ExtraBold,
                                    color = Color(0xFFFBBF24)
                                )
                                Text(
                                    text = "Puntos Eco",
                                    fontSize = 13.sp,
                                    color = Color(0xFFCBD5E1)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        // Device Hash Indicator
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color.Black.copy(alpha = 0.35f))
                                .padding(horizontal = 10.dp, vertical = 6.dp)
                        ) {
                            Text(
                                text = "📱 Device Hash (Dispositivo): ",
                                fontSize = 10.sp,
                                color = Color(0xFF94A3B8),
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = manager.deviceHash.take(12) + "...",
                                fontSize = 10.sp,
                                color = Color(0xFFA5B4FC),
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }

            // ── TAB SELECTOR ──
            TabRow(
                selectedTabIndex = selectedTab,
                containerColor = Color.Transparent,
                contentColor = Color(0xFF34D399),
                indicator = { tabPositions ->
                    TabRowDefaults.Indicator(
                        modifier = Modifier.tabIndicatorOffset(tabPositions[selectedTab]),
                        color = Color(0xFF34D399)
                    )
                }
            ) {
                Tab(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    text = { Text("Retos Ecológicos", fontWeight = FontWeight.ExtraBold, color = Color.White) }
                )
                Tab(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    text = { Text("Puntos de Acopio", fontWeight = FontWeight.ExtraBold, color = Color.White) }
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            if (isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = Color(0xFF10B981))
                }
            } else {
                when (selectedTab) {
                    0 -> {
                        LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            items(ecoActions) { action ->
                                Card(
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(14.dp),
                                    colors = CardDefaults.cardColors(
                                        containerColor = Color(0xFF1E293B).copy(alpha = 0.85f)
                                    ),
                                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF10B981).copy(alpha = 0.4f))
                                ) {
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(16.dp),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Column(modifier = Modifier.weight(1f)) {
                                            Text(
                                                text = action.title,
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 15.sp,
                                                color = Color.White
                                            )
                                            Spacer(modifier = Modifier.height(4.dp))
                                            Text(
                                                text = "${action.description} (+${action.co2Impact} kg CO₂)",
                                                fontSize = 12.sp,
                                                color = Color(0xFFCBD5E1)
                                            )
                                        }

                                        Button(
                                            onClick = {
                                                if (!manager.isLoggedIn) {
                                                    onLoginRequired()
                                                } else {
                                                    coroutineScope.launch {
                                                        val success = manager.logUserEcoImpact(
                                                            actionId = action.id,
                                                            co2Saved = action.co2Impact,
                                                            pointsEarned = action.pointsEarned
                                                        )
                                                        if (success) {
                                                            co2Saved += action.co2Impact
                                                            pointsEarned += action.pointsEarned
                                                            Toast.makeText(context, "🌿 Reto completado: +${action.co2Impact} kg CO₂", Toast.LENGTH_SHORT).show()
                                                        } else {
                                                            Toast.makeText(context, "⚠️ Error al registrar reto", Toast.LENGTH_SHORT).show()
                                                        }
                                                    }
                                                }
                                            },
                                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF10B981)),
                                            shape = RoundedCornerShape(10.dp)
                                        ) {
                                            Text("+${action.pointsEarned} pts", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.White)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    1 -> {
                        LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            items(mapPoints) { point ->
                                Card(
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = RoundedCornerShape(14.dp),
                                    colors = CardDefaults.cardColors(
                                        containerColor = Color(0xFF1E293B).copy(alpha = 0.85f)
                                    ),
                                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF3B82F6).copy(alpha = 0.3f))
                                ) {
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(16.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(
                                            imageVector = Icons.Default.LocationOn,
                                            contentDescription = "Punto de acopio",
                                            tint = Color(0xFF10B981),
                                            modifier = Modifier.size(28.dp)
                                        )
                                        Spacer(modifier = Modifier.width(12.dp))
                                        Column {
                                            Text(
                                                text = point.name,
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 15.sp,
                                                color = Color.White
                                            )
                                            point.description?.let { desc ->
                                                Text(
                                                    text = desc,
                                                    fontSize = 12.sp,
                                                    color = Color(0xFFCBD5E1)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
