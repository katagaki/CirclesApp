//
//  MoreAccountsView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/04.
//

import Komponents
import SwiftData
import SwiftUI

struct MoreAccountsView: View {

    @Environment(\.openURL) var openURL
    @Environment(Authenticator.self) var authenticator
    @Environment(Database.self) var database
    @Environment(ImageCache.self) var imageCache
    @Environment(Unifier.self) var unifier

    @State var isGoingToSignOut: Bool = false
    @State var isDeletingAccount: Bool = false

    var body: some View {
        List {
            Section {
                Button("Shared.Logout") {
                    isGoingToSignOut = true
                }
                .contextMenu {
                    Button("Shared.LoginAgain", role: .destructive) {
                        unifier.isPresented = false
                        authenticator.isAuthenticating = true
                    }
                }
            }
            Section {
                Button("More.DeleteAccount", role: .destructive) {
                    #if !os(visionOS)
                    isDeletingAccount = true
                    #else
                    openURL(URL(string: "https://auth2.circle.ms/Account/WithDraw1")!)
                    #endif
                }
            }
        }
        .navigationTitle("ViewTitle.More.Accounts")
        .navigationBarTitleDisplayMode(.inline)
        #if !os(visionOS)
        .sheet(isPresented: $isDeletingAccount) {
            SafariView(url: URL(string: "https://auth2.circle.ms/Account/WithDraw1")!)
                .ignoresSafeArea()
        }
        #endif
        .alert("Alerts.Logout.Title", isPresented: $isGoingToSignOut) {
            Button("Shared.Logout", role: .destructive) {
                logout()
            }
            Button("Shared.Cancel", role: .cancel) {
                isGoingToSignOut = false
            }
        } message: {
            Text("Alerts.Logout.Message")
        }
    }

    func logout() {
        database.delete()
        imageCache.clear()
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        Task.detached {
            let actor = DataConverter(modelContainer: sharedModelContainer)
            await actor.deleteAll()
            await MainActor.run {
                unifier.close()
                authenticator.resetAuthentication()
            }
        }
    }
}
