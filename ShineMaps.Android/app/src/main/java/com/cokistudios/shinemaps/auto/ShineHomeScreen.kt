package com.cokistudios.shinemaps.auto

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.*
import androidx.core.graphics.drawable.IconCompat
import com.cokistudios.shinemaps.R

class ShineHomeScreen(carContext: CarContext) : Screen(carContext) {

    override fun onGetTemplate(): Template {
        val carIcon = CarIcon.Builder(IconCompat.createWithResource(carContext, R.drawable.ic_car)).build()
        val homeIcon = CarIcon.Builder(IconCompat.createWithResource(carContext, R.drawable.ic_home)).build()
        val workIcon = CarIcon.Builder(IconCompat.createWithResource(carContext, R.drawable.ic_work)).build()

        val itemList = ItemList.Builder()
            .addItem(
                Row.Builder()
                    .setImage(carIcon)
                    .setTitle("Iniciar Navegacion en Vivo")
                    .addText("Modo Google Maps con giros en tiempo real, trafico y ETA")
                    .setOnClickListener {
                        screenManager.push(ShineLiveNavScreen(carContext, "Ruta en Vivo", 4.7110, -74.0721))
                    }
                    .build()
            )
            .addItem(
                Row.Builder()
                    .setImage(homeIcon)
                    .setTitle("Casa (CS ID)")
                    .addText("Ruta rapida con trafico en tiempo real")
                    .setOnClickListener {
                        screenManager.push(ShineLiveNavScreen(carContext, "Casa (CS ID)", 4.6980, -74.0620))
                    }
                    .build()
            )
            .addItem(
                Row.Builder()
                    .setImage(workIcon)
                    .setTitle("Estudio (CS ID)")
                    .addText("Via principal y corredores sin congestion")
                    .setOnClickListener {
                        screenManager.push(ShineLiveNavScreen(carContext, "Estudio (CS ID)", 4.7230, -74.0510))
                    }
                    .build()
            )
            .build()

        val actionStrip = ActionStrip.Builder()
            .addAction(
                Action.Builder()
                    .setTitle("Iniciar")
                    .setBackgroundColor(CarColor.BLUE)
                    .setOnClickListener {
                        screenManager.push(ShineLiveNavScreen(carContext, "Navegacion Activa", 4.7110, -74.0721))
                    }
                    .build()
            )
            .build()

        return ListTemplate.Builder()
            .setSingleList(itemList)
            .setHeaderAction(Action.APP_ICON)
            .setTitle("Shine Maps")
            .setActionStrip(actionStrip)
            .build()
    }
}
