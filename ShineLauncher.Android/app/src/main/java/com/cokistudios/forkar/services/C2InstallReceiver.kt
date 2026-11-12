package com.cokistudios.forkar.services

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast
import java.io.File

/**
 * C2InstallReceiver — Listens for OTA and ADB module push intents from UI Connect (PC)
 * Action: com.cokistudios.shine.INSTALL_C2
 * Extras: path (String) — Absolute path to .c2 module on device storage.
 */
class C2InstallReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_INSTALL_C2 = "com.cokistudios.shine.INSTALL_C2"
        const val EXTRA_PATH = "path"
        const val ACTION_C2_RELOADED = "com.cokistudios.shine.C2_RELOADED"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_INSTALL_C2) {
            val path = intent.getStringExtra(EXTRA_PATH)
            if (path.isNullOrEmpty()) {
                Log.e("C2InstallReceiver", "Missing 'path' extra in INSTALL_C2 intent")
                return
            }

            val file = File(path)
            if (!file.exists()) {
                Log.e("C2InstallReceiver", "Target .c2 file does not exist: $path")
                return
            }

            Log.i("C2InstallReceiver", "UI Connect trigger received. Installing module: ${file.name}")
            val result = C2ModuleLoader.installC2Package(context, file)
            
            result.onSuccess { module ->
                Toast.makeText(context, "✨ Módulo .c2 activado: ${module.name} (${module.targetDevice})", Toast.LENGTH_SHORT).show()
                // Broadcast reload to UI
                val reloadIntent = Intent(ACTION_C2_RELOADED).apply {
                    putExtra("component_id", module.componentId)
                    putExtra("theme", module.theme)
                    putExtra("primary_color", module.primaryColorHex)
                    setPackage(context.packageName)
                }
                context.sendBroadcast(reloadIntent)
            }.onFailure { err ->
                Toast.makeText(context, "❌ Error instalando .c2: ${err.message}", Toast.LENGTH_LONG).show()
            }
        }
    }
}
