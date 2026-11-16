import SwiftUI

@Animatable
struct PinchZoomListLayers<Row: View, Header: View>: View {

    @AnimatableIgnored var session: PinchZoomListSession
    var progress: CGFloat
    var focusY: CGFloat
    @AnimatableIgnored var header: Header
    @AnimatableIgnored var row: (Int, Int, CGFloat) -> Row

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(session.headerFrames(progress: progress, focusY: focusY)) { frame in
                if session.sections[frame.id].leading > 0.0 {
                    header
                        .frame(width: frame.header.width, height: frame.header.height, alignment: .top)
                        .offset(y: frame.header.minY)
                }
            }
            ForEach(session.placements(progress: progress, focusY: focusY)) { placement in
                row(placement.section, placement.index, progress)
                    .frame(width: session.width, height: progress, alignment: .top)
                    .clipped()
                    .offset(y: placement.originY)
            }
        }
        .frame(width: session.width, height: 1.0, alignment: .topLeading)
    }
}
