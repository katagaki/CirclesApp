package com.tsubuzaki.circlesgo.api.catalog

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class WebCatalogDatabase(
    val status: String,
    val response: Response
) {
    @Serializable
    data class Response(
        @SerialName("url") val urls: Map<String, String>,
        @SerialName("md5") val hashes: Map<String, String>,
        @SerialName("updatedate") val updateDate: String
    ) {
        fun databaseForText(
            mode: SQLiteMode = SQLiteMode.SQLITE3,
            compression: CompressionMode = CompressionMode.ZIP
        ): String? {
            return urls["textdb_${mode.value}${compression.value}_ssl"]
        }

        fun databaseFor211By300Images(
            compression: CompressionMode = CompressionMode.ZIP
        ): String? {
            return urls["imagedb1${compression.value}_ssl"]
        }

        fun databaseFor180By256Images(
            compression: CompressionMode = CompressionMode.ZIP
        ): String? {
            return urls["imagedb2${compression.value}_ssl"]
        }

        enum class SQLiteMode(val value: String) {
            SQLITE2("sqlite2"),
            SQLITE3("sqlite3")
        }

        enum class CompressionMode(val value: String) {
            ZIP("_zip_url"),
            GZIP("_url")
        }
    }
}
