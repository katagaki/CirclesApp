//
//  ProfileView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Komponents
import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(AuthManager.self) var authManager
    @Environment(UserManager.self) var userManager

    var body: some View {
        NavigationStack(path: $navigationManager[.profile]) {
            List {
                ListRow(image: "ListIcon.Profile.User",
                        title: userManager.userInfo?.nickname ?? "")
            }
            .navigationTitle("ViewTitle.Profile")
            .task {
                if let token = authManager.token {
                    await userManager.getUser(authToken: token)
                }
            }
        }
    }
}
