//
//  MapVisitedLayer.swift
//  CiRCLES
//
//  Created by Antigravity on 2026/02/01.
//

import SwiftData
import SwiftUI

struct MapVisitedLayer: View {

    @Environment(\.colorScheme) var colorScheme
    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(Mapper.self) var mapper

    @Query var visits: [CirclesVisitEntry]

    @State var visitedPath: Path = Path()

    let spaceSize: Int

    var body: some View {
        ZStack(alignment: .topLeading) {
            visitedPath
                .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .shadow(color: .black, radius: 2)
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
    }

    func reloadVisits() async {
        let actor = DataFetcher(database: database.getTextDatabase())

        let currentEventNumber = planner.activeEventNumber
        let validVisits = visits.filter { $0.eventNumber == currentEventNumber }
        let circleIDs = validVisits.map { $0.circleID }

        if circleIDs.isEmpty {
            await MainActor.run {
                withAnimation {
                    self.visitedPath = Path()
                }
            }
            return
        }

        let webCatalogIDs = await actor.webCatalogIDs(forCircleIDs: circleIDs)
        let visitedWCIDSet = Set(webCatalogIDs)

        var newPath = Path()

        for (layout, layoutWCIDs) in mapper.layouts {
            let sortedIDs = layoutWCIDs.sorted()
            let orderedIDs: [Int]
            switch layout.layoutType {
            case .aOnBottom, .aOnRight:
                orderedIDs = sortedIDs.reversed()
            default:
                orderedIDs = sortedIDs
            }

            let count = orderedIDs.count
            guard count > 0 else { continue }

            for (index, id) in orderedIDs.enumerated() {
                if visitedWCIDSet.contains(id) {
                    let rect = getGenericRect(layout: layout, index: index, total: count)
                    let checkmark = checkmarkPath(in: rect)
                    newPath.addPath(checkmark)
                }
            }
        }

        let finalPath = newPath
        await MainActor.run {
            withAnimation(.smooth.speed(2.0)) {
                self.visitedPath = finalPath
            }
        }
    }

    func getGenericRect(layout: LayoutCatalogMapping, index: Int, total: Int) -> CGRect {
        let rectWidth: CGFloat
        let rectHeight: CGFloat
        let castSpaceSize = CGFloat(spaceSize)

        // Determine dimensions
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

        // Square to center checkmark        
        let sideLength = min(rect.width, rect.height)
        let xOffset = rect.minX + (rect.width - sideLength) / 2
        let yOffset = rect.minY + (rect.height - sideLength) / 2
        let square = CGRect(x: xOffset, y: yOffset, width: sideLength, height: sideLength)

        // Checkmark
        let start = CGPoint(x: square.minX + square.width * 0.20, y: square.minY + square.height * 0.50)
        let mid = CGPoint(x: square.minX + square.width * 0.45, y: square.minY + square.height * 0.80)
        let end = CGPoint(x: square.minX + square.width * 0.80, y: square.minY + square.height * 0.20)
        path.move(to: start)
        path.addLine(to: mid)
        path.addLine(to: end)

        return path
    }
}
