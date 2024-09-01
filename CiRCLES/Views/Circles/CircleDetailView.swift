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
    @Environment(FavoritesManager.self) var favorites
    @Environment(DatabaseManager.self) var database

    var circle: ComiketCircle
    @State var circleImage: UIImage?
    @State var extendedInformation: ComiketCircleExtendedInformation?
    @State var circleCutURL: URL?

    @State var isAddingToFavorites: Bool = false
    @State var favoriteColorToAddTo: WebCatalogColor?

    @State var isShowingTranslationPopover: Bool = false
    @State var textToTranslate: String = ""

    var body: some View {
        List {
            Section {
                VStack(spacing: 10.0) {
                    Group {
                        if let circleCutURL {
                            AsyncImage(url: circleCutURL)
                        } else {
                            if let circleImage {
                                Image(uiImage: circleImage)
                                    .resizable()
                            }
                        }
                    }
                    .frame(width: 180.0, height: 256.0, alignment: .center)
                    .transition(.opacity)
                    if circle.bookName.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                        Text(circle.bookName)
                    }
                    if let block = database.block(circle.blockID) {
                        Text("\(block.name)\(circle.spaceNumberCombined())")
                            .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.init(uiColor: UIColor.label))
                        .padding([.top, .bottom], 2.0)
                        .padding([.leading, .trailing], 10.0)
                        .background(Material.ultraThin)
                        .clipShape(.capsule)
                        .overlay {
                            Capsule()
                                .stroke(lineWidth: 1)
                                .foregroundColor(.secondary)
                        }
                        .padding(2.0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
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
                    Button("Shared.Translate", systemImage: "character.bubble") {
                        textToTranslate = circle.supplementaryDescription
                        isShowingTranslationPopover = true
                    }
                    .textCase(nil)
                    .foregroundStyle(.teal)
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
                    Text(circle.penName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if let extendedInformation,
                    let circleMsPortalURL = extendedInformation.circleMsPortalURL {
                    Button("Shared.OpenInCircleMs", systemImage: "safari") {
                        openURL(circleMsPortalURL)
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
                                Group {
                                    if favorites.contains(webCatalogID: extendedInformation.webCatalogID) {
                                        Button {
                                            Task.detached {
                                                await deleteFavorite()
                                            }
                                        } label: {
                                            Image(systemName: "star.slash.fill")
                                                .resizable()
                                                .padding(2.0)
                                                .frame(width: 28.0, height: 28.0)
                                                .scaledToFit()
                                            Text("Shared.RemoveFromFavorites")
                                        }
                                    } else {
                                        Button {
                                            isAddingToFavorites = true
                                        } label: {
                                            Image(systemName: "star.fill")
                                                .resizable()
                                                .padding(2.0)
                                                .frame(width: 28.0, height: 28.0)
                                                .scaledToFit()
                                            Text("Shared.AddToFavorites")
                                        }
                                        .popover(isPresented: $isAddingToFavorites, arrowEdge: .bottom) {
                                            FavoriteColorSelector(selectedColor: $favoriteColorToAddTo)
                                        }
                                    }
                                    if let twitterURL = extendedInformation.twitterURL {
                                        Button {
                                            openURL(twitterURL)
                                        } label: {
                                            Image(.snsTwitter)
                                                .resizable()
                                                .frame(width: 28.0, height: 28.0)
                                            Text("Shared.SNS.Twitter")
                                        }
                                        .foregroundStyle(.background)
                                        .tint(.primary)
                                    }
                                    if let pixivURL = extendedInformation.pixivURL {
                                        Button {
                                            openURL(pixivURL)
                                        } label: {
                                            Image(.snsPixiv)
                                                .resizable()
                                                .frame(width: 28.0, height: 28.0)
                                            Text("Shared.SNS.Pixiv")
                                        }
                                        .foregroundStyle(.white)
                                        .tint(.blue)
                                    }
                                    if let circleMsPortalURL = extendedInformation.circleMsPortalURL {
                                        Button {
                                            openURL(circleMsPortalURL)
                                        } label: {
                                            Image(.snsCircleMs)
                                                .resizable()
                                                .frame(width: 28.0, height: 28.0)
                                            Text("Shared.SNS.CircleMsPortal")
                                        }
                                        .foregroundStyle(.white)
                                        .tint(.green)
                                    }
                                }
                                .clipShape(.capsule(style: .continuous))
                                .buttonStyle(.borderedProminent)
                            }
                            .padding([.leading, .trailing], 12.0)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
                .padding(.bottom, 12.0)
            }
        }
        .translationPresentation(isPresented: $isShowingTranslationPopover, text: textToTranslate)
        .task {
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
                   let circleInformation = circleResponse.response.circle {
                    withAnimation(.snappy.speed(2.0)) {
                        circleCutURL = URL(string: circleInformation.cutWebURL)
                    }
                }
            }
        }
        .onChange(of: favoriteColorToAddTo) { _, newValue in
            Task.detached {
                await addToFavorites(with: newValue)
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
