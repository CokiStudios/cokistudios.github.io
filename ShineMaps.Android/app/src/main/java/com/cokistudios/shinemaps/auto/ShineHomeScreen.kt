package com.cokistudios.shinemaps.auto

import androidx.car.app.CarContext
import androidx.car.app.CarToast
import androidx.car.app.Screen
import androidx.car.app.model.*

class ShineHomeScreen(carContext: CarContext) : Screen(carContext) {

    override fun onGetTemplate(): Template {
        val pane = Pane.Builder()
            .addRow(
                Row.Builder()
                    .setTitle("Shine Maps • Conducción")
                    .addText("Navegación inteligente con Mapbox HD y CS ID")
                    .build()
            )
            .addRow(
                Row.Builder()
                    .setTitle("🏠 Casa (CS ID)")
                    .addText("Ruta rápida hacia el hogar")
                    .build()
            )
            .addRow(
                Row.Builder()
                    .setTitle("🏢 Estudio (CS ID)")
                    .addText("Tráfico en vivo optimizado")
                    .build()
            )
            .addAction(
                Action.Builder()
                    .setTitle("Ruta a Casa")
                    .setBackgroundColor(CarColor.BLUE)
                    .setOnClickListener {
                        CarToast.makeText(carContext, "Iniciando ruta a Casa en Shine Maps", CarToast.LENGTH_SHORT).show()
                    }
                    .build()
            )
            .addAction(
                Action.Builder()
                    .setTitle("Ruta a Estudio")
                    .setBackgroundColor(CarColor.SECONDARY)
                    .setOnClickListener {
                        CarToast.makeText(carContext, "Iniciando ruta a Estudio en Shine Maps", CarToast.LENGTH_SHORT).show()
                    }
                    .build()
            )
            .build()

        return PaneTemplate.Builder(pane)
            .setHeaderAction(Action.APP_ICON)
            .setTitle("Shine Maps")
            .build()
    }
}
