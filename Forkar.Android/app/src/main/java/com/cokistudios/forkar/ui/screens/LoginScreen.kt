package com.cokistudios.forkar.ui.screens

import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
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
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
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
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cokistudios.forkar.data.SupabaseManager
import com.cokistudios.forkar.ui.components.GlassCard
import com.cokistudios.forkar.ui.components.PrimaryButton
import com.cokistudios.forkar.ui.theme.BorderDark
import com.cokistudios.forkar.ui.theme.BorderLight
import com.cokistudios.forkar.ui.theme.CardDark
import com.cokistudios.forkar.ui.theme.CardLight
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

    val isDark = isSystemInDarkTheme()
    val bgColors = if (isDark) {
        listOf(Color(0xFF0D1117), Color(0xFF06090F))
    } else {
        listOf(Color(0xFFF1F5F9), Color(0xFFF8FAFC))
    }

    val handleOAuth = { provider: String ->
        val authUrl = "${manager.baseURL}/auth/v1/authorize?provider=$provider&redirect_to=forkar://oauth"
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(authUrl))
        context.startActivity(intent)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Autenticación") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent,
                    titleContentColor = MaterialTheme.colorScheme.onBackground
                )
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
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onBackground
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "Conéctate con otros jugadores y comparte tus ideas",
                        fontSize = 13.sp,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f),
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
                            text = if (isRegistering) "Crear Cuenta" else "Iniciar Sesión",
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp,
                            color = MaterialTheme.colorScheme.onBackground
                        )

                        if (isRegistering) {
                            OutlinedTextField(
                                value = name,
                                onValueChange = { name = it },
                                placeholder = { Text("Nombre Completo") },
                                leadingIcon = { Icon(Icons.Default.Person, contentDescription = null) },
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(12.dp)
                            )

                            OutlinedTextField(
                                value = company,
                                onValueChange = { company = it },
                                placeholder = { Text("Biografía / Estado (opcional)") },
                                leadingIcon = { Icon(Icons.Default.Info, contentDescription = null) },
                                modifier = Modifier.fillMaxWidth(),
                                shape = RoundedCornerShape(12.dp)
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
                                        .background(if (isDark) CardDark else CardLight)
                                        .border(1.dp, if (isDark) BorderDark else BorderLight, RoundedCornerShape(12.dp))
                                        .clickable { handleOAuth("google") }
                                        .padding(vertical = 12.dp),
                                    horizontalArrangement = Arrangement.Center,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = "Continuar con Google",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 14.sp,
                                        color = MaterialTheme.colorScheme.onBackground
                                    )
                                }

                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(Color.Black.copy(alpha = 0.4f))
                                        .border(1.dp, if (isDark) BorderDark else BorderLight, RoundedCornerShape(12.dp))
                                        .clickable { handleOAuth("github") }
                                        .padding(vertical = 12.dp),
                                    horizontalArrangement = Arrangement.Center,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = "Continuar con GitHub",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 14.sp,
                                        color = Color.White
                                    )
                                }
                            }

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Divider(modifier = Modifier.weight(1f))
                                Text(
                                    text = "o usa tu correo",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    modifier = Modifier.padding(horizontal = 8.dp),
                                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.5f)
                                )
                                Divider(modifier = Modifier.weight(1f))
                            }
                        }

                        OutlinedTextField(
                            value = email,
                            onValueChange = { email = it },
                            placeholder = { Text("Correo Electrónico") },
                            leadingIcon = { Icon(Icons.Default.Email, contentDescription = null) },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(12.dp)
                        )

                        OutlinedTextField(
                            value = password,
                            onValueChange = { password = it },
                            placeholder = { Text("Contraseña") },
                            leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null) },
                            visualTransformation = if (showPassword) VisualTransformation.None else PasswordVisualTransformation(),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                            trailingIcon = {
                                IconButton(onClick = { showPassword = !showPassword }) {
                                    Text(if (showPassword) "Ocultar" else "Mostrar", fontSize = 11.sp)
                                }
                            },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(12.dp)
                        )

                        AnimatedVisibility(visible = errorMessage.isNotEmpty()) {
                            Text(
                                text = errorMessage,
                                color = Color.Red,
                                fontSize = 12.sp
                            )
                        }

                        PrimaryButton(
                            text = if (isRegistering) "Crear cuenta" else "Iniciar sesión",
                            onClick = {
                                if (email.isBlank() || password.isBlank()) {
                                    errorMessage = "Completa todos los campos"
                                    return@PrimaryButton
                                }
                                if (isRegistering && name.isBlank()) {
                                    errorMessage = "Completa tu nombre"
                                    return@PrimaryButton
                                }

                                coroutineScope.launch {
                                    isLoading = true
                                    errorMessage = ""
                                    try {
                                        if (isRegistering) {
                                            manager.signUp(email, password, name, company.ifBlank { null })
                                        } else {
                                            manager.login(email, password)
                                        }
                                        Toast.makeText(context, "Bienvenido", Toast.LENGTH_SHORT).show()
                                        onLoginSuccess()
                                    } catch (e: Exception) {
                                        errorMessage = e.message ?: "Ocurrió un error"
                                    } finally {
                                        isLoading = false
                                    }
                                }
                            },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = !isLoading
                        )

                        if (isLoading) {
                            Box(
                                modifier = Modifier.fillMaxWidth(),
                                contentAlignment = Alignment.Center
                            ) {
                                CircularProgressIndicator(color = IndigoPrimary)
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                Text(
                    text = if (isRegistering) "¿Ya tienes cuenta? Inicia sesión" else "¿No tienes cuenta? Regístrate gratis",
                    color = IndigoPrimary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier
                        .clickable {
                            isRegistering = !isRegistering
                            errorMessage = ""
                        }
                        .padding(8.dp)
                )

                Spacer(modifier = Modifier.height(40.dp))
            }
        }
    }
}
