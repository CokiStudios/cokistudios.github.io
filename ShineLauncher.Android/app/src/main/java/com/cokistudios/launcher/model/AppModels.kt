package com.cokistudios.launcher.model

import android.graphics.drawable.Drawable

/**
 * Data model representing an installed app on Android 15/16/17.
 */
data class AppInfo(
    val label: String,
    val packageName: String,
    val activityName: String,
    val icon: Drawable,
    val isSystemApp: Boolean = false
)

/**
 * The 5 Official Coki Studios UI Experience Modes
 */
enum class LauncherMode(val displayName: String, val badgeTitle: String, val description: String) {
    FLUI(
        "🦋 flUI (Plegables)",
        "🦋 flUI HINGE ADAPTIVE ENGINE",
        "Modo plegable continuo para Shine f1, i1 y fW1. Soporta vista dividida y modo Flex a 90°."
    ),
    XUI(
        "⚡ XuI (Gama Alta)",
        "⚡ XuI ZERO-LATENCY FRAME ENGINE",
        "Rendimiento extremo sin capas pesadas en GPU. Hasta 240Hz para X1 y Xa1."
    ),
    UI(
        "🌿 UI (Nomad 1)",
        "🌿 UI CLEAN ERGONOMIC GLASS",
        "Diseño equilibrado con autonomía de 3 días y navegación Shine Maps para el día a día."
    ),
    HIUI(
        "💡 hiUI (A1)",
        "💡 hiUI ESSENTIAL LIGHT ENGINE",
        "Ultra-ligero, diseñado para consumir menos de la mitad de RAM y volar en 3-4GB."
    ),
    VINTAGE(
        "📻 Vintage (niminticos)",
        "📻 niminticos VINTAGE CLASSIC",
        "Formato clásico sin distracciones con tUIlbar curvada inferior adaptada a la mano."
    )
}
