package com.tsubuzaki.circlesgo.ui.sharedbuys

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuysSession
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream

/** What the sheet opens with: blank for a new item, filled in for a personal one. */
class SharedBuyComposition(
    val name: String = "",
    val cost: Int = 0,
    val image: ByteArray? = null,
    val isConversion: Boolean = false
)

object SharedBuyImageEncoder {

    private const val MAX_DIMENSION = 1000

    /**
     * Scales a photo down to 1000 pixels on its long edge and encodes it as WebP, lowering
     * the quality until it fits under the relay's limit.
     */
    fun webp(bytes: ByteArray): ByteArray? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        val longest = maxOf(bounds.outWidth, bounds.outHeight)
        if (longest <= 0) return null
        var sample = 1
        while (longest / (sample * 2) >= MAX_DIMENSION) sample *= 2
        val options = BitmapFactory.Options().apply { inSampleSize = sample }
        val decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options) ?: return null
        val scale = minOf(1f, MAX_DIMENSION.toFloat() / maxOf(decoded.width, decoded.height))
        val resized = Bitmap.createScaledBitmap(
            decoded,
            (decoded.width * scale).toInt().coerceAtLeast(1),
            (decoded.height * scale).toInt().coerceAtLeast(1),
            true
        )
        val format = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Bitmap.CompressFormat.WEBP_LOSSY
        } else {
            @Suppress("DEPRECATION")
            Bitmap.CompressFormat.WEBP
        }
        for (quality in listOf(80, 65, 50, 35, 20)) {
            val out = ByteArrayOutputStream()
            if (resized.compress(format, quality, out) && out.size() <= SharedBuysSession.MAX_IMAGE_BYTES) {
                return out.toByteArray()
            }
        }
        return null
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SharedBuyComposerSheet(
    session: SharedBuysSession,
    circleId: Int,
    composition: SharedBuyComposition,
    onDismiss: () -> Unit,
    circleName: String? = null,
    circleSpace: String? = null,
    onMoved: () -> Unit = {}
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var name by remember { mutableStateOf(composition.name) }
    var costText by remember {
        mutableStateOf(if (composition.cost == 0) "" else composition.cost.toString())
    }
    var image by remember { mutableStateOf(composition.image) }
    var assignToSelf by remember { mutableStateOf(true) }
    var removeFromBuys by remember { mutableStateOf(true) }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) {
            image = context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
        }
    }

    fun commit() {
        val itemId = session.addItem(
            name.trim(),
            costText.toIntOrNull() ?: 0,
            circleId,
            circleName,
            circleSpace,
            assignToSelf
        )
        image?.let { picked ->
            scope.launch {
                val encoded = withContext(Dispatchers.Default) { SharedBuyImageEncoder.webp(picked) }
                encoded?.let { session.attachImage(it, itemId, circleId) }
            }
        }
        if (composition.isConversion && removeFromBuys) onMoved()
        onDismiss()
    }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = stringResource(
                    if (composition.isConversion) R.string.buys_shared_move else R.string.buys_add_item_shared
                ),
                style = MaterialTheme.typography.titleMedium
            )
            Box(
                modifier = Modifier
                    .align(Alignment.CenterHorizontally)
                    .size(120.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(MaterialTheme.colorScheme.surfaceVariant)
                    .clickable {
                        picker.launch(
                            PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                        )
                    },
                contentAlignment = Alignment.Center
            ) {
                val bitmap = remember(image) {
                    image?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
                }
                if (bitmap != null) {
                    Image(
                        bitmap = bitmap.asImageBitmap(),
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.size(120.dp)
                    )
                } else {
                    Text(
                        text = stringResource(R.string.buys_shared_add_photo),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                placeholder = { Text(stringResource(R.string.buys_item_name_placeholder)) },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            OutlinedTextField(
                value = costText,
                onValueChange = { value -> costText = value.filter { it.isDigit() } },
                placeholder = { Text(stringResource(R.string.buys_item_cost_placeholder)) },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
            )
            ToggleRow(stringResource(R.string.buys_shared_assign_to_me), assignToSelf) { assignToSelf = it }
            if (composition.isConversion) {
                ToggleRow(stringResource(R.string.buys_shared_remove_from_buys), removeFromBuys) {
                    removeFromBuys = it
                }
                Text(
                    text = stringResource(R.string.buys_shared_visible),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Button(
                onClick = { commit() },
                enabled = name.isNotBlank(),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    stringResource(
                        if (composition.isConversion) R.string.buys_shared_move else R.string.buys_shared_add
                    )
                )
            }
        }
    }
}

@Composable
private fun ToggleRow(title: String, isOn: Boolean, onChange: (Boolean) -> Unit) {
    Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(title)
        Spacer(modifier = Modifier.weight(1f))
        Switch(checked = isOn, onCheckedChange = onChange)
    }
}
