package com.cokistudios.shinemaps.auto

import android.content.Intent
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.view.Surface
import androidx.car.app.AppManager
import androidx.car.app.Screen
import androidx.car.app.Session
import androidx.car.app.SurfaceCallback
import androidx.car.app.SurfaceContainer

class ShineCarSession : Session() {

    override fun onCreateScreen(intent: Intent): Screen {
        setupSurfaceRendering()
        return ShineHomeScreen(carContext)
    }

    private fun setupSurfaceRendering() {
        val appManager = carContext.getCarService(AppManager::class.java)
        appManager.setSurfaceCallback(object : SurfaceCallback {
            override fun onSurfaceAvailable(surfaceContainer: SurfaceContainer) {
                surfaceContainer.surface?.let { renderMapSurface(it) }
            }

            override fun onVisibleAreaChanged(visibleArea: Rect) {}

            override fun onStableAreaChanged(stableArea: Rect) {}

            override fun onSurfaceDestroyed(surfaceContainer: SurfaceContainer) {}
        })
    }

    private fun renderMapSurface(surface: Surface) {
        try {
            val canvas = surface.lockCanvas(null)
            if (canvas != null) {
                // Draw dark obsidian background
                canvas.drawColor(0xFF020617.toInt())

                val gridPaint = Paint().apply {
                    color = 0xFF0f172a.toInt()
                    strokeWidth = 2f
                    style = Paint.Style.STROKE
                }

                val w = canvas.width.toFloat()
                val h = canvas.height.toFloat()

                // Draw subtle road grid
                for (i in 0..10) {
                    val y = h * (i / 10f)
                    canvas.drawLine(0f, y, w, y, gridPaint)
                }

                // Glowing route path (cyan)
                val routePaint = Paint().apply {
                    color = 0xFF38bdf8.toInt()
                    strokeWidth = 16f
                    style = Paint.Style.STROKE
                    isAntiAlias = true
                    strokeCap = Paint.Cap.ROUND
                }
                canvas.drawLine(w * 0.5f, h * 0.85f, w * 0.5f, h * 0.45f, routePaint)
                canvas.drawLine(w * 0.5f, h * 0.45f, w * 0.75f, h * 0.2f, routePaint)

                // Location GPS Puck
                val puckPaint = Paint().apply {
                    color = 0xFF00f2fe.toInt()
                    style = Paint.Style.FILL
                    isAntiAlias = true
                }
                canvas.drawCircle(w * 0.5f, h * 0.85f, 22f, puckPaint)

                surface.unlockCanvasAndPost(canvas)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
