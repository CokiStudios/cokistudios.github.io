package com.cokistudios.csms.meta.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val MetaDarkColors = darkColorScheme(
    primary          = MetaIndigo,
    onPrimary        = TextPrimary,
    secondary        = MetaPurple,
    onSecondary      = TextPrimary,
    tertiary         = MetaCyan,
    background       = MetaMidnight,
    onBackground     = TextPrimary,
    surface          = MetaNavy,
    onSurface        = TextPrimary,
    surfaceVariant   = MetaDeep,
    onSurfaceVariant = TextSecondary,
    outline          = GlassBorder,
    error            = UnreadBadge
)

/**
 * Theme para Meta Horizon OS — siempre oscuro para maximizar
 * el contraste en las pantallas pancake lenses de Quest 2/3/Pro.
 */
@Composable
fun CSMSMetaTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = MetaDarkColors,
        content = content
    )
}
