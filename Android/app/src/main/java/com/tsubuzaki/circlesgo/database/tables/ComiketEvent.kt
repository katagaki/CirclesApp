package com.tsubuzaki.circlesgo.database.tables

import android.database.Cursor
import com.tsubuzaki.circlesgo.database.types.CircleCutConfiguration
import com.tsubuzaki.circlesgo.database.types.MapConfiguration
import com.tsubuzaki.circlesgo.database.types.Point
import com.tsubuzaki.circlesgo.database.types.Size

data class ComiketEvent(
    val eventNumber: Int,
    val name: String,
    val circleCutConfiguration: CircleCutConfiguration,
    val mapConfiguration: MapConfiguration,
    val hdMapConfiguration: MapConfiguration
) {
    companion object {
        const val TABLE_NAME = "ComiketInfoWC"

        fun fromCursor(cursor: Cursor): ComiketEvent {
            return ComiketEvent(
                eventNumber = cursor.getInt(cursor.getColumnIndexOrThrow("comiketNo")),
                name = cursor.getString(cursor.getColumnIndexOrThrow("comiketName")),
                circleCutConfiguration = CircleCutConfiguration(
                    size = Size(
                        width = cursor.getInt(cursor.getColumnIndexOrThrow("cutSizeW")),
                        height = cursor.getInt(cursor.getColumnIndexOrThrow("cutSizeH"))
                    ),
                    origin = Point(
                        x = cursor.getInt(cursor.getColumnIndexOrThrow("cutOriginX")),
                        y = cursor.getInt(cursor.getColumnIndexOrThrow("cutOriginY"))
                    ),
                    offset = Point(
                        x = cursor.getInt(cursor.getColumnIndexOrThrow("cutOffsetX")),
                        y = cursor.getInt(cursor.getColumnIndexOrThrow("cutOffsetY"))
                    )
                ),
                mapConfiguration = MapConfiguration(
                    size = Size(
                        width = cursor.getInt(cursor.getColumnIndexOrThrow("mapSizeW")),
                        height = cursor.getInt(cursor.getColumnIndexOrThrow("mapSizeH"))
                    ),
                    origin = Point(
                        x = cursor.getInt(cursor.getColumnIndexOrThrow("mapOriginX")),
                        y = cursor.getInt(cursor.getColumnIndexOrThrow("mapOriginY"))
                    )
                ),
                hdMapConfiguration = MapConfiguration(
                    size = Size(
                        width = cursor.getInt(cursor.getColumnIndexOrThrow("map2SizeW")),
                        height = cursor.getInt(cursor.getColumnIndexOrThrow("map2SizeH"))
                    ),
                    origin = Point(
                        x = cursor.getInt(cursor.getColumnIndexOrThrow("map2OriginX")),
                        y = cursor.getInt(cursor.getColumnIndexOrThrow("map2OriginY"))
                    )
                )
            )
        }
    }
}
