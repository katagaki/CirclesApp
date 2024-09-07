//
//  MyProfileSection.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import SwiftUI

struct MyProfileSection: View {

    @Binding var userInfo: UserInfo.Response?

    @State var isShowingUserPID: Bool = false

    var body: some View {
        Section {
            VStack(alignment: .center, spacing: 10.0) {
                Image(.profile1)
                    .resizable()
                    .frame(width: 96.0, height: 96.0)
                    .clipShape(.circle)
                    .onTapGesture {
                        isShowingUserPID.toggle()
                    }
                VStack(alignment: .center) {
                    if let userInfo {
                        Text(userInfo.nickname)
                            .fontWeight(.bold)
                            .font(.title3)
                    } else {
                        ProgressView()
                    }
                    if isShowingUserPID {
                        Text("PID " + String(userInfo?.pid ?? 0))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 2.0)
                Link(destination: URL(string: "https://myportal.circle.ms/")!) {
                    Text("Profile.Edit")
                        .font(.caption)
                        .underline()
                        .foregroundStyle(.accent)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                0.0
            }
        }
        .listRowBackground(Color.clear)
    }
}
