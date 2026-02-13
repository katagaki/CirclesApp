package com.tsubuzaki.circlesgo.database

import android.database.sqlite.SQLiteDatabase
import android.util.Log
import com.tsubuzaki.circlesgo.database.tables.ComiketLayout
import com.tsubuzaki.circlesgo.database.tables.LayoutCatalogMapping
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Calendar
import java.util.Date

class DataFetcher(private val database: SQLiteDatabase?) {

    companion object {
        private const val TAG = "DataFetcher"
    }

    suspend fun dates(eventNumber: Int): Map<Int, Date> = withContext(Dispatchers.IO) {
        val db = database ?: return@withContext emptyMap()
        try {
            val cursor = db.rawQuery(
                "SELECT id, year, month, day FROM ComiketDateWC WHERE comiketNo = ? ORDER BY id ASC",
                arrayOf(eventNumber.toString())
            )
            val result = mutableMapOf<Int, Date>()
            cursor.use {
                while (it.moveToNext()) {
                    val id = it.getInt(0)
                    val year = it.getInt(1)
                    val month = it.getInt(2)
                    val day = it.getInt(3)
                    val cal = Calendar.getInstance()
                    cal.set(year, month - 1, day, 0, 0, 0)
                    result[id] = cal.time
                }
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch dates", e)
            emptyMap()
        }
    }

    suspend fun layoutMappings(
        mapID: Int,
        useHighResolutionMaps: Boolean
    ): List<LayoutCatalogMapping> = withContext(Dispatchers.IO) {
        val db = database ?: return@withContext emptyList()
        try {
            val cursor = db.rawQuery(
                "SELECT * FROM ComiketLayoutWC WHERE mapId = ?",
                arrayOf(mapID.toString())
            )
            val result = mutableListOf<LayoutCatalogMapping>()
            cursor.use {
                while (it.moveToNext()) {
                    val layout = ComiketLayout.fromCursor(it)
                    result.add(
                        LayoutCatalogMapping(
                            blockID = layout.blockID,
                            spaceNumber = layout.spaceNumber,
                            positionX = if (useHighResolutionMaps) layout.hdPosition.x else layout.position.x,
                            positionY = if (useHighResolutionMaps) layout.hdPosition.y else layout.position.y,
                            layoutType = layout.layout
                        )
                    )
                }
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch layout mappings", e)
            emptyList()
        }
    }

    suspend fun genre(genreID: Int): String? = withContext(Dispatchers.IO) {
        val db = database ?: return@withContext null
        try {
            val cursor = db.rawQuery(
                "SELECT name FROM ComiketGenreWC WHERE id = ?",
                arrayOf(genreID.toString())
            )
            cursor.use {
                if (it.moveToFirst()) it.getString(0) else null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch genre", e)
            null
        }
    }

    suspend fun layoutCatalogMappingToWebCatalogIDs(
        mappings: List<LayoutCatalogMapping>,
        dateID: Int
    ): Map<LayoutCatalogMapping, List<Int>> = withContext(Dispatchers.IO) {
        val db = database ?: return@withContext emptyMap()
        if (mappings.isEmpty()) return@withContext emptyMap()

        try {
            val blockIDs = mappings.map { it.blockID }.toSet()
            val spaceNumbers = mappings.map { it.spaceNumber }.toSet()

            val blockPlaceholders = blockIDs.joinToString(",") { "?" }
            val spacePlaceholders = spaceNumbers.joinToString(",") { "?" }
            val args = blockIDs.map { it.toString() } +
                    spaceNumbers.map { it.toString() } +
                    listOf(dateID.toString())

            val cursor = db.rawQuery(
                """
                SELECT c.blockId, c.spaceNo, e.WCId
                FROM ComiketCircleWC c
                LEFT OUTER JOIN ComiketCircleExtend e ON c.id = e.id
                WHERE c.blockId IN ($blockPlaceholders)
                AND c.spaceNo IN ($spacePlaceholders)
                AND c.day = ?
                ORDER BY c.id ASC
                """.trimIndent(),
                args.toTypedArray()
            )

            val mappingLookup = mappings.associateBy { "${it.blockID}-${it.spaceNumber}" }
            val result = mutableMapOf<LayoutCatalogMapping, MutableList<Int>>()

            cursor.use {
                val wcIdIndex = it.getColumnIndex("WCId")
                while (it.moveToNext()) {
                    if (wcIdIndex >= 0 && !it.isNull(wcIdIndex)) {
                        val webCatalogID = it.getInt(wcIdIndex)
                        val blockID = it.getInt(it.getColumnIndexOrThrow("blockId"))
                        val spaceNumber = it.getInt(it.getColumnIndexOrThrow("spaceNo"))
                        val key = "$blockID-$spaceNumber"
                        mappingLookup[key]?.let { mapping ->
                            result.getOrPut(mapping) { mutableListOf() }.add(webCatalogID)
                        }
                    }
                }
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch layout mapping web catalog IDs", e)
            emptyMap()
        }
    }

    suspend fun circlesContaining(searchTerm: String): List<Int> = withContext(Dispatchers.IO) {
        val db = database ?: return@withContext emptyList()
        try {
            val pattern = "%$searchTerm%"
            val cursor = db.rawQuery(
                """
                SELECT id FROM ComiketCircleWC
                WHERE circleName LIKE ? OR circleKana LIKE ? OR penName LIKE ?
                """.trimIndent(),
                arrayOf(pattern, pattern, pattern)
            )
            val result = mutableListOf<Int>()
            cursor.use {
                while (it.moveToNext()) {
                    result.add(it.getInt(0))
                }
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "Failed to search circles", e)
            emptyList()
        }
    }

    suspend fun circles(
        mapID: Int?,
        genreIDs: List<Int>?,
        blockIDs: List<Int>?,
        dayID: Int?
    ): List<Int> = withContext(Dispatchers.IO) {
        val db = database ?: return@withContext emptyList()
        try {
            val conditions = mutableListOf<String>()
            val args = mutableListOf<String>()
            var hasFilter = false

            // Filter by map: get block IDs from mapping table
            if (mapID != null) {
                val mapCursor = db.rawQuery(
                    "SELECT blockId FROM ComiketMappingWC WHERE mapId = ?",
                    arrayOf(mapID.toString())
                )
                val mappedBlockIDs = mutableSetOf<Int>()
                mapCursor.use {
                    while (it.moveToNext()) {
                        mappedBlockIDs.add(it.getInt(0))
                    }
                }
                if (mappedBlockIDs.isEmpty()) return@withContext emptyList()

                val placeholders = mappedBlockIDs.joinToString(",") { "?" }
                conditions.add("blockId IN ($placeholders)")
                args.addAll(mappedBlockIDs.map { it.toString() })
                hasFilter = true
            }

            if (!genreIDs.isNullOrEmpty()) {
                val placeholders = genreIDs.joinToString(",") { "?" }
                conditions.add("genreId IN ($placeholders)")
                args.addAll(genreIDs.map { it.toString() })
                hasFilter = true
            }

            if (!blockIDs.isNullOrEmpty()) {
                val placeholders = blockIDs.joinToString(",") { "?" }
                conditions.add("blockId IN ($placeholders)")
                args.addAll(blockIDs.map { it.toString() })
                hasFilter = true
            }

            if (dayID != null) {
                conditions.add("day = ?")
                args.add(dayID.toString())
                hasFilter = true
            }

            if (!hasFilter) return@withContext emptyList()

            val whereClause = conditions.joinToString(" AND ")
            val cursor = db.rawQuery(
                "SELECT id FROM ComiketCircleWC WHERE $whereClause",
                args.toTypedArray()
            )
            val result = mutableListOf<Int>()
            cursor.use {
                while (it.moveToNext()) {
                    result.add(it.getInt(0))
                }
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch circles by filter", e)
            emptyList()
        }
    }

    suspend fun genreIDs(mapID: Int, dayID: Int): List<Int> = withContext(Dispatchers.IO) {
        val db = database ?: return@withContext emptyList()
        try {
            val mapCursor = db.rawQuery(
                "SELECT blockId FROM ComiketMappingWC WHERE mapId = ?",
                arrayOf(mapID.toString())
            )
            val mappedBlockIDs = mutableSetOf<Int>()
            mapCursor.use {
                while (it.moveToNext()) {
                    mappedBlockIDs.add(it.getInt(0))
                }
            }

            if (mappedBlockIDs.isEmpty()) return@withContext emptyList()

            val placeholders = mappedBlockIDs.joinToString(",") { "?" }
            val args = mappedBlockIDs.map { it.toString() } + listOf(dayID.toString())
            val cursor = db.rawQuery(
                "SELECT DISTINCT genreId FROM ComiketCircleWC WHERE blockId IN ($placeholders) AND day = ?",
                args.toTypedArray()
            )
            val result = mutableListOf<Int>()
            cursor.use {
                while (it.moveToNext()) {
                    result.add(it.getInt(0))
                }
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch genre IDs", e)
            emptyList()
        }
    }

    suspend fun blockIDs(
        mapID: Int,
        dayID: Int,
        genreIDs: List<Int>?
    ): List<Int> = withContext(Dispatchers.IO) {
        val db = database ?: return@withContext emptyList()
        try {
            val mapCursor = db.rawQuery(
                "SELECT blockId FROM ComiketMappingWC WHERE mapId = ?",
                arrayOf(mapID.toString())
            )
            val mappedBlockIDs = mutableSetOf<Int>()
            mapCursor.use {
                while (it.moveToNext()) {
                    mappedBlockIDs.add(it.getInt(0))
                }
            }

            if (mappedBlockIDs.isEmpty()) return@withContext emptyList()

            val conditions = mutableListOf<String>()
            val args = mutableListOf<String>()

            val placeholders = mappedBlockIDs.joinToString(",") { "?" }
            conditions.add("blockId IN ($placeholders)")
            args.addAll(mappedBlockIDs.map { it.toString() })

            conditions.add("day = ?")
            args.add(dayID.toString())

            if (!genreIDs.isNullOrEmpty()) {
                val genrePlaceholders = genreIDs.joinToString(",") { "?" }
                conditions.add("genreId IN ($genrePlaceholders)")
                args.addAll(genreIDs.map { it.toString() })
            }

            val whereClause = conditions.joinToString(" AND ")
            val cursor = db.rawQuery(
                "SELECT DISTINCT blockId FROM ComiketCircleWC WHERE $whereClause",
                args.toTypedArray()
            )
            val result = mutableListOf<Int>()
            cursor.use {
                while (it.moveToNext()) {
                    result.add(it.getInt(0))
                }
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch block IDs", e)
            emptyList()
        }
    }

    suspend fun circlesWithWebCatalogIDs(webCatalogIDs: List<Int>): List<Int> =
        withContext(Dispatchers.IO) {
            val db = database ?: return@withContext emptyList()
            if (webCatalogIDs.isEmpty()) return@withContext emptyList()
            try {
                val placeholders = webCatalogIDs.joinToString(",") { "?" }
                val args = webCatalogIDs.map { it.toString() }.toTypedArray()
                val cursor = db.rawQuery(
                    "SELECT id FROM ComiketCircleExtend WHERE WCId IN ($placeholders)",
                    args
                )
                val result = mutableListOf<Int>()
                cursor.use {
                    while (it.moveToNext()) {
                        result.add(it.getInt(0))
                    }
                }
                result
            } catch (e: Exception) {
                Log.e(TAG, "Failed to fetch circles by web catalog IDs", e)
                emptyList()
            }
        }

    suspend fun webCatalogIDs(circleIDs: List<Int>): List<Int> = withContext(Dispatchers.IO) {
        val db = database ?: return@withContext emptyList()
        if (circleIDs.isEmpty()) return@withContext emptyList()
        try {
            val placeholders = circleIDs.joinToString(",") { "?" }
            val args = circleIDs.map { it.toString() }.toTypedArray()
            val cursor = db.rawQuery(
                "SELECT WCId FROM ComiketCircleExtend WHERE id IN ($placeholders)",
                args
            )
            val result = mutableListOf<Int>()
            cursor.use {
                while (it.moveToNext()) {
                    result.add(it.getInt(0))
                }
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch web catalog IDs", e)
            emptyList()
        }
    }

    suspend fun spaceNumberSuffixes(webCatalogIDs: List<Int>): Map<Int, Int> =
        withContext(Dispatchers.IO) {
            val db = database ?: return@withContext webCatalogIDs.associateWith { 0 }
            if (webCatalogIDs.isEmpty()) return@withContext emptyMap()
            try {
                val placeholders = webCatalogIDs.joinToString(",") { "?" }
                val args = webCatalogIDs.map { it.toString() }.toTypedArray()
                val cursor = db.rawQuery(
                    """
                SELECT e.WCId, c.spaceNoSub
                FROM ComiketCircleWC c
                INNER JOIN ComiketCircleExtend e ON c.id = e.id
                WHERE e.WCId IN ($placeholders)
                """.trimIndent(),
                    args
                )
                val result = mutableMapOf<Int, Int>()
                cursor.use {
                    while (it.moveToNext()) {
                        result[it.getInt(0)] = it.getInt(1)
                    }
                }
                result
            } catch (e: Exception) {
                Log.e(TAG, "Failed to fetch space number suffixes", e)
                webCatalogIDs.associateWith { 0 }
            }
        }

    suspend fun mapID(blockID: Int): Int? = withContext(Dispatchers.IO) {
        val db = database ?: return@withContext null
        try {
            val cursor = db.rawQuery(
                "SELECT mapId FROM ComiketMappingWC WHERE blockId = ?",
                arrayOf(blockID.toString())
            )
            cursor.use {
                if (it.moveToFirst()) it.getInt(0) else null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch map ID", e)
            null
        }
    }
}
