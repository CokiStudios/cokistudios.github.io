package com.cokistudios.shinemaps.auto

import androidx.car.app.CarContext
import androidx.car.app.CarToast
import androidx.car.app.Screen
import androidx.car.app.model.*
import androidx.car.app.navigation.NavigationManager
import androidx.car.app.navigation.NavigationManagerCallback
import androidx.car.app.navigation.model.*
import androidx.core.graphics.drawable.IconCompat
import com.cokistudios.shinemaps.R

class ShineLiveNavScreen(
    carContext: CarContext,
    private val destinationName: String = "Casa (CS ID)",
    private val destinationLat: Double = 4.7110,
    private val destinationLng: Double = -74.0721
) : Screen(carContext) {

    private var isNavigating = true
    private var isMuted = false
    private var currentStepIndex = 0

    init {
        val navManager = carContext.getCarService(NavigationManager::class.java)
        navManager.setNavigationManagerCallback(object : NavigationManagerCallback {
            override fun onStopNavigation() {
                isNavigating = false
                invalidate()
            }
        })
        navManager.navigationStarted()
    }

    override fun onGetTemplate(): Template {
        if (!isNavigating) {
            // Finished route
            return PaneTemplate.Builder(
                Pane.Builder()
                    .addRow(
                        Row.Builder()
                            .setTitle("Has llegado a tu destino")
                            .addText(destinationName)
                            .build()
                    )
                    .addAction(
                        Action.Builder()
                            .setTitle("Volver")
                            .setOnClickListener { screenManager.pop() }
                            .build()
                    )
                    .build()
            )
                .setTitle("Fin de la Ruta")
                .setHeaderAction(Action.BACK)
                .build()
        }

        // ── 1. GOOGLE MAPS STYLE TOP ROUTING BANNER ──
        val currentManeuver = Maneuver.Builder(Maneuver.TYPE_TURN_NORMAL_RIGHT)
            .build()

        val currentStep = Step.Builder("Gira a la derecha por Av. Calle 72")
            .setManeuver(currentManeuver)
            .setRoad("Av. Chile / Calle 72")
            .build()

        val routingInfo = RoutingInfo.Builder()
            .setCurrentStep(currentStep, Distance.create(350.0, Distance.UNIT_METERS))
            .setNextStep(Step.Builder("Luego continua por Carrera 15").build())
            .build()

        // ── 2. BOTTOM TRAVEL ESTIMATES (ETA & DISTANCE) ──
        val travelEstimate = TravelEstimate.Builder(
            Distance.create(8.4, Distance.UNIT_KILOMETERS),
            DateTimeWithZone.create(
                System.currentTimeMillis() + 18 * 60 * 1000,
                java.util.TimeZone.getDefault()
            )
        )
            .setRemainingTimeSeconds(18 * 60)
            .setRemainingTimeColor(CarColor.GREEN) // Green = Good traffic
            .build()

        // ── 3. ACTION STRIP (Google Maps style right controls) ──
        val volumeIcon = CarIcon.Builder(
            IconCompat.createWithResource(
                carContext,
                if (isMuted) R.drawable.ic_volume_off else R.drawable.ic_volume_up
            )
        ).build()

        val actionStrip = ActionStrip.Builder()
            .addAction(
                Action.Builder()
                    .setIcon(volumeIcon)
                    .setOnClickListener {
                        isMuted = !isMuted
                        CarToast.makeText(
                            carContext,
                            if (isMuted) "Voz silenciada" else "Instrucciones de voz activadas",
                            CarToast.LENGTH_SHORT
                        ).show()
                        invalidate()
                    }
                    .build()
            )
            .addAction(
                Action.Builder()
                    .setTitle("Terminar")
                    .setBackgroundColor(CarColor.RED)
                    .setOnClickListener {
                        val navManager = carContext.getCarService(NavigationManager::class.java)
                        navManager.navigationEnded()
                        isNavigating = false
                        invalidate()
                    }
                    .build()
            )
            .build()

        // ── 4. NAVIGATION TEMPLATE ──
        return NavigationTemplate.Builder()
            .setNavigationInfo(routingInfo)
            .setDestinationTravelEstimate(travelEstimate)
            .setActionStrip(actionStrip)
            .setBackgroundColor(CarColor.createCustom(0xFF06090F.toInt(), 0xFF020617.toInt()))
            .build()
    }
}
