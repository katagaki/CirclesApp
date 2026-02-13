package com.tsubuzaki.circlesgo.api.catalog

import androidx.compose.ui.graphics.Color

enum class WebCatalogColor(val value: Int) {
    ORANGE(1),
    PINK(2),
    YELLOW(3),
    GREEN(4),
    CYAN(5),
    PURPLE(6),
    BLUE(7),
    LIME(8),
    RED(9);

    fun backgroundColor(): Color {
        return when (this) {
            ORANGE -> Color(1.0f, 0.58f, 0.29f)
            PINK -> Color(1.0f, 0.0f, 1.0f)
            YELLOW -> Color(1.0f, 0.97f, 0.0f)
            GREEN -> Color(0.0f, 0.71f, 0.29f)
            CYAN -> Color(0.0f, 0.71f, 1.0f)
            PURPLE -> Color(0.61f, 0.32f, 0.61f)
            BLUE -> Color(0.0f, 0.0f, 1.0f)
            LIME -> Color(0.0f, 1.0f, 0.0f)
            RED -> Color(1.0f, 0.0f, 0.0f)
        }
    }

    fun foregroundColor(): Color {
        return when (this) {
            ORANGE, PINK, GREEN, PURPLE, BLUE, RED -> Color.White
            YELLOW, CYAN, LIME -> Color.Black
        }
    }

    companion object {
        fun fromValue(value: Int): WebCatalogColor? {
            return entries.find { it.value == value }
        }
    }
}
