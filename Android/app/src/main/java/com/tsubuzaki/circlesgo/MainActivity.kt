package com.tsubuzaki.circlesgo

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.lifecycleScope
import androidx.compose.runtime.CompositionLocalProvider
import com.tsubuzaki.circlesgo.api.catalog.FavoritesAPI
import com.tsubuzaki.circlesgo.auth.Authenticator
import com.tsubuzaki.circlesgo.data.local.AttachmentsCache
import com.tsubuzaki.circlesgo.data.local.BuysCache
import com.tsubuzaki.circlesgo.data.local.FavoritesCache
import com.tsubuzaki.circlesgo.data.local.VisitEntryCache
import com.tsubuzaki.circlesgo.data.local.WebCutImageCache
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.ui.shared.LocalAuthenticator
import com.tsubuzaki.circlesgo.ui.shared.LocalDemoMode
import com.tsubuzaki.circlesgo.ui.shared.LocalEvents
import com.tsubuzaki.circlesgo.ui.shared.LocalSharedBuys
import com.tsubuzaki.circlesgo.ui.shared.LocalVisitsState
import com.tsubuzaki.circlesgo.ui.shared.LocalWebCutImageCache
import com.tsubuzaki.circlesgo.state.CatalogCache
import com.tsubuzaki.circlesgo.state.DataManager
import com.tsubuzaki.circlesgo.state.DemoState
import com.tsubuzaki.circlesgo.state.Events
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.Mapper
import com.tsubuzaki.circlesgo.state.Oasis
import com.tsubuzaki.circlesgo.state.UnifiedPath
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.state.UserSelections
import com.tsubuzaki.circlesgo.state.VisitsState
import com.tsubuzaki.circlesgo.ui.login.LoginView
import com.tsubuzaki.circlesgo.ui.theme.CirclesGoTheme
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuysHost
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuysSession
import com.tsubuzaki.circlesgo.ui.guest.GuestView
import com.tsubuzaki.circlesgo.ui.sharedbuys.SharedBuysDebugScreen
import com.tsubuzaki.circlesgo.ui.unified.UnifiedView
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {

    private var authenticator: Authenticator? = null
    private var sharedBuys: SharedBuysSession? = null
    private var unifierState: Unifier? = null

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
        unifierState = unifier
        val catalogCache = CatalogCache()
        val oasis = Oasis()
        val demoState = DemoState(this)

        val favoritesCache = FavoritesCache(this)
        val favoritesAPI = FavoritesAPI(favoritesCache)
        val webCutImageCache = WebCutImageCache(this)
        val buysCache = BuysCache(this)
        val visitsState = VisitsState(VisitEntryCache(this))
        val attachmentsCache = AttachmentsCache(this)

        val dataManager = DataManager(
            context = this,
            authenticator = auth,
            database = database,
            events = events,
            selections = selections,
            favorites = favorites,
            unifier = unifier,
            oasis = oasis,
            favoritesAPI = favoritesAPI,
            catalogCache = catalogCache,
            demoState = demoState
        )

        sharedBuys = SharedBuysHost.session(this)

        handleDeepLink(intent)

        enableEdgeToEdge()

        setContent {
            CirclesGoTheme {
                val isDemoActive by demoState.isActive.collectAsState()
                CompositionLocalProvider(
                    LocalAuthenticator provides auth,
                    LocalWebCutImageCache provides webCutImageCache,
                    LocalDemoMode provides isDemoActive,
                    LocalVisitsState provides visitsState,
                    LocalEvents provides events,
                    LocalSharedBuys provides sharedBuys
                ) {
                    val buys = sharedBuys
                    if (buys != null && buys.isDebugVisible) {
                        SharedBuysDebugScreen(buys) { buys.isDebugVisible = false }
                        return@CompositionLocalProvider
                    }
                    Surface(
                        modifier = Modifier.fillMaxSize(),
                    ) {
                        val isAuthenticating by auth.isAuthenticating.collectAsState()
                        val isReady by auth.isReady.collectAsState()
                        val token by auth.token.collectAsState()

                        // Guest Mode is a different app, not a mode of this one: no
                        // catalog, so no map, no browsing and no favourites. Checked
                        // before the login branch so a guest is never shown a sign-in
                        // screen they have no account for.
                        if (buys != null && buys.isGuest) {
                            GuestView(session = buys)
                        } else if (isDemoActive) {
                            var hasTriggeredDemoLoad by rememberSaveable {
                                mutableStateOf(false)
                            }
                            var previousDemoEventNumber by rememberSaveable {
                                mutableStateOf<Int?>(null)
                            }

                            LaunchedEffect(Unit) {
                                if (!hasTriggeredDemoLoad) {
                                    hasTriggeredDemoLoad = true
                                    val target = demoState.selectedDataset
                                    previousDemoEventNumber = target
                                    dataManager.reloadDemoData(target)
                                }
                            }

                            val demoActiveEvent by events.activeEvent.collectAsState()
                            LaunchedEffect(demoActiveEvent) {
                                val currentNumber = demoActiveEvent?.number
                                if (currentNumber != null && hasTriggeredDemoLoad) {
                                    if (previousDemoEventNumber != null &&
                                        previousDemoEventNumber != currentNumber
                                    ) {
                                        previousDemoEventNumber = currentNumber
                                        dataManager.reloadDemoData(currentNumber)
                                    } else {
                                        previousDemoEventNumber = currentNumber
                                    }
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
                                buysCache = buysCache,
                                visitsState = visitsState,
                                attachmentsCache = attachmentsCache,
                                onLogout = {
                                    hasTriggeredDemoLoad = false
                                    previousDemoEventNumber = null
                                    // Drop everything the demo session created:
                                    // its databases, event list, and selections
                                    demoState.reset()
                                    database.delete()
                                    database.useStoreDirectory(CatalogDatabase.DEFAULT_STORE)
                                    buysCache.clearAll()
                                    visitsState.clearAll()
                                    attachmentsCache.clearAll()
                                    favorites.reset()
                                    selections.resetSelections()
                                    events.reset()
                                    catalogCache.invalidate()
                                    unifier.clearSheetContent()
                                    unifier.close()
                                }
                            )
                        } else if (isAuthenticating || token == null) {
                            LoginView(
                                authURL = auth.authURL,
                                onGuestTapped = { buys?.enterGuestMode() }
                            )
                        } else {
                            var hasTriggeredInitialLoad by rememberSaveable {
                                mutableStateOf(false)
                            }

                            LaunchedEffect(isReady, isAuthenticating, token) {
                                if (isReady && !isAuthenticating && token != null && !hasTriggeredInitialLoad) {
                                    hasTriggeredInitialLoad = true
                                    dataManager.reloadData(shouldResetSelections = false)
                                }
                            }

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
                                buysCache = buysCache,
                                visitsState = visitsState,
                                attachmentsCache = attachmentsCache,
                                onLogout = {
                                    hasTriggeredInitialLoad = false
                                    // Wipe all local data, caches, and preferences
                                    database.delete()
                                    webCutImageCache.clear()
                                    favoritesCache.clear()
                                    buysCache.clearAll()
                                    visitsState.clearAll()
                                    attachmentsCache.clearAll()
                                    favorites.reset()
                                    selections.wipeAll()
                                    events.reset()
                                    unifier.close()
                                    auth.resetAuthentication()
                                }
                            )
                        }
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
            val session = sharedBuys
            if (uri.scheme == "circles-app" && session != null) {
                when (uri.host) {
                    "buys-selftest" -> {
                        session.runSelfTest()
                        session.isDebugVisible = true
                        return
                    }
                    "buys-debug" -> {
                        session.isDebugVisible = true
                        return
                    }
                    SharedBuysSession.JOIN_HOST -> {
                        requestBluetoothPermissions(session)
                        session.adoptIdentity()
                        session.join(uri, session.nickname)
                        unifierState?.setCurrentPath(UnifiedPath.BUYS)
                        unifierState?.show()
                        return
                    }
                    "buys-add" -> {
                        session.addItem(
                            uri.getQueryParameter("name").orEmpty(),
                            uri.getQueryParameter("cost")?.toIntOrNull() ?: 0,
                            1
                        )
                        return
                    }
                    "buys-cycle" -> {
                        val itemId = uri.getQueryParameter("item")
                        session.items.firstOrNull { it.id == itemId }?.let { session.cycle(it) }
                        return
                    }
                }
            }
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

    private fun requestBluetoothPermissions(session: SharedBuysSession) {
        val missing = session.missingBluetoothPermissions()
        if (missing.isNotEmpty()) {
            androidx.core.app.ActivityCompat.requestPermissions(
                this,
                missing.toTypedArray(),
                BLUETOOTH_PERMISSION_REQUEST
            )
        }
    }

    override fun onResume() {
        super.onResume()
        sharedBuys?.resume()
        requestNotificationPermission()
    }

    /**
     * Asked for while a session is running, which is the only time the Live Update has
     * anything to show. Without it the foreground service still runs and still syncs —
     * the ongoing notification is simply not drawn.
     */
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        if (sharedBuys?.isActive != true) return
        val permission = android.Manifest.permission.POST_NOTIFICATIONS
        if (checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) return
        requestPermissions(arrayOf(permission), NOTIFICATION_PERMISSION_REQUEST)
    }

    override fun onPause() {
        super.onPause()
        // The radio and the socket are worth releasing while the app is away; the log
        // itself is already persisted, so onResume brings the room back.
        // A running session keeps its socket: the foreground service behind the Live
        // Update is what the relay's push wakes, and it has nothing to wake into if the
        // transports were torn down on the way out.
        val buys = sharedBuys
        if (isFinishing && buys?.isActive != true) buys?.pause()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray,
        deviceId: Int
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults, deviceId)
        // Without this the user granted the Bluetooth permissions and nothing happened:
        // startBluetooth() had already bailed and was never called again.
        if (requestCode == BLUETOOTH_PERMISSION_REQUEST) sharedBuys?.startBluetooth()
    }

    override fun onDestroy() {
        super.onDestroy()
        authenticator?.teardownReachability()
        // The session outlives the activity now, so only an idle one is released here;
        // there is one per process, so a rotation no longer leaks a Ktor client either.
        val buys = sharedBuys
        if (buys?.isActive != true) buys?.close()
    }

    companion object {
        private const val BLUETOOTH_PERMISSION_REQUEST = 4001
        private const val NOTIFICATION_PERMISSION_REQUEST = 4002
    }
}
