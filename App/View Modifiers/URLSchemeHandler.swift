import ORBiT
import RADiUS
import SwiftUI

struct URLSchemeHandlerModifier: ViewModifier {

    @Environment(Authenticator.self) var authenticator
    @Environment(Unifier.self) var unifier
    @Environment(SharedBuysSession.self) var sharedBuys

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                // Every buys-* link, the join link included, belongs to a feature that may
                // be switched off; the rest of the schemes are unaffected.
                if url.scheme == "circles-app", let host = url.host(),
                   host.hasPrefix("buys-") || host == SharedBuysSession.joinHost,
                   !sharedBuys.isFeatureEnabled {
                    return
                }
                if url.scheme == "circles-app" && url.host() == "buys-selftest" {
                    sharedBuys.runSelfTest()
                    unifier.isSharedBuysDebugPresenting = true
                } else if url.scheme == "circles-app" && url.host() == "buys-add",
                   let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    let name = components.queryItems?.first(where: { $0.name == "name" })?.value ?? ""
                    let cost = Int(components.queryItems?.first(where: { $0.name == "cost" })?.value ?? "") ?? 0
                    sharedBuys.addItem(name: name, cost: cost, circleID: 1)
                } else if url.scheme == "circles-app" && url.host() == "buys-cycle",
                          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                          let itemID = components.queryItems?.first(where: { $0.name == "item" })?.value,
                          let item = sharedBuys.items.first(where: { $0.id == itemID }) {
                    sharedBuys.cycle(item)
                } else if url.scheme == "circles-app" && url.host() == "buys-debug" {
                    unifier.isSharedBuysDebugPresenting = true
                } else if url.scheme == "circles-app" && url.host() == SharedBuysSession.joinHost {
                    sharedBuys.adoptIdentity()
                    sharedBuys.join(url: url, nickname: sharedBuys.nickname)
                    unifier.current = .buys
                    unifier.expand()
                } else if url.scheme == "circles-app" && url.host() == "sixseven" {
                    authenticator.isAuthenticating = true
                } else if url.scheme == "circles-app" && url.host() == "attach-product-list",
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
