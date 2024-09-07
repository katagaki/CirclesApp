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

    @Environment(\.openURL) var openURL

    @Environment(AuthManager.self) var authManager
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database

    var circle: ComiketCircle
    @State var circleImage: UIImage?
    @State var extendedInformation: ComiketCircleExtendedInformation?
    @State var webCatalogInformation: WebCatalogCircle?
    @State var circleCutURL: URL?

    @State var isAddingToFavorites: Bool = false
    @State var favoriteColorToAddTo: WebCatalogColor?

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
            if let genre = database.genre(circle.genreID) {
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
                VStack(spacing: 12.0) {
                    if let extendedInformation {
                        Divider()
                        ScrollView(.horizontal) {
                            HStack(spacing: 10.0) {
                                FavoriteButton {
                                    favorites.contains(webCatalogID: extendedInformation.webCatalogID)
                                } onAdd: {
                                    isAddingToFavorites = true
                                } onDelete: {
                                    Task.detached {
                                        await deleteFavorite()
                                    }
                                }
                                .popover(isPresented: $isAddingToFavorites, arrowEdge: .bottom) {
                                    FavoriteColorSelector(selectedColor: $favoriteColorToAddTo)
                                }
                                HStack(spacing: 5.0) {
                                    if let twitterURL = extendedInformation.twitterURL {
                                        SNSButton(twitterURL, showsLabel: false, type: .twitter)
                                    }
                                    if let pixivURL = extendedInformation.pixivURL {
                                        SNSButton(pixivURL, showsLabel: false, type: .pixiv)
                                    }
                                    if let circleMsPortalURL = extendedInformation.circleMsPortalURL {
                                        SNSButton(circleMsPortalURL, showsLabel: false, type: .circleMs)
                                    }
                                }
                            }
                            .padding([.leading, .trailing], 12.0)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
                .padding(.bottom, 12.0)
            }
        }
        .task {
            await prepareCircle()
        }
        .onChange(of: favoriteColorToAddTo) { _, newValue in
            Task.detached {
                await addToFavorites(with: newValue)
            }
        }
    }

    func prepareCircle() async {
        if let circleImage = database.circleImage(for: circle.id) {
            self.circleImage = circleImage
        }
        if let extendedInformation = circle.extendedInformation {
            debugPrint("Extended information found for circle with ID \(circle.id)")
            self.extendedInformation = extendedInformation
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
    }

    func addToFavorites(with color: WebCatalogColor?) async {
        if let extendedInformation = circle.extendedInformation, let color, let token = authManager.token {
            let actor = FavoritesActor()
            let favoritesAddResult = await actor.add(
                extendedInformation.webCatalogID,
                to: color,
                authToken: token
            )
            if favoritesAddResult {
                let (items, wcIDMappedItems) = await actor.all(authToken: token)
                await MainActor.run {
                    favorites.items = items
                    favorites.wcIDMappedItems = wcIDMappedItems
                    isAddingToFavorites = false
                }
            }
        }
    }

    func deleteFavorite() async {
        if let extendedInformation = circle.extendedInformation, let token = authManager.token {
            let actor = FavoritesActor()
            let favoritesDeleteResult = await actor.delete(
                extendedInformation.webCatalogID,
                authToken: token
            )
            if favoritesDeleteResult {
                let (items, wcIDMappedItems) = await actor.all(authToken: token)
                await MainActor.run {
                    favorites.items = items
                    favorites.wcIDMappedItems = wcIDMappedItems
                    isAddingToFavorites = false
                }
            }
        }
    }
}
