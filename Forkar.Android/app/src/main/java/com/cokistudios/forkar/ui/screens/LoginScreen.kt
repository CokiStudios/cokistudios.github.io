package com.cokistudios.forkar.ui.screens

import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cokistudios.forkar.data.SupabaseManager
import com.cokistudios.forkar.ui.components.GlassCard
import com.cokistudios.forkar.ui.components.LiquidGlassTopBar
import com.cokistudios.forkar.ui.components.PrimaryButton
import com.cokistudios.forkar.ui.theme.IndigoPrimary
import com.cokistudios.forkar.ui.theme.PurpleAccent2
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LoginScreen(
    manager: SupabaseManager,
    onLoginSuccess: () -> Unit,
    onBack: () -> Unit
) {
    var isRegistering by remember { mutableStateOf(false) }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var name by remember { mutableStateOf("") }
    var company by remember { mutableStateOf("") }
    var errorMessage by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var showPassword by remember { mutableStateOf(false) }

    val coroutineScope = rememberCoroutineScope()
    val context = LocalContext.current
    val scrollState = rememberScrollState()

    val bgColors = listOf(Color(0xFF0F172A), Color(0xFF06090F))

    val textFieldColors = OutlinedTextFieldDefaults.colors(
        focusedTextColor = Color.White,
        unfocusedTextColor = Color.White,
        focusedBorderColor = IndigoPrimary,
        unfocusedBorderColor = Color.White.copy(alpha = 0.3f),
        focusedLabelColor = IndigoPrimary,
        unfocusedLabelColor = Color(0xFFCBD5E1),
        focusedLeadingIconColor = Color.White,
        unfocusedLeadingIconColor = Color(0xFFCBD5E1),
        focusedTrailingIconColor = Color.White,
        unfocusedTrailingIconColor = Color(0xFFCBD5E1),
        cursorColor = Color.White,
        focusedPlaceholderColor = Color(0xFF94A3B8),
        unfocusedPlaceholderColor = Color(0xFF64748B)
    )

    val handleOAuth = { provider: String ->
        val authUrl = "${manager.baseURL}/auth/v1/authorize?provider=$provider&redirect_to=forkar://oauth"
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(authUrl))
        context.startActivity(intent)
    }

    Scaffold(
        topBar = {
            LiquidGlassTopBar(
                title = "Autenticación",
                subtitle = "Acceso seguro con CS ID",
                icon = Icons.Default.Lock,
                iconColor = IndigoPrimary
            )
        },
        containerColor = Color.Transparent
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Brush.verticalGradient(bgColors))
                .padding(paddingValues)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(scrollState)
                    .padding(horizontal = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Spacer(modifier = Modifier.height(20.dp))

                // Logo Branding
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                    modifier = Modifier.padding(bottom = 24.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(64.dp)
                            .clip(RoundedCornerShape(16.dp))
                            .background(Brush.linearGradient(listOf(IndigoPrimary, PurpleAccent2))),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "F",
                            color = Color.White,
                            fontSize = 32.sp,
                            fontWeight = FontWeight.Black
                        )
                    }
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = "Forkar",
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Black,
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "Conéctate con otros builders y comparte tus ideas",
                        fontSize = 13.sp,
                        color = Color(0xFFCBD5E1),
                        textAlign = TextAlign.Center
                    )
                }

                // Form Card
                GlassCard(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Text(
                            text = if (isRegistering) "Crear Cuenta Coki ID" else "Iniciar Sesión Coki ID",
                            fontWeight = FontWeight.Black,
                            fontSize = 18.sp,
                            color = Color.White
                        )

                        if (isRegistering) {
                            OutlinedTextField(
                                value = name,
                                onValueChange = { name = it },
                                placeholder = { Text("Nombre Completo") },
                                leadingIcon = { Icon(Icons.Default.Person, contentDescription = null) },
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(12.dp),
                                colors = textFieldColors
                            )

                            OutlinedTextField(
                                value = company,
                                onValueChange = { company = it },
                                placeholder = { Text("Biografía / Estado (opcional)") },
                                leadingIcon = { Icon(Icons.Default.Info, contentDescription = null) },
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(12.dp),
                                colors = textFieldColors
                            )
                        } else {
                            // OAuth Social Buttons
                            Column(
                                modifier = Modifier.fillMaxWidth(),
                                verticalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(Color(0x1EFFFFFF))
                                        .border(1.dp, Color(0x33FFFFFF), RoundedCornerShape(12.dp))
                                        .clickable { handleOAuth("google") }
                                        .padding(vertical = 12.dp),
                                    horizontalArrangement = Arrangement.Center,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = "Continuar con Google 🌐",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 14.sp,
                                        color = Color.White
                                    )
                                }
                            }

                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Divider(modifier = Modifier.weight(1f), color = Color.White.copy(alpha = 0.2f))
                                Text(
                                    text = "  o con tu correo  ",
                                    fontSize = 12.sp,
                                    color = Color(0xFFCBD5E1)
                                )
                                Divider(modifier = Modifier.weight(1f), color = Color.White.copy(alpha = 0.2f))
                            }
                        }

                        OutlinedTextField(
                            value = email,
                            onValueChange = { email = it; errorMessage = "" },
                            placeholder = { Text("correo@ejemplo.com") },
                            leadingIcon = { Icon(Icons.Default.Email, contentDescription = null) },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(12.dp),
                            colors = textFieldColors
                        )

                        OutlinedTextField(
                            value = password,
                            onValueChange = { password = it; errorMessage = "" },
                            placeholder = { Text("Contraseña") },
                            leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null) },
                            visualTransformation = if (showPassword) VisualTransformation.None else PasswordVisualTransformation(),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(12.dp),
                            colors = textFieldColors
                        )

                        AnimatedVisibility(visible = errorMessage.isNotEmpty()) {
                            Text(
                                text = errorMessage,
                                color = Color(0xFFEF4444),
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(vertical = 4.dp)
                            )
                        }

                        PrimaryButton(
                            text = if (isLoading) "Procesando..." else if (isRegistering) "Registrarme" else "Entrar",
                            onClick = {
                                if (email.isBlank() || password.isBlank()) {
                                    errorMessage = "Completa todos los campos obligatorios"
                                    return@PrimaryButton
                                }
                                isLoading = true
                                coroutineScope.launch {
                                    try {
                                        if (isRegistering) {
                                            manager.signUp(email, password, name, company)
                                            Toast.makeText(context, "Cuenta creada exitosamente", Toast.LENGTH_LONG).show()
                                        } else {
                                            manager.login(email, password)
                                        }
                                        onLoginSuccess()
                                    } catch (e: Exception) {
                                        errorMessage = e.message ?: "Error al autenticar"
                                    } finally {
                                        isLoading = false
                                    }
                                }
                            },
                            enabled = !isLoading,
                            modifier = Modifier.fillMaxWidth()
                        )

                        Spacer(modifier = Modifier.height(4.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.Center
                        ) {
                            Text(
                                text = if (isRegistering) "¿Ya tienes cuenta? " else "¿No tienes cuenta aún? ",
                                fontSize = 13.sp,
                                color = Color(0xFFCBD5E1)
                            )
                            Text(
                                text = if (isRegistering) "Inicia Sesión" else "Regístrate gratis",
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Black,
                                color = IndigoPrimary,
                                modifier = Modifier.clickable {
                                    isRegistering = !isRegistering
                                    errorMessage = ""
                                }
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(40.dp))
            }
        }
    }
}
