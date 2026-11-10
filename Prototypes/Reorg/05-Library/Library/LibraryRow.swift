import SwiftUI

struct LibraryRow: View {

    @Environment(Harness.self) var harness
    let item: LibraryItem

    var body: some View {
        HStack(spacing: 12.0) {
            LibraryRowIcon(item: item)
            Text(item.title)
                .lineLimit(1)
            Spacer(minLength: 8.0)
            LibraryRowAccessory(item: item)
        }
        .padding(.leading, isNested ? 20.0 : 0.0)
    }

    var isNested: Bool {
        if case .favoriteColor = item { return true }
        return false
    }
}
