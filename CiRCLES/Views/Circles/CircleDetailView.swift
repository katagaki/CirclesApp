//
//  CircleDetailView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Komponents
import SwiftUI
import Translation

struct CircleDetailView: View {

    @Environment(AuthManager.self) var authManager
    @Environment(Database.self) var database

    var circle: ComiketCircle

    @State var circleImage: UIImage?
    @State var extendedInformation: ComiketCircleExtendedInformation?
    @State var webCatalogInformation: WebCatalogCircle?
    @State var circleCutURL: URL?
    @State var genre: String?

    var body: some View {
        List {
            Section {
                VStack(spacing: 2.0) {
                    HStack(spacing: 6.0) {
                        Group {
                            Text("Circles.Image.Catalog")
                            Text("Circles.Image.Web")
                        }
                        .textCase(.uppercase)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                    }
                    HStack(spacing: 6.0) {
                        Group {
                            if let circleImage {
                                Image(uiImage: circleImage)
                                    .resizable()
                            } else {
                                Rectangle()
                                    .foregroundStyle(Color.primary.opacity(0.05))
                                    .overlay {
                                        ProgressView()
                                    }
                            }
                            if webCatalogInformation != nil {
                                if let circleCutURL {
                                    AsyncImage(url: circleCutURL,
                                               transaction: Transaction(animation: .snappy.speed(2.0))
                                    ) { result in
                                        switch result {
                                        case .success(let image):
                                            image
                                                .resizable()
                                        default:
                                            Rectangle()
                                                .foregroundStyle(Color.primary.opacity(0.05))
                                                .overlay {
                                                    ProgressView()
                                                }
                                        }
                                    }
                                } else {
                                    Rectangle()
                                        .foregroundStyle(Color.primary.opacity(0.05))
                                        .overlay {
                                            Text("Circles.NoImage")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                }
                            } else {
                                Rectangle()
                                    .foregroundStyle(Color.primary.opacity(0.05))
                            }
                        }
                        .aspectRatio(180.0 / 256.0, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 0.0, leading: 20.0, bottom: 0.0, trailing: 20.0))
                HStack(spacing: 5.0) {
                    CircleBlockPill("Shared.\(circle.day)th.Day", size: .large)
                    if let circleSpaceName = circle.spaceName() {
                        CircleBlockPill(LocalizedStringKey(circleSpaceName), size: .large)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 2.0)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 10.0, leading: 20.0, bottom: 0.0, trailing: 20.0))
            }
            Section {
                if circle.supplementaryDescription.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                    Text(circle.supplementaryDescription)
                        .textSelection(.enabled)
                } else {
                    Text("Circles.NoDescription")
                        .foregroundStyle(.secondary)
                }
            } header: {
                HStack {
                    ListSectionHeader(text: "Shared.Description")
                    Spacer()
                    if circle.supplementaryDescription.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                        TranslateButton(translating: circle.supplementaryDescription)
                    }
                }
            }
            if circle.bookName.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                Section {
                    Text(circle.bookName)
                } header: {
                    HStack {
                        ListSectionHeader(text: "Shared.BookName")
                        Spacer()
                        if circle.bookName.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                            TranslateButton(translating: circle.bookName)
                        }
                    }
                }
            }
            if let genre {
                Section {
                    Text(genre)
                        .textSelection(.enabled)
                } header: {
                    HStack {
                        ListSectionHeader(text: "Shared.Genre")
                        Spacer()
                        TranslateButton(translating: genre)
                    }
                }
            }
            if let tags = webCatalogInformation?.tag, tags.trimmingCharacters(in: .whitespaces).count > 0 {
                Section {
                    Text(tags)
                        .textSelection(.enabled)
                } header: {
                    HStack {
                        ListSectionHeader(text: "Shared.Tags")
                        Spacer()
                        TranslateButton(translating: tags)
                    }
                }
            }
            if circle.memo.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                Section {
                    Text(circle.memo)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle(circle.circleName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0.0) {
                    Text(circle.circleName)
                        .bold()
                    if circle.penName.trimmingCharacters(in: .whitespaces) != "" {
                        Text(circle.penName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0.0) {
            ToolbarAccessory(placement: .bottom) {
                if let extendedInformation {
                    VStack(spacing: 12.0) {
                        CircleToolbar(extendedInformation)
                    }
                    .padding([.top, .bottom], 12.0)
                }
            }
        }
        .task {
            await prepareCircle()
        }
    }

    func prepareCircle() async {
        if let circleImage = database.circleImage(for: circle.id) {
            withAnimation(.snappy.speed(2.0)) {
                self.circleImage = circleImage
            }
        }
        if let extendedInformation = circle.extendedInformation {
            debugPrint("Extended information found for circle with ID \(circle.id)")
            withAnimation(.snappy.speed(2.0)) {
                self.extendedInformation = extendedInformation
            }
        }
        if let token = authManager.token, let extendedInformation {
            if let circleResponse = await WebCatalog.circle(
                with: extendedInformation.webCatalogID, authToken: token
            ),
               let webCatalogInformation = circleResponse.response.circle {
                withAnimation(.snappy.speed(2.0)) {
                    self.circleCutURL = URL(string: webCatalogInformation.cutWebURL)
                    self.webCatalogInformation = webCatalogInformation
                }
            }
        }
        let actor = DataFetcher(modelContainer: sharedModelContainer)
        if let genre = await actor.genre(circle.genreID) {
            self.genre = genre
        }
    }
}
