package com.tsubuzaki.circlesgo.state

import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class Unifier {
    private val _isPresenting = MutableStateFlow(false)
    val isPresenting: StateFlow<Boolean> = _isPresenting

    private val _sidebarPosition = MutableStateFlow(SidebarPosition.LEADING)
    val sidebarPosition: StateFlow<SidebarPosition> = _sidebarPosition

    private val _currentPath = MutableStateFlow<UnifiedPath?>(UnifiedPath.CIRCLES)
    val currentPath: StateFlow<UnifiedPath?> = _currentPath

    private val _sheetPath = MutableStateFlow<List<UnifiedPath>>(emptyList())
    val sheetPath: StateFlow<List<UnifiedPath>> = _sheetPath

    private val _isMyComiketPresenting = MutableStateFlow(false)
    val isMyComiketPresenting: StateFlow<Boolean> = _isMyComiketPresenting

    private val _isGoingToSignOut = MutableStateFlow(false)
    val isGoingToSignOut: StateFlow<Boolean> = _isGoingToSignOut

    private val _selectedCircle = MutableStateFlow<ComiketCircle?>(null)
    val selectedCircle: StateFlow<ComiketCircle?> = _selectedCircle

    private val _isSearchActive = MutableStateFlow(false)
    val isSearchActive: StateFlow<Boolean> = _isSearchActive

    // Incremented to ask the sheet to collapse to its partial height
    // (e.g. after tapping Show on Map in the circle detail view)
    private val _sheetCollapseRequest = MutableStateFlow(0)
    val sheetCollapseRequest: StateFlow<Int> = _sheetCollapseRequest

    fun requestSheetCollapse() {
        _sheetCollapseRequest.value += 1
    }

    fun show() {
        _isPresenting.value = true
    }

    fun hide() {
        _isPresenting.value = false
    }

    fun close() {
        _isPresenting.value = false
        _currentPath.value = null
        _sheetPath.value = emptyList()
    }

    fun setCurrentPath(path: UnifiedPath?) {
        _currentPath.value = path
    }

    fun append(newPath: UnifiedPath) {
        // After close() the tab selection is null; restore the default tab so
        // pushed content renders on top of the tab row instead of replacing it
        if (_currentPath.value == null) {
            _currentPath.value = UnifiedPath.CIRCLES
        }
        _sheetPath.value = _sheetPath.value + newPath
        _isPresenting.value = true
    }

    fun popSheetPath() {
        val current = _sheetPath.value
        if (current.isNotEmpty()) {
            _sheetPath.value = current.dropLast(1)
        }
    }

    fun setIsMyComiketPresenting(value: Boolean) {
        _isMyComiketPresenting.value = value
    }

    fun setIsGoingToSignOut(value: Boolean) {
        _isGoingToSignOut.value = value
    }

    fun showCircleDetail(circle: ComiketCircle) {
        _selectedCircle.value = circle
        append(UnifiedPath.CIRCLE_DETAIL)
    }

    fun clearCircleDetail() {
        _selectedCircle.value = null
    }

    fun clearSheetContent() {
        _sheetPath.value = emptyList()
        _selectedCircle.value = null
    }

    fun setIsSearchActive(value: Boolean) {
        _isSearchActive.value = value
    }

    fun hasSheetContent(): Boolean {
        return _sheetPath.value.isNotEmpty()
    }

    fun toggleSidebarPosition() {
        _sidebarPosition.value = if (_sidebarPosition.value == SidebarPosition.LEADING) {
            SidebarPosition.TRAILING
        } else {
            SidebarPosition.LEADING
        }
    }
}
