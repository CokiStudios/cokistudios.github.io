package com.cokistudios.csms.xr.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val XRDarkColorScheme = darkColorScheme(
    primary          = CokiIndigo,
    onPrimary        = TextPrimary,
    secondary        = CokiPurple,
    onSecondary      = TextPrimary,
    tertiary         = CokiCyan,
    background       = CokiMidnight,
    onBackground     = TextPrimary,
    surface          = CokiNavy,
    onSurface        = TextPrimary,
    surfaceVariant   = CokiDeepBlue,
    onSurfaceVariant = TextSecondary,
    outline          = GlassBorder,
    error            = UnreadBadge
)

/**
 * CSMS XR theme — always dark for optimal spatial/headset visibility.
 * Android XR headsets render in a dark environment so we default to
 * a deep-space dark scheme with glassmorphic accents.
 */
@Composable
fun CSMSXRTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = XRDarkColorScheme,
        content = content
    )
}
