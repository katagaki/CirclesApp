//
//  LoginView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/19.
//

import SwiftUI

struct LoginView: View {
    @State var username: String = ""
    @State var password: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            Text("Login.Title")
                .fontWeight(.bold)
                .font(.largeTitle)
            Spacer()
            VStack(alignment: .leading, spacing: 8.0) {
                Text("Shared.Email")
                TextField("Shared.Email", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.none)
            }
            VStack(alignment: .leading, spacing: 8.0) {
                Text("Shared.Password")
                SecureField("Shared.Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .privacySensitive()
                Link("Shared.ForgotPassword", destination: URL(string: "https://auth2.circle.ms/Account/RecoveryPassword")!)
            }
            Spacer()
            HStack {
                Image(systemName: "info.circle")
                Text("Login.Disclaimer")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            Button {
                // TODO
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

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            LoginView()
        }
}
