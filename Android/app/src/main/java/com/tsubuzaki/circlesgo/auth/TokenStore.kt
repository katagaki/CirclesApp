package com.tsubuzaki.circlesgo.auth

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.core.content.edit
import com.tsubuzaki.circlesgo.api.auth.OpenIDToken
import kotlinx.serialization.json.Json
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class TokenStore(context: Context) {

    companion object {
        private const val PREFS_NAME = "com.tsubuzaki.circlesgo.auth.v2"
        private const val KEY_AUTH_TOKEN = "CircleMsAuthToken"
        private const val KEY_AUTH_TOKEN_IV = "CircleMsAuthToken_IV"
        private const val KEY_TOKEN_EXPIRY = "Auth.TokenExpiryDate"
        private const val KEYSTORE_ALIAS = "CirclesGoTokenKey"
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val GCM_TAG_LENGTH = 128
    }

    private val json = Json { ignoreUnknownKeys = true }

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private fun getOrCreateSecretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE)
        keyStore.load(null)

        keyStore.getEntry(KEYSTORE_ALIAS, null)?.let { entry ->
            return (entry as KeyStore.SecretKeyEntry).secretKey
        }

        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            ANDROID_KEYSTORE
        )
        val spec = KeyGenParameterSpec.Builder(
            KEYSTORE_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .build()
        keyGenerator.init(spec)
        return keyGenerator.generateKey()
    }

    private fun encrypt(plaintext: String): Pair<String, String> {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateSecretKey())
        val ciphertext = cipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))
        val iv = cipher.iv
        return Pair(
            Base64.encodeToString(ciphertext, Base64.NO_WRAP),
            Base64.encodeToString(iv, Base64.NO_WRAP)
        )
    }

    private fun decrypt(ciphertextBase64: String, ivBase64: String): String {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val iv = Base64.decode(ivBase64, Base64.NO_WRAP)
        val spec = GCMParameterSpec(GCM_TAG_LENGTH, iv)
        cipher.init(Cipher.DECRYPT_MODE, getOrCreateSecretKey(), spec)
        val plaintext = cipher.doFinal(Base64.decode(ciphertextBase64, Base64.NO_WRAP))
        return String(plaintext, Charsets.UTF_8)
    }

    fun saveToken(token: OpenIDToken) {
        val tokenJson = json.encodeToString(OpenIDToken.serializer(), token)
        val (ciphertext, iv) = encrypt(tokenJson)
        prefs.edit {
            putString(KEY_AUTH_TOKEN, ciphertext)
            putString(KEY_AUTH_TOKEN_IV, iv)
        }
    }

    fun getToken(): OpenIDToken? {
        val ciphertext = prefs.getString(KEY_AUTH_TOKEN, null) ?: return null
        val iv = prefs.getString(KEY_AUTH_TOKEN_IV, null) ?: return null
        return try {
            val tokenJson = decrypt(ciphertext, iv)
            json.decodeFromString(OpenIDToken.serializer(), tokenJson)
        } catch (e: Exception) {
            null
        }
    }

    fun clearToken() {
        prefs.edit {
            remove(KEY_AUTH_TOKEN)
            remove(KEY_AUTH_TOKEN_IV)
        }
    }

    fun saveTokenExpiryDate(expiryMillis: Long) {
        prefs.edit { putLong(KEY_TOKEN_EXPIRY, expiryMillis) }
    }

    fun getTokenExpiryDate(): Long {
        return prefs.getLong(KEY_TOKEN_EXPIRY, Long.MAX_VALUE)
    }

    fun clearTokenExpiryDate() {
        prefs.edit { remove(KEY_TOKEN_EXPIRY) }
    }

    fun clearAll() {
        clearToken()
        clearTokenExpiryDate()
    }
}
