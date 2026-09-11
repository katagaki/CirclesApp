import ORBiT
import SwiftUI

struct LoginView: View {

    @Environment(\.openURL) var openURL
    @Environment(Authenticator.self) var authenticator
    @Environment(SharedBuysSession.self) var sharedBuys

    @State var isOfflineModeConfirmationShowing: Bool = false

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
            LinearGradient(
                colors: [.accent.opacity(0.12), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
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
                // Someone who was handed a join code has no circle.ms account and no
                // reason to make one; they are here to tick items off a friend's list.
                Button {
                    authenticator.isAuthenticating = false
                    sharedBuys.enterGuestMode()
                } label: {
                    Text("Login.JoinAsGuest")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6.0)
                }
                .clipShape(.capsule)
                .tint(.accent)
                .buttonStyle(.glass)
                if authenticator.canUseOfflineMode {
                    Button {
                        isOfflineModeConfirmationShowing = true
                    } label: {
                        Text("Login.UseOffline")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6.0)
                    }
                    .clipShape(.capsule)
                    .tint(.accent)
                    .buttonStyle(.glass)
                }
            }
            .padding()
            .padding(.top, 8.0)
            // The scroll area deliberately bleeds under this stack, so lay down a
            // scrim that fades in from the top to keep the buttons legible. The hall
            // sits on top of the scrim rather than under it, so it stays visible.
            .background(alignment: .bottom) {
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(.regularMaterial)
                        .mask {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: .black, location: 0.22)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .ignoresSafeArea(edges: .bottom)
                    Image("TokyoBigSight")
                        .resizable()
                        .scaledToFit()
                        .tint(.accent)
                        .opacity(0.07)
                        .ignoresSafeArea(edges: .bottom)
                        .offset(y: 50.0)
                }
                .allowsHitTesting(false)
            }
        }
        .alert("Alerts.OfflineMode.Enter.Title", isPresented: $isOfflineModeConfirmationShowing) {
            Button("Login.UseOffline") {
                authenticator.enterOfflineMode()
            }
            Button("Shared.Cancel", role: .cancel) {
            }
        } message: {
            Text("Alerts.OfflineMode.Enter.Message")
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
