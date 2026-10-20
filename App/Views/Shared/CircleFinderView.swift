import SwiftUI
import AXiS

/// The circles a shared post mentions, for picking the one to open.
struct CircleFinderView: View {

    @Environment(Database.self) var database
    @Environment(\.dismiss) var dismiss

    let text: String
    let onSelect: (ComiketCircle) -> Void

    @State var placements: [CirclePlacement] = []
    @State var circles: [ComiketCircle] = []
    @State var isSearching: Bool = true

    @Namespace var namespace

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(circles) { circle in
                        Button {
                            onSelect(circle)
                            dismiss()
                        } label: {
                            row(circle)
                        }
                    }
                } header: {
                    if !placements.isEmpty {
                        Text("Circles.Finder.Detected.\(placements.map(\.displayName).formatted(.list(type: .and)))")
                    }
                }
            }
            .listStyle(.plain)
            .overlay {
                if isSearching {
                    ProgressView()
                } else if circles.isEmpty {
                    ContentUnavailableView(
                        "Circles.Finder.NoResults",
                        systemImage: "text.viewfinder",
                        description: Text("Circles.Finder.NoResults.Description")
                    )
                }
            }
            .navigationTitle("Circles.Finder.Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await search()
        }
    }

    @ViewBuilder
    func row(_ circle: ComiketCircle) -> some View {
        HStack(spacing: 10.0) {
            CircleCutImage(
                circle, in: namespace, cutType: .catalog,
                showSpaceName: .constant(false), showDay: .constant(false)
            )
            .frame(width: 70.0, height: 100.0, alignment: .center)
            VStack(alignment: .leading, spacing: 5.0) {
                Text(circle.circleName)
                    .strikethrough(circle: circle)
                    .foregroundStyle(.primary)
                if circle.penName.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                    Text(circle.penName)
                        .foregroundStyle(.secondary)
                }
                if let spaceName = circle.spaceName() {
                    CircleBlockPill(LocalizedStringKey(spaceName))
                }
            }
            Spacer(minLength: 0)
        }
    }

    func search() async {
        placements = CirclePlacement.placements(in: text)
        let fetcher = DataFetcher(database: database.newReadOnlyTextConnection())
        let identifiers = await CircleFinder.circles(mentionedIn: text, using: fetcher)
        let circlesByID = Dictionary(
            database.circles(identifiers).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        circles = identifiers.compactMap { circlesByID[$0] }
        isSearching = false
    }
}
