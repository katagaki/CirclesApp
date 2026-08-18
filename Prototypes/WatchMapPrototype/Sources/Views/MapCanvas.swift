import SwiftUI
import UIKit

struct MapMarker: Identifiable {
    let id: Int
    let rect: CGRect
    let color: Color
}

struct MapCanvas: View {

    let image: UIImage
    let markers: [MapMarker]
    let focusRect: CGRect?
    let scale: CGFloat
    let center: CGPoint
    var markerMinimumSize: CGFloat = 0.0
    var drawsMarkersAsDots: Bool = false

    @AppStorage(wrappedValue: true, "Prototype.InvertMap") private var invertMap: Bool

    private var scaledSize: CGSize {
        CGSize(width: image.size.width * scale, height: image.size.height * scale)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.medium)
                    .frame(width: scaledSize.width, height: scaledSize.height)
                    .modifier(InvertIfNeeded(isEnabled: invertMap))

                ForEach(markers) { marker in
                    markerShape(marker)
                }

                if let focusRect {
                    focusIndicator(focusRect)
                }
            }
            .frame(width: scaledSize.width, height: scaledSize.height, alignment: .topLeading)
            .offset(
                x: proxy.size.width / 2.0 - center.x * scale,
                y: proxy.size.height / 2.0 - center.y * scale
            )
        }
        .clipped()
    }

    @ViewBuilder
    private func markerShape(_ marker: MapMarker) -> some View {
        let width = max(marker.rect.width * scale, markerMinimumSize)
        let height = max(marker.rect.height * scale, markerMinimumSize)
        Group {
            if drawsMarkersAsDots {
                Circle()
                    .fill(marker.color)
                    .frame(width: max(width, height), height: max(width, height))
            } else {
                Rectangle()
                    .fill(marker.color.opacity(0.75))
                    .frame(width: width, height: height)
            }
        }
        .position(x: marker.rect.midX * scale, y: marker.rect.midY * scale)
    }

    @ViewBuilder
    private func focusIndicator(_ rect: CGRect) -> some View {
        let width = max(rect.width * scale, 10.0)
        let height = max(rect.height * scale, 10.0)
        ZStack {
            RoundedRectangle(cornerRadius: 2.0)
                .stroke(.white, lineWidth: 2.0)
                .frame(width: width + 4.0, height: height + 4.0)
            RoundedRectangle(cornerRadius: 2.0)
                .stroke(.black, lineWidth: 1.0)
                .frame(width: width + 6.0, height: height + 6.0)
        }
        .position(x: rect.midX * scale, y: rect.midY * scale)
    }
}

private struct InvertIfNeeded: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.colorInvert()
        } else {
            content
        }
    }
}
