package com.cokistudios.shinemaps

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.graphics.Color
import android.location.Location
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Looper
import android.text.Editable
import android.text.TextWatcher
import android.util.Base64
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.*
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.cokistudios.shinemaps.data.SearchResult
import com.cokistudios.shinemaps.ui.SearchResultAdapter
import com.google.android.gms.location.*
import kotlinx.coroutines.*
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import org.maplibre.android.MapLibre
import org.maplibre.android.annotations.Marker
import org.maplibre.android.annotations.MarkerOptions
import org.maplibre.android.annotations.Polyline
import org.maplibre.android.annotations.PolylineOptions
import org.maplibre.android.camera.CameraPosition
import org.maplibre.android.camera.CameraUpdateFactory
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.geometry.LatLngBounds
import org.maplibre.android.location.LocationComponent
import org.maplibre.android.location.LocationComponentActivationOptions
import org.maplibre.android.location.modes.CameraMode
import org.maplibre.android.location.modes.RenderMode
import org.maplibre.android.maps.MapView
import org.maplibre.android.maps.MapLibreMap
import org.maplibre.android.maps.Style
import java.net.URLEncoder
import kotlin.math.roundToInt

class MainActivity : AppCompatActivity() {

    // ── MAPBOX TOKEN ──
    private val mapboxToken: String by lazy {
        String(
            Base64.decode(
                "cGsuZXlKMUlqb2lhbVZ5YVhoa1pYWmxiRzl3YVc1bmFTSXNJbUVpT2lKamJXaGlaSFUwWW5neE5qRjJNbXR3ZFhBeGFXdHlkalI1SW4wLjBYeDcyNEVwbjN4M25KOGhBWUMxZEE=",
                Base64.DEFAULT
            )
        )
    }

    private val styleNames = listOf(
        "navigation-night-v1",
        "satellite-streets-v12",
        "navigation-day-v1"
    )
    private var currentStyleIndex = 0

    private fun getMapboxRasterStyleJson(styleName: String): String {
        return """
        {
          "version": 8,
          "name": "ShineMapbox",
          "sources": {
            "mapbox-tiles": {
              "type": "raster",
              "tiles": [
                "https://api.mapbox.com/styles/v1/mapbox/$styleName/tiles/512/{z}/{x}/{y}@2x?access_token=$mapboxToken"
              ],
              "tileSize": 512,
              "maxzoom": 22
            }
          },
          "layers": [
            {
              "id": "mapbox-tiles-layer",
              "type": "raster",
              "source": "mapbox-tiles"
            }
          ]
        }
        """.trimIndent()
    }

    private fun getFallbackDarkStyleJson(): String {
        return """
        {
          "version": 8,
          "name": "ShineFallbackDark",
          "sources": {
            "carto-dark-tiles": {
              "type": "raster",
              "tiles": [
                "https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png",
                "https://b.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png",
                "https://c.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png"
              ],
              "tileSize": 256,
              "maxzoom": 19
            }
          },
          "layers": [
            {
              "id": "carto-dark-layer",
              "type": "raster",
              "source": "carto-dark-tiles"
            }
          ]
        }
        """.trimIndent()
    }

    // ── NATIVE MAP & GPS STATE ──
    private lateinit var mapView: MapView
    private var map: MapLibreMap? = null
    private var locationComponent: LocationComponent? = null
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private var locationCallback: LocationCallback? = null
    private var currentLocation: Location? = null

    // ── ROUTING STATE ──
    private var currentPolyline: Polyline? = null
    private var destMarker: Marker? = null
    private var activeDestName: String? = null
    private val httpClient = OkHttpClient()

    // ── UI VIEWS ──
    private lateinit var etSearch: EditText
    private lateinit var btnClearSearch: ImageView
    private lateinit var btnSearch: ImageView
    private lateinit var rvSearchResults: RecyclerView
    private lateinit var searchAdapter: SearchResultAdapter
    private lateinit var tvSpeedVal: TextView
    private lateinit var cardNavigation: View
    private lateinit var tvInstruction: TextView
    private lateinit var ivRouteManeuverIcon: ImageView
    private lateinit var tvRouteStats: TextView
    private lateinit var hudOverlay: View
    private lateinit var hudSpeedNumber: TextView
    private lateinit var hudNextInstruction: TextView
    private lateinit var hudNextDistance: TextView
    private lateinit var loadingIndicator: ProgressBar

