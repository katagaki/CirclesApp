package com.tsubuzaki.circlesgo.ui.circledetail

import androidx.browser.customtabs.CustomTabColorSchemeParams
import androidx.browser.customtabs.CustomTabsIntent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Link
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material.icons.outlined.PinDrop
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ElevatedButton
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.core.net.toUri
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.api.catalog.FavoritesAPI
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogColor
import com.tsubuzaki.circlesgo.auth.Authenticator
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogAPI
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogCircle
import com.tsubuzaki.circlesgo.api.OnlineState
import com.tsubuzaki.circlesgo.data.local.AttachmentsCache
import com.tsubuzaki.circlesgo.data.local.BuysCache
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.DataFetcher
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.state.Events
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.Mapper
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.state.UserSelections
import com.tsubuzaki.circlesgo.state.VisitsState
import com.tsubuzaki.circlesgo.ui.shared.CircleBlockPill
import com.tsubuzaki.circlesgo.ui.shared.CircleBlockPillSize
import com.tsubuzaki.circlesgo.ui.shared.CircleCutImage
import com.tsubuzaki.circlesgo.ui.shared.DemoUnavailableDialog
import com.tsubuzaki.circlesgo.ui.shared.LocalDemoMode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@Composable
fun CircleDetailView(
    initialCircle: ComiketCircle,
    database: CatalogDatabase,
    favorites: FavoritesState,
    unifier: Unifier,
    favoritesAPI: FavoritesAPI,
    authenticator: Authenticator,
    selections: UserSelections,
    visitsState: VisitsState? = null,
    buysCache: BuysCache? = null,
    events: Events? = null,
    mapper: Mapper? = null,
    attachmentsCache: AttachmentsCache? = null,
    /** Ordered circle IDs constraining previous/next navigation (e.g. within
     *  a favorite color group); null falls back to circle.id ± 1. */
    navigationCircleIDs: List<Int>? = null,
    /** Height of the visible part of the sheet, so the bottom toolbar stays
     *  on screen while the sheet is only partially expanded. */
    visibleHeight: Dp? = null
) {
    val context = LocalContext.current
    val primaryColor = MaterialTheme.colorScheme.primary.toArgb()
    val scope = rememberCoroutineScope()
    val isDemo = LocalDemoMode.current
    var showDemoUnavailable by remember { mutableStateOf(false) }
    var genre by remember { mutableStateOf<String?>(null) }

    // Currently shown circle; changes with previous/next navigation
    var circle by remember(initialCircle) { mutableStateOf(initialCircle) }
    var boundaryAlertMessage by remember { mutableStateOf<Int?>(null) }

    // Favorite state
    val wcIDMappedItems by favorites.wcIDMappedItems.collectAsState()
    val authToken by authenticator.token.collectAsState()
    val webCatalogID = circle.extendedInformation?.webCatalogID

    val existingFavorite = webCatalogID?.let { wcIDMappedItems?.get(it) }
    val isFavorited = existingFavorite != null

    var isEditing by remember { mutableStateOf(false) }
    var selectedColor by remember {
        mutableStateOf(
            existingFavorite?.favorite?.webCatalogColor()
                ?.takeIf { it != WebCatalogColor.UNCOLORED }
                ?: WebCatalogColor.ORANGE
        )
    }
    var memo by remember { mutableStateOf(existingFavorite?.favorite?.memo ?: "") }
    var isSaving by remember { mutableStateOf(false) }

    // Update editing state when favorite data changes
    LaunchedEffect(existingFavorite) {
        selectedColor = existingFavorite?.favorite?.webCatalogColor()
            ?.takeIf { it != WebCatalogColor.UNCOLORED }
            ?: WebCatalogColor.ORANGE
        memo = existingFavorite?.favorite?.memo ?: ""
    }

    // Fetch genre name
    LaunchedEffect(circle.genreID) {
        scope.launch(Dispatchers.IO) {
            val fetcher = DataFetcher(database.getTextDatabase())
            genre = fetcher.genre(circle.genreID)
        }
    }

    // Fetch web catalog tags and online store links
    var tags by remember { mutableStateOf<String?>(null) }
    var onlineStores by remember {
        mutableStateOf<List<WebCatalogCircle.OnlineStore>>(emptyList())
    }
    LaunchedEffect(circle.id) {
        tags = null
        onlineStores = emptyList()
        val token = authToken ?: return@LaunchedEffect
        val wcID = circle.extendedInformation?.webCatalogID ?: return@LaunchedEffect
        if (isDemo) return@LaunchedEffect
        scope.launch(Dispatchers.IO) {
            val response = WebCatalogAPI.circle(wcID, token)
            tags = response?.response?.circle?.tag?.takeIf { it.isNotBlank() }
            onlineStores = response?.response?.circle?.onlineStores.orEmpty()
                .filter { it.link.isNotBlank() }
        }
    }

    val extInfo = circle.extendedInformation

    Column(
        modifier = if (visibleHeight != null) {
            Modifier
                .fillMaxWidth()
                .height(visibleHeight)
        } else {
            Modifier.fillMaxSize()
        }
    ) {
        // Top bar with back button and circle name
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = {
                unifier.popSheetPath()
                unifier.clearCircleDetail()
            }) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = stringResource(R.string.back)
                )
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = circle.circleName,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                if (circle.penName.trim().isNotEmpty()) {
                    Text(
                        text = circle.penName,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
            // Previous / next circle navigation; walks the navigation list
            // when one is set, otherwise circle.id ± 1
            fun navigate(step: Int, boundaryMessage: Int) {
                scope.launch(Dispatchers.IO) {
                    val targetID = if (navigationCircleIDs != null) {
                        val index = navigationCircleIDs.indexOf(circle.id)
                        navigationCircleIDs.getOrNull(index + step)
                            .takeIf { index != -1 }
                    } else {
                        circle.id + step
                    }
                    val target = targetID?.let {
                        database.circles(listOf(it)).firstOrNull()
                    }
                    if (target != null) {
                        circle = target
                    } else {
                        boundaryAlertMessage = boundaryMessage
                    }
                }
            }
            IconButton(onClick = {
                navigate(-1, R.string.first_circle_message)
            }) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                    contentDescription = stringResource(R.string.previous_circle)
                )
            }
            IconButton(onClick = {
                navigate(1, R.string.last_circle_message)
            }) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = stringResource(R.string.next_circle)
                )
            }
            // Show on map
            if (mapper != null) {
                IconButton(onClick = {
                    mapper.setHighlightTarget(circle)
                    unifier.requestSheetCollapse()
                }) {
                    Icon(
                        imageVector = Icons.Outlined.PinDrop,
                        contentDescription = stringResource(R.string.show_on_map),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }

        // Scrollable detail content
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
        ) {

        // Hero section: cut image + info
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.Start
        ) {
            // Cut image; tapping toggles between the catalog and web cut
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                val isPrivacyMode by selections.isPrivacyMode.collectAsState()
                val showWebCuts by selections.showWebCuts.collectAsState()
                val canToggleCut = !isDemo && authToken != null
                var showWebCutInHero by remember(circle.id) {
                    mutableStateOf(showWebCuts)
                }
                Box(
                    modifier = Modifier
                        .width(120.dp)
                        .height(172.dp)
                        .then(
                            if (canToggleCut) {
                                Modifier.clickable {
                                    showWebCutInHero = !showWebCutInHero
                                }
                            } else {
                                Modifier
                            }
                        )
                ) {
                    CircleCutImage(
                        circle = circle,
                        database = database,
                        favorites = favorites,
                        isPrivacyMode = isPrivacyMode,
                        showWebCuts = showWebCutInHero && canToggleCut
                    )
                    // Invisible tap target over the checkmark corner that
                    // toggles visited, like the iOS hero cut
                    if (visitsState != null && events != null) {
                        val haptics = LocalHapticFeedback.current
                        Box(
                            modifier = Modifier
                                .size(44.dp)
                                .align(Alignment.TopStart)
                                .clickable(
                                    interactionSource = remember {
                                        MutableInteractionSource()
                                    },
                                    indication = null,
                                    onClickLabel = stringResource(R.string.mark_visited)
                                ) {
                                    haptics.performHapticFeedback(
                                        HapticFeedbackType.LongPress
                                    )
                                    visitsState.toggleVisit(
                                        circle.id, events.activeEventNumber
                                    )
                                }
                        )
                    }
                }
                if (canToggleCut) {
                    Text(
                        text = stringResource(
                            if (showWebCutInHero) R.string.cut_web else R.string.cut_catalog
                        ),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Info stack
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Day and space pills
                Row(horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                    CircleBlockPill(
                        text = stringResource(R.string.day_format, circle.day),
                        size = CircleBlockPillSize.LARGE
                    )
                    circle.spaceName()?.let { spaceName ->
                        CircleBlockPill(
                            text = spaceName,
                            size = CircleBlockPillSize.LARGE
                        )
                    }
                }

                // Favorite memo
                existingFavorite?.favorite?.memo?.takeIf { it.isNotBlank() }?.let { favoriteMemo ->
                    Text(
                        text = favoriteMemo,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                // Description
                if (circle.supplementaryDescription.trim().isNotEmpty()) {
                    InfoSection(
                        title = stringResource(R.string.description_label),
                        content = circle.supplementaryDescription
                    )
                } else {
                    InfoSection(
                        title = stringResource(R.string.description_label),
                        content = stringResource(R.string.no_description)
                    )
                }
            }
        }

        HorizontalDivider(modifier = Modifier.padding(horizontal = 20.dp))

        // Book name section
        if (circle.bookName.trim().isNotEmpty()) {
            InfoSection(
                title = stringResource(R.string.book_name),
                content = circle.bookName,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 20.dp))
        }

        // Genre section
        genre?.let {
            InfoSection(
                title = stringResource(R.string.genre_label),
                content = it,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 20.dp))
        }

        // Tags section (from web catalog)
        tags?.let {
            InfoSection(
                title = stringResource(R.string.tags_label),
                content = it,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 20.dp))
        }

        // Memo section
        if (circle.memo.trim().isNotEmpty()) {
            InfoSection(
                title = stringResource(R.string.circle_memo),
                content = circle.memo,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 20.dp))
        }

        // Buys section
        if (buysCache != null && events != null) {
            CircleDetailBuysSection(
                circleID = circle.id,
                eventNumber = events.activeEventNumber,
                buysCache = buysCache,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 20.dp))
        }

        // Attachments section
        if (attachmentsCache != null && events != null) {
            CircleDetailAttachmentsSection(
                circleID = circle.id,
                eventNumber = events.activeEventNumber,
                attachmentsCache = attachmentsCache,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
            )
            HorizontalDivider(modifier = Modifier.padding(horizontal = 20.dp))
        }

        Spacer(modifier = Modifier.height(12.dp))

        // URL link
        circle.url?.let { url ->
            if (url.isNotEmpty()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp, vertical = 8.dp)
                        .clickable {
                            val colorSchemeParams = CustomTabColorSchemeParams.Builder()
                                .setToolbarColor(primaryColor)
                                .build()
                            val customTabsIntent = CustomTabsIntent.Builder()
                                .setDefaultColorSchemeParams(colorSchemeParams)
                                .build()
                            customTabsIntent.launchUrl(context, url.toUri())
                        },

                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Filled.Link,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = url,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(32.dp))
        } // end scrollable content

        // Persistent bottom toolbar: favorite action on the leading edge,
        // SNS links trailing, mirroring the iOS circle detail bottom bar
        HorizontalDivider()
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Favorites can only be edited for the latest event while online
            val onlineState by authenticator.onlineState.collectAsState()
            val isActiveEventLatest = events?.isActiveEventLatestFlow
                ?.collectAsState()?.value ?: true
            val canShowFavoriteAction = webCatalogID != null &&
                    isActiveEventLatest &&
                    (isDemo || onlineState == OnlineState.ONLINE)
            if (canShowFavoriteAction) {
                val favoriteTint = if (isFavorited) {
                    existingFavorite.favorite.webCatalogColor().backgroundColor()
                } else {
                    MaterialTheme.colorScheme.onSurfaceVariant
                }
                TextButton(onClick = {
                    if (isDemo) showDemoUnavailable = true else isEditing = !isEditing
                }) {
                    Icon(
                        imageVector = if (isFavorited) Icons.Filled.Star else Icons.Filled.StarBorder,
                        contentDescription = null,
                        tint = favoriteTint,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = stringResource(
                            if (isFavorited) R.string.edit_favorite else R.string.add_to_favorites
                        ),
                        style = MaterialTheme.typography.labelLarge,
                        color = favoriteTint
                    )
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            fun openURL(url: String) {
                val colorSchemeParams = CustomTabColorSchemeParams.Builder()
                    .setToolbarColor(primaryColor)
                    .build()
                CustomTabsIntent.Builder()
                    .setDefaultColorSchemeParams(colorSchemeParams)
                    .build()
                    .launchUrl(context, url.toUri())
            }

            // Online store links from the Web Catalog
            if (onlineStores.isNotEmpty()) {
                var linksExpanded by remember { mutableStateOf(false) }
                Box {
                    IconButton(onClick = { linksExpanded = true }) {
                        Icon(
                            imageVector = Icons.Filled.Link,
                            contentDescription = stringResource(R.string.links),
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                    DropdownMenu(
                        expanded = linksExpanded,
                        onDismissRequest = { linksExpanded = false }
                    ) {
                        onlineStores.forEach { store ->
                            DropdownMenuItem(
                                text = { Text(store.name.ifBlank { store.link }) },
                                onClick = {
                                    linksExpanded = false
                                    openURL(store.link)
                                }
                            )
                        }
                    }
                }
            }

            // SNS buttons
            if (extInfo != null && extInfo.hasAccessibleURLs()) {
                extInfo.circleMsPortalURL?.let { url ->
                    SNSIconButton(
                        label = stringResource(R.string.sns_circlems),
                        iconRes = R.drawable.ic_sns_circlems,
                        color = Color(0xFF4CAF50),
                        onClick = { openURL(url) }
                    )
                }
                extInfo.pixivURL?.let { url ->
                    SNSIconButton(
                        label = stringResource(R.string.sns_pixiv),
                        iconRes = R.drawable.ic_sns_pixiv,
                        color = Color(0xFF0096FA),
                        onClick = { openURL(url) }
                    )
                }
                extInfo.twitterURL?.let { url ->
                    SNSIconButton(
                        label = stringResource(R.string.sns_twitter),
                        iconRes = R.drawable.ic_sns_twitter,
                        color = Color(0xFF0D0D0D),
                        onClick = { openURL(url) }
                    )
                }
            }
        }
    }

    if (showDemoUnavailable) {
        DemoUnavailableDialog(onDismiss = { showDemoUnavailable = false })
    }

    // Favorite editor, shown as a popover dialog like the iOS favorite popover
    if (isEditing && webCatalogID != null) {
        FavoriteEditorDialog(
            isFavorited = isFavorited,
            selectedColor = selectedColor,
            onColorSelected = { selectedColor = it },
            memo = memo,
            onMemoChange = { memo = it },
            isSaving = isSaving,
            onSave = {
                val token = authToken
                if (token != null) {
                    isSaving = true
                    scope.launch(Dispatchers.IO) {
                        val success = favoritesAPI.add(webCatalogID, selectedColor, memo, token)
                        if (success) {
                            val (items, wcIDMapped) = favoritesAPI.all(token)
                            favorites.setItems(items)
                            favorites.setWcIDMappedItems(wcIDMapped)
                        }
                        isSaving = false
                        isEditing = false
                    }
                }
            },
            onRemove = {
                val token = authToken
                if (token != null) {
                    isSaving = true
                    scope.launch(Dispatchers.IO) {
                        val success = favoritesAPI.delete(webCatalogID, token)
                        if (success) {
                            val (items, wcIDMapped) = favoritesAPI.all(token)
                            favorites.setItems(items)
                            favorites.setWcIDMappedItems(wcIDMapped)
                        }
                        isSaving = false
                        isEditing = false
                    }
                }
            },
            onDismiss = { if (!isSaving) isEditing = false }
        )
    }

    boundaryAlertMessage?.let { messageRes ->
        AlertDialog(
            onDismissRequest = { boundaryAlertMessage = null },
            text = { Text(stringResource(messageRes)) },
            confirmButton = {
                TextButton(onClick = { boundaryAlertMessage = null }) {
                    Text(stringResource(R.string.ok))
                }
            }
        )
    }
}

@Composable
private fun InfoSection(
    title: String,
    content: String,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Text(
            text = title,
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(2.dp))
        Text(
            text = content,
            style = MaterialTheme.typography.bodyMedium
        )
    }
}

