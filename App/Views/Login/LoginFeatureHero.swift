//
//  LoginFeatureHero.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/16.
//

import SwiftUI

struct LoginFeatureHero: View {
    var imageName: String
    var title: LocalizedStringKey
    var description: LocalizedStringKey

    var body: some View {
        HStack(alignment: .center, spacing: 16.0) {
            Image(imageName)
                .resizable()
                .frame(width: 56.0, height: 56.0)
            VStack(alignment: .leading, spacing: 6.0) {
                Text(title)
                    .fontWeight(.bold)
                Text(description)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0.0)
        }
    }
}
