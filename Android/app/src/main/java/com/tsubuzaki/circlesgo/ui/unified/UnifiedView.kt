package com.tsubuzaki.circlesgo.ui.unified

import android.os.Build
import android.view.RoundedCorner
import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.BottomSheetScaffold
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FloatingToolbarDefaults
import androidx.compose.material3.HorizontalFloatingToolbar
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SheetValue
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberBottomSheetScaffoldState
import androidx.compose.material3.rememberStandardBottomSheetState
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
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.api.catalog.FavoritesAPI
import com.tsubuzaki.circlesgo.auth.Authenticator
import com.tsubuzaki.circlesgo.data.local.AttachmentsCache
import com.tsubuzaki.circlesgo.data.local.BuysCache
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.state.VisitsState
import com.tsubuzaki.circlesgo.state.CatalogCache
import com.tsubuzaki.circlesgo.state.Events
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.Mapper
import com.tsubuzaki.circlesgo.state.Oasis
import com.tsubuzaki.circlesgo.state.UnifiedPath
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.state.UserSelections
import com.tsubuzaki.circlesgo.ui.map.MapView
import com.tsubuzaki.circlesgo.ui.more.EventDataView
import com.tsubuzaki.circlesgo.ui.shared.LocalDemoMode
import com.tsubuzaki.circlesgo.ui.shared.ProgressOverlay
import kotlinx.coroutines.launch

/** Height of the sheet in its standard, catalog-showing state. */
private val standardSheetHeight = 400.dp

/** Height of the sheet when minimized: only the drag handle and the tab row
 *  are visible, so the map is left as clear as possible. */
private val minimizedSheetHeight = 76.dp

