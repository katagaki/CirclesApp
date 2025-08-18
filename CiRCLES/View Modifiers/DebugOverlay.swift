//
//  DebugOverlay.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/07/21.
//

import SwiftUI

#if DEBUG
struct DebugOverlayModifier: ViewModifier {
    @Environment(Authenticator.self) var authenticator
    @Environment(Events.self) var planner

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack(alignment: .topLeading) {
                    Color.clear
                    VStack(alignment: .leading) {
                        Group {
                            switch authenticator.onlineState {
                            case .online:
                                RoundedRectangle(cornerRadius: 6.0)
                                    .fill(Color.green)
                            case .offline:
                                RoundedRectangle(cornerRadius: 6.0)
                                    .fill(Color.red)
                            case .undetermined:
                                RoundedRectangle(cornerRadius: 6.0)
                                    .fill(Color.gray)
                            }
                        }
                        .frame(width: 8.0, height: 8.0)
                        Group {
                            Text(verbatim: "Token expiry: \(authenticator.tokenExpiryDate)")
                            Text(verbatim: "Token string: \((authenticator.token?.accessToken ?? "").prefix(5))")
                            Text(verbatim: "Active event number: \(planner.activeEventNumber)")
                            Text(verbatim: "Event count: \(String(describing: planner.eventData?.list.count))")
                        }
                        .font(.system(size: 10.0))
                    }
                }
            }
    }
}

extension View {
    func debugOverlay() -> some View {
        self.modifier(DebugOverlayModifier())
    }
}
#endif
