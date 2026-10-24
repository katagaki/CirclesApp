package com.tsubuzaki.circlesgo.database.tables

import android.database.Cursor

data class ComiketGenre(
    val eventNumber: Int,
    val id: Int,
    val name: String,
    val code: Int,
    val day: Int
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is ComiketGenre) return false
        return id == other.id && eventNumber == other.eventNumber
    }

    override fun hashCode(): Int {
        var result = id
        result = 31 * result + eventNumber
        return result
    }

    companion object {
        const val TABLE_NAME = "ComiketGenreWC"

        fun fromCursor(cursor: Cursor): ComiketGenre {
            return ComiketGenre(
                eventNumber = cursor.getInt(cursor.getColumnIndexOrThrow("comiketNo")),
                id = cursor.getInt(cursor.getColumnIndexOrThrow("id")),
                name = cursor.getString(cursor.getColumnIndexOrThrow("name")),
                code = cursor.getInt(cursor.getColumnIndexOrThrow("code")),
                day = cursor.getInt(cursor.getColumnIndexOrThrow("day"))
            )
        }
    }
}
