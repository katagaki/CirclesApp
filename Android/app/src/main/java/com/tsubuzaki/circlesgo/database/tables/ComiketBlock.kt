package com.tsubuzaki.circlesgo.database.tables

import android.database.Cursor

data class ComiketBlock(
    val eventNumber: Int,
    val id: Int,
    val name: String,
    val areaID: Int,
    var circles: List<ComiketCircle>? = null
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is ComiketBlock) return false
        return id == other.id && eventNumber == other.eventNumber
    }

    override fun hashCode(): Int {
        var result = id
        result = 31 * result + eventNumber
        return result
    }

    companion object {
        const val TABLE_NAME = "ComiketBlockWC"

        fun fromCursor(cursor: Cursor): ComiketBlock {
            return ComiketBlock(
                eventNumber = cursor.getInt(cursor.getColumnIndexOrThrow("comiketNo")),
                id = cursor.getInt(cursor.getColumnIndexOrThrow("id")),
                name = cursor.getString(cursor.getColumnIndexOrThrow("name")),
                areaID = cursor.getInt(cursor.getColumnIndexOrThrow("areaId"))
            )
        }
    }
}
