//
//  LoginView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/19.
//

import SwiftUI

struct LoginView: View {

    @Environment(\.openURL) var openURL
    @Environment(Authenticator.self) var authenticator

    var body: some View {
        @Bindable var authenticator = authenticator
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
            VStack {
                Button {
                    #if !targetEnvironment(macCatalyst) && !os(visionOS)
                    authenticator.isWaitingForAuthenticationCode = true
                    #else
                    openURL(authenticator.authURL)
                    #endif
                } label: {
                    Text("Shared.Login")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6.0)
                }
                .clipShape(.capsule)
                .buttonStyleGlassProminentIfSupported()
            }
            .padding()
        }
        #if !os(visionOS)
        .sheet(isPresented: $authenticator.isWaitingForAuthenticationCode) {
            SafariView(url: authenticator.authURL)
                .ignoresSafeArea()
        }
        #endif
    }
}
