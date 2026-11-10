import SwiftData
import SwiftUI
import AXiS

struct MapVisitedLayer: View {

    @Environment(\.colorScheme) var colorScheme
    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(Favorites.self) var favorites
    @Environment(Mapper.self) var mapper
    @Environment(Navigator.self) var navigator

    @Query var visits: [CirclesVisitEntry]

    @State var favoritePath: Path = Path()
    @State var plainPath: Path = Path()

    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool

    let spaceSize: Int

    var isMapInverted: Bool {
        useDarkModeMaps && colorScheme == .dark
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            favoritePath
                .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .shadow(color: .black, radius: 2)
            plainPath
                .stroke(isMapInverted ? .black : .white,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            plainPath
                .stroke(isMapInverted ? .white : .black,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
        .frame(width: mapper.canvasSize.width, height: mapper.canvasSize.height)
        .allowsHitTesting(false)
        .task {
            await reloadVisits()
        }
        .onChange(of: mapper.layouts) {
            Task.detached {
                await reloadVisits()
            }
        }
        .onChange(of: visits) {
            Task.detached {
                await reloadVisits()
            }
        }
        .onChange(of: favorites.items) {
            Task.detached {
                await reloadVisits()
            }
        }
        .onChange(of: routeStopIDs) {
            Task.detached {
                await reloadVisits()
            }
        }
    }

    /// A route's own badges tick off the stops it has passed, so the map leaves those
    /// spaces alone while the route is up rather than ticking them twice.
    var routeStopIDs: Set<Int> {
        Set(navigator.route?.stops.map(\.id) ?? [])
    }

    func reloadVisits() async {
        let actor = DataFetcher(database: database.getTextDatabase())

        let currentEventNumber = planner.activeEventNumber
        let validVisits = visits.filter { $0.eventNumber == currentEventNumber }
        let circleIDs = validVisits.map { $0.circleID }

        if circleIDs.isEmpty {
            await MainActor.run {
                withAnimation {
                    self.favoritePath = Path()
                    self.plainPath = Path()
                }
            }
            return
        }

        let webCatalogIDs = await actor.webCatalogIDs(forCircleIDs: circleIDs)
        let visitedWCIDSet = Set(webCatalogIDs).subtracting(await MainActor.run { routeStopIDs })
        let favoriteWCIDSet = Set(await MainActor.run { favorites.wcIDMappedItems?.keys.map { $0 } ?? [] })

        let allLayoutWCIDs = Array(Set(mapper.layouts.values.flatMap { $0 }))
        let spaceNumberSuffixes = await actor.spaceNumberSuffixes(forWebCatalogIDs: allLayoutWCIDs)

        var newFavoritePath = Path()
        var newPlainPath = Path()

        for (layout, layoutWCIDs) in mapper.layouts {
            let sortedIDs = layoutWCIDs.sorted {
                let lhsSuffix = spaceNumberSuffixes[$0] ?? 0
                let rhsSuffix = spaceNumberSuffixes[$1] ?? 0
                return lhsSuffix < rhsSuffix
            }
            let orderedIDs: [Int]
            switch layout.layoutType {
            case .aOnBottom, .aOnRight:
                orderedIDs = sortedIDs.reversed()
            default:
                orderedIDs = sortedIDs
            }

            let count = orderedIDs.count
            guard count > 0 else { continue }

            for (index, id) in orderedIDs.enumerated() where visitedWCIDSet.contains(id) {
                let rect = getGenericRect(layout: layout, index: index, total: count)
                let checkmark = checkmarkPath(in: rect)
                if favoriteWCIDSet.contains(id) {
                    newFavoritePath.addPath(checkmark)
                } else {
                    newPlainPath.addPath(checkmark)
                }
            }
        }

        let finalFavoritePath = newFavoritePath
        let finalPlainPath = newPlainPath
        await MainActor.run {
            withAnimation(.smooth.speed(2.0)) {
                self.favoritePath = finalFavoritePath
                self.plainPath = finalPlainPath
            }
        }
    }

    func getGenericRect(layout: LayoutCatalogMapping, index: Int, total: Int) -> CGRect {
        let rectWidth: CGFloat
        let rectHeight: CGFloat
        let castSpaceSize = CGFloat(spaceSize)

        switch layout.layoutType {
        case .aOnLeft, .aOnRight, .unknown:
            rectWidth = castSpaceSize / CGFloat(total)
            rectHeight = castSpaceSize
        case .aOnTop, .aOnBottom:
            rectWidth = castSpaceSize
            rectHeight = castSpaceSize / CGFloat(total)
        }

        let baseX = CGFloat(layout.positionX)
        let baseY = CGFloat(layout.positionY)
        let idx = CGFloat(index)

        if layout.layoutType == .aOnLeft || layout.layoutType == .aOnRight || layout.layoutType == .unknown {
            return CGRect(x: baseX + idx * rectWidth, y: baseY, width: rectWidth, height: rectHeight)
        } else {
            return CGRect(x: baseX, y: baseY + idx * rectHeight, width: rectWidth, height: rectHeight)
        }
    }

    func checkmarkPath(in rect: CGRect) -> Path {
        var path = Path()

        let sideLength = min(rect.width, rect.height)
        let xOffset = rect.minX + (rect.width - sideLength) / 2
        let yOffset = rect.minY + (rect.height - sideLength) / 2
        let square = CGRect(x: xOffset, y: yOffset, width: sideLength, height: sideLength)

        let start = CGPoint(x: square.minX + square.width * 0.20, y: square.minY + square.height * 0.50)
        let mid = CGPoint(x: square.minX + square.width * 0.45, y: square.minY + square.height * 0.80)
        let end = CGPoint(x: square.minX + square.width * 0.80, y: square.minY + square.height * 0.20)
        path.move(to: start)
        path.addLine(to: mid)
        path.addLine(to: end)

        return path
    }
}
