package com.tsubuzaki.circlesgo.database.tables

import android.database.Cursor

data class ComiketCircle(
    val eventNumber: Int,
    val id: Int,
    val pageNumber: Int,
    val cutIndex: Int,
    val day: Int,
    val blockID: Int,
    val spaceNumber: Int,
    val spaceNumberSuffix: Int,
    val genreID: Int,
    val circleName: String,
    val circleNameKana: String,
    val penName: String,
    val bookName: String,
    val url: String?,
    val mailAddress: String,
    val supplementaryDescription: String,
    val memo: String,
    val updateID: Int,
    val updateData: String,
    val circleMsURL: String?,
    val rss: String,
    val updateFlag: Int,
    var extendedInformation: ComiketCircleExtendedInformation? = null,
    var block: ComiketBlock? = null,
    var layout: ComiketLayout? = null
) {
    fun spaceName(): String? {
        val block = block ?: return null
        return "${block.name}${spaceNumberCombined()}"
    }

    fun spaceNumberCombined(): String {
        val formatted = String.format("%02d", spaceNumber)
        val suffix = when (spaceNumberSuffix) {
            0 -> "a"
            1 -> "b"
            2 -> "c"
            else -> ""
        }
        return "$formatted$suffix"
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is ComiketCircle) return false
        return id == other.id && eventNumber == other.eventNumber
    }

    override fun hashCode(): Int {
        var result = id
        result = 31 * result + eventNumber
        return result
    }

    companion object {
        const val TABLE_NAME = "ComiketCircleWC"

        fun fromCursor(cursor: Cursor): ComiketCircle {
            val urlString = cursor.getString(cursor.getColumnIndexOrThrow("url"))
            val circleMsString = cursor.getString(cursor.getColumnIndexOrThrow("circlems"))

            return ComiketCircle(
                eventNumber = cursor.getInt(cursor.getColumnIndexOrThrow("comiketNo")),
                id = cursor.getInt(cursor.getColumnIndexOrThrow("id")),
                pageNumber = cursor.getInt(cursor.getColumnIndexOrThrow("pageNo")),
                cutIndex = cursor.getInt(cursor.getColumnIndexOrThrow("cutIndex")),
                day = cursor.getInt(cursor.getColumnIndexOrThrow("day")),
                blockID = cursor.getInt(cursor.getColumnIndexOrThrow("blockId")),
                spaceNumber = cursor.getInt(cursor.getColumnIndexOrThrow("spaceNo")),
                spaceNumberSuffix = cursor.getInt(cursor.getColumnIndexOrThrow("spaceNoSub")),
                genreID = cursor.getInt(cursor.getColumnIndexOrThrow("genreId")),
                circleName = cursor.getString(cursor.getColumnIndexOrThrow("circleName")),
                circleNameKana = cursor.getString(cursor.getColumnIndexOrThrow("circleKana")),
                penName = cursor.getString(cursor.getColumnIndexOrThrow("penName")),
                bookName = cursor.getString(cursor.getColumnIndexOrThrow("bookName")),
                url = urlString.ifEmpty { null },
                mailAddress = cursor.getString(cursor.getColumnIndexOrThrow("mailAddr")),
                supplementaryDescription = cursor.getString(cursor.getColumnIndexOrThrow("description")),
                memo = cursor.getString(cursor.getColumnIndexOrThrow("memo")),
                updateID = cursor.getInt(cursor.getColumnIndexOrThrow("updateId")),
                updateData = cursor.getString(cursor.getColumnIndexOrThrow("updateData")),
                circleMsURL = circleMsString.ifEmpty { null },
                rss = cursor.getString(cursor.getColumnIndexOrThrow("rss")),
                updateFlag = cursor.getInt(cursor.getColumnIndexOrThrow("updateFlag"))
            )
        }
    }
}
