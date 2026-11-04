package com.tsubuzaki.circlesgo.ui.buys

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
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
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.data.local.AttachmentsCache
import com.tsubuzaki.circlesgo.data.local.BuysCache
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuyItem
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuysSession
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.ByteArrayOutputStream

object BuyImageEncoder {

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

/** The row being edited. New rows exist only here until they have a name. */
private sealed interface EditTarget {
    data class Personal(val id: String) : EditTarget
    data class Shared(val id: String) : EditTarget
    data object NewPersonal : EditTarget
    data object NewShared : EditTarget
}

/**
 * Every item for a circle in one view, edited in place.
 *
 * Shown inside the panel rather than over it. Shared edits go out when a row is finished,
 * not per keystroke: the relay allows 20 messages per 10 seconds, and a half-typed name
 * should not reach other members.
 */
@Composable
fun BuysEditView(
    session: SharedBuysSession?,
    circleId: Int,
    eventNumber: Int,
    buysCache: BuysCache,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
    circleName: String? = null,
    circleSpace: String? = null,
    attachmentsCache: AttachmentsCache? = null
) {
    val focusManager = LocalFocusManager.current
    val listState = rememberLazyListState()
    val version by buysCache.version.collectAsState()
    val personal = remember(version, circleId, eventNumber) {
        buysCache.entry(circleId, eventNumber)?.items?.sortedBy { it.sortOrder }.orEmpty()
    }
    val hasShared = session?.isActive == true
    val shared = if (hasShared) session!!.items.filter { it.circleId == circleId } else emptyList()
    val attachments = remember(circleId, eventNumber) {
        attachmentsCache?.attachments(eventNumber, circleId).orEmpty()
    }

    var editing by remember { mutableStateOf<EditTarget?>(null) }
    var draftName by remember { mutableStateOf("") }
    var draftCost by remember { mutableStateOf("") }
    var moving by remember { mutableStateOf<BuysCache.BuyItem?>(null) }
    var isAddMenuOpen by remember { mutableStateOf(false) }
    val nameFocus = remember { FocusRequester() }

    fun addShared(name: String, cost: Int): String? =
        session?.addItem(name, cost, circleId, circleName, circleSpace)

    fun finishEditing() {
        val target = editing ?: return
        editing = null
        val name = draftName.trim()
        val cost = draftCost.toIntOrNull() ?: 0
        if (name.isEmpty()) return
        when (target) {
            EditTarget.NewPersonal ->
                buysCache.addItem(circleId, eventNumber, BuysCache.BuyItem(name = name, cost = cost))
            EditTarget.NewShared -> addShared(name, cost)
            is EditTarget.Personal -> personal.firstOrNull { it.id == target.id }?.let {
                buysCache.updateItem(circleId, eventNumber, it.copy(name = name, cost = cost))
            }
            is EditTarget.Shared -> shared.firstOrNull { it.id == target.id }?.let {
                if (name != it.name) session?.rename(it.id, circleId, name)
                if (cost != it.cost) session?.setCost(it.id, circleId, cost)
            }
        }
    }

    fun begin(target: EditTarget, name: String = "", cost: Int = 0) {
        finishEditing()
        draftName = name
        draftCost = if (cost == 0) "" else cost.toString()
        editing = target
    }

    fun close() {
        finishEditing()
        focusManager.clearFocus()
        onClose()
    }

    fun applyPhoto(bytes: ByteArray, target: EditTarget) {
        when (target) {
            is EditTarget.Personal -> CoroutineScope(Dispatchers.Default).launch {
                BuyImageEncoder.webp(bytes)?.let { buysCache.setImage(target.id, it) }
            }
            is EditTarget.Shared -> session?.attachImage(target.id, circleId) { BuyImageEncoder.webp(bytes) }
            else -> Unit
        }
    }

    fun moveToShared(item: BuysCache.BuyItem) {
        val itemId = addShared(item.name, item.cost) ?: return
        if (item.status != BuysCache.STATUS_PENDING) session?.setStatus(itemId, circleId, item.status)
        buysCache.image(item.id)?.let { applyPhoto(it, EditTarget.Shared(itemId)) }
        buysCache.deleteItem(circleId, eventNumber, item.id)
    }

    /** A copy, not a move: removing something from a group list is what Delete is for. */
    fun copyToPersonal(item: SharedBuyItem) {
        val copy = buysCache.addItem(
            circleId,
            eventNumber,
            BuysCache.BuyItem(name = item.name, cost = item.cost, status = item.status)
        )
        session?.image(item)?.let { buysCache.setImage(copy.id, it) }
    }

    BackHandler(onBack = ::close)

    // Header, personal rows, the new personal row, header, shared rows, the new shared row.
    val editingIndex = when (val target = editing) {
        null -> null
        is EditTarget.Personal -> 1 + personal.indexOfFirst { it.id == target.id }
        EditTarget.NewPersonal -> 1 + personal.size
        is EditTarget.Shared -> 2 + personal.size + shared.indexOfFirst { it.id == target.id }
        EditTarget.NewShared -> 2 + personal.size + shared.size
    }
    LaunchedEffect(editing) {
        if (editing == null) return@LaunchedEffect
        editingIndex?.let { listState.animateScrollToItem(it) }
        nameFocus.requestFocus()
    }

    @Composable
    fun RowScope.fields() {
        OutlinedTextField(
            value = draftName,
            onValueChange = { draftName = it },
            placeholder = { Text(stringResource(R.string.buys_item_name_placeholder)) },
            modifier = Modifier.weight(1f).focusRequester(nameFocus),
            singleLine = true,
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next)
        )
        Spacer(modifier = Modifier.width(8.dp))
        OutlinedTextField(
            value = draftCost,
            onValueChange = { value -> draftCost = value.filter { it.isDigit() } },
            placeholder = { Text(stringResource(R.string.buys_item_cost_placeholder)) },
            modifier = Modifier.width(100.dp),
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = ImeAction.Done),
            keyboardActions = KeyboardActions(onDone = {
                finishEditing()
                focusManager.clearFocus()
            })
        )
    }

    Column(modifier = modifier.fillMaxSize().imePadding()) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = ::close) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, stringResource(R.string.back))
            }
            Text(
                text = stringResource(R.string.buys_edit_title),
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.weight(1f)
            )
            if (editing != null) {
                IconButton(onClick = {
                    finishEditing()
                    focusManager.clearFocus()
                }) {
                    Icon(Icons.Filled.Check, stringResource(R.string.buys_done))
                }
            } else {
                Box {
                    IconButton(onClick = {
                        if (hasShared) isAddMenuOpen = true else begin(EditTarget.NewPersonal)
                    }) {
                        Icon(Icons.Filled.Add, stringResource(R.string.buys_add_item))
                    }
                    DropdownMenu(expanded = isAddMenuOpen, onDismissRequest = { isAddMenuOpen = false }) {
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.buys_edit_add_to_mine)) },
                            onClick = {
                                isAddMenuOpen = false
                                begin(EditTarget.NewPersonal)
                            }
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.buys_add_item_shared)) },
                            onClick = {
                                isAddMenuOpen = false
                                begin(EditTarget.NewShared)
                            }
                        )
                    }
                }
            }
        }
        HorizontalDivider()
        LazyColumn(state = listState, modifier = Modifier.fillMaxSize()) {
            item { SectionTitle(stringResource(R.string.buys_section_title)) }
            items(personal, key = { it.id }) { item ->
                val target = EditTarget.Personal(item.id)
                EditRow(
                    photo = buysCache.image(item.id).takeIf { version >= 0 },
                    isEditing = editing == target,
                    name = item.name,
                    cost = item.cost,
                    attachments = attachments,
                    attachmentsCache = attachmentsCache,
                    onTap = { begin(target, item.name, item.cost) },
                    onPhoto = { applyPhoto(it, target) },
                    fields = { fields() }
                ) { dismiss ->
                    if (hasShared) {
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.buys_shared_move)) },
                            onClick = {
                                dismiss()
                                moving = item
                            }
                        )
                    }
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.buys_delete)) },
                        onClick = {
                            dismiss()
                            buysCache.deleteItem(circleId, eventNumber, item.id)
                        }
                    )
                }
            }
            item {
                if (editing == EditTarget.NewPersonal) {
                    Row(modifier = Modifier.fillMaxWidth().padding(16.dp, 6.dp)) { fields() }
                }
            }
            if (hasShared) {
                item { SectionTitle(stringResource(R.string.buys_shared_title)) }
                items(shared, key = { it.id }) { item ->
                    val target = EditTarget.Shared(item.id)
                    EditRow(
                        photo = session?.image(item),
                        isEditing = editing == target,
                        name = item.name,
                        cost = item.cost,
                        attachments = attachments,
                        attachmentsCache = attachmentsCache,
                        onTap = { begin(target, item.name, item.cost) },
                        onPhoto = { applyPhoto(it, target) },
                        fields = { fields() }
                    ) { dismiss ->
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.buys_shared_copy)) },
                            onClick = {
                                dismiss()
                                copyToPersonal(item)
                            }
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.buys_delete)) },
                            onClick = {
                                dismiss()
                                session?.remove(item.id, circleId)
                            }
                        )
                    }
                }
                item {
                    if (editing == EditTarget.NewShared) {
                        Row(modifier = Modifier.fillMaxWidth().padding(16.dp, 6.dp)) { fields() }
                    }
                }
            }
        }
    }

    moving?.let { item ->
        AlertDialog(
            onDismissRequest = { moving = null },
            title = { Text(stringResource(R.string.buys_shared_move_confirm)) },
            text = { Text(stringResource(R.string.buys_shared_visible)) },
            confirmButton = {
                TextButton(onClick = {
                    moving = null
                    moveToShared(item)
                }) {
                    Text(stringResource(R.string.buys_shared_move))
                }
            },
            dismissButton = {
                TextButton(onClick = { moving = null }) { Text(stringResource(R.string.cancel)) }
            }
        )
    }
}

