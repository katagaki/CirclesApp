package com.tsubuzaki.circlesgo.ui.shared

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.api.OnlineState
import com.tsubuzaki.circlesgo.api.catalog.UserFavorites
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogAPI
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogColor
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.GridDisplayMode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Composable
fun CircleCutImage(
    circle: ComiketCircle,
    database: CatalogDatabase,
    favorites: FavoritesState,
    displayMode: GridDisplayMode = GridDisplayMode.MEDIUM,
    showSpaceName: Boolean = false,
    showDay: Boolean = false,
    isPrivacyMode: Boolean = false,
    showWebCuts: Boolean = false
) {
    val authenticator = LocalAuthenticator.current
    val webCutImageCache = LocalWebCutImageCache.current
    val onlineState by authenticator.onlineState.collectAsState()
    val authToken by authenticator.token.collectAsState()

    // Load catalog image from database (always needed as fallback)
    // State must be keyed on circle.id so a reused composable slot
    // doesn't keep showing the previous circle's cut
    var catalogImageBitmap by remember(circle.id) {
        mutableStateOf(database.cachedCircleImage(circle.id)?.asImageBitmap())
    }
    LaunchedEffect(circle.id) {
        if (catalogImageBitmap == null) {
            catalogImageBitmap = withContext(Dispatchers.IO) {
                database.circleImage(circle.id)?.asImageBitmap()
            }
        }
    }

    // Load web cut image from API cache / network
    var webCutImageBitmap by remember(circle.id) {
        mutableStateOf(webCutImageCache.getCached(circle.id)?.asImageBitmap())
    }
    LaunchedEffect(circle.id, showWebCuts) {
        if (!showWebCuts) return@LaunchedEffect
        if (webCutImageBitmap != null) return@LaunchedEffect

        // Try disk cache first
        val cached = withContext(Dispatchers.IO) {
            webCutImageCache.getCached(circle.id)?.asImageBitmap()
        }
        if (cached != null) {
            webCutImageBitmap = cached
            return@LaunchedEffect
        }

        // Already fetched but no image available
        if (webCutImageCache.isFetched(circle.id)) return@LaunchedEffect

        // Fetch from API if online
        if (onlineState != OnlineState.ONLINE) return@LaunchedEffect
        val token = authToken ?: return@LaunchedEffect
        val webCatalogID = circle.extendedInformation?.webCatalogID ?: return@LaunchedEffect

        val circleResponse = WebCatalogAPI.circle(webCatalogID, token)
        val cutWebURL = circleResponse?.response?.circle?.cutWebURL
        if (cutWebURL != null && cutWebURL.isNotEmpty()) {
            val bitmap = webCutImageCache.download(circle.id, cutWebURL)
            if (bitmap != null) {
                webCutImageBitmap = bitmap.asImageBitmap()
            }
        }
    }

    val imageBitmap = if (showWebCuts) webCutImageBitmap ?: catalogImageBitmap else catalogImageBitmap

    val wcIDMappedItems by favorites.wcIDMappedItems.collectAsState()

    Box(
        modifier = Modifier.aspectRatio(180f / 256f),
        contentAlignment = Alignment.Center
    ) {
        val currentBitmap = imageBitmap
        if (currentBitmap != null) {
            Image(
                bitmap = currentBitmap,
                contentDescription = circle.circleName,
                contentScale = ContentScale.Fit,
                modifier = Modifier
                    .fillMaxSize()
                    .then(
                        if (isPrivacyMode) Modifier.blur(16.dp) else Modifier
                    )
            )
        } else {
            // No image available placeholder
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f)),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
            }
        }

        // Favorite color indicator overlay
        if (currentBitmap != null) {
            val favoriteItem: UserFavorites.Response.FavoriteItem? = remember(
                circle.extendedInformation?.webCatalogID, wcIDMappedItems
            ) {
                circle.extendedInformation?.webCatalogID?.let { wcID ->
                    wcIDMappedItems?.get(wcID)
                }
            }

            if (favoriteItem != null) {
                val favoriteColor = WebCatalogColor.fromValue(favoriteItem.favorite.color)
                if (favoriteColor != null) {
                    Canvas(
                        modifier = Modifier
                            .fillMaxSize()
                            .aspectRatio(180f / 256f)
                    ) {
                        val squareSize = 0.23f * size.width
                        val squareOffset = 0.03f * size.width
                        drawRect(
                            color = favoriteColor.backgroundColor(),
                            topLeft = Offset(squareOffset, squareOffset),
                            size = Size(squareSize, squareSize)
                        )
                    }
                }
            }
        }

        // Space name and day pills overlay
        if (showSpaceName || showDay) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(2.dp),
                contentAlignment = Alignment.BottomEnd
            ) {
                androidx.compose.foundation.layout.Column(
                    horizontalAlignment = Alignment.End,
                    verticalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(2.dp)
                ) {
                    if (showDay) {
                        CircleBlockPill(
                            text = stringResource(R.string.day_format, circle.day),
                            size = if (displayMode == GridDisplayMode.SMALL) CircleBlockPillSize.TINY else CircleBlockPillSize.SMALL
                        )
                    }
                    if (showSpaceName) {
                        circle.spaceName()?.let { spaceName ->
                            CircleBlockPill(
                                text = spaceName,
                                size = if (displayMode == GridDisplayMode.SMALL) CircleBlockPillSize.TINY else CircleBlockPillSize.SMALL
                            )
                        }
                    }
                }
            }
        }
    }
}
