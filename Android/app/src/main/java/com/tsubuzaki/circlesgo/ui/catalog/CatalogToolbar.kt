package com.tsubuzaki.circlesgo.ui.catalog

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.Checklist
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Theaters
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.tables.ComiketBlock
import com.tsubuzaki.circlesgo.database.tables.ComiketGenre
import com.tsubuzaki.circlesgo.state.CatalogCache
import com.tsubuzaki.circlesgo.state.CircleDisplayMode
import com.tsubuzaki.circlesgo.state.UserSelections
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@Composable
fun CatalogToolbar(
    database: CatalogDatabase,
    selections: UserSelections
) {
    val selectedMap by selections.map.collectAsState()
    val selectedDate by selections.date.collectAsState()
    val selectedGenres by selections.genres.collectAsState()
    val selectedBlocks by selections.blocks.collectAsState()
    val displayMode by selections.displayMode.collectAsState()

    val allGenres = remember { database.genres() }
    val allBlocks = remember { database.blocks() }

    val scope = rememberCoroutineScope()

    var selectableGenres by remember { mutableStateOf<List<ComiketGenre>?>(null) }
    var selectableBlocks by remember { mutableStateOf<List<ComiketBlock>?>(null) }

    // Reload selectable genres when map or date changes
    LaunchedEffect(selectedMap, selectedDate) {
        val mapID = selectedMap?.id
        val dayID = selectedDate?.id
        if (mapID != null && dayID != null) {
            scope.launch(Dispatchers.IO) {
                val genreIDs = CatalogCache.fetchGenreIDs(mapID, dayID, database)
                selectableGenres = allGenres
                    .filter { it.id in genreIDs }
                    .sortedBy { it.name }
            }
        } else {
            selectableGenres = null
        }
    }

    // Reload selectable blocks when map, date, or genres change
    LaunchedEffect(selectedMap, selectedDate, selectedGenres) {
        val mapID = selectedMap?.id
        val dayID = selectedDate?.id
        if (mapID != null && dayID != null) {
            val genreIDs = if (selectedGenres.isEmpty()) null
            else selectedGenres.map { it.id }
            scope.launch(Dispatchers.IO) {
                val blockIDs = CatalogCache.fetchBlockIDs(mapID, dayID, genreIDs, database)
                selectableBlocks = allBlocks
                    .filter { it.id in blockIDs }
                    .sortedBy { it.name }
            }
        } else {
            selectableBlocks = null
        }
    }

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(horizontal = 16.dp)
    ) {
        GenreFilterMenu(
            selectedGenres = selectedGenres,
            genres = selectableGenres ?: allGenres,
            onGenreToggled = { genre ->
                val newGenres = selectedGenres.toMutableSet()
                if (newGenres.contains(genre)) {
                    newGenres.remove(genre)
                } else {
                    newGenres.add(genre)
                }
                selections.setGenres(newGenres)
            },
            onClearAll = { selections.setGenres(emptySet()) }
        )
        Spacer(modifier = Modifier.width(4.dp))
        BlockFilterMenu(
            selectedBlocks = selectedBlocks,
            blocks = selectableBlocks ?: allBlocks,
            onBlockToggled = { block ->
                val newBlocks = selectedBlocks.toMutableSet()
                if (newBlocks.contains(block)) {
                    newBlocks.remove(block)
                } else {
                    newBlocks.add(block)
                }
                selections.setBlocks(newBlocks)
            },
            onClearAll = { selections.setBlocks(emptySet()) }
        )
        Spacer(modifier = Modifier.weight(1f))
        IconButton(onClick = {
            val newMode = if (displayMode == CircleDisplayMode.GRID) {
                CircleDisplayMode.LIST
            } else {
                CircleDisplayMode.GRID
            }
            selections.setDisplayMode(newMode)
        }) {
            Icon(
                imageVector = if (displayMode == CircleDisplayMode.GRID) {
                    Icons.AutoMirrored.Filled.List
                } else {
                    Icons.Filled.GridView
                },
                contentDescription = stringResource(
                    if (displayMode == CircleDisplayMode.GRID) R.string.switch_to_list
                    else R.string.switch_to_grid
                )
            )
        }
    }
}

@Composable
private fun GenreFilterMenu(
    selectedGenres: Set<ComiketGenre>,
    genres: List<ComiketGenre>,
    onGenreToggled: (ComiketGenre) -> Unit,
    onClearAll: () -> Unit
) {
    var expanded by remember { mutableStateOf(false) }

    Box {
        TextButton(onClick = { expanded = true }) {
            Icon(
                imageVector = Icons.Filled.Theaters,
                contentDescription = null,
                modifier = Modifier.padding(end = 4.dp)
            )
            Text(
                text = when {
                    selectedGenres.size == 1 -> selectedGenres.first().name
                    selectedGenres.size > 1 -> stringResource(
                        R.string.genres_count_format,
                        selectedGenres.size
                    )

                    else -> stringResource(R.string.genre_filter)
                },
                fontSize = 13.sp
            )
        }

        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            DropdownMenuItem(
                text = { Text(stringResource(R.string.all_filter)) },
                onClick = {
                    onClearAll()
                }
            )
            for (genre in genres) {
                DropdownMenuItem(
                    text = {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(genre.name)
                            if (selectedGenres.contains(genre)) {
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("✓", fontSize = 12.sp)
                            }
                        }
                    },
                    onClick = { onGenreToggled(genre) }
                )
            }
        }
    }
}

@Composable
private fun BlockFilterMenu(
    selectedBlocks: Set<ComiketBlock>,
    blocks: List<ComiketBlock>,
    onBlockToggled: (ComiketBlock) -> Unit,
    onClearAll: () -> Unit
) {
    var expanded by remember { mutableStateOf(false) }

    Box {
        TextButton(onClick = { expanded = true }) {
            Icon(
                imageVector = Icons.Filled.Checklist,
                contentDescription = null,
                modifier = Modifier.padding(end = 4.dp)
            )
            Text(
                text = when {
                    selectedBlocks.size == 1 -> selectedBlocks.first().name
                    selectedBlocks.size > 1 -> stringResource(
                        R.string.blocks_count_format,
                        selectedBlocks.size
                    )

                    else -> stringResource(R.string.block_filter)
                },
                fontSize = 13.sp
            )
        }

        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            DropdownMenuItem(
                text = { Text(stringResource(R.string.all_filter)) },
                onClick = {
                    onClearAll()
                }
            )
            for (block in blocks) {
                DropdownMenuItem(
                    text = {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(block.name)
                            if (selectedBlocks.contains(block)) {
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("✓", fontSize = 12.sp)
                            }
                        }
                    },
                    onClick = { onBlockToggled(block) }
                )
            }
        }
    }
}
