package com.tsubuzaki.circlesgo.database.tables

import android.database.Cursor

data class ComiketCircleExtendedInformation(
    val eventNumber: Int,
    val id: Int,
    val webCatalogID: Int,
    val twitterURL: String?,
    val pixivURL: String?,
    val circleMsPortalURL: String?,
    var circle: ComiketCircle? = null
) {
    fun hasAccessibleURLs(): Boolean {
        return !twitterURL.isNullOrEmpty() || !pixivURL.isNullOrEmpty() || !circleMsPortalURL.isNullOrEmpty()
    }

    companion object {
        const val TABLE_NAME = "ComiketCircleExtend"

        fun fromCursor(cursor: Cursor): ComiketCircleExtendedInformation {
            val twitterString = cursor.getString(cursor.getColumnIndexOrThrow("twitterURL"))
            val pixivString = cursor.getString(cursor.getColumnIndexOrThrow("pixivURL"))
            val portalString = cursor.getString(cursor.getColumnIndexOrThrow("CirclemsPortalURL"))

            return ComiketCircleExtendedInformation(
                eventNumber = cursor.getInt(cursor.getColumnIndexOrThrow("comiketNo")),
                id = cursor.getInt(cursor.getColumnIndexOrThrow("id")),
                webCatalogID = cursor.getInt(cursor.getColumnIndexOrThrow("WCId")),
                twitterURL = twitterString.ifEmpty { null },
                pixivURL = pixivString.ifEmpty { null },
                circleMsPortalURL = portalString.ifEmpty { null }
            )
        }

        fun fromJoinedCursor(
            cursor: Cursor,
            extendedTablePrefix: String = ""
        ): ComiketCircleExtendedInformation {
            val twitterString = cursor.getString(cursor.getColumnIndexOrThrow("twitterURL"))
            val pixivString = cursor.getString(cursor.getColumnIndexOrThrow("pixivURL"))
            val portalString = cursor.getString(cursor.getColumnIndexOrThrow("CirclemsPortalURL"))

            return ComiketCircleExtendedInformation(
                eventNumber = cursor.getInt(cursor.getColumnIndexOrThrow("comiketNo")),
                id = cursor.getInt(cursor.getColumnIndexOrThrow("id")),
                webCatalogID = cursor.getInt(cursor.getColumnIndexOrThrow("WCId")),
                twitterURL = twitterString.ifEmpty { null },
                pixivURL = pixivString.ifEmpty { null },
                circleMsPortalURL = portalString.ifEmpty { null }
            )
        }
    }
}
