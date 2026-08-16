package com.tsubuzaki.circlesgo.ui.more

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.state.Unifier

private data class Dependency(val name: String, val license: String)

private val dependencies = listOf(
    Dependency(
        "AndroidX / Jetpack Compose",
        "Copyright The Android Open Source Project\n\n" +
            "Licensed under the Apache License, Version 2.0 (the \"License\"); " +
            "you may not use this file except in compliance with the License. " +
            "You may obtain a copy of the License at\n\n" +
            "    http://www.apache.org/licenses/LICENSE-2.0"
    ),
    Dependency(
        "Kotlin / kotlinx.serialization / kotlinx.coroutines",
        "Copyright 2010-2024 JetBrains s.r.o. and respective authors and developers\n\n" +
            "Licensed under the Apache License, Version 2.0 (the \"License\"); " +
            "you may not use this file except in compliance with the License. " +
            "You may obtain a copy of the License at\n\n" +
            "    http://www.apache.org/licenses/LICENSE-2.0"
    ),
    Dependency(
        "Material Components for Android",
        "Copyright The Android Open Source Project\n\n" +
            "Licensed under the Apache License, Version 2.0 (the \"License\"); " +
            "you may not use this file except in compliance with the License. " +
            "You may obtain a copy of the License at\n\n" +
            "    http://www.apache.org/licenses/LICENSE-2.0"
    ),
    Dependency(
        "AndroidX Browser (Custom Tabs)",
        "Copyright The Android Open Source Project\n\n" +
            "Licensed under the Apache License, Version 2.0 (the \"License\"); " +
            "you may not use this file except in compliance with the License. " +
            "You may obtain a copy of the License at\n\n" +
            "    http://www.apache.org/licenses/LICENSE-2.0"
    )
)

/**
 * Open source attributions, mirroring the iOS MoreLicensesView.
 */
@Composable
fun LicensesView(unifier: Unifier) {
    Column(modifier = Modifier.fillMaxSize()) {
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
                text = stringResource(R.string.attributions_title),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(
                horizontal = 16.dp,
                vertical = 8.dp
            )
        ) {
            items(dependencies, key = { it.name }) { dependency ->
                Text(
                    text = dependency.name,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(top = 12.dp, bottom = 4.dp)
                )
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = MaterialTheme.shapes.medium,
                    color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                ) {
                    Text(
                        text = dependency.license,
                        style = MaterialTheme.typography.bodySmall,
                        fontFamily = FontFamily.Monospace,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(12.dp)
                    )
                }
                Spacer(modifier = Modifier.height(4.dp))
            }
        }
    }
}
