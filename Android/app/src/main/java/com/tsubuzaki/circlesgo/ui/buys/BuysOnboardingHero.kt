package com.tsubuzaki.circlesgo.ui.buys

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.Photo
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.ui.sharedbuys.MemberInitial
import kotlinx.coroutines.delay

private val heroMembers = listOf("H", "U", "K")

private val heroItems = listOf(
    BuysOnboardingHeroItem(Color(0xFFAF52DE), Icons.Filled.Book, 500, 0),
    BuysOnboardingHeroItem(Color(0xFF007AFF), Icons.Filled.Photo, 1000, 1),
    BuysOnboardingHeroItem(Color(0xFFFFCC00), Icons.Filled.AutoAwesome, 1500, 2)
)

/**
 * A shared list drawn the way the Buys grid draws one: members join, then each item is
 * assigned and ticked off in turn while the group total fills in.
 */
@Composable
fun BuysOnboardingHero(cardColor: Color, modifier: Modifier = Modifier) {
    var joinedCount by rememberSaveable { mutableIntStateOf(0) }
    var boughtCount by rememberSaveable { mutableIntStateOf(0) }
    val total = heroItems.take(boughtCount).sumOf { it.cost }

    LaunchedEffect(Unit) {
        if (joinedCount != 0 || boughtCount != 0) return@LaunchedEffect
        delay(400)
        repeat(heroMembers.size) {
            joinedCount += 1
            delay(300)
        }
        delay(300)
        repeat(heroItems.size) {
            boughtCount += 1
            delay(600)
        }
    }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(cardColor, RoundedCornerShape(20.dp))
            .padding(18.dp)
            .clearAndSetSemantics {},
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Row {
            heroMembers.forEachIndexed { index, nickname ->
                BuysOnboardingPopIn(
                    isShown = index < joinedCount,
                    modifier = Modifier.offset(x = (-8 * index).dp)
                ) {
                    Box(
                        modifier = Modifier
                            .border(2.dp, cardColor, CircleShape)
                    ) {
                        MemberInitial(nickname = nickname, size = 28)
                    }
                }
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            heroItems.forEachIndexed { index, item ->
                BuysOnboardingHeroTile(
                    item = item,
                    buyer = heroMembers[item.buyer],
                    isBought = index < boughtCount,
                    isAssigned = index < joinedCount,
                    modifier = Modifier.weight(1f)
                )
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .width(72.dp)
                    .height(10.dp)
                    .background(MaterialTheme.colorScheme.outlineVariant, CircleShape)
            )
            Spacer(modifier = Modifier.weight(1f))
            AnimatedContent(
                targetState = total,
                transitionSpec = {
                    (slideInVertically { it } + fadeIn()).togetherWith(slideOutVertically { -it } + fadeOut())
                },
                label = "total"
            ) { value ->
                Text(
                    text = stringResource(R.string.buys_quick_cost, value),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    fontFamily = FontFamily.Monospace
                )
            }
        }
    }
}
