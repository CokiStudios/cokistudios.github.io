package com.cokistudios.shinemaps.auto

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.*

class ShineHomeScreen(carContext: CarContext) : Screen(carContext) {

    override fun onGetTemplate(): Template {
        val itemList = ItemList.Builder()
            .addItem(
                Row.Builder()
                    .setTitle("🚗 Iniciar Navegación en Vivo")
                    .addText("Modo Google Maps con giros en tiempo real, tráfico y ETA")
                    .setOnClickListener {
                        screenManager.push(ShineLiveNavScreen(carContext, "Ruta en Vivo", 4.7110, -74.0721))
                    }
                    .build()
            )
            .addItem(
                Row.Builder()
                    .setTitle("🏠 Casa (CS ID)")
                    .addText("Ruta rápida con tráfico en tiempo real")
                    .setOnClickListener {
                        screenManager.push(ShineLiveNavScreen(carContext, "Casa (CS ID)", 4.6980, -74.0620))
                    }
                    .build()
            )
            .addItem(
                Row.Builder()
                    .setTitle("🏢 Estudio (CS ID)")
                    .addText("Vía principal y corredores sin congestión")
                    .setOnClickListener {
                        screenManager.push(ShineLiveNavScreen(carContext, "Estudio (CS ID)", 4.7230, -74.0510))
                    }
                    .build()
            )
            .build()

        val actionStrip = ActionStrip.Builder()
            .addAction(
                Action.Builder()
                    .setTitle("▶ Iniciar")
                    .setBackgroundColor(CarColor.BLUE)
                    .setOnClickListener {
                        screenManager.push(ShineLiveNavScreen(carContext, "Navegación Activa", 4.7110, -74.0721))
                    }
                    .build()
            )
            .build()

        return ListTemplate.Builder()
            .setSingleList(itemList)
            .setHeaderAction(Action.APP_ICON)
            .setTitle("Shine Maps • Android Auto")
            .setActionStrip(actionStrip)
            .build()
    }
}
