package com.cokistudios.looprunner

import android.annotation.SuppressLint
import android.content.Context
import android.os.Bundle
import android.view.ViewGroup
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.view.WindowCompat

/**
 * ═══════════════════════════════════════════════════════════════
 * LOOPING NATIVE ANDROID RUNTIME HOST (APK ENGINE)
 * Executes .loop games directly on Android & Shine Phones at 60/120 FPS
 * ═══════════════════════════════════════════════════════════════
 */

class LoopingHostActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Fullscreen Gaming Immersion
        WindowCompat.setDecorFitsSystemWindows(window, false)

        setContent {
            LoopingGameView(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color(0xFF06090F))
            )
        }
    }
}

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun LoopingGameView(modifier: Modifier = Modifier) {
    AndroidView(
        modifier = modifier,
        factory = { context ->
            WebView(context).apply {
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )

                settings.apply {
                    javaScriptEnabled = true
                    domStorageEnabled = true
                    databaseEnabled = true
                    mediaPlaybackRequiresUserGesture = false
                    cacheMode = WebSettings.LOAD_DEFAULT
                    allowFileAccess = true
                    allowContentAccess = true
                }

                setBackgroundColor(0xFF06090F.toInt())
                webChromeClient = WebChromeClient()
                webViewClient = WebViewClient()

                // Load the packaged .loop runtime from assets
                loadUrl("file:///android_asset/loop_game.html")
            }
        }
    )
}
