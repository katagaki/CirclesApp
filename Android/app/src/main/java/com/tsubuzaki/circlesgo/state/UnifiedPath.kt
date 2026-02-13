package com.tsubuzaki.circlesgo.state

enum class UnifiedPath(val identifier: String) {
    MAP("Map"),
    CIRCLES("Circles"),
    FAVORITES("Favorites"),
    CIRCLE_DETAIL("CircleDetail"),
    MY("My"),
    MORE("More"),
    MORE_DB_ADMIN("More.DBAdmin"),
    MORE_ATTRIBUTIONS("More.Attributions");

    companion object {
        fun fromIdentifier(id: String): UnifiedPath? {
            return entries.find { it.identifier == id }
        }
    }
}

enum class SidebarPosition {
    LEADING,
    TRAILING
}
