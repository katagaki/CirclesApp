package com.tsubuzaki.circlesgo.state

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class Oasis {

    private val _isShowing = MutableStateFlow(false)
    val isShowing: StateFlow<Boolean> = _isShowing

    private val _headerText = MutableStateFlow<String?>(null)
    val headerText: StateFlow<String?> = _headerText

    private val _bodyText = MutableStateFlow<String?>(null)
    val bodyText: StateFlow<String?> = _bodyText

    private val _progress = MutableStateFlow<Double?>(null)
    val progress: StateFlow<Double?> = _progress

    fun setHeaderText(text: String?) {
        _headerText.value = text
    }

    fun setBodyText(text: String?) {
        _bodyText.value = text
    }

    fun setProgress(progress: Double?) {
        _progress.value = progress
    }

    fun open() {
        _headerText.value = null
        _bodyText.value = null
        _progress.value = null
        _isShowing.value = true
    }

    fun close() {
        _isShowing.value = false
        _headerText.value = null
        _bodyText.value = null
        _progress.value = null
    }
}
