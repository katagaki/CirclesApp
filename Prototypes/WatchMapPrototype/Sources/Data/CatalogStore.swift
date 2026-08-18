import Foundation
import Observation
import SwiftUI
import UIKit

@Observable
@MainActor
final class CatalogStore {

    private(set) var days: [EventDay] = []
    private(set) var maps: [HallMap] = []
    private(set) var favorites: [Favorite] = []
    var buys: [BuyItem] = []
    var visitedIDs: Set<Int> = []

    private var textDB: CatalogDB?
    private var imageDB: CatalogDB?

    private var blocks: [Int: String] = [:]
    private var layouts: [SpaceKey: SpaceLayout] = [:]
    private var layoutsByMap: [Int: [SpaceLayout]] = [:]
    private var circlesBySpace: [OccupantKey: [CatalogCircle]] = [:]
    private var imageCache: [String: UIImage] = [:]

    struct SpaceKey: Hashable {
        let blockID: Int
        let spaceNumber: Int
    }

    struct OccupantKey: Hashable {
        let day: Int
        let blockID: Int
        let spaceNumber: Int
    }

    func load() {
        guard let textPath = Bundle.main.path(forResource: "webcatalog999", ofType: "db") else {
            return
        }
        textDB = CatalogDB(path: textPath)
        if let imagePath = Bundle.main.path(forResource: "webcatalog999Image1", ofType: "db") {
            imageDB = CatalogDB(path: imagePath)
        }

        loadDays()
        loadMaps()
        loadBlocks()
        loadLayouts()
        loadCircles()
        buildDemoFavorites()
        buildDemoBuys()
        visitedIDs = SharedState.visitedIDs
        if let seed = UserDefaults.standard.string(forKey: "Prototype.VisitFirst").flatMap({ Int($0) }) {
            visitedIDs.formUnion(favorites(on: SharedState.day).prefix(seed).map { $0.id })
        }
    }

    private func loadDays() {
        var result: [EventDay] = []
        textDB?.rows("SELECT id, year, month, day FROM ComiketDateWC ORDER BY id") { row in
            result.append(EventDay(id: row.int(0), year: row.int(1), month: row.int(2), day: row.int(3)))
        }
        days = result
    }

    private func loadMaps() {
        var result: [HallMap] = []
        textDB?.rows("SELECT id, name, filename, w2, h2 FROM ComiketMapWC ORDER BY id") { row in
            result.append(
                HallMap(
                    id: row.int(0),
                    name: row.string(1),
                    filename: row.string(2),
                    size: CGSize(width: row.int(3), height: row.int(4))
                )
            )
        }
        maps = result
    }

    private func loadBlocks() {
        var result: [Int: String] = [:]
        textDB?.rows("SELECT id, name FROM ComiketBlockWC") { row in
            result[row.int(0)] = row.string(1)
        }
        blocks = result
    }

    private func loadLayouts() {
        var result: [SpaceKey: SpaceLayout] = [:]
        var byMap: [Int: [SpaceLayout]] = [:]
        textDB?.rows("SELECT blockId, spaceNo, xpos2, ypos2, layout, mapId FROM ComiketLayoutWC") { row in
            let key = SpaceKey(blockID: row.int(0), spaceNumber: row.int(1))
            let layout = SpaceLayout(
                blockID: row.int(0),
                spaceNumber: row.int(1),
                position: CGPoint(x: row.int(2), y: row.int(3)),
                layoutType: LayoutType(rawValue: row.int(4)) ?? .unknown,
                mapID: row.int(5)
            )
            result[key] = layout
            byMap[layout.mapID, default: []].append(layout)
        }
        layouts = result
        layoutsByMap = byMap
    }

    private func loadCircles() {
        var result: [OccupantKey: [CatalogCircle]] = [:]
        textDB?.rows(
            """
            SELECT id, day, blockId, spaceNo, spaceNoSub, genreId, circleName, penName
            FROM ComiketCircleWC ORDER BY spaceNoSub
            """
        ) { row in
            let circle = CatalogCircle(
                id: row.int(0),
                day: row.int(1),
                blockID: row.int(2),
                spaceNumber: row.int(3),
                spaceNumberSuffix: row.int(4),
                genreID: row.int(5),
                name: row.string(6),
                penName: row.string(7)
            )
            let key = OccupantKey(day: circle.day, blockID: circle.blockID, spaceNumber: circle.spaceNumber)
            result[key, default: []].append(circle)
        }
        circlesBySpace = result
    }

    private func buildDemoFavorites() {
        var picked: [CatalogCircle] = []
        textDB?.rows(
            """
            SELECT id, day, blockId, spaceNo, spaceNoSub, genreId, circleName, penName
            FROM ComiketCircleWC WHERE id % 131 = 7 ORDER BY id
            """
        ) { row in
            picked.append(
                CatalogCircle(
                    id: row.int(0),
                    day: row.int(1),
                    blockID: row.int(2),
                    spaceNumber: row.int(3),
                    spaceNumberSuffix: row.int(4),
                    genreID: row.int(5),
                    name: row.string(6),
                    penName: row.string(7)
                )
            )
        }

        let palette = FavoriteColor.allCases
        favorites = picked.enumerated().compactMap { index, circle in
            guard let layout = layout(for: circle) else { return nil }
            return Favorite(
                circle: circle,
                color: palette[index % palette.count],
                blockName: blocks[circle.blockID] ?? "?",
                mapID: layout.mapID
            )
        }
    }

