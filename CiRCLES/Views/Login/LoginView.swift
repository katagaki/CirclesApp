//
//  LoginView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/19.
//

import SwiftUI

struct LoginView: View {

    @Environment(AuthManager.self) var authManager

    @State var isAuthenticating: Bool = false
    @State var isShowingDemoAlert: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            Text("Login.Title")
                .fontWeight(.bold)
                .font(.largeTitle)
            Spacer()
            HStack {
                Image(systemName: "info.circle")
                Text("Login.Disclaimer")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            Button {
                isShowingDemoAlert = true
            } label: {
                Text("Shared.Login.Demo")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding([.top, .bottom], 6.0)
            }
            .buttonStyle(.bordered)
            .clipShape(.capsule(style: .continuous))
            Button {
                isAuthenticating = true
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
        .sheet(isPresented: $isAuthenticating) {
            SafariView(url: authManager.authURL)
                .ignoresSafeArea()
        }
        .alert("Alert.Unavailable.Title", isPresented: $isShowingDemoAlert) {
            Button("Shared.OK") {
                isShowingDemoAlert = false
            }
        } message: {
            Text("Alert.Unavailable.Text")
        }
        .onChange(of: authManager.code) { oldValue, newValue in
            if oldValue == nil && newValue != nil {
                Task {
                    await authManager.getAuthenticationToken()
                }
            }
        }
    }
}
