//
//  ActionExtensionSearchView.swift
//  AttachProductList
//
//  Created by シン・ジャスティン on 2026/02/28.
//

import SQLite
import SwiftUI

struct ActionExtensionSearchView: View {

    let imageData: Data
    let onComplete: () -> Void
    let onCancel: () -> Void

    @State var searchTerm: String = ""
    @State var searchResults: [ActionExtensionCircle] = []
    @State var selectedCircle: ActionExtensionCircle?
    @State var isSaving: Bool = false

    var body: some View {
        NavigationStack {
            List(searchResults) { circle in
                Button {
                    selectedCircle = circle
                } label: {
                    HStack(spacing: 12.0) {
                        VStack(alignment: .leading, spacing: 4.0) {
                            Text(circle.circleName)
                                .foregroundStyle(selectedCircle?.id == circle.id ? Color.accentColor : .primary)
                            if !circle.penName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(circle.penName)
                                    .font(.subheadline)
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
                        onCancel()
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
                search()
            }
        }
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

    func search() {
        let term = searchTerm.trimmingCharacters(in: .whitespaces)
        guard term.count >= 2 else {
            searchResults = []
            return
        }

        let databaseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let databaseURL else { return }

        let activeEventNumber = UserDefaults.standard.integer(forKey: "Events.Active.Number")
        guard activeEventNumber > 0 else { return }

        let textDBURL = databaseURL.appending(path: "webcatalog\(activeEventNumber).db")
        guard FileManager.default.fileExists(atPath: textDBURL.path(percentEncoded: false)),
              let db = try? Connection(textDBURL.path(percentEncoded: false), readonly: true) else {
            return
        }

        do {
            let table = Table("ComiketCircleWC")
            let colID = Expression<Int>("id")
            let colEventNumber = table[Expression<Int>("comiketNo")]
            let colCircleName = Expression<String>("circleName")
            let colCircleNameKana = Expression<String>("circleKana")
            let colPenName = Expression<String>("penName")

            let query = table.filter(
                colCircleName.like("%\(term)%") ||
                colCircleNameKana.like("%\(term)%") ||
                colPenName.like("%\(term)%")
            )

            searchResults = try db.prepare(query).map { row in
                ActionExtensionCircle(
                    id: row[colID],
                    eventNumber: row[colEventNumber],
                    circleName: row[colCircleName],
                    penName: row[colPenName]
                )
            }
        } catch {
            debugPrint("Search failed: \(error.localizedDescription)")
        }
    }

    func save() {
        guard let selectedCircle else { return }
        isSaving = true

        AttachmentsDatabase.shared.insert(
            eventNumber: selectedCircle.eventNumber,
            circleID: selectedCircle.id,
            attachmentType: "image",
            type: "productList",
            attachmentBlob: imageData
        )

        onComplete()
    }
}

struct ActionExtensionCircle: Identifiable {
    let id: Int
    let eventNumber: Int
    let circleName: String
    let penName: String
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
