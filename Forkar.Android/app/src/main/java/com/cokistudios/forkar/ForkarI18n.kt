package com.cokistudios.forkar

import android.content.Context
import androidx.compose.runtime.*

enum class ForkarLang(val code: String, val displayName: String) {
    ES("es", "🇪🇸 Español"),
    EN("en", "🇺🇸 English"),
    FR("fr", "🇫🇷 Français"),
    PT("pt", "🇧🇷 Português");

    companion object {
        fun fromCode(code: String): ForkarLang {
            return entries.find { it.code == code } ?: ES
        }
    }
}

class ForkarI18n private constructor(context: Context) {
    private val prefs = context.getSharedPreferences("forkar_prefs", Context.MODE_PRIVATE)

    var currentLang by mutableStateOf(ForkarLang.fromCode(prefs.getString("coki-lang", "es") ?: "es"))
        private set

    fun setLanguage(lang: ForkarLang) {
        currentLang = lang
        prefs.edit().putString("coki-lang", lang.code).apply()
    }

    fun t(key: String): String {
        return when (currentLang) {
            ForkarLang.ES -> when (key) {
                "community" -> "Comunidad"
                "new_post" -> "Nueva Publicación"
                "eco_hub" -> "Forkar Eco Hub"
                "co2_saved" -> "CO₂ Ahorrado"
                "eco_points" -> "Puntos Eco"
                "explore" -> "Explorar"
                "categories" -> "Categorías"
                "my_account" -> "Mi Cuenta"
                "sign_in" -> "Iniciar Sesión"
                "search_placeholder" -> "Buscar publicaciones..."
                else -> key
            }
            ForkarLang.EN -> when (key) {
                "community" -> "Community"
                "new_post" -> "New Post"
                "eco_hub" -> "Forkar Eco Hub"
                "co2_saved" -> "CO₂ Saved"
                "eco_points" -> "Eco Points"
                "explore" -> "Explore"
                "categories" -> "Categories"
                "my_account" -> "My Account"
                "sign_in" -> "Sign In"
                "search_placeholder" -> "Search posts..."
                else -> key
            }
            ForkarLang.FR -> when (key) {
                "community" -> "Communauté"
                "new_post" -> "Nouveau Post"
                "eco_hub" -> "Forkar Eco Hub"
                "co2_saved" -> "CO₂ Économisé"
                "eco_points" -> "Points Éco"
                "explore" -> "Explorer"
                "categories" -> "Catégories"
                "my_account" -> "Mon Compte"
                "sign_in" -> "Connexion"
                "search_placeholder" -> "Rechercher des posts..."
                else -> key
            }
            ForkarLang.PT -> when (key) {
                "community" -> "Comunidade"
                "new_post" -> "Nova Publicação"
                "eco_hub" -> "Forkar Eco Hub"
                "co2_saved" -> "CO₂ Economizado"
                "eco_points" -> "Pontos Eco"
                "explore" -> "Explorar"
                "categories" -> "Categorias"
                "my_account" -> "Minha Conta"
                "sign_in" -> "Entrar"
                "search_placeholder" -> "Buscar posts..."
                else -> key
            }
        }
    }

    companion object {
        @Volatile
        private var INSTANCE: ForkarI18n? = null

        fun getInstance(context: Context): ForkarI18n {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: ForkarI18n(context.applicationContext).also { INSTANCE = it }
            }
        }
    }
}
