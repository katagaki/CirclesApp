import SwiftUI
import AXiS

struct AttachProductListView: View {

    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(\.dismiss) var dismiss

    let imageData: Data

    @State var searchTerm: String = ""
    @State var searchResults: [ComiketCircle] = []
    @State var hasMoreResults: Bool = false
    @State var selectedCircle: ComiketCircle?
    @State var isSaving: Bool = false
    @State var searchTask: Task<Void, Never>?
    @State var isSearching: Bool = false
    @State var isShowingSuggestions: Bool = false

    @Namespace var namespace

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(searchResults) { circle in
                        Button {
                            selectedCircle = circle
                        } label: {
                            HStack(spacing: 10.0) {
                                CircleCutImage(
                                    circle, in: namespace, cutType: .catalog,
                                    showSpaceName: .constant(false), showDay: .constant(false)
                                )
                                .frame(width: 70.0, height: 100.0, alignment: .center)
                                VStack(alignment: .leading, spacing: 5.0) {
                                    Text(circle.circleName)
                                        .strikethrough(circle: circle)
                                        .foregroundStyle(selectedCircle?.id == circle.id
                                                         ? Color.accentColor : .primary)
                                    if circle.penName
                                        .trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                                        Text(circle.penName)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer(minLength: 0)
                                if selectedCircle?.id == circle.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    if isShowingSuggestions {
                        Text("Circles.Attachments.Suggested")
                    }
                }
                if hasMoreResults {
                    Text("Circles.Attachments.MoreResults")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .overlay {
                if searchResults.isEmpty && searchTerm.trimmingCharacters(in: .whitespaces).count < 2 {
                    ContentUnavailableView(
                        "Circles.Attachments.Search",
                        systemImage: "magnifyingglass",
                        description: Text("Circles.Attachments.Search.Description")
                    )
                } else if searchResults.isEmpty {
                    ContentUnavailableView(
                        "Circles.Attachments.NoResults",
                        systemImage: "questionmark.square.dashed",
                        description: Text("Circles.Attachments.NoResults.Description")
                    )
                }
            }
            .navigationTitle("Circles.Attachments.Attach")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchTerm,
                isPresented: $isSearching,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Circles.Attachments.Search.Prompt"
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
                if let selectedCircle {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Circles.Attachments.Open", systemImage: "arrow.up.forward.app") {
                            CircleFinderRouter.shared.pendingCircle = CircleEntity.identifier(
                                eventNumber: planner.activeEventNumber, circleID: selectedCircle.id
                            )
                            dismiss()
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if selectedCircle != nil {
                    saveButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.smooth.speed(2.0), value: selectedCircle?.id)
            .onChange(of: searchTerm) {
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    await performSearch()
                }
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            isSearching = true
        }
        .task {
            await suggestCircles()
        }
    }

    var saveButton: some View {
        Button {
            save()
        } label: {
            Text("Shared.Save")
                .padding(.horizontal, 20.0)
                .padding(.vertical, 12.0)
                .frame(maxWidth: .infinity)
        }
        .disabled(isSaving)
        .modifier(SaveButtonStyle())
        .padding(.horizontal, 20.0)
        .padding(.bottom, 8.0)
    }

    func performSearch() async {
        let identifiers = await CatalogCache.searchCircles(searchTerm, database: database)
        guard let identifiers else {
            // Keep what was read from the image until a search replaces it.
            guard !isShowingSuggestions else { return }
            searchResults = []
            hasMoreResults = false
            return
        }

        let hasMore = identifiers.count > 10
        let limited = Array(identifiers.prefix(10))
        let circles = database.circles(limited)
        searchResults = circles
        hasMoreResults = hasMore
        isShowingSuggestions = false
    }

    /// Product lists usually carry the circle's space, so the circle can often be found
    /// before anything is typed.
    func suggestCircles() async {
        guard let text = await CircleFinder.text(in: imageData) else { return }
        let fetcher = DataFetcher(database: database.newReadOnlyTextConnection())
        let identifiers = await fetcher.circles(mentionedIn: text)
        guard !identifiers.isEmpty, searchTerm.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let circlesByID = Dictionary(
            database.circles(Array(identifiers.prefix(10))).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        searchResults = identifiers.prefix(10).compactMap { circlesByID[$0] }
        hasMoreResults = identifiers.count > 10
        isShowingSuggestions = true
        if searchResults.count == 1 {
            selectedCircle = searchResults.first
        }
        isSearching = false
    }

    func save() {
        guard let selectedCircle else { return }
        isSaving = true

        AttachmentsDatabase.shared.insert(
            eventNumber: planner.activeEventNumber,
            circleID: selectedCircle.id,
            attachmentType: "image",
            type: "productList",
            attachmentBlob: imageData
        )

        dismiss()
    }
}

struct SaveButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(.glassProminent)
            .clipShape(Capsule())
    }
}
