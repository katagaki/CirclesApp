import SwiftUI

/// Lets a pinch resize a grid smoothly between column counts, like the Photos app.
struct PinchZoomGrid<Content: View, Cell: View, Header: View>: View {

    var columnCount: Int
    var columnCounts: [Int]
    var sections: [PinchZoomSection]
    var spacing: CGFloat
    var heightRatio: CGFloat
    var onColumnCountChange: (Int) -> Void
    var header: Header
    var cell: (Int, Int) -> Cell
    var content: Content

    private static var coordinateSpace: String { "PinchZoomGridSpace" }

    @State private var zoom = PinchZoomState<PinchZoomGridSession>()
    @State private var gridSize: CGSize = .zero

    init(
        columnCount: Int,
        columnCounts: [Int],
        sections: [PinchZoomSection],
        spacing: CGFloat,
        heightRatio: CGFloat,
        onColumnCountChange: @escaping (Int) -> Void,
        @ViewBuilder header: () -> Header = { EmptyView() },
        @ViewBuilder cell: @escaping (Int, Int) -> Cell,
        @ViewBuilder content: () -> Content
    ) {
        self.columnCount = columnCount
        self.columnCounts = columnCounts
        self.sections = sections
        self.spacing = spacing
        self.heightRatio = heightRatio
        self.onColumnCountChange = onColumnCountChange
        self.header = header()
        self.cell = cell
        self.content = content()
    }

    var body: some View {
        content
            .opacity(zoom.session == nil ? 1.0 : 0.0)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { gridSize = $0 }
            .modifier(PinchZoomHeightModifier(session: zoom.session, progress: zoom.progress, focusY: zoom.focusY))
            .overlay(alignment: .topLeading) {
                if let session = zoom.session {
                    PinchZoomGridLayers(session: session, progress: zoom.progress, focusY: zoom.focusY,
                                        header: header, cell: cell)
                        .allowsHitTesting(false)
                }
            }
            .coordinateSpace(.named(Self.coordinateSpace))
            .gesture(PinchZoomGesture(isEnabled: !zoom.isSettling,
                                      coordinateSpace: Self.coordinateSpace,
                                      onBegan: begin(at:viewport:),
                                      onChanged: update(scale:location:),
                                      onEnded: end(velocity:scroller:)))
    }

    private func begin(at location: CGPoint, viewport: CGRect) {
        guard gridSize.width > 0.0, !zoom.isSettling,
              sections.contains(where: { $0.count > 0 }) else { return }
        var session = PinchZoomGridSession(
            startCount: columnCount,
            columnCounts: Array(Set(columnCounts + [columnCount])).sorted(),
            width: gridSize.width, spacing: spacing, heightRatio: heightRatio,
            sections: sections, viewport: viewport,
            anchorSection: 0, anchorIndex: 0, anchorFraction: 0.0
        )
        let rowPitch = session.rowPitch(columns: columnCount)
        let cellHeight = rowPitch - spacing
        let cellWidth = session.cellWidth(columns: CGFloat(columnCount))
        let anchorSection = sections.indices.last(where: { section in
            sections[section].count > 0 &&
                session.itemsTop(section: section, columns: columnCount, rowPitch: rowPitch) <= location.y
        }) ?? sections.indices.first(where: { sections[$0].count > 0 }) ?? 0
        let localY = location.y - session.itemsTop(section: anchorSection, columns: columnCount, rowPitch: rowPitch)
        let row = max(Int(localY / rowPitch), 0)
        let column = min(max(Int(location.x / (cellWidth + spacing)), 0), columnCount - 1)
        session.anchorSection = anchorSection
        session.anchorIndex = min(row * columnCount + column, sections[anchorSection].count - 1)
        session.anchorFraction = min(max((localY - CGFloat(session.anchorIndex / columnCount) * rowPitch)
                                         / cellHeight, 0.0), 1.0)
        zoom.session = session
        zoom.progress = CGFloat(columnCount)
        zoom.focusY = location.y
    }

    private func update(scale: CGFloat, location: CGPoint) {
        guard let session = zoom.session, !zoom.isSettling else { return }
        let startWidth = session.cellWidth(columns: CGFloat(session.startCount))
        let columns = session.columns(forCellWidth: startWidth * max(scale, 0.01))
        zoom.progress = columns.rubberBanded(between: CGFloat(session.lower), and: CGFloat(session.upper))
        zoom.focusY = location.y
    }

    private func end(velocity: CGFloat, scroller: PinchZoomScroller) {
        guard let session = zoom.session, !zoom.isSettling else { return }
        let progress = zoom.progress
        let target = session.snapped(progress, velocity: velocity)
        let anchorY = session.anchorY(columns: target)
        let currentHeight = session.contentBottom(progress: progress, focusY: zoom.focusY)
        let heightChange = session.gridHeight(columns: target) - currentHeight
        let scrollDelta = scroller.clampedDelta(anchorY - zoom.focusY, contentHeightChange: heightChange)

        zoom.isSettling = true
        withAnimation(.spring(duration: 0.3, bounce: 0.0)) {
            zoom.progress = CGFloat(target)
            zoom.focusY = anchorY - scrollDelta
        } completion: {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                if target != session.startCount {
                    onColumnCountChange(target)
                }
                zoom.session = nil
                zoom.isSettling = false
                scroller.layoutAndScroll(by: scrollDelta)
            }
        }
    }
}
