package com.cokistudios.launcher

import android.app.ActivityManager
import android.app.WallpaperManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.net.Uri
import android.os.BatteryManager
import android.os.Bundle
import android.provider.MediaStore
import android.provider.Settings
import android.text.Editable
import android.text.TextWatcher
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.window.layout.FoldingFeature
import androidx.window.layout.WindowInfoTracker
import com.cokistudios.launcher.adapter.AppGridAdapter
import com.cokistudios.launcher.model.AppInfo
import com.cokistudios.launcher.model.LauncherMode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : AppCompatActivity() {

    private lateinit var rootContainer: View
    private lateinit var bubblyDotView: LinearLayout
    private lateinit var bubblyTitleText: TextView
    private lateinit var bubblyTimeText: TextView
    private lateinit var bubblyStatusIndicator: View

    private lateinit var btnModeFlui: Button
    private lateinit var btnModeXui: Button
    private lateinit var btnModeUi: Button
    private lateinit var btnModeHiui: Button
    private lateinit var btnModeVintage: Button

    private lateinit var modeBannerTitle: TextView
    private lateinit var modeBannerDesc: TextView

    private lateinit var oneUiClockWidget: LinearLayout
    private lateinit var tvOneUiClock: TextView
    private lateinit var tvBatteryStatus: TextView
    private lateinit var tvRamStatus: TextView
    private lateinit var tvDateStatus: TextView
    private lateinit var btnChangeWallpaper: ImageView

    private lateinit var etSearchApps: EditText
    private lateinit var rvAppsGrid: RecyclerView
    private lateinit var tvEmptySearch: TextView

    // 📻 Vintage Bar
    private lateinit var vintageTuilbar: LinearLayout
    private lateinit var tuilbarPhone: LinearLayout
    private lateinit var tuilbarNotes: LinearLayout
    private lateinit var tuilbarMaps: LinearLayout
    private lateinit var tuilbarSos: LinearLayout

    // 🚀 Modern Floating Dock
    private lateinit var modernDockBar: LinearLayout
    private lateinit var dockPhone: FrameLayout
    private lateinit var dockMessages: FrameLayout
    private lateinit var dockShineMaps: FrameLayout
    private lateinit var dockCamera: FrameLayout
    private lateinit var dockSettings: FrameLayout

    private lateinit var appAdapter: AppGridAdapter
    private var allApps: List<AppInfo> = emptyList()
    private var currentMode: LauncherMode = LauncherMode.FLUI

    private val batteryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            updateBatteryInfo(intent)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_main)

        initViews()
        setupInsets()
        setupRecyclerView()
        setupSearch()
        setupModeButtons()
        setupVintageTuilbar()
        setupModernDock()
        setupSystemWidgets()
        setupBubblyDot()
        observeFoldingFeatures()

        loadInstalledApps()
        setLauncherMode(LauncherMode.FLUI)
    }

    override fun onResume() {
        super.onResume()
        registerReceiver(batteryReceiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        updateSystemRamAndDate()
    }

    override fun onPause() {
        super.onPause()
        try {
            unregisterReceiver(batteryReceiver)
        } catch (_: Exception) {}
    }

    private fun initViews() {
        rootContainer = findViewById(R.id.rootContainer)
        bubblyDotView = findViewById(R.id.bubblyDotView)
        bubblyTitleText = findViewById(R.id.bubblyTitleText)
        bubblyTimeText = findViewById(R.id.bubblyTimeText)
        bubblyStatusIndicator = findViewById(R.id.bubblyStatusIndicator)

        btnModeFlui = findViewById(R.id.btnModeFlui)
        btnModeXui = findViewById(R.id.btnModeXui)
        btnModeUi = findViewById(R.id.btnModeUi)
        btnModeHiui = findViewById(R.id.btnModeHiui)
        btnModeVintage = findViewById(R.id.btnModeVintage)

        modeBannerTitle = findViewById(R.id.modeBannerTitle)
        modeBannerDesc = findViewById(R.id.modeBannerDesc)

        oneUiClockWidget = findViewById(R.id.oneUiClockWidget)
        tvOneUiClock = findViewById(R.id.tvOneUiClock)
        tvBatteryStatus = findViewById(R.id.tvBatteryStatus)
        tvRamStatus = findViewById(R.id.tvRamStatus)
        tvDateStatus = findViewById(R.id.tvDateStatus)
        btnChangeWallpaper = findViewById(R.id.btnChangeWallpaper)

        etSearchApps = findViewById(R.id.etSearchApps)
        rvAppsGrid = findViewById(R.id.rvAppsGrid)
        tvEmptySearch = findViewById(R.id.tvEmptySearch)

        vintageTuilbar = findViewById(R.id.vintageTuilbar)
        tuilbarPhone = findViewById(R.id.tuilbarPhone)
        tuilbarNotes = findViewById(R.id.tuilbarNotes)
        tuilbarMaps = findViewById(R.id.tuilbarMaps)
        tuilbarSos = findViewById(R.id.tuilbarSos)

        modernDockBar = findViewById(R.id.modernDockBar)
        dockPhone = findViewById(R.id.dockPhone)
        dockMessages = findViewById(R.id.dockMessages)
        dockShineMaps = findViewById(R.id.dockShineMaps)
        dockCamera = findViewById(R.id.dockCamera)
        dockSettings = findViewById(R.id.dockSettings)
    }

    private fun setupInsets() {
        ViewCompat.setOnApplyWindowInsetsListener(rootContainer) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, 0)

            val bottomPadding = systemBars.bottom + dpToPx(8)
            vintageTuilbar.setPadding(
                vintageTuilbar.paddingLeft,
                vintageTuilbar.paddingTop,
                vintageTuilbar.paddingRight,
                bottomPadding
            )
            
            // Adjust margin for modern dock
            (modernDockBar.layoutParams as? android.view.ViewGroup.MarginLayoutParams)?.let { mlp ->
                mlp.bottomMargin = systemBars.bottom + dpToPx(8)
                modernDockBar.layoutParams = mlp
            }

            insets
        }
    }

    private fun setupRecyclerView() {
        appAdapter = AppGridAdapter(
            onAppClick = { app -> launchApp(app) },
            onAppLongClick = { app ->
                showAppOptionsDialog(app)
                true
            }
        )
        rvAppsGrid.layoutManager = GridLayoutManager(this, 4)
        rvAppsGrid.adapter = appAdapter
    }

    private fun setupSearch() {
        etSearchApps.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                filterApps(s?.toString().orEmpty())
            }
            override fun afterTextChanged(s: Editable?) {}
        })
    }

    private fun setupModeButtons() {
        btnModeFlui.setOnClickListener { setLauncherMode(LauncherMode.FLUI) }
        btnModeXui.setOnClickListener { setLauncherMode(LauncherMode.XUI) }
        btnModeUi.setOnClickListener { setLauncherMode(LauncherMode.UI) }
        btnModeHiui.setOnClickListener { setLauncherMode(LauncherMode.HIUI) }
        btnModeVintage.setOnClickListener { setLauncherMode(LauncherMode.VINTAGE) }
    }

    private fun setupVintageTuilbar() {
        tuilbarPhone.setOnClickListener {
            startSafely(Intent(Intent.ACTION_DIAL), "Teléfono")
        }

        tuilbarNotes.setOnClickListener {
            val noteIntent = Intent(Intent.ACTION_CREATE_NOTE).apply { type = "text/plain" }
            if (packageManager.resolveActivity(noteIntent, 0) != null) {
                startActivity(noteIntent)
            } else {
                val sendIntent = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, "")
                }
                startSafely(Intent.createChooser(sendIntent, "Crear Nota Rápida"), "Notas")
            }
        }

        tuilbarMaps.setOnClickListener {
            launchShineMapsOrFallback()
        }

        tuilbarSos.setOnClickListener {
            startSafely(Intent(Intent.ACTION_DIAL, Uri.parse("tel:112")), "Emergencia SOS")
        }
    }

    private fun setupModernDock() {
        dockPhone.setOnClickListener {
            startSafely(Intent(Intent.ACTION_DIAL), "Teléfono")
        }

        dockMessages.setOnClickListener {
            val smsIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_APP_MESSAGING)
            }
            if (packageManager.resolveActivity(smsIntent, 0) != null) {
                startActivity(smsIntent)
            } else {
                startSafely(Intent(Intent.ACTION_VIEW, Uri.parse("sms:")), "Mensajes")
            }
        }

        dockShineMaps.setOnClickListener {
            launchShineMapsOrFallback()
        }

        dockCamera.setOnClickListener {
            startSafely(Intent(MediaStore.INTENT_ACTION_STILL_IMAGE_CAMERA), "Cámara")
        }

        dockSettings.setOnClickListener {
            startSafely(Intent(Settings.ACTION_SETTINGS), "Ajustes")
        }
    }

    private fun launchShineMapsOrFallback() {
        val shineMapsPkg = "com.cokistudios.shinemaps"
        val launchIntent = packageManager.getLaunchIntentForPackage(shineMapsPkg)
        if (launchIntent != null) {
            startActivity(launchIntent)
        } else {
            val fallbackMap = Intent(Intent.ACTION_VIEW, Uri.parse("geo:0,0?q=maps"))
            startSafely(fallbackMap, "Shine Maps")
        }
    }

    private fun setupSystemWidgets() {
        btnChangeWallpaper.setOnClickListener {
            try {
                val wallpaperIntent = Intent(Intent.ACTION_SET_WALLPAPER)
                startActivity(Intent.createChooser(wallpaperIntent, "Elegir fondo de pantalla"))
            } catch (_: Exception) {
                Toast.makeText(this, "Fondo de pantalla", Toast.LENGTH_SHORT).show()
            }
        }
        oneUiClockWidget.setOnClickListener {
            val clockIntent = Intent(android.provider.AlarmClock.ACTION_SHOW_ALARMS)
            if (packageManager.resolveActivity(clockIntent, 0) != null) {
                startActivity(clockIntent)
            } else {
                startSafely(Intent(Intent.ACTION_QUICK_CLOCK), "Reloj")
            }
        }
        updateSystemRamAndDate()
    }

    private fun updateBatteryInfo(intent: Intent?) {
        val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                         status == BatteryManager.BATTERY_STATUS_FULL

        val batteryPct = if (level >= 0 && scale > 0) (level * 100 / scale) else 100
        val icon = if (isCharging) "⚡ " else "🔋 "
        tvBatteryStatus.text = "$icon$batteryPct%"
    }

    private fun updateSystemRamAndDate() {
        try {
            val actManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val memInfo = ActivityManager.MemoryInfo()
            actManager.getMemoryInfo(memInfo)
            val freeRamGb = String.format(Locale.getDefault(), "%.1f GB", memInfo.availMem / (1024.0 * 1024.0 * 1024.0))
            tvRamStatus.text = "RAM Libre: $freeRamGb • One UI Home"
        } catch (_: Exception) {
            tvRamStatus.text = "RAM Libre Óptima • One UI Home"
        }

        val dateFmt = SimpleDateFormat("EEEE, d 'de' MMMM", Locale.getDefault())
        val formattedDate = dateFmt.format(Date())
        tvDateStatus.text = formattedDate.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() }
    }

    private fun setupBubblyDot() {
        updateBubblyTime()
        bubblyDotView.setOnClickListener {
            val time = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
            Toast.makeText(
                this,
                "🫧 One UI • Modo ${currentMode.displayName}\n$time • Sistema Coki OS",
                Toast.LENGTH_SHORT
            ).show()
        }
    }

    private fun updateBubblyTime() {
        val sdf = SimpleDateFormat("HH:mm", Locale.getDefault())
        val timeStr = sdf.format(Date())
        bubblyTimeText.text = timeStr
        if (::tvOneUiClock.isInitialized) {
            tvOneUiClock.text = timeStr
        }
    }

    private fun setLauncherMode(mode: LauncherMode) {
        currentMode = mode
        updateBubblyTime()

        val buttons = listOf(
            btnModeFlui to LauncherMode.FLUI,
            btnModeXui to LauncherMode.XUI,
            btnModeUi to LauncherMode.UI,
            btnModeHiui to LauncherMode.HIUI,
            btnModeVintage to LauncherMode.VINTAGE
        )

        buttons.forEach { (btn, m) ->
            if (m == mode) {
                btn.alpha = 1.0f
                btn.isSelected = true
            } else {
                btn.alpha = 0.55f
                btn.isSelected = false
            }
        }

        when (mode) {
            LauncherMode.FLUI -> {
                modeBannerTitle.text = "🦋 flUI HINGE ADAPTIVE ENGINE"
                modeBannerDesc.text = "Diseñado para Shine f1, i1 y fW1 (Fold WIDER 1). Adaptación continua a bisagra y ratio expandido."
                bubblyTitleText.text = "One UI • flUI Fold"
                oneUiClockWidget.visibility = View.VISIBLE
                vintageTuilbar.visibility = View.GONE
                modernDockBar.visibility = View.VISIBLE
                (rvAppsGrid.layoutManager as? GridLayoutManager)?.spanCount = 4
                rvAppsGrid.setPadding(dpToPx(10), 0, dpToPx(10), dpToPx(88))
            }
            LauncherMode.XUI -> {
                modeBannerTitle.text = "⚡ XuI HIGH PERFORMANCE ENGINE"
                modeBannerDesc.text = "Diseñado para X1 y Xa1. Refresco dinámico a 120-240Hz, telemetría y respuesta inmediata al toque."
                bubblyTitleText.text = "One UI • 240Hz Ultra"
                oneUiClockWidget.visibility = View.VISIBLE
                vintageTuilbar.visibility = View.GONE
                modernDockBar.visibility = View.VISIBLE
                (rvAppsGrid.layoutManager as? GridLayoutManager)?.spanCount = 4
                rvAppsGrid.setPadding(dpToPx(10), 0, dpToPx(10), dpToPx(88))
            }
            LauncherMode.UI -> {
                modeBannerTitle.text = "🌿 UI BALANCED ECOSYSTEM"
                modeBannerDesc.text = "Diseñado para Nomad 1 / N1. Equilibrio ideal de rendimiento, cristal táctil y optimización de batería."
                bubblyTitleText.text = "One UI • Nomad 1"
                oneUiClockWidget.visibility = View.VISIBLE
                vintageTuilbar.visibility = View.GONE
                modernDockBar.visibility = View.VISIBLE
                (rvAppsGrid.layoutManager as? GridLayoutManager)?.spanCount = 4
                rvAppsGrid.setPadding(dpToPx(10), 0, dpToPx(10), dpToPx(88))
            }
            LauncherMode.HIUI -> {
                modeBannerTitle.text = "💡 hiUI LIGHT ENGINE"
                modeBannerDesc.text = "Diseñado para A1. Consumo mínimo de memoria RAM y arranque ultra ágil sin saturar recursos."
                bubblyTitleText.text = "One UI • A1 Lite"
                oneUiClockWidget.visibility = View.VISIBLE
                vintageTuilbar.visibility = View.GONE
                modernDockBar.visibility = View.VISIBLE
                (rvAppsGrid.layoutManager as? GridLayoutManager)?.spanCount = 4
                rvAppsGrid.setPadding(dpToPx(10), 0, dpToPx(10), dpToPx(88))
            }
            LauncherMode.VINTAGE -> {
                modeBannerTitle.text = "📻 niminticos (Vintage OS)"
                modeBannerDesc.text = "Diseñado para Vintage. Interfaz ergonómica y minimalista con tUIlbar curvada inferior para el pulgar."
                bubblyTitleText.text = "niminticos Vintage"
                oneUiClockWidget.visibility = View.GONE
                vintageTuilbar.visibility = View.VISIBLE
                modernDockBar.visibility = View.GONE
                (rvAppsGrid.layoutManager as? GridLayoutManager)?.spanCount = 3
                rvAppsGrid.setPadding(dpToPx(16), 0, dpToPx(16), dpToPx(94))
            }
        }
    }

    private fun observeFoldingFeatures() {
        lifecycleScope.launch {
            WindowInfoTracker.getOrCreate(this@MainActivity)
                .windowLayoutInfo(this@MainActivity)
                .collectLatest { layoutInfo ->
                    val foldingFeature = layoutInfo.displayFeatures
                        .filterIsInstance<FoldingFeature>()
                        .firstOrNull()

                    if (foldingFeature != null && currentMode == LauncherMode.FLUI) {
                        val stateStr = when (foldingFeature.state) {
                            FoldingFeature.State.HALF_OPENED -> "Flex Mode (90°)"
                            FoldingFeature.State.FLAT -> "Desplegado (180°)"
                            else -> "Normal"
                        }
                        val orientationStr = if (foldingFeature.orientation == FoldingFeature.Orientation.HORIZONTAL) {
                            "Bisagra Horizontal (i1 Flip)"
                        } else {
                            "Bisagra Vertical (f1 / fW1)"
                        }
                        modeBannerDesc.text = "flUI Detectado: $stateStr • $orientationStr. Adaptando área táctil y ratio."

                        if (foldingFeature.state == FoldingFeature.State.FLAT) {
                            (rvAppsGrid.layoutManager as? GridLayoutManager)?.spanCount = 5
                        } else {
                            (rvAppsGrid.layoutManager as? GridLayoutManager)?.spanCount = 4
                        }
                    }
                }
        }
    }

    private fun loadInstalledApps() {
        lifecycleScope.launch {
            val apps = withContext(Dispatchers.IO) {
                val pm = packageManager
                val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
                    addCategory(Intent.CATEGORY_LAUNCHER)
                }
                val resolveInfos: List<ResolveInfo> = pm.queryIntentActivities(mainIntent, 0)

                resolveInfos.mapNotNull { resolveInfo ->
                    val pkg = resolveInfo.activityInfo.packageName
                    val label = resolveInfo.loadLabel(pm).toString()
                    val icon = resolveInfo.loadIcon(pm)
                    AppInfo(
                        label = label,
                        packageName = pkg,
                        icon = icon,
                        activityName = resolveInfo.activityInfo.name
                    )
                }.sortedBy { it.label.lowercase(Locale.getDefault()) }
            }

            allApps = apps
            filterApps(etSearchApps.text?.toString().orEmpty())
        }
    }

    private fun filterApps(query: String) {
        val filtered = if (query.isBlank()) {
            allApps
        } else {
            allApps.filter {
                it.label.contains(query, ignoreCase = true) ||
                it.packageName.contains(query, ignoreCase = true)
            }
        }
        appAdapter.submitList(filtered)
        tvEmptySearch.visibility = if (filtered.isEmpty()) View.VISIBLE else View.GONE
    }

    private fun launchApp(app: AppInfo) {
        val intent = packageManager.getLaunchIntentForPackage(app.packageName)
        if (intent != null) {
            startActivity(intent)
        } else {
            Toast.makeText(this, "No se pudo abrir ${app.label}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun showAppOptionsDialog(app: AppInfo) {
        val options = arrayOf(
            "🚀 Abrir aplicación",
            "ℹ️ Información y permisos",
            "🗑️ Desinstalar aplicación"
        )

        AlertDialog.Builder(this)
            .setTitle(app.label)
            .setIcon(app.icon)
            .setItems(options) { _, which ->
                when (which) {
                    0 -> launchApp(app)
                    1 -> openAppDetails(app)
                    2 -> uninstallApp(app)
                }
            }
            .setNegativeButton("Cancelar", null)
            .show()
    }

    private fun openAppDetails(app: AppInfo) {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", app.packageName, null)
            }
            startActivity(intent)
        } catch (_: Exception) {
            Toast.makeText(this, app.label, Toast.LENGTH_SHORT).show()
        }
    }

    private fun uninstallApp(app: AppInfo) {
        try {
            val uninstallIntent = Intent(Intent.ACTION_DELETE).apply {
                data = Uri.fromParts("package", app.packageName, null)
            }
            startActivity(uninstallIntent)
        } catch (_: Exception) {
            Toast.makeText(this, "No se puede desinstalar ${app.label}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun startSafely(intent: Intent, appName: String) {
        try {
            startActivity(intent)
        } catch (_: Exception) {
            Toast.makeText(this, "No hay aplicación compatible con $appName", Toast.LENGTH_SHORT).show()
        }
    }

    private fun dpToPx(dp: Int): Int {
        val density = resources.displayMetrics.density
        return (dp * density).toInt()
    }
}
