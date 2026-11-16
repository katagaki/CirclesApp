package com.tsubuzaki.circlesgo.ui.buys

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.data.local.BuysCache
import com.tsubuzaki.circlesgo.ui.sharedbuys.MemberInitial

data class BuysOnboardingHeroItem(val tint: Color, val symbol: ImageVector, val cost: Int, val buyer: Int)

@Composable
fun BuysOnboardingHeroTile(item: BuysOnboardingHeroItem, buyer: String, isBought: Boolean, isAssigned: Boolean, modifier: Modifier) {
    val dim by animateFloatAsState(
        targetValue = if (isBought) 0.3f else 0f,
        animationSpec = tween(350),
        label = "dim"
    )
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .clip(RoundedCornerShape(10.dp))
                .background(item.tint.copy(alpha = 0.25f))
        ) {
            Icon(
                imageVector = item.symbol,
                contentDescription = null,
                tint = item.tint,
                modifier = Modifier
                    .align(Alignment.Center)
                    .size(28.dp)
            )
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = dim))
            )
            BuyStatusBadge(
                status = if (isBought) BuysCache.STATUS_BOUGHT else BuysCache.STATUS_PENDING,
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(6.dp)
            )
            BuysOnboardingPopIn(
                isShown = isAssigned,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(6.dp)
            ) {
                MemberInitial(nickname = buyer, size = 22)
            }
        }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(end = 12.dp)
                .height(8.dp)
                .background(MaterialTheme.colorScheme.outlineVariant, CircleShape)
        )
        Text(
            text = stringResource(R.string.buys_quick_cost, item.cost),
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontFamily = FontFamily.Monospace
        )
    }
}