    private var searchJob: Job? = null
    private lateinit var prefs: SharedPreferences

    // ── PERMISSIONS ──
    private val locationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { perms ->
        val fine = perms[Manifest.permission.ACCESS_FINE_LOCATION] == true
        val coarse = perms[Manifest.permission.ACCESS_COARSE_LOCATION] == true
        if (fine || coarse) {
            enableLocationComponent()
            startLocationUpdates()
        } else {
            Toast.makeText(this, "Permiso de GPS necesario para navegación", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize MapLibre Native engine
        MapLibre.getInstance(this)

        // Edge-to-edge for Android 15 / 16 / 17
        WindowCompat.setDecorFitsSystemWindows(window, false)

        setContentView(R.layout.activity_main)

        prefs = getSharedPreferences("shine_maps_prefs", Context.MODE_PRIVATE)
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        initViews(savedInstanceState)
        setupSearch()
        setupButtons()
        setupChips()
        handleBack()
    }

    private fun initViews(savedInstanceState: Bundle?) {
        mapView = findViewById(R.id.mapView)
        mapView.onCreate(savedInstanceState)

        etSearch = findViewById(R.id.etSearch)
        btnClearSearch = findViewById(R.id.btnClearSearch)
        btnSearch = findViewById(R.id.btnSearch)
        rvSearchResults = findViewById(R.id.rvSearchResults)
        tvSpeedVal = findViewById(R.id.tvSpeedVal)
        cardNavigation = findViewById(R.id.cardNavigation)
        ivRouteManeuverIcon = findViewById(R.id.ivRouteManeuverIcon)
        tvInstruction = findViewById(R.id.tvInstruction)
        tvRouteStats = findViewById(R.id.tvRouteStats)
        hudOverlay = findViewById(R.id.hudOverlay)
        hudSpeedNumber = findViewById(R.id.hudSpeedNumber)
        hudNextInstruction = findViewById(R.id.hudNextInstruction)
        hudNextDistance = findViewById(R.id.hudNextDistance)
        loadingIndicator = findViewById(R.id.loadingIndicator)

        searchAdapter = SearchResultAdapter { selectedResult ->
            onPlaceSelected(selectedResult)
        }
        rvSearchResults.layoutManager = LinearLayoutManager(this)
        rvSearchResults.adapter = searchAdapter

        mapView.addOnDidFailLoadingMapListener { errorMessage ->
            android.util.Log.e("ShineMaps", "Map failed loading, using fallback: $errorMessage")
            val fallbackJson = getFallbackDarkStyleJson()
            map?.setStyle(Style.Builder().fromJson(fallbackJson)) { style ->
                loadingIndicator.visibility = View.GONE
                enableLocationComponent(style)
            }
        }

        mapView.getMapAsync { maplibreMap ->
            this.map = maplibreMap

            // Configure native map settings
            maplibreMap.uiSettings.isLogoEnabled = false
            maplibreMap.uiSettings.isAttributionEnabled = false
            maplibreMap.uiSettings.isCompassEnabled = true

            // Set default position (Bogotá, Colombia)
            maplibreMap.cameraPosition = CameraPosition.Builder()
                .target(LatLng(4.7110, -74.0721))
                .zoom(14.0)
                .build()

            // Load initial native Mapbox style
            loadMapStyle(currentStyleIndex)
        }
    }

    private fun loadMapStyle(index: Int) {
        val styleName = styleNames[index]
        loadingIndicator.visibility = View.VISIBLE

        val styleJson = getMapboxRasterStyleJson(styleName)
        map?.setStyle(Style.Builder().fromJson(styleJson)) { style ->
            loadingIndicator.visibility = View.GONE
            enableLocationComponent(style)

            // Re-render annotations if active
            currentPolyline?.let { poly ->
                val pts = poly.points
                currentPolyline = map?.addPolyline(
                    PolylineOptions().addAll(pts).color(Color.parseColor("#38bdf8")).width(6f)
                )
            }
            destMarker?.let { marker ->
                val pos = marker.position
                val title = marker.title
                destMarker = map?.addMarker(MarkerOptions().position(pos).title(title))
            }
        }
    }

    private fun enableLocationComponent(style: Style? = map?.style) {
        if (style == null || map == null) return
        if (!hasLocationPermission()) {
            requestLocationPermission()
            return
        }

        try {
            val activationOptions = LocationComponentActivationOptions.builder(this, style).build()
            locationComponent = map?.locationComponent?.apply {
                activateLocationComponent(activationOptions)
                isLocationComponentEnabled = true
                cameraMode = CameraMode.TRACKING
                renderMode = RenderMode.COMPASS
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun startLocationUpdates() {
        if (!hasLocationPermission()) return

        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 1000)
            .setMinUpdateIntervalMillis(500)
            .build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                val loc = result.lastLocation ?: return
                currentLocation = loc

                // Speed calculation: m/s -> km/h
                val speedKmh = if (loc.hasSpeed()) (loc.speed * 3.6f).roundToInt() else 0
                tvSpeedVal.text = "$speedKmh"
                hudSpeedNumber.text = "$speedKmh"
            }
        }

        try {
            fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback!!, Looper.getMainLooper())
        } catch (e: SecurityException) {
            e.printStackTrace()
        }
    }

    private fun stopLocationUpdates() {
        locationCallback?.let { fusedLocationClient.removeLocationUpdates(it) }
    }

    // ── SEARCH & GEOCODING (MAPBOX NATIVE API) ──
    private fun setupSearch() {
        etSearch.addTextChangedListener(object : TextWatcher {
            override fun afterTextChanged(s: Editable?) {
                val q = s?.toString()?.trim() ?: ""
                btnClearSearch.visibility = if (q.isNotEmpty()) View.VISIBLE else View.GONE

                searchJob?.cancel()
                if (q.length < 3) {
                    rvSearchResults.visibility = View.GONE
                    return
                }
                searchJob = lifecycleScope.launch {
                    delay(350)
                    performGeocoding(q)
                }
            }
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
        })

        etSearch.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                hideKeyboard()
                val q = etSearch.text.toString().trim()
                if (q.isNotEmpty()) performGeocoding(q)
                true
            } else false
        }

