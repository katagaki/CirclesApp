//
//  AttachProductListView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/02/28.
//

import SwiftUI

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

    @Namespace var namespace

    var body: some View {
        NavigationStack {
            List {
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
                if hasMoreResults {
                    Text("他にも検索結果があります。検索条件を絞ってください。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .overlay {
                if searchTerm.trimmingCharacters(in: .whitespaces).count < 2 {
                    ContentUnavailableView(
                        "サークルを検索",
                        systemImage: "magnifyingglass",
                        description: Text("サークル名またはペンネームで検索してください。")
                    )
                } else if searchResults.isEmpty {
                    ContentUnavailableView(
                        "見つかりませんでした",
                        systemImage: "questionmark.square.dashed",
                        description: Text("検索条件に一致するサークルがありません。")
                    )
                }
            }
            .navigationTitle("お品書きを添付")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchTerm,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "サークル名・ペンネーム"
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
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
    }

    var saveButton: some View {
        Button {
            save()
        } label: {
            Text("保存")
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
            searchResults = []
            hasMoreResults = false
            return
        }

        let hasMore = identifiers.count > 10
        let limited = Array(identifiers.prefix(10))
        let circles = database.circles(limited)
        searchResults = circles
        hasMoreResults = hasMore
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
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glassProminent)
                .clipShape(Capsule())
        } else {
            content
                .buttonStyle(.borderedProminent)
                .clipShape(Capsule())
        }
    }
}
