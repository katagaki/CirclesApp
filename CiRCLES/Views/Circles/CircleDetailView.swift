//
//  CircleDetailView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Komponents
import SwiftUI

struct CircleDetailView: View {

    @Environment(\.openURL) var openURL

    @Environment(AuthManager.self) var authManager
    @Environment(FavoritesManager.self) var favorites
    @Environment(DatabaseManager.self) var database

    var circle: ComiketCircle
    @State var circleImage: UIImage?
    @State var extendedInformation: ComiketCircleExtendedInformation?

    @State var isAddingToFavorites: Bool = false
    @State var favoriteColorToAddTo: WebCatalogColor?

    var body: some View {
        List {
            if let extendedInformation {
                Section {
                    Button("Shared.AddToFavorites", systemImage: "star") {
                        isAddingToFavorites = true
                    }
                    .popover(isPresented: $isAddingToFavorites, arrowEdge: .bottom) {
                        FavoriteColorSelector(selectedColor: $favoriteColorToAddTo)
                    }
                }
            }
            Section {
                Text(circle.supplementaryDescription)
                if circle.memo.count > 0 {
                    Text(circle.memo)
                }
            } header: {
                ListSectionHeader(text: "Shared.Description")
            }
        }
        .listSectionSpacing(.compact)
        .navigationTitle(circle.circleName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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
        .safeAreaInset(edge: .top) {
            ToolbarAccessory(placement: .top) {
                VStack {
                    if let circleImage {
                        Image(uiImage: circleImage)
                    }
                    Text(circle.bookName)
                    if let extendedInformation {
                        Divider()
                        HStack {
                            if let twitterURL = extendedInformation.twitterURL {
                                Button("Shared.OpenTwitter") {
                                    openURL(twitterURL)
                                }
                            }
                            if let pixivURL = extendedInformation.pixivURL {
                                Button("Shared.OpenPixiv") {
                                    openURL(pixivURL)
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            if let circleImage = database.circleImage(for: circle.id) {
                self.circleImage = circleImage
            }
            if let extendedInformation = database.extendedCircleInformation(for: circle.id) {
                debugPrint("Extended information found for circle with ID \(circle.id)")
                self.extendedInformation = extendedInformation
            }
        }
        .onChange(of: favoriteColorToAddTo) { _, newValue in
            if let extendedInformation, let token = authManager.token, let newValue {
                Task {
                    await favorites.add(
                        circle,
                        using: extendedInformation,
                        to: newValue,
                        authToken: token
                    )
                    isAddingToFavorites = false
                }
            }
        }
    }
}
