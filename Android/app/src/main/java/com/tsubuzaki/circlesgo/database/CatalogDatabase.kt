package com.tsubuzaki.circlesgo.database

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import android.util.LruCache
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogDatabase
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogEvent
import com.tsubuzaki.circlesgo.database.tables.ComiketBlock
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.database.tables.ComiketCircleExtendedInformation
import com.tsubuzaki.circlesgo.database.tables.ComiketDate
import com.tsubuzaki.circlesgo.database.tables.ComiketEvent
import com.tsubuzaki.circlesgo.database.tables.ComiketGenre
import com.tsubuzaki.circlesgo.database.tables.ComiketMap
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.io.File

class CatalogDatabase(private val context: Context) {

    companion object {
        private const val TAG = "CatalogDatabase"
    }

    var databaseInformation: WebCatalogDatabase? = null
        private set

    private var textDatabase: SQLiteDatabase? = null
    private var imageDatabase: SQLiteDatabase? = null
    private var textDatabaseFile: File? = null
    private var imageDatabaseFile: File? = null

    private val commonImages = java.util.concurrent.ConcurrentHashMap<String, ByteArray>()

    private val imageCache: LruCache<String, Bitmap> = run {
        val maxMemory = (Runtime.getRuntime().maxMemory() / 1024).toInt()
        val cacheSize = maxMemory / 8
        object : LruCache<String, Bitmap>(cacheSize) {
            override fun sizeOf(key: String, bitmap: Bitmap): Int {
                return bitmap.byteCount / 1024
            }
        }
    }

    private val _commonImagesLoadCount = MutableStateFlow(0)
    val commonImagesLoadCount: StateFlow<Int> = _commonImagesLoadCount

    private val _circleImagesLoadCount = MutableStateFlow(0)
    val circleImagesLoadCount: StateFlow<Int> = _circleImagesLoadCount

    val dataStoreDir: File
        get() = File(context.filesDir, "databases")

    // MARK: Database Connection

    fun getTextDatabase(): SQLiteDatabase? {
        if (textDatabase == null && textDatabaseFile != null) {
            val file = textDatabaseFile!!
            Log.d(TAG, "Connecting to text database at ${file.absolutePath}")
            textDatabase = try {
                SQLiteDatabase.openDatabase(
                    file.absolutePath,
                    null,
                    SQLiteDatabase.OPEN_READONLY
                )
            } catch (e: Exception) {
                Log.e(TAG, "Failed to open text database", e)
                null
            }
        }
        return textDatabase
    }

    fun getImageDatabase(): SQLiteDatabase? {
        if (imageDatabase == null && imageDatabaseFile != null) {
            val file = imageDatabaseFile!!
            Log.d(TAG, "Connecting to image database at ${file.absolutePath}")
            imageDatabase = try {
                SQLiteDatabase.openDatabase(
                    file.absolutePath,
                    null,
                    SQLiteDatabase.OPEN_READONLY
                )
            } catch (e: Exception) {
                Log.e(TAG, "Failed to open image database", e)
                null
            }
        }
        return imageDatabase
    }

    fun disconnect() {
        Log.d(TAG, "Disconnecting...")
        textDatabase?.close()
        textDatabase = null
        imageDatabase?.close()
        imageDatabase = null
    }

    fun prepare(event: WebCatalogEvent.Response.Event) {
        disconnect()
        Log.d(TAG, "Preparing for event ${event.number}...")

        val dir = dataStoreDir
        val textFile = File(dir, "webcatalog${event.number}.db")
        if (textFile.exists()) {
            Log.d(TAG, "Found text database.")
            textDatabaseFile = textFile
        }

        val imageFile = File(dir, "webcatalog${event.number}Image1.db")
        if (imageFile.exists()) {
            Log.d(TAG, "Found image database.")
            imageDatabaseFile = imageFile
        }
    }

    fun delete() {
        textDatabaseFile = null
        imageDatabaseFile = null
        databaseInformation = null
        disconnect()
        commonImages.clear()
        imageCache.evictAll()
        dataStoreDir.deleteRecursively()
    }

    fun delete(event: WebCatalogEvent.Response.Event) {
        val dir = dataStoreDir
        val targetTextFile = File(dir, "webcatalog${event.number}.db")
        val targetImageFile = File(dir, "webcatalog${event.number}Image1.db")

        if (textDatabaseFile == targetTextFile) {
            textDatabase?.close()
            textDatabase = null
            textDatabaseFile = null
            databaseInformation = null
        }
        if (imageDatabaseFile == targetImageFile) {
            imageDatabase?.close()
            imageDatabase = null
            imageDatabaseFile = null
            commonImages.clear()
            imageCache.evictAll()
        }

        targetTextFile.delete()
        targetImageFile.delete()
    }

