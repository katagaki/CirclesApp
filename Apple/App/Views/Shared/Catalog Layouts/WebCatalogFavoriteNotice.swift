import SwiftUI

struct WebCatalogFavoriteNotice: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            Label("Favorites.WebCatalogFavorites", systemImage: "exclamationmark.circle.fill")
                .font(.subheadline)
                .fontWeight(.bold)
            Text("Favorites.WebCatalogFavorites.Description")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.leading, .trailing], 20.0)
        .padding([.top, .bottom], 12.0)
        .background(.bar)
    }
}
