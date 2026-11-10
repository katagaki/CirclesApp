import SwiftUI

struct LibraryRowIcon: View {

    let item: LibraryItem

    var body: some View {
        if case .favoriteColor(let color) = item {
            Rectangle()
                .fill(color.color)
                .frame(width: 14.0, height: 14.0)
                .overlay(Rectangle().stroke(.black.opacity(0.1), lineWidth: 0.5))
                .frame(width: 28.0)
        } else {
            Image(systemName: item.symbol)
                .font(.body.weight(.medium))
                .foregroundStyle(item.tint)
                .frame(width: 28.0)
        }
    }
}
