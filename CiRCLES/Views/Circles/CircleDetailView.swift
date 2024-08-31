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
    @Environment(CatalogManager.self) var catalog
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
                VStack(spacing: 12.0) {
                    Group {
                        VStack(spacing: 6.0) {
                            if let circleImage {
                                Image(uiImage: circleImage)
                            }
                            if let circleCutURL {
                                AsyncImage(url: circleCutURL)
                            }
                        }
                        .frame(width: 180.0, height: 256.0, alignment: .center)
                        Text(circle.bookName)
                    }
                    .padding([.leading, .trailing], 18.0)
                    if let extendedInformation {
                        Divider()
                        ScrollView(.horizontal) {
                            HStack(spacing: 10.0) {
                                Group {
                                    if favorites.contains(extendedInformation) {
                                        Button {
                                            if let token = authManager.token {
                                                Task {
                                                    await favorites.delete(using: extendedInformation, authToken: token)
                                                    isAddingToFavorites = false
                                                }
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
            if let extendedInformation = database.extendedCircleInformation(for: circle.id) {
                debugPrint("Extended information found for circle with ID \(circle.id)")
                self.extendedInformation = extendedInformation
            }
            if let token = authManager.token, let extendedInformation {
                if let circleResponse = await catalog.getCircle(self.circle,
                                                                using: extendedInformation,
                                                                authToken: token),
                   let circleInformation = circleResponse.response.circle {
                    circleCutURL = URL(string: circleInformation.cutWebURL)
                }
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
