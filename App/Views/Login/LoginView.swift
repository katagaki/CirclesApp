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
                    .foregroundStyle(.accent)
                    .padding(.top, 24.0)
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
                    LoginFeatureHero(imageName: "Hero.Buys",
                                     title: "Hero.Buys.Title",
                                     description: "Hero.Buys.Description")
                }
                Spacer()
                Divider()
                Text("Login.Subtitle")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(18.0)
        }
        .background {
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [.accent.opacity(0.12), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                Image("TokyoBigSight")
                    .resizable()
                    .scaledToFit()
                    .tint(.accent)
                    .opacity(0.07)
                    .ignoresSafeArea(edges: .bottom)
                    .offset(y: 50.0)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0.0) {
            VStack(spacing: 12.0) {
                if let message = authenticator.authBroadcastMessage, !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                Button {
                    if authenticator.canLogin {
                        #if !targetEnvironment(macCatalyst) && !os(visionOS)
                        authenticator.isWaitingForAuthenticationCode = true
                        #else
                        if let authURL = authenticator.authURL {
                            openURL(authURL)
                        }
                        #endif
                    } else {
                        Task {
                            await authenticator.refreshLoginInformation()
                        }
                    }
                } label: {
                    Group {
                        if authenticator.canLogin {
                            Text("Shared.Login")
                        } else if authenticator.isFetchingLoginInformation {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Shared.Retry")
                        }
                    }
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6.0)
                }
                .disabled(!authenticator.canLogin && authenticator.isFetchingLoginInformation)
                .clipShape(.capsule)
                .tint(.accent)
                .buttonStyle(.glassProminent)
            }
            .padding()
        }
        .task {
            await authenticator.refreshLoginInformation()
        }
        #if !os(visionOS)
        .sheet(isPresented: $authenticator.isWaitingForAuthenticationCode) {
            if let authURL = authenticator.authURL {
                SafariView(url: authURL)
                    .ignoresSafeArea()
            }
        }
        #endif
    }
}
