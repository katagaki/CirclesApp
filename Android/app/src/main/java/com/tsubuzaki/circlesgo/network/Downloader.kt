package com.tsubuzaki.circlesgo.network

import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL

class Downloader {

    companion object {
        private const val TAG = "Downloader"
        private const val BUFFER_SIZE = 8192
    }

    suspend fun download(
        sourceURL: String,
        destinationDir: File,
        onProgress: (suspend (Double) -> Unit)? = null
    ): File = withContext(Dispatchers.IO) {
        if (!destinationDir.exists()) {
            destinationDir.mkdirs()
        }

        val url = URL(sourceURL)
        val connection = url.openConnection() as HttpURLConnection
        try {
            connection.connect()

            if (connection.responseCode != HttpURLConnection.HTTP_OK) {
                throw Exception("HTTP error: ${connection.responseCode}")
            }

            val totalBytes = connection.contentLengthLong
            val fileName = url.path.substringAfterLast("/")
            val destinationFile = File(destinationDir, fileName)

            connection.inputStream.use { input ->
                FileOutputStream(destinationFile).use { output ->
                    val buffer = ByteArray(BUFFER_SIZE)
                    var bytesRead: Int
                    var totalBytesRead = 0L

                    while (input.read(buffer).also { bytesRead = it } != -1) {
                        output.write(buffer, 0, bytesRead)
                        totalBytesRead += bytesRead

                        if (totalBytes > 0) {
                            onProgress?.invoke(totalBytesRead.toDouble() / totalBytes.toDouble())
                        }
                    }
                }
            }

            Log.d(TAG, "Downloaded to ${destinationFile.absolutePath}")
            destinationFile
        } finally {
            connection.disconnect()
        }
    }
}
