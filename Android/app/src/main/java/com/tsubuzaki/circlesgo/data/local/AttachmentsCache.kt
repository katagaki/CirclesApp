package com.tsubuzaki.circlesgo.data.local

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.io.File
import java.util.UUID

/**
 * Stores image attachments per event and circle, mirroring the iOS
 * AttachmentsDatabase. Images live as JPEG files under the app's
 * internal storage.
 */
class AttachmentsCache(context: Context) {

    private val baseDir = File(context.filesDir, "attachments")

    // Bumped after every mutation so views can observe changes
    private val _version = MutableStateFlow(0)
    val version: StateFlow<Int> = _version

    private fun dir(eventNumber: Int, circleID: Int): File {
        return File(baseDir, "$eventNumber/$circleID")
    }

    fun attachments(eventNumber: Int, circleID: Int): List<File> {
        val files = dir(eventNumber, circleID).listFiles() ?: return emptyList()
        return files.filter { it.isFile }.sortedBy { it.name }
    }

    /** Removes every event's attachments (sign-out wipe). */
    fun clearAll() {
        baseDir.deleteRecursively()
        _version.value += 1
    }

    fun load(file: File): Bitmap? {
        return try {
            BitmapFactory.decodeFile(file.path)
        } catch (e: Exception) {
            null
        }
    }

    fun add(eventNumber: Int, circleID: Int, bitmap: Bitmap) {
        val directory = dir(eventNumber, circleID)
        directory.mkdirs()
        val file = File(directory, "${System.currentTimeMillis()}-${UUID.randomUUID()}.jpg")
        file.outputStream().use { stream ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 80, stream)
        }
        _version.value += 1
    }

    fun delete(file: File) {
        file.delete()
        _version.value += 1
    }
}
