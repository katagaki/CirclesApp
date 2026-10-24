package com.tsubuzaki.circlesgo.state

import android.graphics.RectF
import com.tsubuzaki.circlesgo.database.tables.LayoutCatalogMapping

data class PopoverData(
    val layout: LayoutCatalogMapping,
    val webCatalogIDs: List<Int>,
    val reversed: Boolean = false,
    val sourceRect: RectF = RectF()
) {
    val id: String
        get() = "ID_${webCatalogIDs},L_${layout.viewID()}"

    val ids: List<Int>
        get() = webCatalogIDs

    val layoutId: String
        get() = "Layout.${layout.blockID}.${layout.spaceNumber}"
}

data class HighlightData(
    val sourceRect: RectF,
    val shouldBlink: Boolean = false
)
