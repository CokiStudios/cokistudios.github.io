package com.cokistudios.shineui

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * ═══════════════════════════════════════════════════════════════
 * COKI STUDIOS SHINE UI SYSTEM FOR REAL ANDROID (AOSP / Jetpack Compose)
 * Based on CS Design Guide Specifications (Pages 4, 5, 10, 14 & 17)
 * Hardware Target: Shine Phones (A, Nomad, X, i-Fold)
 * ═══════════════════════════════════════════════════════════════
 */

enum class CSUIProfile {
    SHINE_UI, // Base Universal Glass
    HI_UI,    // Gama A (A79, A49, Atom - Android Go)
    XUI,      // Gama X (1A, 240Hz, Snapdragon Elite X)
    FLUI      // Gama i (Flex & Fold Dual-Screen)
}

object ShineColors {
    // Frosted Glass Acrílico Aqua A17 (Page 4)
    val GlassBackground = Color(0xCC0F172A)
    val GlassBorder = Color(0x33FFFFFF)
    val AquaGlow = Color(0xFF38BDF8)
    
    // hi!UI (Gama A)
    val HiAccent = Color(0xFF0EA5E9)
    val HiBackground = Color(0xB30F172A)
    val HiBorder = Color(0x400EA5E9)

    // XUI (Gama X / Cyber Neon Cyan)
    val XuiNeon = Color(0xFF38BDF8)
    val XuiDarkCyan = Color(0xE0082F49)
    val XuiBorder = Color(0x8038BDF8)

    // FlUI (Gama i / Ultra Violet Plegable)
    val FluiViolet = Color(0xFF8B5CF6)
    val FluiMagenta = Color(0xFFD946EF)
    val FluiDeepViolet = Color(0xE02E1065)
    val FluiBorder = Color(0x808B5CF6)
}

/**
 * ── 1. BUBBLY DOT (CS Dynamic Island Component for Android Phones - Page 17) ──
 */
@Composable
fun BubblyDotNotch(
    title: String = "Shine Audio Active",
    isMusicPlaying: Boolean = true,
    modifier: Modifier = Modifier
) {
    val infiniteTransition = rememberInfiniteTransition(label = "BubblyDotTransition")
    val pulse by infiniteTransition.animateFloat(
        initialValue = 4f,
        targetValue = 16f,
        animationSpec = infiniteRepeatable(
            animation = tween(600, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "EqualizerBar"
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(top = 8.dp),
        contentAlignment = Alignment.Center
    ) {
        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(20.dp))
                .background(Color.Black)
                .border(1.5.dp, ShineColors.AquaGlow.copy(alpha = 0.6f), RoundedCornerShape(20.dp))
                .shadow(12.dp, RoundedCornerShape(20.dp), spotColor = ShineColors.AquaGlow)
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            if (isMusicPlaying) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(3.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(modifier = Modifier.width(3.dp).height(pulse.dp).background(ShineColors.AquaGlow, CircleShape))
                    Box(modifier = Modifier.width(3.dp).height((20f - pulse).dp).background(ShineColors.AquaGlow, CircleShape))
                    Box(modifier = Modifier.width(3.dp).height((pulse * 0.8f).dp).background(ShineColors.AquaGlow, CircleShape))
                }
            } else {
                Box(modifier = Modifier.size(8.dp).background(Color(0xFF10B981), CircleShape))
            }

            Text(
                text = title,
                color = Color.White,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

/**
 * ── 2. FROSTED GLASS ACRÍLICO AQUA A17 CARD (Page 4) ──
 */
@Composable
fun ShineGlassCard(
    profile: CSUIProfile = CSUIProfile.SHINE_UI,
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit
) {
    val (backgroundBrush, borderColor) = when (profile) {
        CSUIProfile.HI_UI -> Pair(
            Brush.verticalGradient(listOf(ShineColors.HiBackground, Color(0xFF0F172A))),
            ShineColors.HiBorder
        )
        CSUIProfile.XUI -> Pair(
            Brush.verticalGradient(listOf(ShineColors.XuiDarkCyan, Color(0xFF0F172A))),
            ShineColors.XuiBorder
        )
        CSUIProfile.FLUI -> Pair(
            Brush.verticalGradient(listOf(ShineColors.FluiDeepViolet, Color(0xFF0F172A))),
            ShineColors.FluiBorder
        )
        CSUIProfile.SHINE_UI -> Pair(
            Brush.verticalGradient(listOf(ShineColors.GlassBackground, Color(0xFF0F172A))),
            ShineColors.GlassBorder
        )
    }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(backgroundBrush)
            .border(1.5.dp, borderColor, RoundedCornerShape(20.dp))
            .shadow(16.dp, RoundedCornerShape(20.dp), spotColor = borderColor.copy(alpha = 0.3f))
            .padding(20.dp)
    ) {
        content()
    }
}

/**
 * ── 3. SHINE UI ACTION BUTTON ──
 */
@Composable
fun ShineButton(
    text: String,
    onClick: () -> Unit,
    profile: CSUIProfile = CSUIProfile.SHINE_UI,
    modifier: Modifier = Modifier
) {
    val gradient = when (profile) {
        CSUIProfile.HI_UI -> Brush.horizontalGradient(listOf(Color(0xFF0EA5E9), Color(0xFF0284C7)))
        CSUIProfile.XUI -> Brush.horizontalGradient(listOf(Color(0xFF0284C7), Color(0xFF38BDF8)))
        CSUIProfile.FLUI -> Brush.horizontalGradient(listOf(Color(0xFF8B5CF6), Color(0xFFD946EF)))
        CSUIProfile.SHINE_UI -> Brush.horizontalGradient(listOf(Color(0xFF6366F1), Color(0xFF8B5CF6)))
    }

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(14.dp))
            .background(gradient)
            .clickable { onClick() }
            .padding(horizontal = 24.dp, vertical = 12.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            color = Color.White,
            fontWeight = FontWeight.Bold,
            fontSize = 14.sp
        )
    }
}
