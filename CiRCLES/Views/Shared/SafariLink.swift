//
//  SafariLink.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import Komponents
import SwiftUI

struct SafariLink: View {

    var url: URL
    var title: String
    var image: String

    init(_ url: String, title: String, image: String) {
        self.url = URL(string: url)!
        self.title = title
        self.image = image
    }

    var body: some View {
        Link(destination: url) {
            HStack(alignment: .center) {
                #if targetEnvironment(macCatalyst)
                Text(LocalizedStringKey(title))
                #else
                ListRow(image: image, title: title)
                    .foregroundStyle(.foreground)
                Spacer()
                #endif
                Image(systemName: "safari")
                    .foregroundStyle(.foreground.opacity(0.5))
            }
        }
    }
}
