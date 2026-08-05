package com.cokistudios.forkar.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties

@Composable
fun ShineMenuDialog(
    onDismissRequest: () -> Unit,
    title: String,
    onAccept: (() -> Unit)? = null,
    onReject: (() -> Unit)? = null,
    onNext: (() -> Unit)? = null,
    onPrevious: (() -> Unit)? = null
) {
    Dialog(
        onDismissRequest = onDismissRequest,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(0.9f)
                .padding(24.dp),
            contentAlignment = Alignment.Center
        ) {
            // Main Rectangle
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(4.dp),
                color = Color.White,
                border = BorderStroke(6.dp, Color.Black),
                shadowElevation = 0.dp
            ) {
                Column(
                    modifier = Modifier.padding(40.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = title.replace("\\n", "\n"),
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Black,
                        color = Color.Black,
                        textAlign = TextAlign.Center
                    )
                    
                    if (onAccept != null || onReject != null) {
                        Spacer(modifier = Modifier.height(30.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceEvenly
                        ) {
                            if (onReject != null) {
                                ShineColorButton(text = "X", onClick = onReject)
                            }
                            if (onAccept != null) {
                                ShineColorButton(text = "✓", onClick = onAccept)
                            }
                        }
                    }
                }
            }

            // Top Left Close Button
            ShineCornerButton(
                text = "X",
                modifier = Modifier.align(Alignment.TopStart),
                onClick = onDismissRequest
            )

            // Bottom Left Previous
            if (onPrevious != null) {
                ShineCornerButton(
                    text = "←",
                    modifier = Modifier.align(Alignment.BottomStart),
                    onClick = onPrevious
                )
            }

            // Bottom Right Next
            if (onNext != null) {
                ShineCornerButton(
                    text = "→",
                    modifier = Modifier.align(Alignment.BottomEnd),
                    onClick = onNext
                )
            }
        }
    }
}

@Composable
fun ShineCornerButton(text: String, modifier: Modifier, onClick: () -> Unit) {
    Box(
        modifier = modifier
            .size(48.dp)
            .background(Color.White, CircleShape)
            .border(6.dp, Color.Black, CircleShape)
            .clickable { onClick() },
        contentAlignment = Alignment.Center
    ) {
        Text(text = text, fontWeight = FontWeight.Black, fontSize = 22.sp, color = Color.Black)
    }
}

@Composable
fun ShineColorButton(text: String, onClick: () -> Unit) {
    val colorfulGradient = Brush.sweepGradient(
        colors = listOf(
            Color(0xFF2196F3), // Blue
            Color(0xFFFFEB3B), // Yellow
            Color(0xFFF44336), // Red
            Color(0xFF4CAF50), // Green
            Color(0xFF2196F3)
        )
    )
    
    Box(
        modifier = Modifier
            .size(64.dp)
            .background(colorfulGradient, CircleShape)
            .border(6.dp, Color.Black, CircleShape)
            .clickable { onClick() },
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            fontWeight = FontWeight.Black,
            fontSize = 34.sp,
            color = if (text == "X") Color(0xFFF44336) else Color(0xFF4CAF50)
        )
    }
}
