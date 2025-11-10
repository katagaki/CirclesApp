//
//  SNSButton.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/01.
//

import SwiftUI

struct SNSButton: View {

    @Environment(\.openURL) var openURL

    var url: URL
    var showsLabel: Bool
    var type: SNSType

    init(_ url: URL, showsLabel: Bool = true, type: SNSType) {
        self.url = url
        self.showsLabel = showsLabel
        self.type = type
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            buttonWithIcon()
                .foregroundStyle(.white)
                .buttonStyle(.glassProminent)
        } else {
            buttonWithIcon()
                .clipShape(showsLabel ? AnyShape(.capsule) : AnyShape(.circle))
                .buttonStyle(.borderedProminent)
        }
    }

    // swiftlint:disable function_body_length
    @ViewBuilder
    func buttonWithIcon() -> some View {
        switch type {
        case .twitter:
            Button {
                openURL(url)
            } label: {
                Image(.snsTwitter)
                    .resizable()
                    .frame(width: 28.0, height: 28.0)
                    .foregroundStyle(.white)
                    .padding(1.0)
                if showsLabel {
                    Text("Shared.SNS.Twitter")
                }
            }
            .tint(.init(red: 0.05, green: 0.05, blue: 0.05))
        case .pixiv:
            Button {
                var urlToOpen: URL = url
                if UIApplication.shared.canOpenURL(URL(string: "pixiv://")!) {
                    let pixivPrefix = "https://www.pixiv.net/member.php?id="
                    let urlString = url.absoluteString
                    if urlString.starts(with: pixivPrefix) {
                        let userID = urlString.trimmingPrefix(pixivPrefix)
                        let formattedURL = "pixiv://users/\(userID)"
                        if let appURL = URL(string: formattedURL) {
                            urlToOpen = appURL
                        }
                    }
                }
                openURL(urlToOpen)
            } label: {
                Image(.snsPixiv)
                    .resizable()
                    .frame(width: 28.0, height: 28.0)
                    .foregroundStyle(.white)
                    .padding(1.0)
                if showsLabel {
                    Text("Shared.SNS.Pixiv")
                }
            }
            .tint(.blue)
        case .circleMs:
            Button {
                openURL(url)
            } label: {
                Image(.snsCircleMs)
                    .resizable()
                    .frame(width: 28.0, height: 28.0)
                    .foregroundStyle(.white)
                    .padding(1.0)
                if showsLabel {
                    Text("Shared.SNS.CircleMsPortal")
                }
            }
            .tint(.green)
        }
    }
    // swiftlint:enable function_body_length
}
