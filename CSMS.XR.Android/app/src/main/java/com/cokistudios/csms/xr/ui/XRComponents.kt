package com.cokistudios.csms.xr.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cokistudios.csms.xr.ui.theme.*

/**
 * Glassmorphic card — simula el efecto de vidrio esmerilado para paneles XR.
 * En Android XR estos paneles flotan en el espacio 3D con profundidad real.
 */
@Composable
fun XRGlassPanel(
    modifier: Modifier = Modifier,
    cornerRadius: Dp = 20.dp,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(cornerRadius))
            .background(GlassSurface)
            .border(1.dp, GlassBorder, RoundedCornerShape(cornerRadius))
            .padding(16.dp),
        content = content
    )
}

/**
 * Avatar circular con iniciales — para usuarios sin foto de perfil.
 * Usa el gradiente de Coki Studios.
 */
@Composable
fun XRAvatarInitials(
    initials: String,
    size: Dp = 40.dp,
    textSize: Int = 16
) {
    val gradient = Brush.linearGradient(listOf(CokiIndigo, CokiPurple))
    Box(
        modifier = Modifier
            .size(size)
            .clip(CircleShape)
            .background(gradient),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = initials.take(1).uppercase(),
            color = Color.White,
            fontSize = textSize.sp,
            fontWeight = FontWeight.Bold
        )
    }
}

/**
 * Indicador de presencia online — punto verde animado junto al nombre del usuario.
 */
@Composable
fun OnlineIndicator(isOnline: Boolean, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .size(8.dp)
            .clip(CircleShape)
            .background(if (isOnline) OnlineGreen else OfflineGray)
    )
}

/**
 * Header de panel XR — título con degradado de Coki Studios y subtítulo.
 */
@Composable
fun XRPanelHeader(title: String, subtitle: String? = null) {
    Column {
        Text(
            text = title,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )
        if (subtitle != null) {
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = TextSecondary
            )
        }
    }
}
