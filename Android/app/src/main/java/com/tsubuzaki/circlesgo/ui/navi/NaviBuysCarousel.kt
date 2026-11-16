package com.tsubuzaki.circlesgo.ui.navi

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.data.local.BuysCache
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuyItem
import com.tsubuzaki.circlesgo.ui.buys.BuyItemTile
import com.tsubuzaki.circlesgo.ui.shared.LocalSharedBuys
import com.tsubuzaki.circlesgo.ui.sharedbuys.SharedBuyTile

/** The Buys at the circle the route is heading to, with the same actions as in the Buys tab. */
@Composable
fun NaviBuysCarousel(circleID: Int, eventNumber: Int, buysCache: BuysCache) {
    val buysVersion by buysCache.version.collectAsState()
    val ownItems = buysCache.entry(circleID, eventNumber)?.items
        ?.filter { it.name.isNotBlank() }
        ?.sortedBy { it.sortOrder }
        .orEmpty()
        .takeIf { buysVersion >= 0 }
        .orEmpty()
    val session = LocalSharedBuys.current?.takeIf { it.isActive }
    val sharedItems = session?.items?.filter { it.circleId == circleID }.orEmpty()
    if (ownItems.isEmpty() && sharedItems.isEmpty()) return

    val tiles: List<Any> = ownItems + sharedItems
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(26.dp))
            .background(MaterialTheme.colorScheme.surfaceContainerHigh)
    ) {
        LazyRow(
            contentPadding = PaddingValues(horizontal = 14.dp, vertical = 14.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(tiles) { tile ->
                Box(modifier = Modifier.width(96.dp)) {
                    if (tile is BuysCache.BuyItem) {
                        BuyItemTile(
                            name = tile.name,
                            cost = tile.cost,
                            photo = buysCache.image(tile.id),
                            status = tile.status,
                            onTap = {
                                buysCache.updateItem(
                                    circleID, eventNumber,
                                    tile.copy(status = BuysCache.nextStatus(tile.status))
                                )
                            }
                        )
                    } else if (tile is SharedBuyItem && session != null) {
                        SharedBuyTile(session, tile)
                    }
                }
            }
        }
    }
}
