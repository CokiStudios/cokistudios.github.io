package com.holoentertainment.adventures

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlin.math.hypot

// ── Retro Palette ──
val CyanHelium = Color(0xFF38BDF8)
val HaloGold = Color(0xFFFBBF24)
val DarkBg = Color(0xFF070B14)
val CardDark = Color(0xFF0F172A)
val NeonRed = Color(0xFFEF4444)
val TextLight = Color(0xFFF1F5F9)
val TextMuted = Color(0xFF94A3B8)
val ClueGold = Color(0xFFF59E0B)
val PortalGreen = Color(0xFF10B981)

data class Platform2D(val x: Float, val y: Float, val w: Float, val h: Float, val isMoving: Boolean = false, val moveRange: Float = 0f)
data class Clue2D(val id: String, val x: Float, val y: Float, val name: String)

data class Level2D(
    val levelNum: Int,
    val title: String,
    val subtitle: String,
    val playerSpawnX: Float,
    val playerSpawnY: Float,
    val exitX: Float,
    val exitY: Float,
    val forkbotSpawnX: Float,
    val forkbotSpawnY: Float,
    val forkbotMinX: Float,
    val forkbotMaxX: Float,
    val platforms: List<Platform2D>,
    val clues: List<Clue2D>
)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            HoloAdventuresGameApp()
        }
    }
}