/**
 * Round-rect, icon-only SNS button for the circle detail bottom toolbar,
 * matching the iOS SNSButton with showsLabel disabled.
 */
@Composable
private fun SNSIconButton(
    label: String,
    iconRes: Int,
    color: Color,
    onClick: () -> Unit
) {
    ElevatedButton(
        onClick = onClick,
        colors = ButtonDefaults.elevatedButtonColors(
            containerColor = color,
            contentColor = Color.White
        ),
        shape = RoundedCornerShape(12.dp),
        contentPadding = PaddingValues(0.dp),
        modifier = Modifier
            .size(width = 52.dp, height = 40.dp)
            .padding(start = 6.dp)
    ) {
        Icon(
            painter = painterResource(iconRes),
            contentDescription = label,
            tint = Color.White,
            modifier = Modifier.size(18.dp)
        )
    }
}

/**
 * Popover-style dialog for adding or editing a favorite, with the 18-color
 * palette grid and a memo field.
 */
@Composable
private fun FavoriteEditorDialog(
    isFavorited: Boolean,
    selectedColor: WebCatalogColor,
    onColorSelected: (WebCatalogColor) -> Unit,
    memo: String,
    onMemoChange: (String) -> Unit,
    isSaving: Boolean,
    onSave: () -> Unit,
    onRemove: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                stringResource(
                    if (isFavorited) R.string.edit_favorite else R.string.add_to_favorites
                )
            )
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                // 4-wide color grid over the assignable palette
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    WebCatalogColor.assignable.chunked(4).forEach { rowColors ->
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            rowColors.forEach { color ->
                                Box(
                                    modifier = Modifier
                                        .size(44.dp)
                                        .clip(CircleShape)
                                        .background(color.backgroundColor())
                                        .then(
                                            if (color == selectedColor) {
                                                Modifier.border(
                                                    3.dp,
                                                    MaterialTheme.colorScheme.onSurface,
                                                    CircleShape
                                                )
                                            } else {
                                                Modifier
                                            }
                                        )
                                        .clickable { onColorSelected(color) },
                                    contentAlignment = Alignment.Center
                                ) {
                                    if (color == selectedColor) {
                                        Icon(
                                            imageVector = Icons.Filled.Check,
                                            contentDescription = null,
                                            tint = color.foregroundColor(),
                                            modifier = Modifier.size(20.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                OutlinedTextField(
                    value = memo,
                    onValueChange = onMemoChange,
                    label = { Text(stringResource(R.string.favorite_memo)) },
                    placeholder = { Text(stringResource(R.string.favorite_memo_placeholder)) },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = false,
                    maxLines = 3
                )
            }
        },
        confirmButton = {
            FilledTonalButton(
                onClick = onSave,
                enabled = !isSaving
            ) {
                if (isSaving) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(18.dp),
                        strokeWidth = 2.dp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                }
                Text(
                    stringResource(
                        if (isFavorited) R.string.save_favorite else R.string.add_to_favorites
                    )
                )
            }
        },
        dismissButton = {
            if (isFavorited) {
                TextButton(
                    onClick = onRemove,
                    enabled = !isSaving,
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text(stringResource(R.string.remove_from_favorites))
                }
            } else {
                TextButton(onClick = onDismiss, enabled = !isSaving) {
                    Text(stringResource(R.string.cancel))
                }
            }
        }
    )
}
