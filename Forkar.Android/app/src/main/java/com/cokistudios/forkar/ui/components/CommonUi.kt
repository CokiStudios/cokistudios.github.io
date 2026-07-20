package com.cokistudios.forkar.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
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
import com.cokistudios.forkar.ui.theme.BorderDark
import com.cokistudios.forkar.ui.theme.BorderLight
import com.cokistudios.forkar.ui.theme.CardDark
import com.cokistudios.forkar.ui.theme.CardLight
import com.cokistudios.forkar.ui.theme.IndigoPrimary
import com.cokistudios.forkar.ui.theme.PurpleAccent2

@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    shape: RoundedCornerShape = RoundedCornerShape(16.dp),
    content: @Composable BoxScope.() -> Unit
) {
    val isDark = isSystemInDarkTheme()
    val bgColor = if (isDark) CardDark else CardLight
    val borderColor = if (isDark) BorderDark else BorderLight

    Box(
        modifier = modifier
            .clip(shape)
            .background(bgColor)
            .border(1.dp, borderColor, shape)
            .padding(16.dp),
        content = content
    )
}

@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    val gradient = Brush.linearGradient(
        colors = listOf(IndigoPrimary, PurpleAccent2)
    )

    val backgroundModifier = if (enabled) {
        Modifier.background(gradient)
    } else {
        Modifier.background(Color.Gray.copy(alpha = 0.5f))
    }

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .then(backgroundModifier)
            .clickable(enabled = enabled) { onClick() }
            .padding(vertical = 12.dp, horizontal = 24.dp),
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

@Composable
fun SecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    val isDark = isSystemInDarkTheme()
    val bgColor = if (isDark) CardDark else CardLight
    val borderColor = if (isDark) BorderDark else BorderLight
    val textColor = MaterialTheme.colorScheme.onBackground

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(bgColor)
            .border(1.dp, borderColor, RoundedCornerShape(12.dp))
            .clickable(enabled = enabled) { onClick() }
            .padding(vertical = 12.dp, horizontal = 24.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            color = textColor,
            fontWeight = FontWeight.SemiBold,
            fontSize = 14.sp
        )
    }
}

@Composable
fun CircleAvatarPlaceholder(
    initials: String,
    modifier: Modifier = Modifier,
    size: Dp = 32.dp,
    textSize: Int = 12
) {
    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(IndigoPrimary.copy(alpha = 0.15f)),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = initials,
            color = IndigoPrimary,
            fontWeight = FontWeight.Bold,
            fontSize = textSize.sp
        )
    }
}
