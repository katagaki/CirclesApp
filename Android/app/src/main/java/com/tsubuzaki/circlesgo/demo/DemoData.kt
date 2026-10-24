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

    fun install(context: Context, targetDir: File) {
        if (!targetDir.exists()) targetDir.mkdirs()
        for (eventNumber in DemoState.DATASET_EVENT_NUMBERS) {
            for (name in fileNames(eventNumber)) {
                val out = File(targetDir, name)
                context.assets.open("demo/$name").use { input ->
                    out.outputStream().use { output -> input.copyTo(output) }
                }
            }
        }
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
