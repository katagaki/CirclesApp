package com.tsubuzaki.circlesgo.database.tables

import android.database.Cursor
import com.tsubuzaki.circlesgo.database.types.MapConfiguration
import com.tsubuzaki.circlesgo.database.types.Point
import com.tsubuzaki.circlesgo.database.types.Size

data class ComiketMap(
    val eventNumber: Int,
    val id: Int,
    val name: String,
    val filename: String,
    val allFilename: String,
    val configuration: MapConfiguration,
    val hdConfiguration: MapConfiguration,
    val rotation: Int,
    var layouts: List<ComiketLayout>? = null
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is ComiketMap) return false
        return id == other.id && eventNumber == other.eventNumber
    }

    override fun hashCode(): Int {
        var result = id
        result = 31 * result + eventNumber
        return result
    }

    companion object {
        const val TABLE_NAME = "ComiketMapWC"

        fun fromCursor(cursor: Cursor): ComiketMap {
            return ComiketMap(
                eventNumber = cursor.getInt(cursor.getColumnIndexOrThrow("comiketNo")),
                id = cursor.getInt(cursor.getColumnIndexOrThrow("id")),
                name = cursor.getString(cursor.getColumnIndexOrThrow("name")),
                filename = cursor.getString(cursor.getColumnIndexOrThrow("filename")),
                allFilename = cursor.getString(cursor.getColumnIndexOrThrow("allFilename")),
                configuration = MapConfiguration(
                    size = Size(
                        width = cursor.getInt(cursor.getColumnIndexOrThrow("w")),
                        height = cursor.getInt(cursor.getColumnIndexOrThrow("h"))
                    ),
                    origin = Point(
                        x = cursor.getInt(cursor.getColumnIndexOrThrow("x")),
                        y = cursor.getInt(cursor.getColumnIndexOrThrow("y"))
                    )
                ),
                hdConfiguration = MapConfiguration(
                    size = Size(
                        width = cursor.getInt(cursor.getColumnIndexOrThrow("w2")),
                        height = cursor.getInt(cursor.getColumnIndexOrThrow("h2"))
                    ),
                    origin = Point(
                        x = cursor.getInt(cursor.getColumnIndexOrThrow("x2")),
                        y = cursor.getInt(cursor.getColumnIndexOrThrow("y2"))
                    )
                ),
                rotation = cursor.getInt(cursor.getColumnIndexOrThrow("rotate"))
            )
        }
    }
}
