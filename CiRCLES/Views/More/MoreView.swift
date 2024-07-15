//
//  MoreView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Komponents
import SwiftUI

struct MoreView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(AuthManager.self) var authManager
    @Environment(UserManager.self) var userManager

    @State var isShowingUserPID: Bool = false

    var body: some View {
        NavigationStack(path: $navigationManager[.more]) {
            MoreList(repoName: "katagaki/CirclesApp") {
                HStack(alignment: .center, spacing: 16.0) {
                    Image("Profile.1")
                        .resizable()
                        .frame(width: 56.0, height: 56.0)
                        .clipShape(.circle)
                    VStack(alignment: .leading) {
                        Text(userManager.userInfo?.nickname ?? NSLocalizedString("Profile.GenericUser", comment: ""))
                            .fontWeight(.medium)
                            .font(.title3)
                        if isShowingUserPID {
                            Text("PID " + String(userManager.userInfo?.pid ?? 0))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .contentShape(.rect)
                .onTapGesture {
                    isShowingUserPID.toggle()
                }
                Link(destination: URL(string: "https://myportal.circle.ms/")!) {
                    HStack(alignment: .center) {
                        Text("Profile.Edit")
                        Spacer()
                        Image(systemName: "safari")
                            .foregroundStyle(.secondary)
                    }
                }
                Button("Shared.LoginAgain", role: .destructive) {
                    authManager.token = nil
                }
            }
            .task {
                if let token = authManager.token {
                    await userManager.getUser(authToken: token)
                }
            }
        }
    }
}
