package com.cokistudios.forkar.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun LiquidGlassTopBar(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    icon: ImageVector? = null,
    iconColor: Color = Color(0xFF6366F1),
    actions: @Composable RowScope.() -> Unit = {}
) {
    val glassBg = Brush.linearGradient(
        colors = listOf(
            Color(0xFF0F172A).copy(alpha = 0.95f),
            Color(0xFF1E1B4B).copy(alpha = 0.90f)
        )
    )

    val glassBorder = Brush.linearGradient(
        colors = listOf(
            Color.White.copy(alpha = 0.60f),
            iconColor.copy(alpha = 0.65f),
            Color.White.copy(alpha = 0.20f)
        )
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 6.dp)
            .clip(RoundedCornerShape(24.dp))
            .background(glassBg)
            .border(1.5.dp, glassBorder, RoundedCornerShape(24.dp))
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (icon != null) {
                    Box(
                        modifier = Modifier
                            .size(38.dp)
                            .clip(CircleShape)
                            .background(
                                Brush.linearGradient(
                                    colors = listOf(iconColor.copy(alpha = 0.40f), iconColor.copy(alpha = 0.18f))
                                )
                            )
                            .border(1.2.dp, iconColor.copy(alpha = 0.70f), CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = icon,
                            contentDescription = null,
                            tint = iconColor,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                }

                Column {
                    Text(
                        text = title,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Black,
                        color = Color.White,
                        letterSpacing = (-0.3).sp
                    )
                    if (!subtitle.isNullOrBlank()) {
                        Text(
                            text = subtitle,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFFC7D2FE)
                        )
                    }
                }
            }

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                content = actions
            )
        }
    }
}

data class LiquidNavItem(
    val title: String,
    val icon: ImageVector,
    val accentColor: Color = Color(0xFF6366F1)
)

@Composable
fun LiquidGlassNavigationBar(
    items: List<LiquidNavItem>,
    selectedIndex: Int,
    onItemSelected: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    val navGlassBg = Brush.verticalGradient(
        colors = listOf(
            Color(0xFF0F172A).copy(alpha = 0.96f),
            Color(0xFF1E1B4B).copy(alpha = 0.94f)
        )
    )

    val glassBorder = Brush.linearGradient(
        colors = listOf(
            Color.White.copy(alpha = 0.65f),
            Color(0xFF818CF8).copy(alpha = 0.50f),
            Color.White.copy(alpha = 0.20f)
        )
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 14.dp, vertical = 8.dp),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(30.dp))
                .background(navGlassBg)
                .border(1.5.dp, glassBorder, RoundedCornerShape(30.dp))
                .padding(horizontal = 8.dp, vertical = 6.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                items.forEachIndexed { index, item ->
                    val isSelected = selectedIndex == index
                    val scale by animateFloatAsState(
                        targetValue = if (isSelected) 1.05f else 1.0f,
                        animationSpec = tween(durationMillis = 180), label = "tabScale"
                    )

                    val pillBg = if (isSelected) {
                        Brush.horizontalGradient(
                            colors = listOf(
                                item.accentColor.copy(alpha = 0.40f),
                                item.accentColor.copy(alpha = 0.20f)
                            )
                        )
                    } else {
                        Brush.linearGradient(listOf(Color.Transparent, Color.Transparent))
                    }

                    val pillBorder = if (isSelected) {
                        item.accentColor.copy(alpha = 0.70f)
                    } else {
                        Color.Transparent
                    }

                    val textColor by animateColorAsState(
                        targetValue = if (isSelected) Color.White else Color(0xFFE2E8F0),
                        label = "textColor"
                    )

                    Box(
                        modifier = Modifier
                            .scale(scale)
                            .clip(RoundedCornerShape(22.dp))
                            .background(pillBg)
                            .border(1.2.dp, pillBorder, RoundedCornerShape(22.dp))
                            .clickable { onItemSelected(index) }
                            .padding(horizontal = 14.dp, vertical = 8.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.Center
                        ) {
                            Icon(
                                imageVector = item.icon,
                                contentDescription = item.title,
                                tint = if (isSelected) item.accentColor else Color(0xFFCBD5E1),
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = item.title,
                                fontSize = 13.sp,
                                fontWeight = if (isSelected) FontWeight.Black else FontWeight.ExtraBold,
                                color = textColor
                            )
                        }
                    }
                }
            }
        }
    }
}
