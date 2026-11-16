package com.tsubuzaki.circlesgo.wayfinding

import android.content.Context
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.io.File

/**
 * A Guide session as it stood when last changed, kept on disk so it can be picked up
 * again after the app is closed. Colors are stored as their Web Catalog values.
 */
@Serializable
data class GuideSession(
    val eventNumber: Int,
    val mapID: Int,
    val day: Int,
    val favoriteColors: Map<Int, Int>,
    val visitedCircleIDs: List<Int>,
    val colorPriority: List<Int>? = null,
    val route: PlannedRoute? = null,
    val stepIndex: Int,
    val origin: RoutePoint? = null,
    val closures: List<RouteClosure>,
    val skippedSpaces: List<String>,
    val remainingStopIDs: Set<Int>? = null,
    val isTrapped: Boolean,
    val isFinished: Boolean
) {

    fun save(context: Context) {
        runCatching {
            val file = file(context)
            val temporary = File(file.parentFile, "${file.name}.tmp")
            temporary.writeText(json.encodeToString(serializer(), this))
            temporary.renameTo(file)
        }
    }

    companion object {
        private val json = Json { ignoreUnknownKeys = true }

        private fun file(context: Context): File = File(context.filesDir, "GuideSession.json")

        fun load(context: Context): GuideSession? = runCatching {
            json.decodeFromString(serializer(), file(context).readText())
        }.getOrNull()

        fun remove(context: Context) {
            file(context).delete()
        }
    }
}
