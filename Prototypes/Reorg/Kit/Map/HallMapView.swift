import SwiftUI

struct HallMapView: View {

    static func floorColor(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.11) : Color(red: 0.95, green: 0.94, blue: 0.92)
    }


    @Environment(Harness.self) var harness
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let layout = HallMapLayout(hall: harness.hall, size: proxy.size)
            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    draw(layout: layout, in: &context)
                }
                if harness.isNavigating {
                    HallRouteOverlay(layout: layout)
                }
                if let circle = harness.selectedCircle, circle.hall == harness.hall {
                    HallSelectionPin(circle: circle)
                        .position(layout.point(for: circle))
                }
                HallYouAreHere()
                    .position(layout.entrance)
            }
        }
    }

    func draw(layout: HallMapLayout, in context: inout GraphicsContext) {
        let dark = colorScheme == .dark
        let hallFill = dark ? Color(white: 0.17) : Color.white
        let hallStroke = dark ? Color(white: 0.3) : Color(white: 0.78)
        let deskFill = dark ? Color(white: 0.26) : Color(white: 0.88)
        let labelColor = dark ? Color(white: 0.7) : Color(white: 0.4)

        let hallPath = Path(roundedRect: layout.hallRect, cornerRadius: 10.0)
        context.fill(hallPath, with: .color(hallFill))
        context.stroke(hallPath, with: .color(hallStroke), lineWidth: 1.5)

        for (blockIndex, block) in harness.hall.blocks.enumerated() {
            let column = layout.columnRect(blockIndex)
            for slot in 0..<HallMapLayout.slotsPerBlock {
                let rect = layout.slotRect(block: blockIndex, slot: slot)
                context.fill(Path(rect), with: .color(deskFill))
            }
            context.draw(
                Text(block).font(.system(size: max(8.0, column.width * 0.55), weight: .semibold)).foregroundStyle(labelColor),
                at: CGPoint(x: column.midX, y: column.minY - 8.0)
            )
        }

        for circle in MockData.circles where circle.hall == harness.hall {
            let rect = layout.slotRect(block: circle.blockIndex, slot: circle.slotIndex)
            if let favorite = harness.favorites[circle.id] {
                context.fill(Path(rect.insetBy(dx: -1.0, dy: -0.5)), with: .color(favorite.color))
            }
            if harness.visited.contains(circle.id) {
                context.fill(Path(rect), with: .color(.black.opacity(0.35)))
            }
        }

        context.draw(
            Text(harness.hall.name).font(.caption.weight(.bold)).foregroundStyle(harness.hall.accent),
            at: CGPoint(x: layout.hallRect.minX + 10.0, y: layout.hallRect.maxY - 12.0),
            anchor: .leading
        )
    }
}
