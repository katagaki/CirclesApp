package com.tsubuzaki.circlesgo.ui.shared

import androidx.compose.runtime.staticCompositionLocalOf
import com.tsubuzaki.circlesgo.auth.Authenticator
import com.tsubuzaki.circlesgo.data.local.WebCutImageCache

val LocalAuthenticator = staticCompositionLocalOf<Authenticator> {
    error("No Authenticator provided")
}

val LocalWebCutImageCache = staticCompositionLocalOf<WebCutImageCache> {
    error("No WebCutImageCache provided")
}
