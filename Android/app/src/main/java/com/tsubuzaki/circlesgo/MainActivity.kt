package com.tsubuzaki.circlesgo

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.lifecycleScope
import com.tsubuzaki.circlesgo.api.catalog.FavoritesAPI
import com.tsubuzaki.circlesgo.auth.Authenticator
import com.tsubuzaki.circlesgo.data.local.FavoritesCache
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.state.CatalogCache
import com.tsubuzaki.circlesgo.state.DataManager
import com.tsubuzaki.circlesgo.state.Events
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.Mapper
import com.tsubuzaki.circlesgo.state.Oasis
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.state.UserSelections
import com.tsubuzaki.circlesgo.ui.login.LoginView
import com.tsubuzaki.circlesgo.ui.theme.CirclesGoTheme
import com.tsubuzaki.circlesgo.ui.unified.UnifiedView
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {

    private var authenticator: Authenticator? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val client = Authenticator.loadClient(this)
        val auth = Authenticator(this, client)
        authenticator = auth
        auth.setupReachability()

        val database = CatalogDatabase(this)
        val mapper = Mapper()
        val selections = UserSelections(this)
        val events = Events(this)
        val favorites = FavoritesState()
        val unifier = Unifier()
        val catalogCache = CatalogCache()
        val oasis = Oasis()

        val favoritesCache = FavoritesCache(this)
        val favoritesAPI = FavoritesAPI(favoritesCache)

        val dataManager = DataManager(
            context = this,
            authenticator = auth,
            database = database,
            events = events,
            selections = selections,
            favorites = favorites,
            unifier = unifier,
            oasis = oasis,
            favoritesAPI = favoritesAPI
        )

        handleDeepLink(intent)

        enableEdgeToEdge()

        setContent {
            CirclesGoTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                ) {
                    val isAuthenticating by auth.isAuthenticating.collectAsState()
                    val isReady by auth.isReady.collectAsState()
                    val token by auth.token.collectAsState()

                    if (isAuthenticating || token == null) {
                        LoginView(
                            authURL = auth.authURL
                        )
                    } else {
                        // Trigger data reload when authenticator becomes ready
                        // or when transitioning from authenticating to authenticated
                        var hasTriggeredInitialLoad by rememberSaveable {
                            mutableStateOf(false)
                        }

                        LaunchedEffect(isReady, isAuthenticating, token) {
                            if (isReady && !isAuthenticating && token != null && !hasTriggeredInitialLoad) {
                                hasTriggeredInitialLoad = true
                                dataManager.reloadData(shouldResetSelections = true)
                            }
                        }

                        // Watch for active event changes
                        val activeEvent by events.activeEvent.collectAsState()
                        var previousActiveEventNumber by rememberSaveable {
                            mutableStateOf<Int?>(
                                null
                            )
                        }

                        LaunchedEffect(activeEvent) {
                            val currentNumber = activeEvent?.number
                            if (currentNumber != null) {
                                if (previousActiveEventNumber != null && previousActiveEventNumber != currentNumber) {
                                    dataManager.reloadData(shouldResetSelections = true)
                                }
                                previousActiveEventNumber = currentNumber
                            }
                        }

                        UnifiedView(
                            unifier = unifier,
                            mapper = mapper,
                            database = database,
                            selections = selections,
                            events = events,
                            favorites = favorites,
                            catalogCache = catalogCache,
                            oasis = oasis,
                            favoritesAPI = favoritesAPI,
                            authenticator = auth,
                            onLogout = {
                                hasTriggeredInitialLoad = false
                                database.delete()
                                selections.resetSelections()
                                unifier.close()
                                auth.resetAuthentication()
                            }
                        )
                    }
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: Intent) {
        intent.data?.let { uri ->
            if (uri.scheme == "circles-app") {
                val gotCode = authenticator?.getAuthenticationCode(uri) ?: false
                if (gotCode) {
                    lifecycleScope.launch {
                        authenticator?.getAuthenticationToken()
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        authenticator?.teardownReachability()
    }
}