    fun reset() {
        Log.d(TAG, "Resetting...")
        textDatabaseFile = null
        imageDatabaseFile = null
        disconnect()
        imageCache.evictAll()
        commonImages.clear()
    }

    fun setDatabaseInformation(info: WebCatalogDatabase) {
        this.databaseInformation = info
    }

    fun setTextDatabaseFile(file: File) {
        this.textDatabaseFile = file
    }

    fun setImageDatabaseFile(file: File) {
        this.imageDatabaseFile = file
    }

    fun isDownloaded(event: WebCatalogEvent.Response.Event): Boolean {
        val dir = dataStoreDir
        val textFile = File(dir, "webcatalog${event.number}.db")
        val imageFile = File(dir, "webcatalog${event.number}Image1.db")
        return textFile.exists() && imageFile.exists()
    }

    fun getDatabaseFileName(event: WebCatalogEvent.Response.Event, type: DatabaseType): String {
        val suffix = when (type) {
            DatabaseType.TEXT -> ""
            DatabaseType.IMAGES -> "Image1"
        }
        return "webcatalog${event.number}${suffix}.db"
    }

    // MARK: Loading

    fun loadCommonImages() {
        val db = getImageDatabase() ?: return
        try {
            val cursor = db.rawQuery(
                "SELECT name, image FROM ComiketCommonImage", null
            )
            cursor.use {
                while (it.moveToNext()) {
                    val name = it.getString(0)
                    val image = it.getBlob(1)
                    commonImages[name] = image
                }
            }
            _commonImagesLoadCount.value += 1
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load common images", e)
        }
    }

    fun loadCircleImages() {
        // Circle images are now loaded on-demand from SQLite for memory efficiency
        _circleImagesLoadCount.value += 1
    }

    // MARK: Text Data Fetchers

