package com.tsubuzaki.circlesgo.ui.more

import android.content.Context
import android.os.StatFs
import android.text.format.Formatter
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.DownloadDone
import androidx.compose.material.icons.outlined.FileDownload
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.api.OnlineState
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogDatabase
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogEvent
import com.tsubuzaki.circlesgo.data.local.WebCutImageCache
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.CatalogDatabaseDownloader
import com.tsubuzaki.circlesgo.state.Events
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.ui.shared.LocalAuthenticator
import com.tsubuzaki.circlesgo.ui.shared.LocalWebCutImageCache
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

@Composable
fun EventDataView(
    database: CatalogDatabase,
    events: Events,
    unifier: Unifier
) {
    val context = LocalContext.current
    val authenticator = LocalAuthenticator.current
    val webCutImageCache = LocalWebCutImageCache.current
    val scope = rememberCoroutineScope()
    val authToken by authenticator.token.collectAsState()
    val onlineState by authenticator.onlineState.collectAsState()

    val downloader = remember(database) { CatalogDatabaseDownloader(database) }

    var storageStats by remember { mutableStateOf<StorageStats?>(null) }
    var eventRows by remember { mutableStateOf<List<EventDataRow>>(emptyList()) }
    var activeDownloads by remember { mutableStateOf<Map<Int, Double?>>(emptyMap()) }
    var pendingSwitchEvent by remember { mutableStateOf<Int?>(null) }
    var pendingDownload by remember { mutableStateOf<PendingDownload?>(null) }

    val activeEventNumber = events.activeEventNumber

    suspend fun refreshLocalData() {
        val stats = withContext(Dispatchers.IO) {
            collectStorageStats(context, database, webCutImageCache)
        }
        val rows = withContext(Dispatchers.IO) {
            buildEventRows(events, database)
        }
        storageStats = stats
        eventRows = rows
    }

    // Show local data immediately, then refresh the event list from the API
    LaunchedEffect(Unit) {
        refreshLocalData()
        val token = authToken
        if (token != null && onlineState == OnlineState.ONLINE) {
            events.refreshEventList(token)
            refreshLocalData()
        }
    }

    fun requestDownload(row: EventDataRow) {
        val event = row.event ?: return
        val token = authToken ?: return
        if (activeDownloads.containsKey(event.number)) return

        // Show the confirmation immediately, then resolve the expected size
        // asynchronously so the dialog always appears, even offline or while
        // the size lookup is still in flight.
        pendingDownload = PendingDownload(
            event = event,
            info = null,
            sizeBytes = null,
            isEstimating = true
        )
        scope.launch {
            val info = downloader.fetchDatabaseInformation(event, token)
            val size = info?.let { downloader.estimateDownloadSize(it) }
            // Only apply if the user is still looking at this event's dialog
            if (pendingDownload?.event?.number == event.number) {
                pendingDownload = PendingDownload(
                    event = event,
                    info = info,
                    sizeBytes = size,
                    isEstimating = false
                )
            }
        }
    }

    fun startDownload(pending: PendingDownload) {
        val token = authToken ?: return
        val info = pending.info ?: return
        if (activeDownloads.containsKey(pending.event.number)) return
        activeDownloads = activeDownloads + (pending.event.number to 0.0)
        scope.launch {
            downloader.downloadEventData(pending.event, info, token) { progress ->
                withContext(Dispatchers.Main) {
                    activeDownloads = activeDownloads + (pending.event.number to progress)
                }
            }
            activeDownloads = activeDownloads - pending.event.number
            refreshLocalData()
        }
    }

    fun deleteEventData(row: EventDataRow) {
        scope.launch {
            withContext(Dispatchers.IO) {
                database.delete(
                    WebCatalogEvent.Response.Event(
                        id = row.event?.id ?: 0,
                        number = row.number
                    )
                )
            }
            refreshLocalData()
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // Top bar with back button and title
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = { unifier.popSheetPath() }) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = stringResource(R.string.back)
                )
            }
            Text(
                text = stringResource(R.string.event_data_title),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }

        LazyColumn(modifier = Modifier.fillMaxSize()) {
            // Storage breakdown
            item {
                SectionHeader(stringResource(R.string.storage_header))
                StorageBreakdown(
                    stats = storageStats,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
                )
                SectionFooter(stringResource(R.string.storage_disclaimer))
                HorizontalDivider(modifier = Modifier.padding(horizontal = 20.dp))
            }

            // Selected event
            val activeRow = eventRows.firstOrNull { it.number == activeEventNumber }
            if (activeRow != null) {
                item {
                    SectionHeader(stringResource(R.string.selected_event_header))
                    EventRow(
                        row = activeRow,
                        isActive = true,
                        downloadProgress = null,
                        onTap = {},
                        onDelete = { deleteEventData(activeRow) }
                    )
                    HorizontalDivider(modifier = Modifier.padding(horizontal = 20.dp))
                }
            }

            // Other events
            val otherRows = eventRows.filter { it.number != activeEventNumber }
            if (otherRows.isNotEmpty()) {
                item {
                    SectionHeader(stringResource(R.string.other_events_header))
                }
                items(count = otherRows.size, key = { otherRows[it].number }) { index ->
                    val row = otherRows[index]
                    EventRow(
                        row = row,
                        isActive = false,
                        downloadProgress = activeDownloads[row.number],
                        onTap = {
                            if (activeDownloads.containsKey(row.number)) return@EventRow
                            if (row.isDownloaded) {
                                pendingSwitchEvent = row.number
                            } else {
                                requestDownload(row)
                            }
                        },
                        onDelete = { deleteEventData(row) }
                    )
                }
                item {
                    SectionFooter(stringResource(R.string.storage_provided_by))
                }
            }

            item {
                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }

    // Switch event confirmation
    pendingSwitchEvent?.let { eventNumber ->
        AlertDialog(
            onDismissRequest = { pendingSwitchEvent = null },
            title = { Text(stringResource(R.string.switch_event_title)) },
            text = { Text(stringResource(R.string.switch_event_message, eventNumber)) },
            confirmButton = {
                TextButton(onClick = {
                    pendingSwitchEvent = null
                    events.setActiveEvent(eventNumber)
                }) {
                    Text(stringResource(R.string.switch_event_action))
                }
            },
            dismissButton = {
                TextButton(onClick = { pendingSwitchEvent = null }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }

    // Download confirmation with expected data size
    pendingDownload?.let { pending ->
        AlertDialog(
            onDismissRequest = { pendingDownload = null },
            title = { Text(stringResource(R.string.download_event_title)) },
            text = {
                when {
                    pending.isEstimating -> {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(18.dp),
                                strokeWidth = 2.dp
                            )
                            Text(stringResource(R.string.download_event_estimating))
                        }
                    }

                    pending.info == null -> {
                        Text(stringResource(R.string.download_event_info_failed))
                    }

                    pending.sizeBytes != null -> {
                        Text(
                            stringResource(
                                R.string.download_event_message,
                                pending.event.number,
                                Formatter.formatFileSize(context, pending.sizeBytes)
                            )
                        )
                    }

                    else -> {
                        Text(
                            stringResource(
                                R.string.download_event_message_unknown_size,
                                pending.event.number
                            )
                        )
                    }
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        pendingDownload = null
                        startDownload(pending)
                    },
                    enabled = !pending.isEstimating && pending.info != null
                ) {
                    Text(stringResource(R.string.download_action))
                }
            },
            dismissButton = {
                TextButton(onClick = { pendingDownload = null }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }
}

@Composable
private fun SectionHeader(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.labelMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
    )
}

@Composable
private fun SectionFooter(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
    )
}

@Composable
private fun EventRow(
    row: EventDataRow,
    isActive: Boolean,
    downloadProgress: Double?,
    onTap: () -> Unit,
    onDelete: () -> Unit
) {
    val context = LocalContext.current
    val isDownloading = downloadProgress != null

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .then(if (isActive) Modifier else Modifier.clickable(onClick = onTap))
            .heightIn(min = 56.dp)
            .padding(horizontal = 20.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        if (isActive) {
            Icon(
                imageVector = Icons.Filled.Check,
                contentDescription = stringResource(R.string.selected_event_header),
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp)
            )
        }
        Text(
            text = stringResource(R.string.comic_market_format, row.number),
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.weight(1f)
        )
        row.downloadedBytes?.let { bytes ->
            Text(
                text = Formatter.formatFileSize(context, bytes),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        when {
            isDownloading -> {
                val progress = downloadProgress
                if (progress != null) {
                    CircularProgressIndicator(
                        progress = { progress.toFloat().coerceIn(0f, 1f) },
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp
                    )
                }
            }

            row.isDownloaded -> {
                Icon(
                    imageVector = Icons.Outlined.DownloadDone,
                    contentDescription = stringResource(R.string.downloaded_indicator),
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(20.dp)
                )
                // Deleting the currently selected event's data is not allowed
                IconButton(
                    onClick = onDelete,
                    enabled = !isActive
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Delete,
                        contentDescription = stringResource(R.string.delete_event_data),
                        tint = if (isActive) {
                            MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.38f)
                        } else {
                            MaterialTheme.colorScheme.error
                        }
                    )
                }
            }

            else -> {
                Icon(
                    imageVector = Icons.Outlined.FileDownload,
                    contentDescription = stringResource(R.string.download_event_data),
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

@Composable
private fun StorageBreakdown(
    stats: StorageStats?,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val segments = listOf(
        StorageSegment(
            label = stringResource(R.string.storage_other_apps),
            color = MaterialTheme.colorScheme.outline,
            bytes = stats?.usedByOtherApps ?: 0L
        ),
        StorageSegment(
            label = stringResource(R.string.app_name),
            color = MaterialTheme.colorScheme.primary,
            bytes = stats?.databaseBytes ?: 0L
        ),
        StorageSegment(
            label = stringResource(R.string.storage_image_cache),
            color = MaterialTheme.colorScheme.tertiary,
            bytes = stats?.imageCacheBytes ?: 0L
        ),
        StorageSegment(
            label = stringResource(R.string.storage_free),
            color = MaterialTheme.colorScheme.surfaceVariant,
            bytes = stats?.freeBytes ?: 0L
        )
    )

    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Proportional usage bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(16.dp)
                .clip(RoundedCornerShape(6.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant)
        ) {
            segments.forEach { segment ->
                if (segment.bytes > 0) {
                    Box(
                        modifier = Modifier
                            .weight(segment.bytes.toFloat())
                            .fillMaxHeight()
                            .background(segment.color)
                    )
                }
            }
        }

        // Legend
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            segments.forEach { segment ->
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(10.dp)
                            .clip(CircleShape)
                            .background(segment.color)
                    )
                    Text(
                        text = segment.label,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.weight(1f)
                    )
                    Text(
                        text = Formatter.formatFileSize(context, segment.bytes),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

private data class StorageSegment(
    val label: String,
    val color: Color,
    val bytes: Long
)

private data class StorageStats(
    val totalBytes: Long,
    val freeBytes: Long,
    val databaseBytes: Long,
    val imageCacheBytes: Long
) {
    val usedByOtherApps: Long
        get() = (totalBytes - freeBytes - databaseBytes - imageCacheBytes).coerceAtLeast(0L)
}

private data class EventDataRow(
    val number: Int,
    val event: WebCatalogEvent.Response.Event?,
    val downloadedBytes: Long?,
    val isDownloaded: Boolean
)

private data class PendingDownload(
    val event: WebCatalogEvent.Response.Event,
    val info: WebCatalogDatabase?,
    val sizeBytes: Long?,
    val isEstimating: Boolean
)

private fun collectStorageStats(
    context: Context,
    database: CatalogDatabase,
    webCutImageCache: WebCutImageCache
): StorageStats {
    val statFs = StatFs(context.filesDir.absolutePath)
    return StorageStats(
        totalBytes = statFs.totalBytes,
        freeBytes = statFs.availableBytes,
        databaseBytes = database.downloadedEventSizes().values.sum(),
        imageCacheBytes = webCutImageCache.diskUsageBytes()
    )
}

private fun buildEventRows(
    events: Events,
    database: CatalogDatabase
): List<EventDataRow> {
    val sizes = database.downloadedEventSizes()
    val list = events.eventData?.list ?: emptyList()
    val numbers = (list.map { it.number } + sizes.keys).distinct().sortedDescending()
    return numbers.map { number ->
        EventDataRow(
            number = number,
            event = list.firstOrNull { it.number == number },
            downloadedBytes = sizes[number],
            isDownloaded = database.isDownloaded(number)
        )
    }
}
