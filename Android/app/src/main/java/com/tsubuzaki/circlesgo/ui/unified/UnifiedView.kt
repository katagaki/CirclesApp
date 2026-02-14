package com.tsubuzaki.circlesgo.ui.unified

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.material3.BottomSheetScaffold
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FloatingToolbarDefaults
import androidx.compose.material3.HorizontalFloatingToolbar
import androidx.compose.material3.Icon
import androidx.compose.material3.SheetValue
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberBottomSheetScaffoldState
import androidx.compose.material3.rememberStandardBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.state.CatalogCache
import com.tsubuzaki.circlesgo.state.Events
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.Mapper
import com.tsubuzaki.circlesgo.state.Oasis
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.state.UserSelections
import com.tsubuzaki.circlesgo.api.catalog.FavoritesAPI
import com.tsubuzaki.circlesgo.auth.Authenticator
import com.tsubuzaki.circlesgo.ui.map.MapView
import com.tsubuzaki.circlesgo.ui.shared.ProgressOverlay
import kotlinx.coroutines.launch

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
    onLogout: () -> Unit
) {
    val isGoingToSignOut by unifier.isGoingToSignOut.collectAsState()
    val isSearchActive by unifier.isSearchActive.collectAsState()
    val scope = rememberCoroutineScope()

    val bottomSheetState = rememberStandardBottomSheetState(
        initialValue = SheetValue.PartiallyExpanded,
        skipHiddenState = false
    )
    val scaffoldState = rememberBottomSheetScaffoldState(
        bottomSheetState = bottomSheetState
    )

    // Expand/collapse bottom sheet based on search state
    LaunchedEffect(isSearchActive) {
        if (isSearchActive) {
            bottomSheetState.expand()
        } else {
            bottomSheetState.partialExpand()
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {

        // Sign out dialog
        if (isGoingToSignOut) {
            AlertDialog(
                onDismissRequest = { unifier.setIsGoingToSignOut(false) },
                title = { Text(stringResource(R.string.sign_out)) },
                text = { Text(stringResource(R.string.sign_out_confirm_message)) },
                confirmButton = {
                    TextButton(onClick = {
                        unifier.setIsGoingToSignOut(false)
                        onLogout()
                    }) {
                        Text(stringResource(R.string.sign_out))
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
            sheetPeekHeight = 400.dp,
            sheetDragHandle = {
                val isExpanded = scaffoldState.bottomSheetState.targetValue == SheetValue.Expanded
                BottomSheetDefaults.DragHandle(
                    modifier = if (isExpanded) Modifier.statusBarsPadding() else Modifier
                )
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
                    authenticator = authenticator
                )
            },
            sheetShape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp),
            sheetShadowElevation = 16.dp,
            sheetSwipeEnabled = scaffoldState.bottomSheetState.currentValue != SheetValue.Hidden
        ) { innerPadding ->
            // Main map view content
            val isSheetHidden = scaffoldState.bottomSheetState.targetValue == SheetValue.Hidden
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(if (isSheetHidden) PaddingValues(bottom = (FloatingToolbarDefaults.ScreenOffset + (96).dp)) else innerPadding)
            ) {
                MapView(
                    database = database,
                    mapper = mapper,
                    selections = selections,
                    favorites = favorites,
                    onCircleTapped = { circle ->
                        unifier.showCircleDetail(circle)
                    }
                )
            }
        }

        // Floating toolbar
        if (scaffoldState.bottomSheetState.targetValue != SheetValue.Expanded) {
            HorizontalFloatingToolbar(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .offset(y = -FloatingToolbarDefaults.ScreenOffset)
                    .padding(16.dp),
                colors = FloatingToolbarDefaults.vibrantFloatingToolbarColors(),
                expanded = true,
                floatingActionButton = {
                    FloatingToolbarDefaults.VibrantFloatingActionButton(
                        onClick = {
                            scope.launch {
                                if (scaffoldState.bottomSheetState.targetValue == SheetValue.Hidden) {
                                    bottomSheetState.partialExpand()
                                } else {
                                    bottomSheetState.hide()
                                }
                            }
                        }
                    ) {
                        if (scaffoldState.bottomSheetState.targetValue == SheetValue.Hidden) {
                            Icon(
                                Icons.Filled.KeyboardArrowUp,
                                contentDescription = stringResource(R.string.show_catalog)
                            )
                        } else {
                            Icon(
                                Icons.Filled.KeyboardArrowDown,
                                contentDescription = stringResource(R.string.hide_catalog)
                            )
                        }
                    }
                },
                content = {
                    UnifiedControl(
                        database = database,
                        selections = selections
                    )
                    UnifiedMoreMenu(
                        unifier = unifier,
                        events = events
                    )
                }
            )
        }

        // Progress overlay (shown during database download/loading)
        ProgressOverlay(oasis = oasis)

    } // end outer Box
}
