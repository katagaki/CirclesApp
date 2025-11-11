//
//  CircleDetailHero.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/10.
//

import SwiftUI

struct CircleDetailHero: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites

    @Binding var circle: ComiketCircle
    @Binding var extendedInformation: ComiketCircleExtendedInformation?
    @Binding var favoriteMemo: String

    @State var currentCutType: CircleCutType = .catalog
    @State var hasShownWebCutOnce: Bool = false

    @AppStorage(wrappedValue: false, "Customization.ShowWebCut") var showWebCut: Bool

    let namespace: Namespace.ID

    var body: some View {
        HStack(alignment: .top, spacing: 12.0) {
            // Cut image
            VStack(alignment: .leading, spacing: 2.0) {
                CircleCutImage(
                    circle,
                    in: namespace,
                    cutType: currentCutType,
                    forceReload: currentCutType == .web && !hasShownWebCutOnce,
                    showSpaceName: .constant(false),
                    showDay: .constant(false)
                )
                .frame(width: 120.0, height: 172.0)
                .onTapGesture {
                    if authenticator.onlineState == .online {
                        withAnimation(.smooth.speed(2.0)) {
                            toggleCutType()
                        }
                    }
                }
                Group {
                    switch currentCutType {
                    case .catalog:
                        Text("Circles.Image.Catalog")
                    case .web:
                        Text("Circles.Image.Web")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            // Info stack
            VStack(alignment: .leading, spacing: 8.0) {
                HStack(spacing: 5.0) {
                    CircleBlockPill("Shared.\(circle.day)th.Day", size: .large)
                    if let circleSpaceName = circle.spaceName() {
                        CircleBlockPill(LocalizedStringKey(circleSpaceName), size: .large)
                    }
                }

                if !favoriteMemo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    InfoStackSection(
                        title: "Shared.Memo.Favorites",
                        contents: favoriteMemo,
                        canTranslate: false,
                        showContextMenu: false
                    )
                }

                if circle.supplementaryDescription.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                    InfoStackSection(
                        title: "Shared.Description",
                        contents: circle.supplementaryDescription,
                        canTranslate: true
                    )
                } else {
                    InfoStackSection(
                        title: "Shared.Description",
                        contents: String(localized: "Circles.NoDescription"),
                        canTranslate: false
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8.0)
        .onAppear {
            currentCutType = showWebCut ? .web : .catalog
            hasShownWebCutOnce = showWebCut
        }
        .onChange(of: circle.id) {
            currentCutType = .catalog
            hasShownWebCutOnce = false
        }
    }

    func toggleCutType() {
        withAnimation(.smooth.speed(2.0)) {
            switch currentCutType {
            case .catalog:
                currentCutType = .web
                if !hasShownWebCutOnce {
                    hasShownWebCutOnce = true
                }
            case .web:
                currentCutType = .catalog
            }
        }
    }
}
