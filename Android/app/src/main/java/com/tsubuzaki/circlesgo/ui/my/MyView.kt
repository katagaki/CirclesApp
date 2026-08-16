package com.tsubuzaki.circlesgo.ui.my

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.api.catalog.UserAPI
import com.tsubuzaki.circlesgo.api.catalog.UserInfo
import com.tsubuzaki.circlesgo.auth.Authenticator
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.state.Events
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.ui.shared.LocalDemoMode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.Locale

// Participation values shared with the iOS app
private val participationOptions = listOf(
    "" to R.string.my_participation_none,
    "Early" to R.string.my_participation_early,
    "ChangingRoom" to R.string.my_participation_changing_room,
    "AM" to R.string.my_participation_am,
    "PM" to R.string.my_participation_pm,
    "Circle" to R.string.my_participation_circle
)

/**
 * "My" page: circle.ms profile and per-day participation planning,
 * mirroring the iOS MyView.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MyView(
    database: CatalogDatabase,
    events: Events,
    authenticator: Authenticator,
    unifier: Unifier
) {
    val isDemo = LocalDemoMode.current
    val token by authenticator.token.collectAsState()

    var userInfo by remember { mutableStateOf<UserInfo.Response?>(null) }
    var isLoaded by remember { mutableStateOf(false) }
    var eventTitle by remember { mutableStateOf<String?>(null) }
    var eventDates by remember { mutableStateOf<List<com.tsubuzaki.circlesgo.database.tables.ComiketDate>>(emptyList()) }
    // Bumped to re-read participation after a change
    var participationVersion by remember { mutableIntStateOf(0) }

    LaunchedEffect(token, isDemo) {
        withContext(Dispatchers.IO) {
            eventTitle = database.events()
                .firstOrNull { it.eventNumber == events.activeEventNumber }?.name
            eventDates = database.dates()
            if (!isDemo) {
                token?.let { userInfo = UserAPI.info(it) }
            }
            isLoaded = true
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
    ) {
        // Top bar
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
                text = eventTitle
                    ?: stringResource(R.string.comic_market_format, events.activeEventNumber),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }

        if (!isLoaded) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(32.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = stringResource(R.string.my_loading),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        } else {
            // Profile section
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Box(
                    modifier = Modifier
                        .size(96.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primaryContainer),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Filled.Person,
                        contentDescription = null,
                        modifier = Modifier.size(48.dp),
                        tint = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = when {
                        isDemo -> stringResource(R.string.my_demo_user)
                        userInfo != null -> userInfo!!.nickname
                        else -> stringResource(R.string.my_loading)
                    },
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Black
                )
                userInfo?.let {
                    Text(
                        text = "PID: ${it.pid}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Participation section
            Text(
                text = stringResource(R.string.my_participation_header),
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 4.dp)
            )

            val dateFormatter = remember { SimpleDateFormat("yyyy/MM/dd", Locale.getDefault()) }
            for (date in eventDates) {
                Surface(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 4.dp),
                    shape = MaterialTheme.shapes.medium,
                    color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = stringResource(
                                    R.string.my_participation_day_format, date.id
                                ),
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = dateFormatter.format(date.date),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        // Read participation (recomputed when version changes)
                        val currentParticipation = remember(participationVersion, date.id) {
                            events.participationInfo(date.id) ?: ""
                        }
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            for ((value, labelRes) in participationOptions) {
                                FilterChip(
                                    selected = currentParticipation == value,
                                    onClick = {
                                        events.setParticipation(date.id, value)
                                        participationVersion += 1
                                    },
                                    label = { Text(stringResource(labelRes)) }
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}
