//
//  CircleToolbar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import Komponents
import SwiftUI

struct CircleToolbar: View {

    @Environment(AuthManager.self) var authManager
    @Environment(Favorites.self) var favorites

    @Environment(\.openURL) var openURL

    var extendedInformation: ComiketCircleExtendedInformation
    var webCatalogInformation: WebCatalogCircle?

    @State var isAddingToFavorites: Bool = false
    @State var selectedFavoriteColor: WebCatalogColor?
    @State var shouldCallAPIToUpdateFavorites: Bool = true

    @AppStorage(wrappedValue: true, "Events.Active.IsLatest") var isActiveEventLatest: Bool

    init(_ extendedInformation: ComiketCircleExtendedInformation, _ webCatalogInformation: WebCatalogCircle?) {
        self.extendedInformation = extendedInformation
        self.webCatalogInformation = webCatalogInformation
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10.0) {
                if isActiveEventLatest {
                    FavoriteButton(
                        color: selectedFavoriteColor?.backgroundColor()
                    ) {
                        favorites.contains(webCatalogID: extendedInformation.webCatalogID)
                    } onSelect: {
                        isAddingToFavorites = true
                    }
                    .popover(isPresented: $isAddingToFavorites, arrowEdge: .bottom) {
                        FavoriteColorSelector(selectedColor: $selectedFavoriteColor)
                    }
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
                if let webCatalogInformation {
                    ForEach(webCatalogInformation.onlineStores, id: \.link) { onlineStore in
                        BarAccessoryButton(LocalizedStringKey(onlineStore.name)) {
                            if let url = URL(string: onlineStore.link) {
                                openURL(url)
                            }
                        }
                    }
                }
            }
            .padding([.leading, .trailing], 12.0)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            shouldCallAPIToUpdateFavorites = false
            selectedFavoriteColor = favorites.wcIDMappedItems?[extendedInformation.webCatalogID]?.favorite.color
            shouldCallAPIToUpdateFavorites = true
        }
        .onChange(of: selectedFavoriteColor) { oldValue, newValue in
            if shouldCallAPIToUpdateFavorites {
                Task.detached {
                    if oldValue != nil && newValue == nil {
                        await deleteFavorite()
                    } else {
                        await addToFavorites(with: newValue)
                    }
                }
                isAddingToFavorites = false
            }
        }
    }

    func addToFavorites(with color: WebCatalogColor?) async {
        if let color, let token = authManager.token {
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
                }
            }
        }
    }

    func deleteFavorite() async {
        if let token = authManager.token {
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
                }
            }
        }
    }
}
