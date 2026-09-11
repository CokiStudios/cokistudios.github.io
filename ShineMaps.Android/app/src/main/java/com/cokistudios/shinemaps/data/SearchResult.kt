package com.cokistudios.shinemaps.data

data class SearchResult(
    val title: String,
    val address: String,
    val latitude: Double,
    val longitude: Double,
    val distanceMeters: Double? = null,
    val iconRes: Int? = null,
    val isCategory: Boolean = false,
    val categoryQuery: String? = null
) {
    val formattedDistance: String?
        get() {
            val d = distanceMeters ?: return null
            return if (d < 1000) {
                "${d.toInt()} m"
            } else {
                String.format(java.util.Locale.US, "%.1f km", d / 1000.0)
            }
        }
}
