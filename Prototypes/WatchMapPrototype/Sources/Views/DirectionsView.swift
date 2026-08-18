import SwiftUI

struct DirectionsView: View {

    @Environment(CatalogStore.self) private var store

    let favorite: Favorite

    var body: some View {
        ScrollView {
            VStack(spacing: 8.0) {
                Text(favorite.spaceLabel)
                    .font(.system(size: 40.0, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(favorite.color.foreground)
                    .padding(.horizontal, 12.0)
                    .padding(.vertical, 2.0)
                    .background(Capsule().fill(favorite.color.color))

                Text(store.map(id: favorite.mapID)?.name ?? "")
                    .font(.headline)

                if let day = store.day(id: favorite.circle.day) {
                    Text("\(day.shortLabel) · \(day.dateLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                thumbnail
                    .frame(height: 90.0)

                Text(favorite.circle.name)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4.0)
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        GeometryReader { proxy in
            if let image = store.mapImage(mapID: favorite.mapID, day: favorite.circle.day) {
                let scale = min(
                    proxy.size.width / image.size.width,
                    proxy.size.height / image.size.height
                )
                MapCanvas(
                    image: image,
                    markers: [],
                    focusRect: store.rect(for: favorite.circle),
                    scale: scale,
                    center: CGPoint(x: image.size.width / 2.0, y: image.size.height / 2.0)
                )
                .opacity(0.9)
            }
        }
    }
}