@Composable
fun HoloAdventuresGameApp() {
    val levels = remember {
        listOf(
            Level2D(
                levelNum = 1,
                title = "Level 1: The Neon Outskirts",
                subtitle = "Collect all Holo Clues while avoiding Forkbot.",
                playerSpawnX = 80f,
                playerSpawnY = 500f,
                exitX = 760f,
                exitY = 220f,
                forkbotSpawnX = 420f,
                forkbotSpawnY = 500f,
                forkbotMinX = 350f,
                forkbotMaxX = 580f,
                platforms = listOf(
                    Platform2D(0f, 560f, 900f, 40f),
                    Platform2D(140f, 460f, 130f, 16f),
                    Platform2D(320f, 380f, 140f, 16f, isMoving = true, moveRange = 60f),
                    Platform2D(520f, 320f, 140f, 16f),
                    Platform2D(700f, 260f, 150f, 16f)
                ),
                clues = listOf(
                    Clue2D("c1", 190f, 420f, "Holo Memory Fragment Alpha"),
                    Clue2D("c2", 370f, 340f, "Quantum Encryption Key"),
                    Clue2D("c3", 750f, 220f, "Beacon Power Cell")
                )
            ),
            Level2D(
                levelNum = 2,
                title = "Level 2: Cyber Fork Factory",
                subtitle = "High-voltage platforms and active Forkbot pursuit.",
                playerSpawnX = 60f,
                playerSpawnY = 520f,
                exitX = 780f,
                exitY = 160f,
                forkbotSpawnX = 500f,
                forkbotSpawnY = 400f,
                forkbotMinX = 300f,
                forkbotMaxX = 700f,
                platforms = listOf(
                    Platform2D(0f, 580f, 350f, 40f),
                    Platform2D(450f, 580f, 450f, 40f),
                    Platform2D(100f, 470f, 140f, 16f, isMoving = true, moveRange = 50f),
                    Platform2D(280f, 400f, 320f, 16f),
                    Platform2D(160f, 290f, 140f, 16f),
                    Platform2D(380f, 240f, 150f, 16f),
                    Platform2D(580f, 200f, 140f, 16f),
                    Platform2D(740f, 190f, 130f, 16f)
                ),
                clues = listOf(
                    Clue2D("c2_1", 150f, 430f, "SENA Mannequin Blueprint"),
                    Clue2D("c2_2", 400f, 360f, "Xtraps Bone Schematic"),
                    Clue2D("c2_3", 220f, 250f, "Sub-zero Helium Capsule"),
                    Clue2D("c2_4", 640f, 160f, "Factory Overdrive Override")
                )
            ),
            Level2D(
                levelNum = 3,
                title = "Level 3: The Corrupted Core",
                subtitle = "The final confrontation with the Xtraps Monstrosity.",
                playerSpawnX = 60f,
                playerSpawnY = 520f,
                exitX = 800f,
                exitY = 140f,
                forkbotSpawnX = 460f,
                forkbotSpawnY = 320f,
                forkbotMinX = 200f,
                forkbotMaxX = 750f,
                platforms = listOf(
                    Platform2D(0f, 580f, 220f, 40f),
                    Platform2D(680f, 580f, 220f, 40f),
                    Platform2D(140f, 460f, 120f, 16f),
                    Platform2D(300f, 390f, 120f, 16f),
                    Platform2D(460f, 340f, 240f, 16f),
                    Platform2D(200f, 260f, 140f, 16f),
                    Platform2D(420f, 200f, 150f, 16f),
                    Platform2D(620f, 170f, 140f, 16f),
                    Platform2D(760f, 160f, 140f, 16f)
                ),
                clues = listOf(
                    Clue2D("c3_1", 180f, 420f, "Origin of Xtraps Core"),
                    Clue2D("c3_2", 520f, 300f, "Angel Helium Aura Sigil"),
                    Clue2D("c3_3", 250f, 220f, "Impostor Jaw Mechanism"),
                    Clue2D("c3_4", 680f, 130f, "Holo Entertainment Master Key")
                )
            )
        )
    }

    var currentLevelIdx by remember { mutableIntStateOf(0) }
    val currentLevel = levels[currentLevelIdx]

    // Player State
    var playerX by remember { mutableFloatStateOf(currentLevel.playerSpawnX) }
    var playerY by remember { mutableFloatStateOf(currentLevel.playerSpawnY) }
    var playerVx by remember { mutableFloatStateOf(0f) }
    var playerVy by remember { mutableFloatStateOf(0f) }
    var jumpsLeft by remember { mutableIntStateOf(2) }
    var isGrounded by remember { mutableStateOf(false) }

    // Forkbot State
    var forkbotX by remember { mutableFloatStateOf(currentLevel.forkbotSpawnX) }
    var forkbotY by remember { mutableFloatStateOf(currentLevel.forkbotSpawnY) }
    var forkbotMovingRight by remember { mutableStateOf(true) }
    var forkbotJawOpen by remember { mutableStateOf(false) }

    // Clues & Progression
    val collectedClues = remember { mutableStateListOf<String>() }
    var hasWonGame by remember { mutableStateOf(false) }

    // Platform animation offset
    var movingOffset by remember { mutableFloatStateOf(0f) }

    fun resetPlayer() {
        playerX = currentLevel.playerSpawnX
        playerY = currentLevel.playerSpawnY
        playerVx = 0f
        playerVy = 0f
        jumpsLeft = 2
    }

    fun loadLevel(index: Int) {
        currentLevelIdx = index
        val lvl = levels[index]
        playerX = lvl.playerSpawnX
        playerY = lvl.playerSpawnY
        playerVx = 0f
        playerVy = 0f
        jumpsLeft = 2
        forkbotX = lvl.forkbotSpawnX
        forkbotY = lvl.forkbotSpawnY
        collectedClues.clear()
    }

    // ── 60 FPS Native Physics & Game Loop ──
    LaunchedEffect(currentLevelIdx) {
        var tick = 0
        while (true) {
            delay(16)
            tick++
            movingOffset = (Math.sin(tick * 0.05) * 40).toFloat()

            // 1. Player Physics & Gravity
            playerVy += 0.85f // Floaty helium gravity
            playerX += playerVx
            playerY += playerVy

            // 2. Collision with Platforms
            var onGround = false
            for (plat in currentLevel.platforms) {
                val pX = if (plat.isMoving) plat.x + movingOffset else plat.x
                if (playerX + 16f >= pX && playerX - 16f <= pX + plat.w) {
                    // Top collision
                    if (playerY + 20f >= plat.y && playerY - playerVy + 20f <= plat.y) {
                        playerY = plat.y - 20f
                        playerVy = 0f
                        onGround = true
                        jumpsLeft = 2
                    }
                }
            }
            isGrounded = onGround

            // Fall off screen respawn
            if (playerY > 700f) {
                resetPlayer()
            }

            // 3. Clue Collection
            for (clue in currentLevel.clues) {
                if (!collectedClues.contains(clue.id)) {
                    val distToClue = hypot(playerX - clue.x, playerY - clue.y)
                    if (distToClue < 30f) {
                        collectedClues.add(clue.id)
                    }
                }
            }

            // 4. Corrupted Forkbot AI
            val distToForkbot = hypot(playerX - forkbotX, playerY - forkbotY)
            if (distToForkbot < 140f) {
                // Threat proximity: Split jaw & reveal Xtraps internal skeleton!
                forkbotJawOpen = true
                val dir = if (playerX > forkbotX) 1f else -1f
                forkbotX += dir * 2.8f
            } else {
                // Normal silent mannequin patrol
                forkbotJawOpen = false
                if (forkbotMovingRight) {
                    forkbotX += 1.5f
                    if (forkbotX >= currentLevel.forkbotMaxX) forkbotMovingRight = false
                } else {
                    forkbotX -= 1.5f
                    if (forkbotX <= currentLevel.forkbotMinX) forkbotMovingRight = true
                }
            }

            // Forkbot kill collision
            if (distToForkbot < 28f) {
                resetPlayer()
            }

            // 5. Exit Portal Check
            if (collectedClues.size == currentLevel.clues.size) {
                val distToExit = hypot(playerX - currentLevel.exitX, playerY - currentLevel.exitY)
                if (distToExit < 35f) {
                    if (currentLevelIdx + 1 < levels.size) {
                        loadLevel(currentLevelIdx + 1)
                    } else {
                        hasWonGame = true
                    }
                }
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBg)
    ) {
        // ── Main Canvas Game Renderer ──
        Canvas(modifier = Modifier.fillMaxSize()) {
            val canvasW = size.width
            val canvasH = size.height

            // Scale to screen
            val scaleX = canvasW / 900f
            val scaleY = canvasH / 640f

            // 1. Draw Platforms
            for (plat in currentLevel.platforms) {
                val pX = (if (plat.isMoving) plat.x + movingOffset else plat.x) * scaleX
                val pY = plat.y * scaleY
                val pW = plat.w * scaleX
                val pH = plat.h * scaleY

                drawRoundRect(
                    color = Color(0xFF1E293B),
                    topLeft = Offset(pX, pY),
                    size = Size(pW, pH),
                    cornerRadius = CornerRadius(6f, 6f)
                )
                drawRoundRect(
                    color = Color(0xFF38BDF8).copy(alpha = 0.6f),
                    topLeft = Offset(pX, pY),
                    size = Size(pW, pH),
                    cornerRadius = CornerRadius(6f, 6f),
                    style = Stroke(width = 2f)
                )
            }

            // 2. Draw Holo Clues
            for (clue in currentLevel.clues) {
                if (!collectedClues.contains(clue.id)) {
                    val cX = clue.x * scaleX
                    val cY = clue.y * scaleY
                    drawCircle(color = ClueGold.copy(alpha = 0.3f), radius = 18f, center = Offset(cX, cY))
                    drawCircle(color = ClueGold, radius = 10f, center = Offset(cX, cY))
                    drawCircle(color = Color.White, radius = 4f, center = Offset(cX, cY))
                }
            }

            // 3. Draw Exit Portal
            val exX = currentLevel.exitX * scaleX
            val exY = currentLevel.exitY * scaleY
            val portalReady = collectedClues.size == currentLevel.clues.size
            drawOval(
                color = if (portalReady) PortalGreen.copy(alpha = 0.8f) else Color.Gray.copy(alpha = 0.3f),
                topLeft = Offset(exX - 18f * scaleX, exY - 30f * scaleY),
                size = Size(36f * scaleX, 60f * scaleY)
            )

            // 4. Draw Corrupted Forkbot
            val fbX = forkbotX * scaleX
            val fbY = forkbotY * scaleY

            // Mannequin Torso
            drawRoundRect(
                color = if (forkbotJawOpen) Color(0xFF1E1B2E).copy(alpha = 0.5f) else Color(0xFF0F172A),
                topLeft = Offset(fbX - 14f * scaleX, fbY - 18f * scaleY),
                size = Size(28f * scaleX, 36f * scaleY),
                cornerRadius = CornerRadius(6f, 6f)
            )

            // Hidden Xtraps Bone Structure (Shown only when close with open mouth)
            if (forkbotJawOpen) {
                for (i in 0..2) {
                    val boneY = (fbY - 10f * scaleY) + i * 8f * scaleY
                    drawLine(
                        color = NeonRed,
                        start = Offset(fbX - 10f * scaleX, boneY),
                        end = Offset(fbX + 10f * scaleX, boneY + 4f),
                        strokeWidth = 3f
                    )
                    drawLine(
                        color = NeonRed,
                        start = Offset(fbX + 10f * scaleX, boneY),
                        end = Offset(fbX - 10f * scaleX, boneY + 4f),
                        strokeWidth = 3f
                    )
                }
            }

            // Detached Floating Head & Split Jaw (Hide and Seek Impostor style)
            val headFloatingY = if (forkbotJawOpen) fbY - 42f * scaleY else fbY - 34f * scaleY

            // Top Jaw
            drawRoundRect(
                color = Color(0xFF1E293B),
                topLeft = Offset(fbX - 12f * scaleX, headFloatingY - 8f),
                size = Size(24f * scaleX, 10f),
                cornerRadius = CornerRadius(4f, 4f)
            )
            // Visor
            drawCircle(color = NeonRed, radius = 3f, center = Offset(fbX + 4f * scaleX, headFloatingY - 3f))

            // Bottom Jaw (Drops down when open)
            val bottomJawY = if (forkbotJawOpen) headFloatingY + 12f else headFloatingY + 4f
            drawRoundRect(
                color = Color(0xFF1E293B),
                topLeft = Offset(fbX - 12f * scaleX, bottomJawY),
                size = Size(24f * scaleX, 8f),
                cornerRadius = CornerRadius(4f, 4f)
            )

            // 5. Draw Player Angel Helium
            val plX = playerX * scaleX
            val plY = playerY * scaleY

            // Glowing Halo
            drawOval(
                color = HaloGold,
                topLeft = Offset(plX - 12f * scaleX, plY - 34f * scaleY),
                size = Size(24f * scaleX, 6f * scaleY),
                style = Stroke(width = 2.5f)
            )
            // Cyan Body
            drawRoundRect(
                color = CyanHelium,
                topLeft = Offset(plX - 12f * scaleX, plY - 20f * scaleY),
                size = Size(24f * scaleX, 36f * scaleY),
                cornerRadius = CornerRadius(8f, 8f)
            )
            // Eyes
            drawCircle(color = Color.White, radius = 2.5f, center = Offset(plX + 4f * scaleX, plY - 8f * scaleY))
        }

        // ── Top Retro HUD ──
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.Top
        ) {
            Column {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("🎮 HOLO ADVENTURES", color = CyanHelium, fontSize = 13.sp, fontWeight = FontWeight.Black, fontFamily = FontFamily.Monospace)
                    Text("Holo Entertainment CS", color = TextMuted, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                }
                Text(currentLevel.title, color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Bold)
                Text(currentLevel.subtitle, color = TextMuted, fontSize = 11.5.sp)
            }

            Box(
                modifier = Modifier
                    .background(Color.White.copy(alpha = 0.08f), RoundedCornerShape(12.dp))
                    .border(1.dp, Color.White.copy(alpha = 0.15f), RoundedCornerShape(12.dp))
                    .padding(horizontal = 12.dp, vertical = 6.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Icon(Icons.Default.Search, contentDescription = null, tint = ClueGold, modifier = Modifier.size(16.dp))
                    Text("CLUES: ${collectedClues.size} / ${currentLevel.clues.size}", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Black, fontFamily = FontFamily.Monospace)
                }
            }
        }

        // ── Virtual Touch Controls (Android D-Pad & Float Jump) ──
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.BottomCenter)
                .padding(24.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.Bottom
        ) {
            // Left / Right Movement
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .background(Color.White.copy(alpha = 0.12f), CircleShape)
                        .border(1.5.dp, Color.White.copy(alpha = 0.25f), CircleShape)
                        .pointerInput(Unit) {
                            detectTapGestures(
                                onPress = {
                                    playerVx = -5.0f
                                    tryAwaitRelease()
                                    playerVx = 0f
                                }
                            )
                        },
                    contentAlignment = Alignment.Center
                ) {
                    Icon(Icons.Default.ArrowBack, contentDescription = null, tint = Color.White, modifier = Modifier.size(28.dp))
                }

                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .background(Color.White.copy(alpha = 0.12f), CircleShape)
                        .border(1.5.dp, Color.White.copy(alpha = 0.25f), CircleShape)
                        .pointerInput(Unit) {
                            detectTapGestures(
                                onPress = {
                                    playerVx = 5.0f
                                    tryAwaitRelease()
                                    playerVx = 0f
                                }
                            )
                        },
                    contentAlignment = Alignment.Center
                ) {
                    Icon(Icons.Default.ArrowForward, contentDescription = null, tint = Color.White, modifier = Modifier.size(28.dp))
                }
            }

            // Float Jump Button
            Box(
                modifier = Modifier
                    .size(76.dp)
                    .background(CyanHelium.copy(alpha = 0.25f), CircleShape)
                    .border(2.dp, CyanHelium, CircleShape)
                    .clickable {
                        if (jumpsLeft > 0) {
                            playerVy = -13.0f
                            jumpsLeft--
                        }
                    },
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Default.ArrowUpward, contentDescription = null, tint = Color.White, modifier = Modifier.size(26.dp))
                    Text("JUMP", color = Color.White, fontSize = 9.sp, fontWeight = FontWeight.Black)
                }
            }
        }

        // ── Win Screen Modal ──
        if (hasWonGame) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.85f)),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth(0.85f)
                        .background(CardDark, RoundedCornerShape(24.dp))
                        .border(1.5.dp, CyanHelium.copy(alpha = 0.4f), RoundedCornerShape(24.dp))
                        .padding(28.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text("👑 MISSION ACCOMPLISHED!", color = PortalGreen, fontSize = 20.sp, fontWeight = FontWeight.Black)
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(
                        "Angel Helium collected all clues and escaped the Corrupted Forkbot!",
                        color = TextLight,
                        fontSize = 13.sp
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text("Created by Holo Entertainment by CS", color = CyanHelium, fontSize = 11.sp, fontWeight = FontWeight.Bold, fontFamily = FontFamily.Monospace)
                    Spacer(modifier = Modifier.height(20.dp))
                    Button(
                        onClick = {
                            hasWonGame = false
                            loadLevel(0)
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = CyanHelium),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text("PLAY AGAIN", fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}