@Composable
private fun SectionTitle(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.labelMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(start = 16.dp, top = 16.dp, bottom = 4.dp)
    )
}

@Composable
private fun EditRow(
    photo: ByteArray?,
    isEditing: Boolean,
    name: String,
    cost: Int,
    attachments: List<java.io.File>,
    attachmentsCache: AttachmentsCache?,
    onTap: () -> Unit,
    onPhoto: (ByteArray) -> Unit,
    fields: @Composable RowScope.() -> Unit,
    menu: @Composable (dismiss: () -> Unit) -> Unit
) {
    val context = LocalContext.current
    var isPhotoMenuOpen by remember { mutableStateOf(false) }
    var isRowMenuOpen by remember { mutableStateOf(false) }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) context.contentResolver.openInputStream(uri)?.use { onPhoto(it.readBytes()) }
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(enabled = !isEditing, onClick = onTap)
            .padding(horizontal = 16.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box {
            BuyPhoto(
                photo,
                Modifier.size(64.dp).clickable { isPhotoMenuOpen = true },
                stringResource(R.string.buys_shared_add_photo)
            )
            DropdownMenu(expanded = isPhotoMenuOpen, onDismissRequest = { isPhotoMenuOpen = false }) {
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.buys_shared_add_photo)) },
                    onClick = {
                        isPhotoMenuOpen = false
                        picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                    }
                )
                attachments.forEachIndexed { index, file ->
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.buys_attachment_number, index + 1)) },
                        leadingIcon = {
                            val bitmap = remember(file) { attachmentsCache?.load(file) }
                            bitmap?.let {
                                Image(it.asImageBitmap(), null, modifier = Modifier.size(32.dp))
                            }
                        },
                        onClick = {
                            isPhotoMenuOpen = false
                            onPhoto(file.readBytes())
                        }
                    )
                }
            }
        }
        Spacer(modifier = Modifier.width(10.dp))
        if (isEditing) {
            fields()
        } else {
            Text(name, modifier = Modifier.weight(1f))
            Text(
                text = stringResource(R.string.buys_cost_value, cost),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.End
            )
            Box {
                IconButton(onClick = { isRowMenuOpen = true }) {
                    Icon(Icons.Filled.MoreVert, stringResource(R.string.buys_more_actions, name))
                }
                DropdownMenu(expanded = isRowMenuOpen, onDismissRequest = { isRowMenuOpen = false }) {
                    menu { isRowMenuOpen = false }
                }
            }
        }
    }
}
