package com.cokistudios.forkar

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.Alignment
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.lifecycle.lifecycleScope
import androidx.navigation.NavController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.cokistudios.forkar.data.Post
import com.cokistudios.forkar.data.SupabaseManager
import com.cokistudios.forkar.ui.screens.CreatePostScreen
import com.cokistudios.forkar.ui.screens.HomeScreen
import com.cokistudios.forkar.ui.screens.LoginScreen
import com.cokistudios.forkar.ui.screens.PostDetailScreen
import com.cokistudios.forkar.ui.screens.ProfileScreen
import com.cokistudios.forkar.ui.theme.ForkarTheme
import com.cokistudios.forkar.ui.theme.IndigoPrimary
import com.cokistudios.forkar.ui.components.XtrapsBackground
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {

    private lateinit var manager: SupabaseManager
    private var navController: NavController? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        manager = SupabaseManager.getInstance(this)

        setContent {
            ForkarTheme {
                val controller = rememberNavController()
                navController = controller

                var activePost by remember { mutableStateOf<Post?>(null) }

                NavHost(
                    navController = controller,
                    startDestination = "main",
                    modifier = Modifier.fillMaxSize()
                ) {
                    composable("main") {
                        MainContainerScreen(
                            manager = manager,
                            onPostClick = { post ->
                                activePost = post
                                controller.navigate("post_detail")
                            },
                            onCreatePostClick = {
                                controller.navigate("create_post")
                            },
                            onLoginRequired = {
                                controller.navigate("login")
                            }
                        )
                    }

                    composable("login") {
                        LoginScreen(
                            manager = manager,
                            onLoginSuccess = {
                                controller.popBackStack()
                            },
                            onBack = {
                                controller.popBackStack()
                            }
                        )
                    }

                    composable("create_post") {
                        CreatePostScreen(
                            manager = manager,
                            onBack = {
                                controller.popBackStack()
                            }
                        )
                    }

                    composable("post_detail") {
                        val post = activePost
                        if (post != null) {
                            PostDetailScreen(
                                post = post,
                                manager = manager,
                                onBack = {
                                    controller.popBackStack()
                                },
                                onLoginRequired = {
                                    controller.navigate("login")
                                }
                            )
                        } else {
                            controller.popBackStack()
                        }
                    }
                }
            }
        }

        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val data = intent?.data
        if (data != null && data.scheme == "forkar" && data.host == "oauth") {
            val url = data.toString()
            lifecycleScope.launch {
                try {
                    manager.handleOAuthCallback(url)
                    Toast.makeText(this@MainActivity, "Inicio de sesión correcto", Toast.LENGTH_SHORT).show()
                    navController?.navigate("main") {
                        popUpTo("main") { inclusive = true }
                    }
                } catch (e: Exception) {
                    Toast.makeText(this@MainActivity, e.message ?: "Error de autenticación", Toast.LENGTH_LONG).show()
                }
            }
        }
    }
}

@Composable
fun MainContainerScreen(
    manager: SupabaseManager,
    onPostClick: (Post) -> Unit,
    onCreatePostClick: () -> Unit,
    onLoginRequired: () -> Unit
) {
    var selectedTab by remember { mutableIntStateOf(0) }

    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = Color.Transparent
            ) {
                NavigationBarItem(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    icon = { Icon(Icons.Default.Home, contentDescription = "Inicio") },
                    label = { Text("Inicio") },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = IndigoPrimary,
                        selectedTextColor = IndigoPrimary
                    )
                )

                NavigationBarItem(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    icon = { Icon(Icons.Default.Person, contentDescription = "Mi Perfil") },
                    label = { Text("Mi Perfil") },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = IndigoPrimary,
                        selectedTextColor = IndigoPrimary
                    )
                )
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            XtrapsBackground(
                opacity = 0.15f
            )

            when (selectedTab) {
                0 -> HomeScreen(
                    manager = manager,
                    onPostClick = onPostClick,
                    onCreatePostClick = onCreatePostClick,
                    onLoginRequired = onLoginRequired
                )
                1 -> ProfileScreen(
                    manager = manager,
                    onLoginClick = onLoginRequired,
                    onPostClick = onPostClick
                )
            }
        }
    }
}
