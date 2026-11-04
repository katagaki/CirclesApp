package com.tsubuzaki.circlesgo.ui.sharedbuys

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuysSession

@Composable
fun SharedBuysDebugScreen(session: SharedBuysSession, onClose: () -> Unit) {
    var itemName by remember { mutableStateOf("") }
    var itemCost by remember { mutableStateOf("1000") }
    var nickname by remember { mutableStateOf("Tester") }
    var composition by remember { mutableStateOf<SharedBuyComposition?>(null) }

    composition?.let {
        SharedBuyComposerSheet(session, 1, it, onDismiss = { composition = null })
    }

    Surface(modifier = Modifier.fillMaxSize()) {
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Shared Buys", style = MaterialTheme.typography.titleLarge)
                    TextButton(onClick = onClose) { Text("Close") }
                }
                Text("Status: ${session.status}")
                Text("Device: ${session.deviceId.ifEmpty { "—" }}")
                Text("Room: ${session.roomId ?: "—"}", overflow = TextOverflow.Ellipsis)
                Text("Bluetooth peers: ${session.bluetoothPeers}")
                OutlinedTextField(
                    value = session.relayBaseUrl,
                    onValueChange = { session.relayBaseUrl = it },
                    label = { Text("Relay") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = nickname,
                    onValueChange = { nickname = it },
                    label = { Text("Nickname") },
                    modifier = Modifier.fillMaxWidth()
                )
                HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
            }

            if (session.isActive) {
                item {
                    session.joinUrl?.let { Text(it, style = MaterialTheme.typography.bodySmall) }
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(onClick = { session.connect() }) { Text("Reconnect") }
                        Button(onClick = { session.leave() }) { Text("Leave") }
                        Button(onClick = { session.rotateKey() }, enabled = session.canRotateKey) {
                            Text("Rotate")
                        }
                    }
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedTextField(
                            value = itemName,
                            onValueChange = { itemName = it },
                            label = { Text("Item") },
                            modifier = Modifier.weight(1f)
                        )
                        OutlinedTextField(
                            value = itemCost,
                            onValueChange = { itemCost = it },
                            label = { Text("Cost") },
                            modifier = Modifier.weight(0.5f)
                        )
                    }
                    Button(
                        onClick = {
                            session.addItem(itemName, itemCost.toIntOrNull() ?: 0, 1)
                            itemName = ""
                        },
                        enabled = itemName.isNotBlank()
                    ) { Text("Add") }
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(onClick = { composition = SharedBuyComposition() }) { Text("Compose") }
                        Button(onClick = {
                            composition = SharedBuyComposition("Converted", 1500, samplePhoto(), true)
                        }) { Text("Convert sample") }
                    }
                    Text("Items (${session.items.size})", style = MaterialTheme.typography.titleMedium)
                }
                items(session.items) { buyItem ->
                    Row(modifier = Modifier.fillMaxWidth()) {
                        TextButton(onClick = { session.cycle(buyItem) }, modifier = Modifier.weight(1f)) {
                            val size = session.image(buyItem)?.size
                            Text(
                                "[${buyItem.status}] ${buyItem.name}  ¥${buyItem.cost}" +
                                    (size?.let { " img=$it" } ?: "")
                            )
                        }
                        TextButton(onClick = { session.remove(buyItem.id, buyItem.circleId) }) {
                            Text("Delete ${buyItem.name}")
                        }
                    }
                }
                item {
                    Text(
                        "Changes (${session.changes.size})",
                        style = MaterialTheme.typography.titleMedium
                    )
                }
                items(session.changes.sortedBy { it.order }) { change ->
                    Text(
                        "${change.id}  kind=${change.payload.kind}",
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            } else {
                item {
                    Button(onClick = { session.start(0, nickname) }) { Text("Start a session") }
                }
            }

            item {
                HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
                Text("Log", style = MaterialTheme.typography.titleMedium)
            }
            items(session.log) { line ->
                Text(line, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

/** Larger than the 1000 pixel limit, so the real resize and encode both run. */
private fun samplePhoto(): ByteArray {
    val bitmap = android.graphics.Bitmap.createBitmap(2400, 1600, android.graphics.Bitmap.Config.ARGB_8888)
    val canvas = android.graphics.Canvas(bitmap)
    val paint = android.graphics.Paint()
    for (band in 0 until 24) {
        paint.color = android.graphics.Color.HSVToColor(floatArrayOf(band * 15f, 0.8f, 0.9f))
        canvas.drawRect(band * 100f, 0f, band * 100f + 100f, 1600f, paint)
    }
    val out = java.io.ByteArrayOutputStream()
    bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 90, out)
    return out.toByteArray()
}
