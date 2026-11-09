import SwiftUI

struct TodayCardView: View {

    let kind: TodayCardKind

    var body: some View {
        switch kind {
        case .guest: GuestBanner()
        case .route: TodayRouteCard()
        case .sharedBuys: TodaySharedBuysCard()
        case .favorites: TodayFavoritesCard()
        case .buys: TodayBuysCard()
        case .readiness: TodayReadinessCard()
        }
    }
}
