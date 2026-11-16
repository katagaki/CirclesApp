import SwiftUI

@Animatable
struct PinchZoomGridLayers<Cell: View, Header: View>: View {

    @AnimatableIgnored var session: PinchZoomGridSession
    var progress: CGFloat
    var focusY: CGFloat
    @AnimatableIgnored var header: Header
    @AnimatableIgnored var cell: (Int, Int) -> Cell

    var body: some View {
        let morph = session.morph(progress: progress)
        ZStack(alignment: .topLeading) {
            ForEach(session.sectionFrames(progress: progress, focusY: focusY)) { frame in
                if session.sections[frame.id].leading > 0.0 {
                    header
                        .frame(width: frame.header.width, height: frame.header.height, alignment: .top)
                        .offset(y: frame.header.minY)
                }
                if let background = session.sections[frame.id].background {
                    Rectangle()
                        .fill(background)
                        .frame(width: frame.items.width, height: frame.items.height)
                        .offset(y: frame.items.minY)
                }
            }
            ForEach(session.placements(progress: progress, focusY: focusY)) { placement in
                cell(placement.section, placement.index)
                    .frame(width: morph.cellWidth, height: morph.cellHeight, alignment: .top)
                    .opacity(placement.opacity)
                    .offset(x: placement.origin.x, y: placement.origin.y)
            }
        }
        .frame(width: session.width, height: 1.0, alignment: .topLeading)
    }
}
