package com.cokistudios.ecovalidator

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.text.SimpleDateFormat
import java.util.*

// ── Theme Colors ──
val BgDark = Color(0xFF06090F)
val CardBg = Color(0xFF0D121F)
val EmeraldGreen = Color(0xFF10B981)
val EmeraldLight = Color(0xFF34D399)
val AmberYellow = Color(0xFFF59E0B)
val SkyBlue = Color(0xFF38BDF8)
val PurpleAccent = Color(0xFF8B5CF6)
val TextSub = Color(0xFF94A3B8)
val BorderColor = Color(0xFF1E293B)

data class EcoStation(
    val id: String,
    val name: String,
    val region: String,
    val type: String,
    val points: Int,
    val co2SavedKg: Double,
    val icon: ImageVector,
    val color: Color
)

data class ValidatedClaim(
    val id: String = UUID.randomUUID().toString(),
    val stationName: String,
    val userName: String,
    val points: Int,
    val co2Kg: Double,
    val time: String,
    val isApproved: Boolean = true
)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            EcoValidatorApp()
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EcoValidatorApp() {
    val stations = remember {
        listOf(
            EcoStation("1", "Punto Verde Parque Principal", "Cota", "Compostaje & Plásticos", 50, 2.5, Icons.Default.Eco, EmeraldGreen),
            EcoStation("2", "Estación Bici Cota Sostenible", "Cota (Vía Siberia)", "Ciclovía & Movilidad", 30, 1.5, Icons.Default.DirectionsBike, SkyBlue),
            EcoStation("3", "Punto RAEE Electrónicos", "Cota (Alcaldía)", "Baterías & Hardware", 70, 3.5, Icons.Default.Bolt, AmberYellow),
            EcoStation("4", "Centro de Acopio Chía Centro", "Chía (Av. Pradilla)", "Reciclaje Masivo", 60, 3.0, Icons.Default.Recycling, PurpleAccent),
            EcoStation("5", "Eco Estación Campus Norte", "Chía Norte", "Estudiantil & Carga", 40, 2.0, Icons.Default.School, EmeraldLight),
            EcoStation("6", "Hub Intermodal Portal 80", "Bogotá - Cota", "Biciestación & Residuos", 45, 2.2, Icons.Default.DirectionsSubway, SkyBlue),
            EcoStation("7", "Punto Limpio Portal Suba", "Bogotá - Chía", "Intermodal Limpio", 50, 2.8, Icons.Default.LocationCity, EmeraldGreen)
        )
    }

    var selectedStation by remember { mutableStateOf(stations[0]) }
    var totalPoints by remember { mutableIntStateOf(240) }
    var totalCo2 by remember { mutableDoubleStateOf(14.5) }
    var showScanDialog by remember { mutableStateOf(false) }
    var showManualDialog by remember { mutableStateOf(false) }
    var manualToken by remember { mutableStateOf("") }

    val recentValidations = remember {
        mutableStateListOf(
            ValidatedClaim(stationName = "Punto Verde Parque Principal", userName = "jerixortixdev@gmail.com", points = 50, co2Kg = 2.5, time = "Hace 5 min"),
            ValidatedClaim(stationName = "Estación Bici Cota Sostenible", userName = "coki_user@gmail.com", points = 30, co2Kg = 1.5, time = "Hace 18 min")
        )
    }

    fun processValidation(token: String) {
        val timeNow = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
        val claim = ValidatedClaim(
            stationName = selectedStation.name,
            userName = if (token.isNotBlank()) "Token: $token" else "Usuario QR Verificado",
            points = selectedStation.points,
            co2Kg = selectedStation.co2SavedKg,
            time = timeNow
        )
        recentValidations.add(0, claim)
        totalPoints += selectedStation.points
        totalCo2 += selectedStation.co2SavedKg
    }

    Scaffold(
        containerColor = BgDark
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 20.dp, vertical = 12.dp)
        ) {
            // ── Top Bar ──
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "🌿 FORKAR ECO VALIDATOR",
                        color = EmeraldGreen,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Black,
                        letterSpacing = 1.5.sp
                    )
                    Text(
                        text = "Terminal Oficial Droid",
                        color = Color.White,
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                Box(
                    modifier = Modifier
                        .background(EmeraldGreen.copy(alpha = 0.15f), RoundedCornerShape(10.dp))
                        .border(1.dp, EmeraldGreen.copy(alpha = 0.4f), RoundedCornerShape(10.dp))
                        .padding(horizontal = 12.dp, vertical = 6.dp)
                ) {
                    Text("Cota • Chía • Bogotá", color = EmeraldGreen, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                }
            }

            // ── Live Impact Metric Card ──
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        Brush.linearGradient(
                            listOf(
                                selectedStation.color.copy(alpha = 0.25f),
                                CardBg
                            )
                        ),
                        RoundedCornerShape(20.dp)
                    )
                    .border(1.dp, selectedStation.color.copy(alpha = 0.4f), RoundedCornerShape(20.dp))
                    .padding(20.dp)
            ) {
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text("Estación Activa de Acopio", color = TextSub, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                            Text(selectedStation.name, color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Bold)
                            Text(selectedStation.region + " • " + selectedStation.type, color = selectedStation.color, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                        Icon(
                            imageVector = selectedStation.icon,
                            contentDescription = null,
                            tint = selectedStation.color,
                            modifier = Modifier.size(36.dp)
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                    Divider(color = Color.White.copy(alpha = 0.08f))
                    Spacer(modifier = Modifier.height(16.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceAround
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(String.format(Locale.US, "%.1f kg", totalCo2), color = EmeraldLight, fontSize = 22.sp, fontWeight = FontWeight.Black)
                            Text("CO₂ Ahorrado", color = TextSub, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                        }
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text("$totalPoints pts", color = AmberYellow, fontSize = 22.sp, fontWeight = FontWeight.Black)
                            Text("Puntos Acreditados", color = TextSub, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // ── Select Station Horizontal Scroll ──
            Text("SELECCIONAR ESTACIÓN DE RECOLECCIÓN", color = TextSub, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(8.dp))

            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                items(stations) { station ->
                    val isSelected = station.id == selectedStation.id
                    Box(
                        modifier = Modifier
                            .background(
                                if (isSelected) station.color.copy(alpha = 0.2f) else CardBg,
                                RoundedCornerShape(14.dp)
                            )
                            .border(
                                1.dp,
                                if (isSelected) station.color else BorderColor,
                                RoundedCornerShape(14.dp)
                            )
                            .clickable { selectedStation = station }
                            .padding(horizontal = 14.dp, vertical = 10.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Icon(station.icon, contentDescription = null, tint = station.color, modifier = Modifier.size(16.dp))
                            Text(station.region, color = Color.White, fontSize = 13.sp, fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // ── Quick Validation Actions ──
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Button(
                    onClick = { showScanDialog = true },
                    modifier = Modifier
                        .weight(1f)
                        .height(50.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = EmeraldGreen),
                    shape = RoundedCornerShape(14.dp)
                ) {
                    Icon(Icons.Default.QrCodeScanner, contentDescription = null)
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Validar QR", fontWeight = FontWeight.Bold, fontSize = 14.sp)
                }

                OutlinedButton(
                    onClick = { showManualDialog = true },
                    modifier = Modifier
                        .weight(1f)
                        .height(50.dp),
                    shape = RoundedCornerShape(14.dp),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White)
                ) {
                    Icon(Icons.Default.Pin, contentDescription = null)
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Token Manual", fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // ── Recent Activity / History ──
            Text("ÚLTIMAS VALIDACIONES EN TIEMPO REAL", color = TextSub, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(8.dp))

            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(10.dp),
                modifier = Modifier.fillMaxSize()
            ) {
                items(recentValidations) { claim ->
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(CardBg, RoundedCornerShape(14.dp))
                            .border(1.dp, BorderColor, RoundedCornerShape(14.dp))
                            .padding(14.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(36.dp)
                                        .background(EmeraldGreen.copy(alpha = 0.15f), CircleShape),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(Icons.Default.Check, contentDescription = null, tint = EmeraldGreen, modifier = Modifier.size(20.dp))
                                }
                                Column {
                                    Text(claim.stationName, color = Color.White, fontSize = 13.5.sp, fontWeight = FontWeight.Bold)
                                    Text(claim.userName + " • " + claim.time, color = TextSub, fontSize = 11.5.sp)
                                }
                            }
                            Column(horizontalAlignment = Alignment.End) {
                                Text("+${claim.points} pts", color = AmberYellow, fontSize = 14.sp, fontWeight = FontWeight.Black)
                                Text("-${claim.co2Kg} kg CO₂", color = EmeraldLight, fontSize = 11.5.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }
        }

        // ── QR Scanner Simulation Dialog ──
        if (showScanDialog) {
            AlertDialog(
                onDismissRequest = { showScanDialog = false },
                containerColor = CardBg,
                title = { Text("Escanear Código QR", color = Color.White, fontWeight = FontWeight.Bold) },
                text = {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                        Box(
                            modifier = Modifier
                                .size(140.dp)
                                .background(Color.White.copy(alpha = 0.05f), RoundedCornerShape(16.dp))
                                .border(2.dp, EmeraldGreen, RoundedCornerShape(16.dp)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Default.QrCode2, contentDescription = null, tint = EmeraldGreen, modifier = Modifier.size(90.dp))
                        }
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            "Simulando lectura de cámara para validar el código del usuario en ${selectedStation.name}",
                            color = TextSub,
                            fontSize = 12.5.sp
                        )
                    }
                },
                confirmButton = {
                    Button(
                        onClick = {
                            processValidation("QR_VALIDATED_SESSION")
                            showScanDialog = false
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = EmeraldGreen)
                    ) {
                        Text("Confirmar y Acreditar")
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showScanDialog = false }) {
                        Text("Cancelar", color = TextSub)
                    }
                }
            )
        }

        // ── Manual Token Dialog ──
        if (showManualDialog) {
            AlertDialog(
                onDismissRequest = { showManualDialog = false },
                containerColor = CardBg,
                title = { Text("Ingresar Token Manual", color = Color.White, fontWeight = FontWeight.Bold) },
                text = {
                    Column {
                        OutlinedTextField(
                            value = manualToken,
                            onValueChange = { manualToken = it },
                            placeholder = { Text("Ej: ECO-COTA-2026", color = TextSub) },
                            singleLine = true,
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White,
                                focusedBorderColor = EmeraldGreen,
                                unfocusedBorderColor = BorderColor
                            )
                        )
                    }
                },
                confirmButton = {
                    Button(
                        onClick = {
                            if (manualToken.isNotBlank()) {
                                processValidation(manualToken)
                                manualToken = ""
                            }
                            showManualDialog = false
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = EmeraldGreen)
                    ) {
                        Text("Acreditar")
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showManualDialog = false }) {
                        Text("Cancelar", color = TextSub)
                    }
                }
            )
        }
    }
}
