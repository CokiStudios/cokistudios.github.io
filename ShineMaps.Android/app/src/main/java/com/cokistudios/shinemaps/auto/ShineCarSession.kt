package com.cokistudios.shinemaps.auto

import android.content.Intent
import androidx.car.app.Screen
import androidx.car.app.Session

class ShineCarSession : Session() {
    override fun onCreateScreen(intent: Intent): Screen {
        return ShineHomeScreen(carContext)
    }
}
