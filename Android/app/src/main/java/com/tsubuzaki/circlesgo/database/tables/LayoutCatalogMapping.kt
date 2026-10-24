package com.tsubuzaki.circlesgo.database.tables

import com.tsubuzaki.circlesgo.database.types.LayoutType

data class LayoutCatalogMapping(
    val blockID: Int,
    val spaceNumber: Int,
    val positionX: Int,
    val positionY: Int,
    val layoutType: LayoutType
) {
    fun viewID(): String = "$blockID,$spaceNumber"

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is LayoutCatalogMapping) return false
        return blockID == other.blockID && spaceNumber == other.spaceNumber
    }

    override fun hashCode(): Int {
        var result = blockID
        result = 31 * result + spaceNumber
        return result
    }
}
