import SwiftUI

struct GenreChips: View {

    @Binding var selection: String?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8.0) {
                chip(nil, title: "All")
                ForEach(MockData.genres, id: \.self) { genre in
                    chip(genre, title: genre)
                }
            }
            .padding(.horizontal, 16.0)
        }
        .scrollIndicators(.hidden)
    }

    func chip(_ value: String?, title: String) -> some View {
        Button {
            selection = value
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12.0)
                .padding(.vertical, 6.0)
                .foregroundStyle(selection == value ? Color.white : Color.primary)
                .background(selection == value ? Color.accentColor : Color(uiColor: .tertiarySystemFill), in: .capsule)
        }
        .buttonStyle(.plain)
    }
}
