package com.tsubuzaki.circlesgo.demo

import android.content.Context
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogEvent
import com.tsubuzaki.circlesgo.state.DemoState
import java.io.File

object DemoData {

    private fun fileNames(eventNumber: Int): List<String> = listOf(
        "webcatalog$eventNumber.db",
        "webcatalog${eventNumber}Image1.db"
    )

    private const val INSTALLED_MARKER = ".installed"

    fun install(context: Context, targetDir: File) {
        if (!targetDir.exists()) targetDir.mkdirs()
        val names = DemoState.DATASET_EVENT_NUMBERS.flatMap(::fileNames)
        val marker = File(targetDir, INSTALLED_MARKER)
        val installStamp = context.packageManager
            .getPackageInfo(context.packageName, 0).lastUpdateTime.toString()
        val isInstalled = marker.exists() && marker.readText() == installStamp &&
            names.all { File(targetDir, it).exists() }
        if (isInstalled) return
        for (name in names) {
            val out = File(targetDir, name)
            context.assets.open("demo/$name").use { input ->
                out.outputStream().use { output -> input.copyTo(output) }
            }
        }
        marker.writeText(installStamp)
    }

    fun eventList(): WebCatalogEvent.Response {
        val list = DemoState.PLACEHOLDER_EVENT_NUMBERS.map {
            WebCatalogEvent.Response.Event(id = it, number = it)
        }
        return WebCatalogEvent.Response(
            list = list,
            latestEventID = DemoState.DEFAULT_DATASET,
            latestEventNumber = DemoState.DEFAULT_DATASET
        )
    }
}
