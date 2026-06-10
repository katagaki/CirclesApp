package com.tsubuzaki.circlesgo.data.local

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import android.util.LruCache
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.net.URL

class WebCutImageCache(context: Context) {

    companion object {
        private const val TAG = "WebCutImageCache"
        private const val CACHE_DIR = "web_cut_cache"
    }

    private val cacheDir: File = File(context.filesDir, CACHE_DIR).also {
        if (!it.exists()) it.mkdirs()
    }

    private val memoryCache: LruCache<Int, Bitmap> = run {
        val maxMemory = (Runtime.getRuntime().maxMemory() / 1024).toInt()
        val cacheSize = maxMemory / 16
        object : LruCache<Int, Bitmap>(cacheSize) {
            override fun sizeOf(key: Int, bitmap: Bitmap): Int {
                return bitmap.byteCount / 1024
            }
        }
    }

    fun getCached(circleID: Int): Bitmap? {
        memoryCache.get(circleID)?.let { return it }

        val file = File(cacheDir, circleID.toString())
        if (file.exists()) {
            val data = file.readBytes()
            if (data.isEmpty()) return null
            val options = BitmapFactory.Options().apply {
                inPreferredConfig = Bitmap.Config.RGB_565
            }
            val bitmap = BitmapFactory.decodeByteArray(data, 0, data.size, options)
            if (bitmap != null) {
                memoryCache.put(circleID, bitmap)
            }
            return bitmap
        }
        return null
    }

    fun isFetched(circleID: Int): Boolean {
        return memoryCache.get(circleID) != null || File(cacheDir, circleID.toString()).exists()
    }

    suspend fun download(circleID: Int, imageURL: String): Bitmap? = withContext(Dispatchers.IO) {
        try {
            val url = URL(imageURL)
            val connection = url.openConnection()
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            val data = connection.inputStream.use { it.readBytes() }

            if (data.isEmpty()) {
                saveEmpty(circleID)
                return@withContext null
            }

            val options = BitmapFactory.Options().apply {
                inPreferredConfig = Bitmap.Config.RGB_565
            }
            val bitmap = BitmapFactory.decodeByteArray(data, 0, data.size, options)
            if (bitmap != null) {
                File(cacheDir, circleID.toString()).writeBytes(data)
                memoryCache.put(circleID, bitmap)
            }
            bitmap
        } catch (e: Exception) {
            Log.e(TAG, "Failed to download web cut for circle $circleID", e)
            null
        }
    }

    private fun saveEmpty(circleID: Int) {
        try {
            File(cacheDir, circleID.toString()).writeBytes(ByteArray(0))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save empty marker for circle $circleID", e)
        }
    }

    fun diskUsageBytes(): Long {
        return cacheDir.listFiles()?.sumOf { it.length() } ?: 0L
    }

    fun clear() {
        memoryCache.evictAll()
        cacheDir.listFiles()?.forEach { it.delete() }
    }
}
