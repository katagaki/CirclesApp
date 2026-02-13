package com.tsubuzaki.circlesgo.database

import android.util.Log
import com.tsubuzaki.circlesgo.api.Endpoints
import com.tsubuzaki.circlesgo.api.auth.OpenIDToken
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogDatabase
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogEvent
import com.tsubuzaki.circlesgo.network.Downloader
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.zip.ZipFile

class CatalogDatabaseDownloader(
    private val catalogDatabase: CatalogDatabase
) {
    companion object {
        private const val TAG = "CatalogDatabaseDownloader"
        private val json = Json { ignoreUnknownKeys = true }
    }

    suspend fun downloadTextDatabase(
        event: WebCatalogEvent.Response.Event,
        authToken: OpenIDToken,
        updateProgress: suspend (Double?) -> Unit
    ) {
        val file = download(event, DatabaseType.TEXT, authToken, updateProgress)
        if (file != null) {
            catalogDatabase.setTextDatabaseFile(file)
        }
    }

    suspend fun downloadImageDatabase(
        event: WebCatalogEvent.Response.Event,
        authToken: OpenIDToken,
        updateProgress: suspend (Double?) -> Unit
    ) {
        val file = download(event, DatabaseType.IMAGES, authToken, updateProgress)
        if (file != null) {
            catalogDatabase.setImageDatabaseFile(file)
        }
    }

    private suspend fun download(
        event: WebCatalogEvent.Response.Event,
        type: DatabaseType,
        authToken: OpenIDToken,
        updateProgress: suspend (Double?) -> Unit
    ): File? = withContext(Dispatchers.IO) {
        val dataStoreDir = catalogDatabase.dataStoreDir
        val databaseFileName = catalogDatabase.getDatabaseFileName(event, type)
        val databaseFile = File(dataStoreDir, databaseFileName)

        if (databaseFile.exists()) {
            return@withContext databaseFile
        }

        if (!dataStoreDir.exists()) {
            dataStoreDir.mkdirs()
        }

        // Fetch database information if not already present
        if (catalogDatabase.databaseInformation == null) {
            val info = fetchDatabaseInformation(event, authToken)
            if (info != null) {
                catalogDatabase.setDatabaseInformation(info)
            }
        }

        val databaseInfo = catalogDatabase.databaseInformation ?: return@withContext null

        val downloadURL = when (type) {
            DatabaseType.TEXT -> databaseInfo.response.databaseForText()
            DatabaseType.IMAGES -> databaseInfo.response.databaseFor211By300Images()
        } ?: return@withContext null

        // Download the ZIP file
        val downloader = Downloader()
        val zippedFile = try {
            downloader.download(downloadURL, dataStoreDir) { progress ->
                updateProgress(progress)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Download failed", e)
            return@withContext null
        }

        updateProgress(null)

        // Unzip the file
        unzip(zippedFile, dataStoreDir, updateProgress)
    }

    private suspend fun fetchDatabaseInformation(
        event: WebCatalogEvent.Response.Event,
        authToken: OpenIDToken
    ): WebCatalogDatabase? = withContext(Dispatchers.IO) {
        try {
            val url = URL("${Endpoints.circleMsAPIEndpoint}/CatalogBase/All/")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.setRequestProperty("Authorization", "Bearer ${authToken.accessToken}")
            connection.doOutput = true

            val body = "event_id=${event.id}&event_no=${event.number}"
            connection.outputStream.use { it.write(body.toByteArray()) }

            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val responseBody = connection.inputStream.bufferedReader().readText()
                json.decodeFromString<WebCatalogDatabase>(responseBody)
            } else {
                Log.e(TAG, "Failed to fetch database info: HTTP $responseCode")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch database information", e)
            null
        }
    }

    private suspend fun unzip(
        zipFile: File,
        destinationDir: File,
        updateProgress: suspend (Double?) -> Unit
    ): File? {
        return try {
            var extractedFile: File? = null
            withContext(Dispatchers.IO) {
                ZipFile(zipFile)
            }.use { zip ->
                val entries = zip.entries().asSequence().toList()
                val totalSize = entries.filter { !it.isDirectory }.sumOf { it.size }.toDouble()
                var extractedSize = 0.0

                for (entry in entries) {
                    val outFile = File(destinationDir, entry.name)
                    // Guard against zip slip
                    if (!outFile.canonicalPath.startsWith(destinationDir.canonicalPath)) {
                        throw SecurityException($$"Zip entry outside target directory: ${entry.name}")
                    }

                    if (entry.isDirectory) {
                        outFile.mkdirs()
                    } else {
                        if (extractedFile == null) {
                            extractedFile = outFile
                        }
                        outFile.parentFile?.mkdirs()
                        zip.getInputStream(entry).use { input ->
                            FileOutputStream(outFile).use { output ->
                                val buffer = ByteArray(8192)
                                var len: Int
                                while (input.read(buffer).also { len = it } != -1) {
                                    output.write(buffer, 0, len)
                                    extractedSize += len
                                    if (totalSize > 0) {
                                        updateProgress(extractedSize / totalSize)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // Clean up the zip file
            zipFile.delete()
            extractedFile
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unzip", e)
            null
        }
    }
}
