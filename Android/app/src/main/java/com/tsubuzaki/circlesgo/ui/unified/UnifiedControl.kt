package com.tsubuzaki.circlesgo.ui.unified

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.tables.ComiketDate
import com.tsubuzaki.circlesgo.database.tables.ComiketMap
import com.tsubuzaki.circlesgo.state.UserSelections
import java.text.SimpleDateFormat
import java.util.Locale

@Composable
fun UnifiedControl(
    database: CatalogDatabase,
    selections: UserSelections
) {
    val selectedDate by selections.date.collectAsState()
    val selectedMap by selections.map.collectAsState()

    if (selectedDate != null && selectedMap != null) {
        DatePickerButton(
            selectedDate = selectedDate,
            database = database,
            onDateSelected = { selections.setDate(it) }
        )
        Spacer(modifier = Modifier.width(8.dp))
        HallPickerButton(
            selectedMap = selectedMap,
            database = database,
            onMapSelected = { selections.setMap(it) }
        )
    }
}

@Composable
private fun DatePickerButton(
    selectedDate: ComiketDate?,
    database: CatalogDatabase,
    onDateSelected: (ComiketDate) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    val dates = remember { database.dates() }
    val dateFormatter = remember { SimpleDateFormat("yyyy/MM/dd", Locale.getDefault()) }

    TextButton(
        modifier = Modifier
            .clip(CircleShape),
        onClick = { expanded = true }
    ) {
        Column {
            selectedDate?.let { date ->
                Text(
                    text = stringResource(R.string.day_format, date.id),
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = dateFormatter.format(date.date),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            } ?: Text(stringResource(R.string.no_day))
        }
    }

    DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
        for (date in dates) {
            DropdownMenuItem(
                text = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(stringResource(R.string.day_format, date.id))
                        if (date == selectedDate) {
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("✓", fontSize = 12.sp)
                        }
                    }
                },
                onClick = {
                    onDateSelected(date)
                    expanded = false
                }
            )
        }
    }
}

@Composable
private fun HallPickerButton(
    selectedMap: ComiketMap?,
    database: CatalogDatabase,
    onMapSelected: (ComiketMap) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    val maps = remember { database.maps() }
    val accentColor = accentColorForMap(selectedMap)

    TextButton(
        modifier = Modifier
            .clip(CircleShape)
            .background(accentColor)
            .padding(horizontal = 4.dp),
        onClick = { expanded = true },
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(horizontal = 4.dp)
        ) {
            Text(
                text = selectedMap?.name ?: stringResource(R.string.no_hall),
                color = Color.White,
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp
            )
        }
    }

    DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
        for (map in maps) {
            DropdownMenuItem(
                text = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(map.name)
                        if (map == selectedMap) {
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("✓", fontSize = 12.sp)
                        }
                    }
                },
                onClick = {
                    onMapSelected(map)
                    expanded = false
                }
            )
        }
    }
}

private fun accentColorForMap(map: ComiketMap?): Color {
    if (map != null) {
        return when {
            map.name.startsWith("東") -> Color.hsv(358f, 0.77f, 0.78f)
            map.name.startsWith("西") -> Color.hsv(215f, 0.77f, 0.59f)
            map.name.startsWith("南") -> Color.hsv(120f, 0.56f, 0.47f)
            map.name.startsWith("会") -> Color.hsv(34f, 0.16f, 0.50f)
            else -> Color.Unspecified
        }
    }
    return Color.Unspecified
}
