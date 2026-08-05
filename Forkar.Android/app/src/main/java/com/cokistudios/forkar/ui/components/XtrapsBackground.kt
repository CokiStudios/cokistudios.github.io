package com.cokistudios.forkar.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import com.cokistudios.forkar.ui.theme.IndigoPrimary
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun XtrapsBackground(
    modifier: Modifier = Modifier,
    strokeColor: Color = IndigoPrimary,
    opacity: Float = 0.55f,
    animated: Boolean = true,
    lineWidth: Float = 6f
) {
    val infiniteTransition = rememberInfiniteTransition(label = "xtraps")
    val phase by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = (2 * kotlin.math.PI).toFloat(),
        animationSpec = infiniteRepeatable(
            animation = tween(5000, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "phase"
    )

    val currentPhase = if (animated) phase else 0f

    Canvas(modifier = modifier.fillMaxSize()) {
        val w = size.width
        val h = size.height

        val wave1Path = Path().apply {
            val s1 = sin(currentPhase) * 40f
            val c1 = cos(currentPhase) * 30f
            moveTo(0f, h * 0.16f + s1)
            cubicTo(
                w * 0.15f, h * 0.16f - c1, 
                w * 0.30f, h * 0.35f + s1, 
                w * 0.45f, h * 0.58f - c1
            )
            cubicTo(
                w * 0.58f, h * 0.76f + s1, 
                w * 0.70f, h * 0.78f - c1, 
                w * 0.82f, h * 0.62f + s1
            )
            cubicTo(
                w * 0.90f, h * 0.50f - c1, 
                w * 0.96f, h * 0.28f + s1, 
                w, h * 0.13f - c1
            )
        }

        val wave2Path = Path().apply {
            val s1 = sin(currentPhase) * 40f
            val c1 = cos(currentPhase) * 30f
            moveTo(0f, h * 0.43f - c1)
            cubicTo(
                w * 0.15f, h * 0.37f + s1, 
                w * 0.35f, h * 0.32f - c1, 
                w * 0.55f, h * 0.32f + s1
            )
            cubicTo(
                w * 0.72f, h * 0.32f - c1, 
                w * 0.83f, h * 0.42f + s1, 
                w * 0.88f, h * 0.34f - c1
            )
            cubicTo(
                w * 0.93f, h * 0.22f + s1, 
                w * 0.97f, h * 0.08f - c1, 
                w, 0f + s1
            )
        }

        val gradient1 = Brush.linearGradient(
            colors = listOf(
                strokeColor.copy(alpha = opacity * 0.5f),
                strokeColor.copy(alpha = opacity * 1.0f),
                strokeColor.copy(alpha = opacity * 0.6f)
            ),
            start = Offset.Zero,
            end = Offset(w, 0f)
        )

        drawPath(
            path = wave1Path,
            brush = gradient1,
            style = Stroke(
                width = lineWidth,
                cap = StrokeCap.Round,
                join = StrokeJoin.Round
            )
        )

        val gradient2 = Brush.linearGradient(
            colors = listOf(
                strokeColor.copy(alpha = opacity * 0.4f),
                strokeColor.copy(alpha = opacity * 0.85f),
                strokeColor.copy(alpha = opacity * 1.0f)
            ),
            start = Offset.Zero,
            end = Offset(w, 0f)
        )

        drawPath(
            path = wave2Path,
            brush = gradient2,
            style = Stroke(
                width = lineWidth,
                cap = StrokeCap.Round,
                join = StrokeJoin.Round
            )
        )
    }
}
