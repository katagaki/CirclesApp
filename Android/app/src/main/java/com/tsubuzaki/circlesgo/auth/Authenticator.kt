package com.tsubuzaki.circlesgo.auth

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.Uri
import android.util.Log
import com.tsubuzaki.circlesgo.api.Endpoints
import com.tsubuzaki.circlesgo.api.OnlineState
import com.tsubuzaki.circlesgo.api.auth.OpenIDClient
import com.tsubuzaki.circlesgo.api.auth.OpenIDToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

class Authenticator(
    private val context: Context,
    private val client: OpenIDClient
) {

    companion object {
        private const val TAG = "Authenticator"
        private val json = Json { ignoreUnknownKeys = true }

        fun loadClient(context: Context): OpenIDClient {
            val inputStream = context.assets.open("OpenID.json")
            val jsonString = inputStream.bufferedReader().readText()
            return json.decodeFromString(OpenIDClient.serializer(), jsonString)
        }
    }

    private val tokenStore = TokenStore(context)

    private val _isAuthenticating = MutableStateFlow(false)
    val isAuthenticating: StateFlow<Boolean> = _isAuthenticating

    private val _isWaitingForAuthenticationCode = MutableStateFlow(false)
    val isWaitingForAuthenticationCode: StateFlow<Boolean> = _isWaitingForAuthenticationCode

    private val _isReady = MutableStateFlow(false)
    val isReady: StateFlow<Boolean> = _isReady

    private val _onlineState = MutableStateFlow(OnlineState.UNDETERMINED)
    val onlineState: StateFlow<OnlineState> = _onlineState

    private val _token = MutableStateFlow<OpenIDToken?>(null)
    val token: StateFlow<OpenIDToken?> = _token

    private val _tokenExpiryDate = MutableStateFlow(Long.MAX_VALUE)
    val tokenExpiryDate: StateFlow<Long> = _tokenExpiryDate

    private var code: String? = null

    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    val authURL: String
        get() {
            val baseURL = "${Endpoints.circleMsAuthEndpoint}/OAuth2"
            val params = mapOf(
                "response_type" to "code",
                "client_id" to client.id,
                "redirect_uri" to client.redirectURL,
                "state" to "auth",
                "scope" to "circle_read circle_write favorite_read favorite_write user_info"
            )
            val queryString = params.entries.joinToString("&") { (key, value) ->
                "$key=${URLEncoder.encode(value, "UTF-8")}"
            }
            return "$baseURL?$queryString"
        }

    // MARK: Reachability

    fun setupReachability() {
        val connectivityManager =
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                handleReachable()
            }

            override fun onLost(network: Network) {
                handleUnreachable()
            }
        }
        networkCallback = callback

        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()
        connectivityManager.registerNetworkCallback(request, callback)

        // Check current state
        val activeNetwork = connectivityManager.activeNetwork
        val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork)
        if (capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true) {
            handleReachable()
        } else {
            handleUnreachable()
        }
    }

    fun teardownReachability() {
        networkCallback?.let {
            val connectivityManager =
                context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            connectivityManager.unregisterNetworkCallback(it)
            networkCallback = null
        }
    }

    private fun handleReachable() {
        _onlineState.value = OnlineState.ONLINE
        if (!_isReady.value) {
            if (!restoreAuthenticationFromStore()) {
                resetAuthentication()
                _isReady.value = true
            } else {
                _isReady.value = true
            }
        }
    }

    private fun handleUnreachable() {
        _onlineState.value = OnlineState.OFFLINE
        useOfflineAuthenticationToken()
        if (!_isReady.value) {
            _isReady.value = true
        }
    }

    // MARK: Authentication

    private fun restoreAuthenticationFromStore(): Boolean {
        val expiryDate = tokenStore.getTokenExpiryDate()
        if (expiryDate > System.currentTimeMillis()) {
            val savedToken = tokenStore.getToken()
            if (savedToken != null) {
                _token.value = savedToken
                _tokenExpiryDate.value = expiryDate
                return true
            }
        }
        return false
    }

    fun resetAuthentication() {
        code = null
        _token.value = null
        tokenStore.clearAll()
        _isAuthenticating.value = true
    }

    fun getAuthenticationCode(uri: Uri): Boolean {
        val codeParam = uri.getQueryParameter("code")
        val stateParam = uri.getQueryParameter("state")

        if (codeParam != null && stateParam == "auth") {
            this.code = codeParam
            _isWaitingForAuthenticationCode.value = false
            return true
        }
        return false
    }

    suspend fun getAuthenticationToken() {
        val params = mutableMapOf(
            "grant_type" to "authorization_code",
            "code" to (code ?: ""),
            "client_id" to client.id,
            "client_secret" to client.secret
        )

        val result = performTokenRequest(params)
        if (result) {
            _isAuthenticating.value = false
        } else {
            _token.value = null
            _isAuthenticating.value = true
        }
    }

    private fun useOfflineAuthenticationToken() {
        _token.value = OpenIDToken()
    }

    suspend fun refreshAuthenticationToken() {
        val refreshToken = _token.value?.refreshToken
        if (refreshToken != null) {
            val params = mutableMapOf(
                "grant_type" to "refresh_token",
                "refresh_token" to refreshToken,
                "client_id" to client.id,
                "client_secret" to client.secret
            )

            val result = performTokenRequest(params)
            if (!result) {
                _isAuthenticating.value = true
            }
        } else {
            _isAuthenticating.value = true
        }
    }

    private suspend fun performTokenRequest(parameters: Map<String, String>): Boolean =
        withContext(Dispatchers.IO) {
            try {
                val url = URL("${Endpoints.circleMsAuthEndpoint}/OAuth2/Token")
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")
                connection.connectTimeout = 2000
                connection.doOutput = true

                val body = parameters.entries.joinToString("&") { (key, value) ->
                    "$key=${URLEncoder.encode(value, "UTF-8")}"
                }
                connection.outputStream.use { it.write(body.toByteArray()) }

                val responseCode = connection.responseCode
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    val responseBody =
                        BufferedReader(InputStreamReader(connection.inputStream)).readText()
                    decodeAuthenticationToken(responseBody)
                } else {
                    Log.e(TAG, "Token request failed: HTTP $responseCode")
                    false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Token request failed", e)
                false
            }
        }

    private fun decodeAuthenticationToken(responseBody: String): Boolean {
        return try {
            val token = json.decodeFromString(OpenIDToken.serializer(), responseBody)
            _token.value = token
            updateTokenExpiryDate(token)
            tokenStore.saveToken(token)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to decode token", e)
            code = null
            _token.value = null
            _isAuthenticating.value = true
            false
        }
    }

    private fun updateTokenExpiryDate(token: OpenIDToken) {
        val expiresIn = maxOf(0, (token.expiresIn.toIntOrNull() ?: 0) - 3600)
        val expiryMillis = System.currentTimeMillis() + (expiresIn * 1000L)
        tokenStore.saveTokenExpiryDate(expiryMillis)
        _tokenExpiryDate.value = expiryMillis
    }
}
