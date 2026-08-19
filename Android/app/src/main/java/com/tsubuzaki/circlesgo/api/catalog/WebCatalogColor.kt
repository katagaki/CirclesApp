package com.tsubuzaki.circlesgo.api.catalog

import androidx.compose.ui.graphics.Color

enum class WebCatalogColor(val value: Int) {
    UNCOLORED(0),
    ORANGE(1),
    PINK(2),
    YELLOW(3),
    GREEN(4),
    CYAN(5),
    PURPLE(6),
    BLUE(7),
    LIME(8),
    RED(9),
    DARK_ORANGE(10),
    DARK_PURPLE(11),
    TEAL(12),
    MAROON(13),
    VIOLET(14),
    GOLD(15),
    DARK_GREEN(16),
    CRIMSON(17),
    DEEP_PINK(18);

    fun backgroundColor(): Color {
        return when (this) {
            UNCOLORED -> Color(0.56f, 0.56f, 0.58f)
            ORANGE -> Color(1.0f, 0.58f, 0.29f)
            PINK -> Color(1.0f, 0.0f, 1.0f)
            YELLOW -> Color(1.0f, 0.97f, 0.0f)
            GREEN -> Color(0.0f, 0.71f, 0.29f)
            CYAN -> Color(0.0f, 0.71f, 1.0f)
            PURPLE -> Color(0.61f, 0.32f, 0.61f)
            BLUE -> Color(0.0f, 0.0f, 1.0f)
            LIME -> Color(0.0f, 1.0f, 0.0f)
            RED -> Color(1.0f, 0.0f, 0.0f)
            DARK_ORANGE -> Color(0.91f, 0.45f, 0.13f)
            DARK_PURPLE -> Color(0.48f, 0.18f, 0.56f)
            TEAL -> Color(0.17f, 0.52f, 0.53f)
            MAROON -> Color(0.63f, 0.17f, 0.18f)
            VIOLET -> Color(0.42f, 0.35f, 0.8f)
            GOLD -> Color(0.78f, 0.63f, 0.15f)
            DARK_GREEN -> Color(0.2f, 0.49f, 0.32f)
            CRIMSON -> Color(0.8f, 0.16f, 0.19f)
            DEEP_PINK -> Color(0.91f, 0.15f, 0.42f)
        }
    }

    fun foregroundColor(): Color {
        return when (this) {
            UNCOLORED, ORANGE, PINK, GREEN, PURPLE, BLUE, RED,
            DARK_ORANGE, DARK_PURPLE, TEAL, MAROON, VIOLET,
            DARK_GREEN, CRIMSON, DEEP_PINK -> Color.White

            YELLOW, CYAN, LIME, GOLD -> Color.Black
        }
    }

    companion object {
        /** Colors a user can assign to a favorite; excludes [UNCOLORED]. */
        val assignable: List<WebCatalogColor> = entries.filter { it != UNCOLORED }

        // Out-of-palette Web Catalog colors decode as UNCOLORED
        fun fromValue(value: Int): WebCatalogColor {
            return entries.find { it.value == value } ?: UNCOLORED
        }
    }
}
