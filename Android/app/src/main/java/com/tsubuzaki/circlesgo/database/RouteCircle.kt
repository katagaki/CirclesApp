package com.tsubuzaki.circlesgo.database

data class RouteCircle(
    val circleID: Int,
    val webCatalogID: Int,
    val name: String,
    val blockName: String,
    val spaceNumber: Int,
    val spaceNumberSuffix: Int
) {
    val spaceName: String
        get() {
            val suffix = when (spaceNumberSuffix) {
                0 -> "a"
                1 -> "b"
                2 -> "c"
                else -> ""
            }
            return "$blockName${"%02d".format(spaceNumber)}$suffix"
        }
}
