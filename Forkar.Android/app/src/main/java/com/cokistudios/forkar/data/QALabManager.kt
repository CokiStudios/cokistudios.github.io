package com.cokistudios.forkar.data

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.util.concurrent.TimeUnit

/**
 * Manages experimental feature flags and diagnostic tools for Forkar QA build.
 * Keeps QA functionality isolated from the retail release.
 */
class QALabManager private constructor(context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences("forkar_qa_lab_prefs", Context.MODE_PRIVATE)

    var realtimeSyncEnabled by mutableStateOf(prefs.getBoolean(KEY_REALTIME_SYNC, false))
        private set

    var audioNotesExperimentEnabled by mutableStateOf(prefs.getBoolean(KEY_AUDIO_NOTES, true))
        private set

    var latencyInspectorEnabled by mutableStateOf(prefs.getBoolean(KEY_LATENCY_INSPECTOR, true))
        private set

    var tagQaPostsByDefault by mutableStateOf(prefs.getBoolean(KEY_TAG_QA_POSTS, true))
        private set

    var filterOnlyQaPosts by mutableStateOf(prefs.getBoolean(KEY_FILTER_QA_POSTS, false))
        private set

    var watermarkEnabled by mutableStateOf(prefs.getBoolean(KEY_WATERMARK, true))
        private set

    var lastMeasuredLatencyMs by mutableLongStateOf(-1L)
        private set

    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(5, TimeUnit.SECONDS)
        .readTimeout(5, TimeUnit.SECONDS)
        .build()

    fun updateRealtimeSync(enabled: Boolean) {
        realtimeSyncEnabled = enabled
        prefs.edit().putBoolean(KEY_REALTIME_SYNC, enabled).apply()
    }

    fun updateAudioNotesExperiment(enabled: Boolean) {
        audioNotesExperimentEnabled = enabled
        prefs.edit().putBoolean(KEY_AUDIO_NOTES, enabled).apply()
    }

    fun updateLatencyInspector(enabled: Boolean) {
        latencyInspectorEnabled = enabled
        prefs.edit().putBoolean(KEY_LATENCY_INSPECTOR, enabled).apply()
    }

    fun updateTagQaPostsByDefault(enabled: Boolean) {
        tagQaPostsByDefault = enabled
        prefs.edit().putBoolean(KEY_TAG_QA_POSTS, enabled).apply()
    }

    fun updateFilterOnlyQaPosts(enabled: Boolean) {
        filterOnlyQaPosts = enabled
        prefs.edit().putBoolean(KEY_FILTER_QA_POSTS, enabled).apply()
    }

    fun updateWatermark(enabled: Boolean) {
        watermarkEnabled = enabled
        prefs.edit().putBoolean(KEY_WATERMARK, enabled).apply()
    }

    suspend fun measureLatency(url: String): Long {
        return withContext(Dispatchers.IO) {
            val start = System.currentTimeMillis()
            try {
                val request = Request.Builder()
                    .url(url)
                    .head()
                    .build()
                httpClient.newCall(request).execute().use {
                    val duration = System.currentTimeMillis() - start
                    withContext(Dispatchers.Main) {
                        lastMeasuredLatencyMs = duration
                    }
                    duration
                }
            } catch (e: Exception) {
                val duration = System.currentTimeMillis() - start
                withContext(Dispatchers.Main) {
                    lastMeasuredLatencyMs = duration
                }
                duration
            }
        }
    }

    fun clearTestCache(context: Context) {
        try {
            context.cacheDir.deleteRecursively()
            context.externalCacheDir?.deleteRecursively()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    companion object {
        private const val KEY_REALTIME_SYNC = "qa_realtime_sync"
        private const val KEY_AUDIO_NOTES = "qa_audio_notes"
        private const val KEY_LATENCY_INSPECTOR = "qa_latency_inspector"
        private const val KEY_TAG_QA_POSTS = "qa_tag_posts"
        private const val KEY_FILTER_QA_POSTS = "qa_filter_posts"
        private const val KEY_WATERMARK = "qa_watermark"

        @Volatile
        private var INSTANCE: QALabManager? = null

        fun getInstance(context: Context): QALabManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: QALabManager(context.applicationContext).also { INSTANCE = it }
            }
        }
    }
}
