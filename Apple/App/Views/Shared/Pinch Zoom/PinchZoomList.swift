import SwiftUI

/// Lets a pinch resize a list's rows smoothly between their heights, like the Photos app.
struct PinchZoomList<Content: View, Row: View, Header: View>: View {

    var level: Int
    var rowHeights: [CGFloat]
    var sections: [PinchZoomSection]
    var onLevelChange: (Int) -> Void
    var header: Header
    var row: (Int, Int, PinchZoomListSession, CGFloat) -> Row
    var content: Content

    private static var coordinateSpace: String { "PinchZoomListSpace" }

    @State private var zoom = PinchZoomState<PinchZoomListSession>()
    @State private var listWidth: CGFloat = 0.0

    init(
        level: Int,
        rowHeights: [CGFloat],
        sections: [PinchZoomSection],
        onLevelChange: @escaping (Int) -> Void,
        @ViewBuilder header: () -> Header = { EmptyView() },
        @ViewBuilder row: @escaping (Int, Int, PinchZoomListSession, CGFloat) -> Row,
        @ViewBuilder content: () -> Content
    ) {
        self.level = level
        self.rowHeights = rowHeights
        self.sections = sections
        self.onLevelChange = onLevelChange
        self.header = header()
        self.row = row
        self.content = content()
    }

    var body: some View {
        content
            .opacity(zoom.session == nil ? 1.0 : 0.0)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { listWidth = $0 }
            .modifier(PinchZoomHeightModifier(session: zoom.session, progress: zoom.progress, focusY: zoom.focusY))
            .overlay(alignment: .topLeading) {
                if let session = zoom.session {
                    PinchZoomListLayers(session: session, progress: zoom.progress, focusY: zoom.focusY,
                                        header: header) { section, index, progress in
                        row(section, index, session, progress)
                    }
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
        guard listWidth > 0.0, !zoom.isSettling, rowHeights.indices.contains(level),
              sections.contains(where: { $0.count > 0 }) else { return }
        var session = PinchZoomListSession(
            startLevel: level, rowHeights: rowHeights, width: listWidth,
            sections: sections, viewport: viewport,
            anchorSection: 0, anchorIndex: 0, anchorFraction: 0.0
        )
        let rowHeight = rowHeights[level]
        let anchorSection = sections.indices.last(where: { section in
            sections[section].count > 0 && session.itemsTop(section: section, rowHeight: rowHeight) <= location.y
        }) ?? sections.indices.first(where: { sections[$0].count > 0 }) ?? 0
        let localY = location.y - session.itemsTop(section: anchorSection, rowHeight: rowHeight)
        session.anchorSection = anchorSection
        session.anchorIndex = min(max(Int(localY / rowHeight), 0), sections[anchorSection].count - 1)
        session.anchorFraction = min(max(localY / rowHeight - CGFloat(session.anchorIndex), 0.0), 1.0)
        zoom.session = session
        zoom.progress = rowHeight
        zoom.focusY = location.y
    }

    private func update(scale: CGFloat, location: CGPoint) {
        guard let session = zoom.session, !zoom.isSettling else { return }
        let rowHeight = session.rowHeights[session.startLevel] * max(scale, 0.01)
        zoom.progress = rowHeight.rubberBanded(between: session.lower, and: session.upper, unit: session.lower)
        zoom.focusY = location.y
    }

    private func end(velocity: CGFloat, scroller: PinchZoomScroller) {
        guard let session = zoom.session, !zoom.isSettling else { return }
        let progress = zoom.progress
        let target = session.snapped(progress, velocity: velocity)
        let anchorY = session.anchorY(level: target)
        let currentHeight = session.contentBottom(progress: progress, focusY: zoom.focusY)
        let heightChange = session.listHeight(level: target) - currentHeight
        let scrollDelta = scroller.clampedDelta(anchorY - zoom.focusY, contentHeightChange: heightChange)

        zoom.isSettling = true
        withAnimation(.spring(duration: 0.3, bounce: 0.0)) {
            zoom.progress = session.rowHeights[target]
            zoom.focusY = anchorY - scrollDelta
        } completion: {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                if target != session.startLevel {
                    onLevelChange(target)
                }
                zoom.session = nil
                zoom.isSettling = false
                scroller.layoutAndScroll(by: scrollDelta)
            }
        }
    }
}