@OptIn(ExperimentalMaterial3Api::class, ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun UnifiedView(
    unifier: Unifier,
    mapper: Mapper,
    database: CatalogDatabase,
    selections: UserSelections,
    events: Events,
    favorites: FavoritesState,
    catalogCache: CatalogCache,
    oasis: Oasis,
    favoritesAPI: FavoritesAPI,
    authenticator: Authenticator,
    buysCache: BuysCache,
    visitsState: VisitsState,
    attachmentsCache: AttachmentsCache,
    onLogout: () -> Unit
) {
    val isGoingToSignOut by unifier.isGoingToSignOut.collectAsState()
    val isSearchActive by unifier.isSearchActive.collectAsState()
    val isEventDataPresenting by unifier.isEventDataPresenting.collectAsState()
    val showGenreOverlay by selections.showGenreOverlay.collectAsState()
    val useHighResolutionMaps by selections.useHighResolutionMaps.collectAsState()
    val scope = rememberCoroutineScope()

    // The sheet can never be dismissed; swiping it down past its standard
    // height minimizes it instead of hiding it
    var isSheetMinimized by remember { mutableStateOf(false) }
    val bottomSheetState = rememberStandardBottomSheetState(
        initialValue = SheetValue.PartiallyExpanded,
        skipHiddenState = false,
        confirmValueChange = { targetValue ->
            if (targetValue == SheetValue.Hidden) {
                isSheetMinimized = true
                false
            } else {
                true
            }
        }
    )
    val scaffoldState = rememberBottomSheetScaffoldState(
        bottomSheetState = bottomSheetState
    )

    // Animating the peek height moves the partially expanded anchor, which the
    // sheet follows, so minimizing and restoring glide instead of jumping
    val targetSheetHeight = if (isSheetMinimized) minimizedSheetHeight else standardSheetHeight
    val sheetPeekHeight by animateDpAsState(
        targetValue = targetSheetHeight,
        label = "sheetPeekHeight"
    )

    val sheetPath by unifier.sheetPath.collectAsState()

    val density = LocalDensity.current
    val view = LocalView.current
    val deviceCornerRadius = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val windowInsets = view.rootWindowInsets
        val topLeft = windowInsets?.getRoundedCorner(RoundedCorner.POSITION_TOP_LEFT)
        val topRight = windowInsets?.getRoundedCorner(RoundedCorner.POSITION_TOP_RIGHT)
        val radiusPx = maxOf(topLeft?.radius ?: 0, topRight?.radius ?: 0)
        with(density) { radiusPx.toDp() }
    } else {
        20.dp
    }

    fun expandSheetToStandardHeight() {
        isSheetMinimized = false
        scope.launch { bottomSheetState.partialExpand() }
    }

    // Expand/collapse bottom sheet based on search state
    LaunchedEffect(isSearchActive) {
        if (isSearchActive) {
            isSheetMinimized = false
            bottomSheetState.expand()
        } else {
            bottomSheetState.partialExpand()
        }
    }

    // A fully expanded sheet is never minimized, so collapsing it from there
    // always lands on the standard height
    val sheetValue = scaffoldState.bottomSheetState.currentValue
    LaunchedEffect(sheetValue) {
        if (sheetValue == SheetValue.Expanded) {
            isSheetMinimized = false
        }
    }

    // Minimize as soon as a downward drag aims past the sheet, so that the
    // sheet settles on the minimized anchor instead of springing back
    val sheetTargetValue = scaffoldState.bottomSheetState.targetValue
    LaunchedEffect(sheetTargetValue) {
        if (sheetTargetValue == SheetValue.Hidden) {
            isSheetMinimized = true
        }
    }

    // A flick can settle before the peek height finishes animating, which
    // leaves the sheet slightly off its anchor; re-settle once it has
    val isSheetHeightSettled = sheetPeekHeight == targetSheetHeight
    LaunchedEffect(isSheetMinimized, isSheetHeightSettled) {
        if (isSheetHeightSettled && sheetValue == SheetValue.PartiallyExpanded) {
            bottomSheetState.partialExpand()
        }
    }

    // Restore the sheet to its standard size when circle detail is pushed
    // (e.g. from the map popover)
    LaunchedEffect(sheetPath) {
        if (sheetPath.lastOrNull() == UnifiedPath.CIRCLE_DETAIL && isSheetMinimized) {
            isSheetMinimized = false
        }
    }

    // Collapse the sheet when requested (e.g. Show on Map)
    val sheetCollapseRequest by unifier.sheetCollapseRequest.collectAsState()
    LaunchedEffect(sheetCollapseRequest) {
        if (sheetCollapseRequest > 0) {
            isSheetMinimized = false
            bottomSheetState.partialExpand()
        }
    }

    // Handle system back gesture: navigate within the bottom sheet before closing the app
    BackHandler(
        enabled = unifier.hasSheetContent()
                || isSearchActive
                || sheetValue == SheetValue.Expanded
                || !isSheetMinimized
    ) {
        when {
            // 1. If circle detail (or other pushed content) is showing, pop it
            unifier.hasSheetContent() -> {
                if (sheetPath.lastOrNull() == UnifiedPath.CIRCLE_DETAIL) {
                    unifier.clearCircleDetail()
                }
                unifier.popSheetPath()
            }
            // 2. If search is active, close it
            isSearchActive -> {
                unifier.setIsSearchActive(false)
            }
            // 3. If bottom sheet is expanded, collapse it to its standard height
            sheetValue == SheetValue.Expanded -> {
                scope.launch { bottomSheetState.partialExpand() }
            }
            // 4. Otherwise minimize the sheet, clearing the map
            else -> {
                isSheetMinimized = true
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {

        // Sign out / exit demo mode dialog
        if (isGoingToSignOut) {
            val isDemoMode = LocalDemoMode.current
            val actionLabel = stringResource(
                if (isDemoMode) R.string.exit_demo_mode else R.string.sign_out
            )
            AlertDialog(
                onDismissRequest = { unifier.setIsGoingToSignOut(false) },
                title = { Text(actionLabel) },
                text = {
                    Text(
                        stringResource(
                            if (isDemoMode) {
                                R.string.exit_demo_mode_confirm_message
                            } else {
                                R.string.sign_out_confirm_message
                            }
                        )
                    )
                },
                confirmButton = {
                    TextButton(onClick = {
                        unifier.setIsGoingToSignOut(false)
                        onLogout()
                    }) {
                        Text(actionLabel)
                    }
                },
                dismissButton = {
                    TextButton(onClick = { unifier.setIsGoingToSignOut(false) }) {
                        Text(stringResource(R.string.cancel))
                    }
                }
            )
        }

        BottomSheetScaffold(
            scaffoldState = scaffoldState,
            sheetPeekHeight = sheetPeekHeight,
            sheetDragHandle = {
                val isExpanded = scaffoldState.bottomSheetState.targetValue == SheetValue.Expanded
                val expandLabel = stringResource(R.string.show_catalog)
                // Compact handle: the Material default reserves ~48dp of height,
                // which wastes space in a sheet that is mostly content
                Box(
                    modifier = (if (isExpanded) Modifier.statusBarsPadding() else Modifier)
                        .fillMaxWidth()
                        .then(
                            if (isSheetMinimized) {
                                Modifier.clickable(onClickLabel = expandLabel) {
                                    expandSheetToStandardHeight()
                                }
                            } else {
                                Modifier
                            }
                        )
                        .padding(vertical = 8.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Box(
                        modifier = Modifier
                            .size(width = 32.dp, height = 4.dp)
                            .background(
                                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f),
                                shape = RoundedCornerShape(2.dp)
                            )
                    )
                }
            },
            sheetContent = {
                UnifiedPanel(
                    unifier = unifier,
                    database = database,
                    favorites = favorites,
                    selections = selections,
                    mapper = mapper,
                    catalogCache = catalogCache,
                    favoritesAPI = favoritesAPI,
                    authenticator = authenticator,
                    events = events,
                    buysCache = buysCache,
                    visitsState = visitsState,
                    attachmentsCache = attachmentsCache,
                    visibleHeight = if (
                        scaffoldState.bottomSheetState.targetValue == SheetValue.Expanded
                    ) null else targetSheetHeight - 20.dp,
                    isMinimized = isSheetMinimized,
                    onRequestExpand = { expandSheetToStandardHeight() }
                )
            },
            sheetShape = RoundedCornerShape(
                topStart = deviceCornerRadius,
                topEnd = deviceCornerRadius
            ),
            sheetShadowElevation = 16.dp
        ) {
            // Main map view content. The sheet's own peek height is used instead
            // of the scaffold padding so the map is only laid out once per
            // sheet size change, rather than on every frame of the animation
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(bottom = targetSheetHeight)
            ) {
                MapView(
                    database = database,
                    mapper = mapper,
                    selections = selections,
                    favorites = favorites,
                    useHighResolutionMaps = useHighResolutionMaps,
                    showGenreOverlay = showGenreOverlay,
                    visitsState = visitsState,
                    events = events,
                    onCircleTapped = { circle ->
                        unifier.showCircleDetail(circle)
                    }
                )
            }
        }

        // Floating toolbar, docked at the top like the iOS navigation bar so the
        // bottom area stays clear for the sheet
        if (scaffoldState.bottomSheetState.targetValue != SheetValue.Expanded) {
            HorizontalFloatingToolbar(
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .statusBarsPadding()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                colors = FloatingToolbarDefaults.vibrantFloatingToolbarColors(),
                expanded = true,
                content = {
                    UnifiedControl(
                        database = database,
                        selections = selections
                    )
                    UnifiedMoreMenu(
                        unifier = unifier,
                        selections = selections
                    )
                }
            )
        }

        // Progress overlay (shown during database download/loading)
        ProgressOverlay(oasis = oasis)

        // Event data management, presented full screen on top of everything else
        AnimatedVisibility(
            visible = isEventDataPresenting,
            enter = slideInHorizontally { it },
            exit = slideOutHorizontally { it }
        ) {
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = MaterialTheme.colorScheme.background
            ) {
                EventDataView(
                    database = database,
                    events = events,
                    onClose = { unifier.setIsEventDataPresenting(false) }
                )
            }
        }
        if (isEventDataPresenting) {
            BackHandler { unifier.setIsEventDataPresenting(false) }
        }

    } // end outer Box
}
