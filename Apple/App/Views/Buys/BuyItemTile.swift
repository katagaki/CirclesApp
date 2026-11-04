import AXiS
import SwiftUI

struct BuyItemGrid<Content: View>: View {

    @ViewBuilder let content: () -> Content

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12.0, alignment: .top),
        count: 3
    )

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 14.0, content: content)
    }
}

struct BuyItemTile<Accessory: View>: View {

    let name: String
    let cost: Int
    let photo: Data?
    let status: BuyItemStatus
    var note: LocalizedStringKey?
    var isHighlighted: Bool = false
    let onToggle: () -> Void
    let onPhotoTap: (UIImage) -> Void
    @ViewBuilder let accessory: () -> Accessory

    private let shape = RoundedRectangle(cornerRadius: 10.0)

    var body: some View {
        let image = photo.flatMap(UIImage.init(data:))
        VStack(alignment: .leading, spacing: 6.0) {
            Button {
                if let image { onPhotoTap(image) } else { onToggle() }
            } label: {
                photoView(image)
            }
            .buttonStyle(.plain)
            .overlay(alignment: .topLeading) {
                Button(action: onToggle) {
                    BuyStatusBadge(status: status)
                        .padding(6.0)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .overlay(alignment: .topTrailing) {
                accessory()
                    .padding(6.0)
            }
            Button(action: onToggle) {
                details
            }
            .buttonStyle(.plain)
        }
        .contentShape(.contextMenuPreview, shape)
    }

    func photoView(_ image: UIImage?) -> some View {
        Color(.systemGray5)
            .aspectRatio(1.0, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 22.0))
                        .foregroundStyle(.secondary)
                }
            }
            .overlay {
                Color.black.opacity(status == .pending ? 0.0 : 0.3)
            }
            .clipShape(shape)
            .overlay {
                if isHighlighted {
                    shape.strokeBorder(Color.accentColor, lineWidth: 2.0)
                }
            }
            .contentShape(.rect)
            .animation(.smooth.speed(2.0), value: status)
    }

    var details: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(name)
                .font(.subheadline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .strikethrough(status == .cancelled)
                .foregroundStyle(status == .pending ? .primary : .secondary)
            Text("Buys.CostValue.\(cost)")
                .font(.footnote)
                .monospacedDigit()
                .strikethrough(status == .cancelled)
                .foregroundStyle(.secondary)
            if let note {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }
}

struct BuyStatusBadge: View {

    let status: BuyItemStatus

    var body: some View {
        Circle()
            .fill(fill)
            .frame(width: 24.0, height: 24.0)
            .overlay {
                Circle()
                    .strokeBorder(.white, lineWidth: 1.5)
                Image(systemName: status == .cancelled ? "xmark" : "checkmark")
                    .font(.system(size: 11.0, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
                    .scaleEffect(status == .pending ? 0.4 : 1.0)
                    .opacity(status == .pending ? 0.0 : 1.0)
            }
            .shadow(color: .black.opacity(0.3), radius: 2.0, y: 1.0)
            .animation(.smooth.speed(2.0), value: status)
    }

    var fill: Color {
        switch status {
        case .pending: .black.opacity(0.25)
        case .bought: .accentColor
        case .cancelled: .red
        }
    }
}
