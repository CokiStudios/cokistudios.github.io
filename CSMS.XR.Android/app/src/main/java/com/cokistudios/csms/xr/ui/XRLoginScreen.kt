package com.cokistudios.csms.xr.ui

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.cokistudios.csms.xr.data.SupabaseManager
import com.cokistudios.csms.xr.ui.theme.*
import kotlinx.coroutines.launch

/**
 * LoginScreen — Pantalla de autenticación optimizada para Android XR.
 * En headsets XR se muestra como un SpatialPanel centrado con fondo translúcido.
 */
@Composable
fun XRLoginScreen(
    manager: SupabaseManager,
    onSuccess: () -> Unit
) {
    val scope = rememberCoroutineScope()
    var isRegistering by remember { mutableStateOf(false) }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var name by remember { mutableStateOf("") }
    var showPassword by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMsg by remember { mutableStateOf<String?>(null) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Brush.radialGradient(
                listOf(CokiNavy, CokiMidnight, CokiDeepBlue)
            )),
        contentAlignment = Alignment.Center
    ) {
        Card(
            modifier = Modifier
                .width(420.dp)
                .wrapContentHeight(),
            shape = RoundedCornerShape(24.dp),
            colors = CardDefaults.cardColors(containerColor = GlassSurface)
        ) {
            Column(
                modifier = Modifier.padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Logo / branding
                Text("⬡", fontSize = 40.sp, color = CokiIndigo)
                Text(
                    "CSMS XR",
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
                Text(
                    if (isRegistering) "Crear cuenta" else "Inicia sesión para continuar",
                    fontSize = 13.sp, color = TextSecondary
                )

                Spacer(Modifier.height(4.dp))

                // Name field (register only)
                AnimatedVisibility(visible = isRegistering) {
                    OutlinedTextField(
                        value = name,
                        onValueChange = { name = it },
                        label = { Text("Nombre") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        colors = xrFieldColors()
                    )
                }

                OutlinedTextField(
                    value = email,
                    onValueChange = { email = it },
                    label = { Text("Correo electrónico") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                    colors = xrFieldColors()
                )

                OutlinedTextField(
                    value = password,
                    onValueChange = { password = it },
                    label = { Text("Contraseña") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    visualTransformation = if (showPassword) VisualTransformation.None else PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                    trailingIcon = {
                        IconButton(onClick = { showPassword = !showPassword }) {
                            Text(if (showPassword) "👁" else "🔒", fontSize = 16.sp)
                        }
                    },
                    colors = xrFieldColors()
                )

                // Error message
                errorMsg?.let {
                    Text(it, color = UnreadBadge, fontSize = 12.sp)
                }

                // Action button
                Button(
                    onClick = {
                        scope.launch {
                            isLoading = true
                            errorMsg = null
                            try {
                                if (isRegistering) {
                                    manager.signUp(email.trim(), password, name.trim())
                                } else {
                                    manager.login(email.trim(), password)
                                }
                                onSuccess()
                            } catch (e: Exception) {
                                errorMsg = e.message
                            } finally {
                                isLoading = false
                            }
                        }
                    },
                    enabled = !isLoading && email.isNotBlank() && password.isNotBlank(),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = CokiIndigo),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    if (isLoading) CircularProgressIndicator(Modifier.size(18.dp), color = TextPrimary, strokeWidth = 2.dp)
                    else Text(if (isRegistering) "Registrarse" else "Ingresar", fontWeight = FontWeight.SemiBold)
                }

                // Toggle register/login
                TextButton(onClick = {
                    isRegistering = !isRegistering
                    errorMsg = null
                }) {
                    Text(
                        if (isRegistering) "¿Ya tienes cuenta? Inicia sesión"
                        else "¿Sin cuenta? Regístrate",
                        color = CokiCyan, fontSize = 13.sp
                    )
                }
            }
        }
    }
}

@Composable
private fun xrFieldColors() = OutlinedTextFieldDefaults.colors(
    focusedTextColor = TextPrimary,
    unfocusedTextColor = TextPrimary,
    focusedBorderColor = CokiIndigo,
    unfocusedBorderColor = GlassBorder,
    focusedLabelColor = CokiCyan,
    unfocusedLabelColor = TextSecondary,
    cursorColor = CokiCyan
)
