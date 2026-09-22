package com.cokistudios.forkar.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cokistudios.forkar.BuildConfig

@Composable
fun ChannelBadge(
    onClick: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    when {
        BuildConfig.IS_QA -> {
            Box(
                modifier = modifier
                    .border(
                        width = 1.dp,
                        color = Color(0xFFF59E0B),
                        shape = RoundedCornerShape(12.dp)
                    )
                    .background(
                        color = Color(0x22F59E0B),
                        shape = RoundedCornerShape(12.dp)
                    )
                    .clickable { onClick() }
                    .padding(horizontal = 8.dp, vertical = 4.dp),
                contentAlignment = Alignment.Center
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.Info,
                        contentDescription = "QA Testing",
                        tint = Color(0xFFF59E0B),
                        modifier = Modifier.size(13.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "QA BUILD",
                        color = Color(0xFFF59E0B),
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
        BuildConfig.IS_INTERNAL_CS -> {
            val purpleGradient = Brush.horizontalGradient(
                colors = listOf(Color(0xFF8B5CF6), Color(0xFFEC4899))
            )
            Box(
                modifier = modifier
                    .border(
                        width = 1.dp,
                        brush = purpleGradient,
                        shape = RoundedCornerShape(12.dp)
                    )
                    .background(
                        color = Color(0x338B5CF6),
                        shape = RoundedCornerShape(12.dp)
                    )
                    .clickable { onClick() }
                    .padding(horizontal = 8.dp, vertical = 4.dp),
                contentAlignment = Alignment.Center
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.Lock,
                        contentDescription = "CS Internal",
                        tint = Color(0xFFA78BFA),
                        modifier = Modifier.size(12.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "CS TEAM STAFF",
                        color = Color(0xFFE9D5FF),
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
        else -> {
            // Production: No banner needed, clean look
        }
    }
}
