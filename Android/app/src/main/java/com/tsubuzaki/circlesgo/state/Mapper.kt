package com.tsubuzaki.circlesgo.state

import android.graphics.PointF
import android.graphics.RectF
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.database.tables.LayoutCatalogMapping
import com.tsubuzaki.circlesgo.database.types.LayoutType
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class Mapper {
    typealias Layouts = Map<LayoutCatalogMapping, List<Int>>

    // Canvas info
    private val _canvasWidth = MutableStateFlow(0.dp)
    val canvasWidth: StateFlow<Dp> = _canvasWidth

    private val _canvasHeight = MutableStateFlow(0.dp)
    val canvasHeight: StateFlow<Dp> = _canvasHeight

    // Layout (interactive) layer
    private val _layouts = MutableStateFlow<Layouts>(emptyMap())
    val layouts: StateFlow<Layouts> = _layouts

    // Popover layer
    val popoverWidth: Float = 240f
    val popoverHeight: Float = (16f * 2) + (65f * 2) + 8f
    val popoverDistance: Float = 8f
    val popoverEdgePadding: Float = 8f

    private val _popoverData = MutableStateFlow<PopoverData?>(null)
    val popoverData: StateFlow<PopoverData?> = _popoverData

    private val _popoverPosition = MutableStateFlow<PointF?>(null)
    val popoverPosition: StateFlow<PointF?> = _popoverPosition

    private val _scrollToPosition = MutableStateFlow<PointF?>(null)
    val scrollToPosition: StateFlow<PointF?> = _scrollToPosition

    // Highlight layer
    private val _highlightData = MutableStateFlow<HighlightData?>(null)
    val highlightData: StateFlow<HighlightData?> = _highlightData

    private val _highlightTarget = MutableStateFlow<ComiketCircle?>(null)
    val highlightTarget: StateFlow<ComiketCircle?> = _highlightTarget

    fun setCanvasSize(width: Dp, height: Dp) {
        _canvasWidth.value = width
        _canvasHeight.value = height
    }

    fun setLayouts(layouts: Layouts) {
        _layouts.value = layouts
    }

    fun removeAllLayouts() {
        _layouts.value = emptyMap()
    }

    fun setPopoverData(data: PopoverData?) {
        _popoverData.value = data
    }

    fun setPopoverPosition(position: PointF?) {
        _popoverPosition.value = position
    }

    fun setScrollToPosition(position: PointF?) {
        _scrollToPosition.value = position
    }

    fun clearScrollToPosition() {
        _scrollToPosition.value = null
    }

    fun setHighlightData(data: HighlightData?) {
        _highlightData.value = data
    }

    fun setHighlightTarget(target: ComiketCircle?) {
        _highlightTarget.value = target
    }

    fun highlightCircle(spaceSize: Int): Boolean {
        val circle = _highlightTarget.value ?: return false
        val blockID = circle.blockID
        val spaceNumber = circle.spaceNumber
        val spaceNumberSuffix = circle.spaceNumberSuffix

        val entry = _layouts.value.entries.firstOrNull { (layout, _) ->
            layout.blockID == blockID && layout.spaceNumber == spaceNumber
        } ?: return false

        val layout = entry.key
        val webCatalogIDs = entry.value
        val count = webCatalogIDs.size
        if (count == 0) return false

        val xMin = layout.positionX.toFloat()
        val yMin = layout.positionY.toFloat()
        val scaledSpaceSize = spaceSize.toFloat()

        var circleIndex = spaceNumberSuffix
        if (layout.layoutType == LayoutType.A_ON_BOTTOM || layout.layoutType == LayoutType.A_ON_RIGHT) {
            circleIndex = count - 1 - spaceNumberSuffix
        }

        val highlightRect: RectF = when (layout.layoutType) {
            LayoutType.A_ON_LEFT, LayoutType.A_ON_RIGHT, LayoutType.UNKNOWN -> {
                val rectWidth = scaledSpaceSize / count.toFloat()
                RectF(
                    xMin + circleIndex * rectWidth,
                    yMin,
                    xMin + circleIndex * rectWidth + rectWidth,
                    yMin + scaledSpaceSize
                )
            }

            LayoutType.A_ON_TOP, LayoutType.A_ON_BOTTOM -> {
                val rectHeight = scaledSpaceSize / count.toFloat()
                RectF(
                    xMin,
                    yMin + circleIndex * rectHeight,
                    xMin + scaledSpaceSize,
                    yMin + circleIndex * rectHeight + rectHeight
                )
            }
        }

        val scrollPosition = PointF(highlightRect.centerX(), highlightRect.centerY())

        _popoverData.value = null
        _scrollToPosition.value = scrollPosition
        _highlightData.value = HighlightData(
            sourceRect = highlightRect,
            shouldBlink = true
        )

        return true
    }
}
