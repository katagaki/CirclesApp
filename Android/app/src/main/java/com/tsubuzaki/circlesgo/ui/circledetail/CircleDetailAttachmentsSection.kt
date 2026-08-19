package com.tsubuzaki.circlesgo.ui.circledetail

import android.graphics.Bitmap
import android.graphics.ImageDecoder
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.VectorConverter
import androidx.compose.animation.core.spring
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.calculatePan
import androidx.compose.foundation.gestures.calculateZoom
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.data.local.AttachmentsCache
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

/**
 * Image attachments for a circle (product lists, notices), mirroring the iOS
 * attachments section. Images are picked from the photo library.
 */
@Composable
fun CircleDetailAttachmentsSection(
    circleID: Int,
    eventNumber: Int,
    attachmentsCache: AttachmentsCache,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val version by attachmentsCache.version.collectAsState()

    var files by remember { mutableStateOf<List<File>>(emptyList()) }
    var thumbnails by remember { mutableStateOf<Map<String, Bitmap>>(emptyMap()) }
    var viewerFile by remember { mutableStateOf<File?>(null) }

    LaunchedEffect(version, circleID, eventNumber) {
        withContext(Dispatchers.IO) {
            val loaded = attachmentsCache.attachments(eventNumber, circleID)
            val thumbs = loaded.mapNotNull { file ->
                attachmentsCache.load(file)?.let { file.path to it }
            }.toMap()
            files = loaded
            thumbnails = thumbs
        }
    }

    val pickImage = rememberLauncherForActivityResult(
        ActivityResultContracts.PickVisualMedia()
    ) { uri ->
        if (uri != null) {
            try {
                val source = ImageDecoder.createSource(context.contentResolver, uri)
                val bitmap = ImageDecoder.decodeBitmap(source) { decoder, _, _ ->
                    decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
                }
                attachmentsCache.add(eventNumber, circleID, bitmap)
            } catch (e: Exception) {
                // Ignore unreadable images
            }
        }
    }

    Column(modifier = modifier) {
        Text(
            text = stringResource(R.string.attachments_title),
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        if (files.isNotEmpty()) {
            Spacer(modifier = Modifier.height(8.dp))
            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items(files, key = { it.path }) { file ->
                    val bitmap = thumbnails[file.path]
                    if (bitmap != null) {
                        Box {
                            Image(
                                bitmap = bitmap.asImageBitmap(),
                                contentDescription = null,
                                contentScale = ContentScale.Crop,
                                modifier = Modifier
                                    .size(96.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .clickable { viewerFile = file }
                            )
                            IconButton(
                                onClick = { attachmentsCache.delete(file) },
                                modifier = Modifier
                                    .align(Alignment.TopEnd)
                                    .size(28.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Outlined.Delete,
                                    contentDescription = stringResource(
                                        R.string.attachments_delete
                                    ),
                                    modifier = Modifier.size(16.dp),
                                    tint = MaterialTheme.colorScheme.error
                                )
                            }
                        }
                    }
                }
            }
        }

        // Add attachment button
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable {
                    pickImage.launch(
                        PickVisualMediaRequest(
                            ActivityResultContracts.PickVisualMedia.ImageOnly
                        )
                    )
                }
                .padding(vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Filled.AddCircle,
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = stringResource(R.string.attachments_add),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.Medium
            )
        }
    }

    // Fullscreen viewer
    viewerFile?.let { file ->
        val bitmap = thumbnails[file.path]
        Dialog(
            onDismissRequest = { viewerFile = null },
            properties = DialogProperties(usePlatformDefaultWidth = false)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clickable { viewerFile = null },
                contentAlignment = Alignment.Center
            ) {
                if (bitmap != null) {
                    // Pinch to zoom with pan; springs back to fit on release
                    val scope = rememberCoroutineScope()
                    val zoomScale = remember { Animatable(1f) }
                    val panOffset = remember { Animatable(Offset.Zero, Offset.VectorConverter) }
                    Image(
                        bitmap = bitmap.asImageBitmap(),
                        contentDescription = null,
                        contentScale = ContentScale.Fit,
                        modifier = Modifier
                            .fillMaxWidth()
                            .graphicsLayer {
                                scaleX = zoomScale.value
                                scaleY = zoomScale.value
                                translationX = panOffset.value.x
                                translationY = panOffset.value.y
                            }
                            .pointerInput(Unit) {
                                awaitEachGesture {
                                    awaitFirstDown()
                                    do {
                                        val event = awaitPointerEvent()
                                        val zoomChange = event.calculateZoom()
                                        val panChange = event.calculatePan()
                                        if (zoomChange != 1f || panChange != Offset.Zero) {
                                            event.changes.forEach { it.consume() }
                                            scope.launch {
                                                zoomScale.snapTo(
                                                    (zoomScale.value * zoomChange)
                                                        .coerceAtLeast(1f)
                                                )
                                                panOffset.snapTo(panOffset.value + panChange)
                                            }
                                        }
                                    } while (event.changes.any { it.pressed })
                                    scope.launch {
                                        zoomScale.animateTo(1f, spring())
                                    }
                                    scope.launch {
                                        panOffset.animateTo(Offset.Zero, spring())
                                    }
                                }
                            }
                    )
                }
                IconButton(
                    onClick = { viewerFile = null },
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(16.dp)
                ) {
                    Icon(
                        imageVector = Icons.Filled.Close,
                        contentDescription = stringResource(R.string.back),
                        tint = MaterialTheme.colorScheme.onSurface
                    )
                }
            }
        }
    }
}