    fun circles(identifiers: List<Int>, reversed: Boolean = false): List<ComiketCircle> {
        val db = getTextDatabase() ?: return emptyList()
        if (identifiers.isEmpty()) return emptyList()

        return try {
            val placeholders = identifiers.joinToString(",") { "?" }
            val args = identifiers.map { it.toString() }.toTypedArray()

            val cursor = db.rawQuery(
                """
                SELECT c.*, e.WCId, e.twitterURL, e.pixivURL, e.CirclemsPortalURL
                FROM ${ComiketCircle.TABLE_NAME} c
                LEFT OUTER JOIN ${ComiketCircleExtendedInformation.TABLE_NAME} e
                ON c.id = e.id
                WHERE c.id IN ($placeholders)
                """.trimIndent(),
                args
            )

            val circles = mutableListOf<ComiketCircle>()
            cursor.use {
                while (it.moveToNext()) {
                    val circle = ComiketCircle.fromCursor(it)
                    val extInfo = ComiketCircleExtendedInformation.fromCursor(it)
                    circle.extendedInformation = extInfo
                    circles.add(circle)
                }
            }

            // Fetch blocks for the circles
            val blockIDs = circles.map { it.blockID }.toSet()
            if (blockIDs.isNotEmpty()) {
                val blockPlaceholders = blockIDs.joinToString(",") { "?" }
                val blockArgs = blockIDs.map { it.toString() }.toTypedArray()
                val blockCursor = db.rawQuery(
                    "SELECT * FROM ${ComiketBlock.TABLE_NAME} WHERE id IN ($blockPlaceholders)",
                    blockArgs
                )
                val blockDict = mutableMapOf<Int, ComiketBlock>()
                blockCursor.use {
                    while (it.moveToNext()) {
                        val block = ComiketBlock.fromCursor(it)
                        blockDict[block.id] = block
                    }
                }
                for (circle in circles) {
                    circle.block = blockDict[circle.blockID]
                }
            }

            if (reversed) {
                circles.sortedByDescending { it.id }
            } else {
                circles.sortedBy { it.id }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch circles", e)
            emptyList()
        }
    }

    fun genres(): List<ComiketGenre> {
        val db = getTextDatabase() ?: return emptyList()
        return try {
            val cursor = db.rawQuery("SELECT * FROM ${ComiketGenre.TABLE_NAME}", null)
            val result = mutableListOf<ComiketGenre>()
            cursor.use {
                while (it.moveToNext()) {
                    result.add(ComiketGenre.fromCursor(it))
                }
            }
            result.sortedBy { it.id }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch genres", e)
            emptyList()
        }
    }

    fun blocks(): List<ComiketBlock> {
        val db = getTextDatabase() ?: return emptyList()
        return try {
            val cursor = db.rawQuery("SELECT * FROM ${ComiketBlock.TABLE_NAME}", null)
            val result = mutableListOf<ComiketBlock>()
            cursor.use {
                while (it.moveToNext()) {
                    result.add(ComiketBlock.fromCursor(it))
                }
            }
            result.sortedBy { it.id }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch blocks", e)
            emptyList()
        }
    }

    fun dates(): List<ComiketDate> {
        val db = getTextDatabase() ?: return emptyList()
        return try {
            val cursor = db.rawQuery("SELECT * FROM ${ComiketDate.TABLE_NAME}", null)
            val result = mutableListOf<ComiketDate>()
            cursor.use {
                while (it.moveToNext()) {
                    result.add(ComiketDate.fromCursor(it))
                }
            }
            result.sortedBy { it.id }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch dates", e)
            emptyList()
        }
    }

    fun maps(): List<ComiketMap> {
        val db = getTextDatabase() ?: return emptyList()
        return try {
            val cursor = db.rawQuery("SELECT * FROM ${ComiketMap.TABLE_NAME}", null)
            val result = mutableListOf<ComiketMap>()
            cursor.use {
                while (it.moveToNext()) {
                    result.add(ComiketMap.fromCursor(it))
                }
            }
            result.sortedBy { it.id }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch maps", e)
            emptyList()
        }
    }

    fun events(): List<ComiketEvent> {
        val db = getTextDatabase() ?: return emptyList()
        return try {
            val cursor = db.rawQuery("SELECT * FROM ${ComiketEvent.TABLE_NAME}", null)
            val result = mutableListOf<ComiketEvent>()
            cursor.use {
                while (it.moveToNext()) {
                    result.add(ComiketEvent.fromCursor(it))
                }
            }
            result.sortedBy { it.eventNumber }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch events", e)
            emptyList()
        }
    }

    // MARK: Images

    fun coverImage(): Bitmap? = commonImage("0001")
    fun blockImage(blockID: Int): Bitmap? = commonImage("B$blockID")
    fun jikoCircleCutImage(): Bitmap? = commonImage("JIKO")

    fun mapImage(hall: String, day: Int, usingHighDefinition: Boolean): Bitmap? {
        val prefix = if (usingHighDefinition) "LWMP" else "WMP"
        return commonImage("$prefix$day$hall")
    }

    fun genreImage(hall: String, day: Int, usingHighDefinition: Boolean): Bitmap? {
        val prefix = if (usingHighDefinition) "LWGR" else "WGR"
        return commonImage("$prefix$day$hall")
    }

    fun cachedCircleImage(id: Int): Bitmap? {
        return imageCache.get(id.toString())
    }

    fun circleImage(id: Int): Bitmap? {
        val cacheKey = id.toString()
        imageCache.get(cacheKey)?.let { return it }

        val db = getImageDatabase() ?: return null
        try {
            val cursor = db.rawQuery(
                "SELECT cutImage FROM ComiketCircleImage WHERE id = ?",
                arrayOf(id.toString())
            )
            cursor.use {
                if (it.moveToFirst()) {
                    val data = it.getBlob(0)
                    val options = BitmapFactory.Options().apply {
                        inPreferredConfig = Bitmap.Config.RGB_565
                    }
                    val bitmap = BitmapFactory.decodeByteArray(data, 0, data.size, options)
                    if (bitmap != null) {
                        imageCache.put(cacheKey, bitmap)
                    }
                    return bitmap
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load circle image $id", e)
        }
        return null
    }

    fun prefetchCircleImages(ids: List<Int>) {
        if (ids.isEmpty()) return
        val uncachedIDs = ids.filter { imageCache.get(it.toString()) == null }
        if (uncachedIDs.isEmpty()) return

        val db = getImageDatabase() ?: return
        try {
            val placeholders = uncachedIDs.joinToString(",") { "?" }
            val args = uncachedIDs.map { it.toString() }.toTypedArray()
            val cursor = db.rawQuery(
                "SELECT id, cutImage FROM ComiketCircleImage WHERE id IN ($placeholders)",
                args
            )
            val options = BitmapFactory.Options().apply {
                inPreferredConfig = Bitmap.Config.RGB_565
            }
            cursor.use {
                while (it.moveToNext()) {
                    val id = it.getInt(0)
                    val data = it.getBlob(1)
                    val bitmap = BitmapFactory.decodeByteArray(data, 0, data.size, options)
                    if (bitmap != null) {
                        imageCache.put(id.toString(), bitmap)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to prefetch circle images", e)
        }
    }

    fun commonImage(imageName: String): Bitmap? {
        imageCache.get(imageName)?.let { return it }
        commonImages[imageName]?.let { data ->
            val bitmap = BitmapFactory.decodeByteArray(data, 0, data.size)
            if (bitmap != null) {
                imageCache.put(imageName, bitmap)
            }
            return bitmap
        }
        return null
    }
}
