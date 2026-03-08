//
//  URLSchemeHandler.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/08/18.
//

import SwiftUI
import RADiUS

struct URLSchemeHandlerModifier: ViewModifier {

    @Environment(Authenticator.self) var authenticator
    @Environment(Unifier.self) var unifier

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                if url.scheme == "circles-app" && url.host() == "attach-product-list",
                   let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let base64 = components.queryItems?.first(where: { $0.name == "image" })?.value,
                   let data = Data(base64Encoded: base64) {
                    unifier.pendingAttachmentData = data
                } else if url.absoluteString == circleMsCancelURLSchema {
                    authenticator.isWaitingForAuthenticationCode = false
                } else {
                    authenticator.getAuthenticationCode(from: url)
                }
            }
    }
}

extension View {
    func urlSchemeHandler() -> some View {
        self.modifier(URLSchemeHandlerModifier())
    }
}