    private func buildDemoBuys() {
        let names = ["新刊", "既刊セット", "アクリルスタンド", "色紙", "缶バッジ", "画集"]
        let costs = [1000, 2000, 1500, 3000, 500, 2500]
        var result: [BuyItem] = []
        for (index, favorite) in favorites.prefix(10).enumerated() {
            let count = (index % 2) + 1
            for item in 0..<count {
                let slot = (index + item) % names.count
                result.append(
                    BuyItem(
                        id: "\(favorite.circle.id)-\(item)",
                        circleID: favorite.circle.id,
                        name: names[slot],
                        cost: costs[slot],
                        isBought: false
                    )
                )
            }
        }
        buys = result
    }

    // MARK: Lookups

    func layout(for circle: CatalogCircle) -> SpaceLayout? {
        layouts[SpaceKey(blockID: circle.blockID, spaceNumber: circle.spaceNumber)]
    }

    func map(id: Int) -> HallMap? {
        maps.first { $0.id == id }
    }

    func day(id: Int) -> EventDay? {
        days.first { $0.id == id }
    }

    func circles(inSpace blockID: Int, spaceNumber: Int, on day: Int) -> [CatalogCircle] {
        circlesBySpace[OccupantKey(day: day, blockID: blockID, spaceNumber: spaceNumber)] ?? []
    }

    func rect(for circle: CatalogCircle) -> CGRect? {
        guard let layout = layout(for: circle) else { return nil }
        let total = circles(
            inSpace: circle.blockID, spaceNumber: circle.spaceNumber, on: circle.day
        ).count
        return MapGeometry.rect(for: circle, layout: layout, occupants: max(total, 1))
    }

    func favorites(inMap mapID: Int, on day: Int) -> [Favorite] {
        favorites
            .filter { $0.mapID == mapID && $0.circle.day == day }
            .sorted {
                ($0.circle.blockID, $0.circle.spaceNumber, $0.circle.spaceNumberSuffix)
                    < ($1.circle.blockID, $1.circle.spaceNumber, $1.circle.spaceNumberSuffix)
            }
    }

    func favorite(forCircle circleID: Int) -> Favorite? {
        favorites.first { $0.circle.id == circleID }
    }

    func favorites(on day: Int) -> [Favorite] {
        favorites
            .filter { $0.circle.day == day }
            .sorted {
                ($0.mapID, $0.circle.blockID, $0.circle.spaceNumber, $0.circle.spaceNumberSuffix)
                    < ($1.mapID, $1.circle.blockID, $1.circle.spaceNumber, $1.circle.spaceNumberSuffix)
            }
    }

    func isVisited(_ circleID: Int) -> Bool {
        visitedIDs.contains(circleID)
    }

    func toggleVisited(_ circleID: Int) {
        if visitedIDs.contains(circleID) {
            visitedIDs.remove(circleID)
        } else {
            visitedIDs.insert(circleID)
        }
        SharedState.visitedIDs = visitedIDs
        WidgetRefresher.reload()
    }

    func nextStop(on day: Int) -> (favorite: Favorite, position: Int, total: Int)? {
        let route = favorites(on: day)
        guard !route.isEmpty else { return nil }
        let index = route.firstIndex { !visitedIDs.contains($0.id) } ?? 0
        return (route[index], index + 1, route.count)
    }

    func buysSummary(forCircle circleID: Int) -> (count: Int, total: Int) {
        let items = buys(forCircle: circleID)
        return (items.count, items.reduce(0) { $0 + $1.cost })
    }

    func circle(at point: CGPoint, mapID: Int, on day: Int) -> CatalogCircle? {
        guard let layouts = layoutsByMap[mapID] else { return nil }
        let size = MapGeometry.spaceSize
        guard let layout = layouts.first(where: {
            CGRect(x: $0.position.x, y: $0.position.y, width: size, height: size).contains(point)
        }) else { return nil }

        let occupants = circles(inSpace: layout.blockID, spaceNumber: layout.spaceNumber, on: day)
        guard !occupants.isEmpty else { return nil }
        for circle in occupants {
            let rect = MapGeometry.rect(for: circle, layout: layout, occupants: occupants.count)
            if rect.contains(point) { return circle }
        }
        return occupants.first
    }

    func blockName(_ blockID: Int) -> String {
        blocks[blockID] ?? "?"
    }

    func buys(forCircle circleID: Int) -> [BuyItem] {
        buys.filter { $0.circleID == circleID }
    }

    func toggleBuy(_ item: BuyItem) {
        guard let index = buys.firstIndex(where: { $0.id == item.id }) else { return }
        buys[index].isBought.toggle()
    }

    func mapImage(mapID: Int, day: Int) -> UIImage? {
        guard let map = map(id: mapID) else { return nil }
        let name = "LWMP\(day)\(map.filename)"
        if let cached = imageCache[name] { return cached }
        guard let data = imageDB?.blob(
            "SELECT image FROM ComiketCommonImage WHERE name = ?", strings: [name]
        ), let image = UIImage(data: data) else { return nil }
        imageCache[name] = image
        return image
    }
}
