import SwiftUI

struct TodaySearchView: View {

    var body: some View {
        CatalogView()
            .safeAreaInset(edge: .top, spacing: 0.0) {
                SearchField()
                    .padding(.horizontal, 16.0)
                    .padding(.vertical, 8.0)
            }
            .navigationTitle("Circles")
            .navigationBarTitleDisplayMode(.inline)
    }
}
