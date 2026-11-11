import AXiS
import SwiftUI

/// The circle the route is heading to, shown on every step so the visitor always knows
/// where the directions lead.
struct NaviUpcomingCircle: View {

    @Environment(Database.self) var database
    @Environment(Favorites.self) var favorites

    let stop: RouteStop
    let isArrival: Bool

    @State var circle: ComiketCircle?

    var favoriteMemo: String {
        guard let webCatalogID = circle?.extendedInformation?.webCatalogID else { return "" }
        let memo = favorites.wcIDMappedItems?[webCatalogID]?.favorite.memo ?? ""
        return memo.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12.0) {
            UnifiedRouteCircleCut(circle: circle)
            VStack(alignment: .leading, spacing: 8.0) {
                VStack(alignment: .leading, spacing: 6.0) {
                    CircleBlockPill(LocalizedStringKey(stop.spaceName))
                    Text(stop.name)
                        .font(.headline)
                        .lineLimit(2)
                }
                if !favoriteMemo.isEmpty {
                    InfoStackSection(
                        title: "Shared.Memo.Favorites",
                        contents: favoriteMemo,
                        canTranslate: false,
                        showContextMenu: false
                    )
                    .lineLimit(3)
                }
                Spacer(minLength: 0.0)
                if isArrival {
                    NaviMarkVisitedButton()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80.0, alignment: .topLeading)
        }
        .padding(12.0)
        .background(.fill.quaternary, in: .rect(cornerRadius: 26.0))
        .padding(.horizontal, -3.5)
        .task(id: stop.circleID) {
            circle = database.circles([stop.circleID]).first
        }
    }
}
