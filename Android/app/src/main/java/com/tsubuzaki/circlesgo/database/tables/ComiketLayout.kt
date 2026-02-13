package com.tsubuzaki.circlesgo.database.tables

import android.database.Cursor
import com.tsubuzaki.circlesgo.database.types.LayoutType
import com.tsubuzaki.circlesgo.database.types.Point

data class ComiketLayout(
    val eventNumber: Int,
    val blockID: Int,
    val spaceNumber: Int,
    val position: Point,
    val hdPosition: Point,
    val layout: LayoutType,
    val mapID: Int,
    val hallID: Int,
    var map: ComiketMap? = null,
    var circles: List<ComiketCircle>? = null
) {
    val mergedID: String
        get() = "$blockID|$spaceNumber"

    companion object {
        const val TABLE_NAME = "ComiketLayoutWC"

        fun fromCursor(cursor: Cursor): ComiketLayout {
            return ComiketLayout(
                eventNumber = cursor.getInt(cursor.getColumnIndexOrThrow("comiketNo")),
                blockID = cursor.getInt(cursor.getColumnIndexOrThrow("blockId")),
                spaceNumber = cursor.getInt(cursor.getColumnIndexOrThrow("spaceNo")),
                position = Point(
                    x = cursor.getInt(cursor.getColumnIndexOrThrow("xpos")),
                    y = cursor.getInt(cursor.getColumnIndexOrThrow("ypos"))
                ),
                hdPosition = Point(
                    x = cursor.getInt(cursor.getColumnIndexOrThrow("xpos2")),
                    y = cursor.getInt(cursor.getColumnIndexOrThrow("ypos2"))
                ),
                layout = LayoutType.fromValue(cursor.getInt(cursor.getColumnIndexOrThrow("layout"))),
                mapID = cursor.getInt(cursor.getColumnIndexOrThrow("mapId")),
                hallID = cursor.getInt(cursor.getColumnIndexOrThrow("hallId"))
            )
        }
    }
}