        btnClearSearch.setOnClickListener {
            etSearch.setText("")
            rvSearchResults.visibility = View.GONE
        }

        btnSearch.setOnClickListener {
            hideKeyboard()
            val q = etSearch.text.toString().trim()
            if (q.isNotEmpty()) performGeocoding(q)
        }
    }

    private fun performGeocoding(query: String) {
        lifecycleScope.launch(Dispatchers.IO) {
            try {
                val userLat = currentLocation?.latitude ?: 4.7110
                val userLng = currentLocation?.longitude ?: -74.0721
                val encoded = URLEncoder.encode(query, "UTF-8")
                val url = "https://api.mapbox.com/geocoding/v5/mapbox.places/$encoded.json?access_token=$mapboxToken&proximity=$userLng,$userLat&language=es,en&limit=5"

                val request = Request.Builder().url(url).build()
                val response = httpClient.newCall(request).execute()
                val body = response.body?.string() ?: return@launch

                val json = JSONObject(body)
                val features = json.optJSONArray("features") ?: return@launch
                val results = mutableListOf<SearchResult>()

                for (i in 0 until features.length()) {
                    val f = features.getJSONObject(i)
                    val title = f.optString("text", "Lugar")
                    val placeName = f.optString("place_name", title)
                    val center = f.getJSONArray("center")
                    val lon = center.getDouble(0)
                    val lat = center.getDouble(1)

                    results.add(SearchResult(title, placeName, lat, lon))
                }

                withContext(Dispatchers.Main) {
                    if (results.isNotEmpty()) {
                        searchAdapter.submitList(results)
                        rvSearchResults.visibility = View.VISIBLE
                    } else {
                        rvSearchResults.visibility = View.GONE
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun onPlaceSelected(result: SearchResult) {
        hideKeyboard()
        rvSearchResults.visibility = View.GONE
        etSearch.setText(result.title)

        val target = LatLng(result.latitude, result.longitude)
        activeDestName = result.title

        // Update Native Marker
        destMarker?.let { map?.removeMarker(it) }
        destMarker = map?.addMarker(
            MarkerOptions().position(target).title(result.title)
        )

        map?.animateCamera(CameraUpdateFactory.newLatLngZoom(target, 15.5))

        // Calculate native route
        calculateRoute(target)
    }

    // ── NATIVE MAPBOX DIRECTIONS ROUTING ──
    private fun calculateRoute(dest: LatLng) {
        val startLat = currentLocation?.latitude ?: 4.7110
        val startLng = currentLocation?.longitude ?: -74.0721

        loadingIndicator.visibility = View.VISIBLE

        lifecycleScope.launch(Dispatchers.IO) {
            try {
                val url = "https://api.mapbox.com/directions/v5/mapbox/driving-traffic/$startLng,$startLat;${dest.longitude},${dest.latitude}?steps=true&geometries=geojson&overview=full&language=es&access_token=$mapboxToken"
                val request = Request.Builder().url(url).build()
                val response = httpClient.newCall(request).execute()
                val body = response.body?.string() ?: return@launch

                val json = JSONObject(body)
                val routes = json.optJSONArray("routes") ?: return@launch
                if (routes.length() == 0) return@launch

                val route = routes.getJSONObject(0)
                val distance = route.getDouble("distance") // meters
                val duration = route.getDouble("duration") // seconds

                val geom = route.getJSONObject("geometry")
                val coords = geom.getJSONArray("coordinates")
                val latLngList = mutableListOf<LatLng>()

                for (i in 0 until coords.length()) {
                    val pair = coords.getJSONArray(i)
                    latLngList.add(LatLng(pair.getDouble(1), pair.getDouble(0)))
                }

                // Steps
                val legs = route.getJSONArray("legs")
                val steps = legs.getJSONObject(0).getJSONArray("steps")
                var firstInstruction = "Continúa por la vía"
                var firstDistance = 0
                var maneuverIconRes = R.drawable.ic_turn_straight

                if (steps.length() > 0) {
                    val firstStep = steps.getJSONObject(0)
                    val maneuver = firstStep.getJSONObject("maneuver")
                    firstInstruction = maneuver.optString("instruction", firstInstruction)
                    firstDistance = firstStep.optDouble("distance", 0.0).roundToInt()

                    val mod = maneuver.optString("modifier", "")
                    val type = maneuver.optString("type", "")
                    maneuverIconRes = when {
                        mod.contains("right") || type.contains("right") -> R.drawable.ic_turn_right
                        mod.contains("left") || type.contains("left") -> R.drawable.ic_turn_left
                        type.contains("arrive") -> R.drawable.ic_flag
                        else -> R.drawable.ic_turn_straight
                    }
                }

                withContext(Dispatchers.Main) {
                    loadingIndicator.visibility = View.GONE
                    drawRoute(latLngList)

                    // Format Stats
                    val distKm = "%.1f".format(distance / 1000)
                    val timeMin = (duration / 60).roundToInt()
                    val timeStr = if (timeMin > 60) "${timeMin / 60}h ${timeMin % 60}m" else "$timeMin min"

                    ivRouteManeuverIcon.setImageResource(maneuverIconRes)
                    tvInstruction.text = firstInstruction
                    tvRouteStats.text = "$distKm km • $timeStr estimados"
                    cardNavigation.visibility = View.VISIBLE

                    // HUD Update
                    hudNextInstruction.text = firstInstruction
                    hudNextDistance.text = "En $firstDistance m"
                }
            } catch (e: Exception) {
                e.printStackTrace()
                withContext(Dispatchers.Main) {
                    loadingIndicator.visibility = View.GONE
                    Toast.makeText(this@MainActivity, "Error al trazar ruta Mapbox", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    private fun drawRoute(points: List<LatLng>) {
        val m = map ?: return
        currentPolyline?.let { m.removePolyline(it) }

        currentPolyline = m.addPolyline(
            PolylineOptions()
                .addAll(points)
                .color(Color.parseColor("#38bdf8"))
                .width(6f)
        )

        // Fit camera to route
        if (points.size > 1) {
            val boundsBuilder = LatLngBounds.Builder()
            points.forEach { boundsBuilder.include(it) }
            m.animateCamera(CameraUpdateFactory.newLatLngBounds(boundsBuilder.build(), 120))
        }
    }

    // ── BUTTON ACTIONS ──
    private fun setupButtons() {
        // My Location
        findViewById<View>(R.id.btnMyLocation).setOnClickListener {
            if (hasLocationPermission()) {
                currentLocation?.let {
                    map?.animateCamera(CameraUpdateFactory.newLatLngZoom(LatLng(it.latitude, it.longitude), 16.0))
                }
            } else {
                requestLocationPermission()
            }
        }

        // Map Layers Toggle
        findViewById<View>(R.id.btnLayers).setOnClickListener {
            currentStyleIndex = (currentStyleIndex + 1) % styleNames.size
            loadMapStyle(currentStyleIndex)
            val name = when (currentStyleIndex) {
                0 -> "Modo Nocturno / Shine Dark"
                1 -> "Satélite Híbrido"
                else -> "Calles de Día"
            }
            Toast.makeText(this, "Capa: $name", Toast.LENGTH_SHORT).show()
        }

        // HUD Mode
        findViewById<View>(R.id.btnHud).setOnClickListener {
            openHUD()
        }

        // HUD Mirror & Close
        findViewById<View>(R.id.btnHudMirror).setOnClickListener {
            val centerBox = findViewById<View>(R.id.hudCenterBox)
            centerBox.scaleX = if (centerBox.scaleX == 1f) -1f else 1f
        }

        findViewById<View>(R.id.btnCloseHud).setOnClickListener {
            closeHUD()
        }

        // Close Navigation Route
        findViewById<View>(R.id.btnCloseNav).setOnClickListener {
            cardNavigation.visibility = View.GONE
            currentPolyline?.let { map?.removePolyline(it) }
            destMarker?.let { map?.removeMarker(it) }
            currentPolyline = null
            destMarker = null
        }
    }

    private fun setupChips() {
        findViewById<View>(R.id.chipHome).setOnClickListener {
            loadSavedPlace("home", "Casa")
        }
        findViewById<View>(R.id.chipWork).setOnClickListener {
            loadSavedPlace("work", "Estudio")
        }
        findViewById<View>(R.id.chipSaveCurrent).setOnClickListener {
            saveCurrentLocationPrompt()
        }
    }

    private fun loadSavedPlace(key: String, defaultName: String) {
        val lat = prefs.getFloat("${key}_lat", 0f).toDouble()
        val lng = prefs.getFloat("${key}_lng", 0f).toDouble()
        if (lat != 0.0 && lng != 0.0) {
            val target = LatLng(lat, lng)
            onPlaceSelected(SearchResult(defaultName, defaultName, lat, lng))
        } else {
            Toast.makeText(this, "Usa 'Guardar' para registrar tu $defaultName", Toast.LENGTH_SHORT).show()
        }
    }

    private fun saveCurrentLocationPrompt() {
        val loc = currentLocation
        if (loc == null) {
            Toast.makeText(this, "Esperando señal GPS...", Toast.LENGTH_SHORT).show()
            return
        }

        val items = arrayOf("Casa", "Estudio")
        android.app.AlertDialog.Builder(this)
            .setTitle("Guardar ubicación actual en CS ID")
            .setItems(items) { _, which ->
                val key = if (which == 0) "home" else "work"
                prefs.edit()
                    .putFloat("${key}_lat", loc.latitude.toFloat())
                    .putFloat("${key}_lng", loc.longitude.toFloat())
                    .apply()
                Toast.makeText(this, "Guardado como ${items[which]}", Toast.LENGTH_SHORT).show()
            }
            .show()
    }

    private fun openHUD() {
        hudOverlay.visibility = View.VISIBLE
        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun closeHUD() {
        hudOverlay.visibility = View.GONE
        window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun hideKeyboard() {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
        imm?.hideSoftInputFromWindow(etSearch.windowToken, 0)
    }

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestLocationPermission() {
        locationPermissionLauncher.launch(
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            )
        )
    }

    private fun handleBack() {
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (hudOverlay.visibility == View.VISIBLE) {
                    closeHUD()
                } else if (rvSearchResults.visibility == View.VISIBLE) {
                    rvSearchResults.visibility = View.GONE
                } else if (cardNavigation.visibility == View.VISIBLE) {
                    cardNavigation.visibility = View.GONE
                    currentPolyline?.let { map?.removePolyline(it) }
                    destMarker?.let { map?.removeMarker(it) }
                } else {
                    isEnabled = false
                    onBackPressedDispatcher.onBackPressed()
                }
            }
        })
    }

    // ── NATIVE MAPVIEW LIFECYCLE ──
    override fun onStart() {
        super.onStart()
        mapView.onStart()
    }

    override fun onResume() {
        super.onResume()
        mapView.onResume()
        startLocationUpdates()
    }

    override fun onPause() {
        super.onPause()
        mapView.onPause()
        stopLocationUpdates()
    }

    override fun onStop() {
        super.onStop()
        mapView.onStop()
    }

    override fun onLowMemory() {
        super.onLowMemory()
        mapView.onLowMemory()
    }

    override fun onDestroy() {
        super.onDestroy()
        mapView.onDestroy()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        mapView.onSaveInstanceState(outState)
    }
}
