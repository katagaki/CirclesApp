package com.tsubuzaki.circlesgo.ui.shared

import androidx.compose.runtime.staticCompositionLocalOf
import com.tsubuzaki.circlesgo.auth.Authenticator
import com.tsubuzaki.circlesgo.data.local.WebCutImageCache
import com.tsubuzaki.circlesgo.state.Events
import com.tsubuzaki.circlesgo.state.VisitsState

val LocalAuthenticator = staticCompositionLocalOf<Authenticator> {
    error("No Authenticator provided")
}

val LocalWebCutImageCache = staticCompositionLocalOf<WebCutImageCache> {
    error("No WebCutImageCache provided")
}

val LocalDemoMode = staticCompositionLocalOf { false }

val LocalVisitsState = staticCompositionLocalOf<VisitsState?> { null }

val LocalEvents = staticCompositionLocalOf<Events?> { null }
