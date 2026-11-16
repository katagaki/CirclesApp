package com.tsubuzaki.circlesgo.ui.shared

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextDecoration
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle

@Composable
fun CircleNameText(
    circle: ComiketCircle,
    style: TextStyle,
    modifier: Modifier = Modifier
) {
    val visitsState = LocalVisitsState.current
    val events = LocalEvents.current
    val isVisited = if (visitsState != null && events != null) {
        val visits by visitsState.visits.collectAsState()
        visits.any {
            it.circleID == circle.id && it.eventNumber == events.activeEventNumber
        }
    } else {
        false
    }

    Text(
        text = circle.circleName,
        style = style,
        textDecoration = if (isVisited) TextDecoration.LineThrough else null,
        modifier = if (isVisited) modifier.alpha(0.6f) else modifier
    )
}
