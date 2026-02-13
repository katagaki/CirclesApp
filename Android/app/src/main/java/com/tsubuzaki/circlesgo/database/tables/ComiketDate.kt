package com.tsubuzaki.circlesgo.database.tables

import android.database.Cursor
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

data class ComiketDate(
    val eventNumber: Int,
    val id: Int,
    val date: Date
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is ComiketDate) return false
        return id == other.id && eventNumber == other.eventNumber
    }

    override fun hashCode(): Int {
        var result = id
        result = 31 * result + eventNumber
        return result
    }

    companion object {
        const val TABLE_NAME = "ComiketDateWC"

        private val dateFormatter = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("Asia/Tokyo")
        }

        fun fromCursor(cursor: Cursor): ComiketDate {
            val year = String.format("%04d", cursor.getInt(cursor.getColumnIndexOrThrow("year")))
            val month = String.format("%02d", cursor.getInt(cursor.getColumnIndexOrThrow("month")))
            val day = String.format("%02d", cursor.getInt(cursor.getColumnIndexOrThrow("day")))

            val date = dateFormatter.parse("$year-$month-$day") ?: Date(0)

            return ComiketDate(
                eventNumber = cursor.getInt(cursor.getColumnIndexOrThrow("comiketNo")),
                id = cursor.getInt(cursor.getColumnIndexOrThrow("id")),
                date = date
            )
        }
    }
}
