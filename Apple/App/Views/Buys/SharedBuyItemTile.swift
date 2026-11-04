import AXiS
import ORBiT
import SwiftUI

struct SharedBuyItemTile: View {

    @Environment(SharedBuysSession.self) var sharedBuys

    let item: SharedBuyItem
    let onAssign: () -> Void
    var onViewPhoto: (UIImage) -> Void = { _ in }

    var isMine: Bool { item.assignee == sharedBuys.actorPID }

    var body: some View {
        BuyItemTile(
            name: item.name,
            cost: item.cost,
            photo: sharedBuys.image(for: item),
            status: BuyItemStatus(rawValue: item.status.rawValue) ?? .pending,
            note: photoNote ?? byline,
            isHighlighted: isMine,
            onToggle: {
                withAnimation(.smooth.speed(2.0)) {
                    sharedBuys.cycle(item)
                }
            },
            onPhotoTap: { image in
                if sharedBuys.imageSends[item.id]?.isFailed == true {
                    sharedBuys.retryImage(for: item)
                } else {
                    onViewPhoto(image)
                }
            },
            accessory: {
                Button(action: onAssign) {
                    if let nickname = sharedBuys.members[item.assignee ?? -1] {
                        MemberInitial(nickname: nickname, isMine: isMine)
                    } else {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 11.0, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 26.0, height: 26.0)
                            .background(.black.opacity(0.25), in: .circle)
                            .overlay {
                                Circle().strokeBorder(.white, lineWidth: 1.5)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 2.0, y: 1.0)
                    }
                }
                .buttonStyle(.plain)
            }
        )
    }

    var photoNote: LocalizedStringKey? {
        if let send = sharedBuys.imageSends[item.id] {
            return send.isFailed ? "Buys.Shared.Image.Failed" : "Buys.Shared.Image.Sending"
        }
        return sharedBuys.isImageMissing(for: item) ? "Buys.Shared.Image.Expired" : nil
    }

    var byline: LocalizedStringKey? {
        guard item.status != .pending,
              let nickname = sharedBuys.members[item.lastTouchedBy],
              item.lastTouchedBy != sharedBuys.actorPID else { return nil }
        return item.status == .bought
            ? "Buys.Shared.Bought.\(nickname)"
            : "Buys.Shared.Cancelled.\(nickname)"
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
