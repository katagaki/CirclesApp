//
//  LoginView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/19.
//

import Komponents
import SwiftUI

struct LoginView: View {

    @Environment(\.openURL) var openURL
    @Environment(AuthManager.self) var authManager

    @State var isShowingAuthSafariViewController: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16.0) {
                Text("Login.Title")
                    .fontWeight(.black)
                    .font(.largeTitle)
                    .foregroundStyle(
                        LinearGradient(colors: [.accent, .primary], startPoint: .leading, endPoint: .trailing)
                    )
                Spacer()
                VStack(alignment: .leading, spacing: 32.0) {
                    LoginFeatureHero(imageName: "Hero.Map",
                                     title: "Hero.Map.Title",
                                     description: "Hero.Map.Description")
                    LoginFeatureHero(imageName: "Hero.Circles",
                                     title: "Hero.Circles.Title",
                                     description: "Hero.Circles.Description")
                    LoginFeatureHero(imageName: "Hero.Favorites",
                                     title: "Hero.Favorites.Title",
                                     description: "Hero.Favorites.Description")
                }
                Spacer()
                Divider()
                Text("Login.Subtitle")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(18.0)
        }
        .safeAreaInset(edge: .bottom, spacing: 0.0) {
            BarAccessory(placement: .bottom) {
                VStack {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Login.Disclaimer")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    Button {
                        #if !targetEnvironment(macCatalyst) && !os(visionOS)
                        isShowingAuthSafariViewController = true
                        #else
                        openURL(authManager.authURL)
                        #endif
                    } label: {
                        Text("Shared.Login")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding([.top, .bottom], 6.0)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(.capsule(style: .continuous))
                }
                .padding()
            }
        }
        #if !os(visionOS)
        .sheet(isPresented: $isShowingAuthSafariViewController) {
            SafariView(url: authManager.authURL)
                .ignoresSafeArea()
        }
        #endif
    }
}
