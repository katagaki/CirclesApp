import ORBiT
import SwiftUI

struct SharedBuyItemRow: View {

    @Environment(SharedBuysSession.self) var sharedBuys

    let item: SharedBuyItem
    let onAssign: () -> Void

    var isMine: Bool { item.assignee == sharedBuys.actorPID }

    var body: some View {
        HStack(spacing: 10.0) {
            Button {
                withAnimation(.smooth.speed(2.0)) {
                    sharedBuys.cycle(item)
                }
            } label: {
                Image(systemName: symbolName)
                    .font(.system(size: 20.0))
                    .foregroundStyle(statusColor)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            if hasPhoto { thumbnail }

            VStack(alignment: .leading, spacing: 2.0) {
                Text(item.name)
                    .strikethrough(item.status == .cancelled)
                    .foregroundStyle(item.status == .cancelled ? .secondary : .primary)
                if let photoNote {
                    Text(photoNote)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else if let byline {
                    Text(byline)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text("Buys.CostValue.\(item.cost)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .strikethrough(item.status == .cancelled)

            Button(action: onAssign) {
                if let nickname = sharedBuys.members[item.assignee ?? -1] {
                    MemberInitial(nickname: nickname, isMine: isMine)
                } else {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 22.0))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .font(.subheadline)
        .listRowBackground(isMine ? Color.accentColor.opacity(0.07) : nil)
    }

    var hasPhoto: Bool { item.imageID != nil || sharedBuys.imageSends[item.id] != nil }

    var photoNote: LocalizedStringKey? {
        if let send = sharedBuys.imageSends[item.id] {
            return send.isFailed ? "Buys.Shared.Image.Failed" : "Buys.Shared.Image.Sending"
        }
        return sharedBuys.isImageMissing(for: item) ? "Buys.Shared.Image.Expired" : nil
    }

    @ViewBuilder
    var thumbnail: some View {
        Group {
            if let data = sharedBuys.image(for: item), let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 14.0))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 36.0, height: 36.0)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 6.0))
        .onTapGesture {
            if sharedBuys.imageSends[item.id]?.isFailed == true { sharedBuys.retryImage(for: item) }
        }
    }

    var byline: LocalizedStringKey? {
        guard item.status != .pending,
              let nickname = sharedBuys.members[item.lastTouchedBy],
              item.lastTouchedBy != sharedBuys.actorPID else { return nil }
        return item.status == .bought
            ? "Buys.Shared.Bought.\(nickname)"
            : "Buys.Shared.Cancelled.\(nickname)"
    }

    var symbolName: String {
        switch item.status {
        case .pending: "circle"
        case .bought: "checkmark.circle.fill"
        case .cancelled: "xmark.circle.fill"
        }
    }

    var statusColor: Color {
        switch item.status {
        case .pending: .secondary
        case .bought: .accentColor
        case .cancelled: .red.opacity(0.7)
        }
    }
}

struct MemberInitial: View {

    let nickname: String
    var isMine: Bool = false
    var size: CGFloat = 26.0

    var body: some View {
        Circle()
            .fill(color.gradient)
            .frame(width: size, height: size)
            .overlay {
                Text(String(nickname.prefix(1)))
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay {
                Circle().strokeBorder(isMine ? Color.accentColor : .clear, lineWidth: 2.0)
            }
    }

    var color: Color {
        let palette: [Color] = [.orange, .teal, .purple, .pink, .indigo, .green]
        return palette[SharedBuysPalette.index(for: nickname, count: palette.count)]
    }
}
