//
//  LoadingPill.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/15.
//

import SwiftUI

struct LoadingPill: View {

    @Environment(Database.self) var database

    var namespace: Namespace.ID
    @Binding var progressHeaderText: String?

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
            HStack(spacing: 4.0) {
                ProgressView()
                    .matchedGeometryEffect(id: "LoadingProgressIndicator", in: namespace)
                if progressHeaderText != nil || database.progressTextKey != nil {
                    VStack(spacing: 2.0) {
                        if let progressHeaderText {
                            Text(NSLocalizedString(progressHeaderText, comment: ""))
                                .font(.caption)
                                .fontWeight(.bold)
                                .matchedGeometryEffect(id: "LoadingProgressHeader", in: namespace)
                        }
                        if let progressTextKey = database.progressTextKey {
                            Text(NSLocalizedString(progressTextKey, comment: ""))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .matchedGeometryEffect(id: "LoadingProgressText", in: namespace)
                        }
                    }
                }
            }
            .padding([.top, .bottom], 4.0)
            .padding([.leading, .trailing], 8.0)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(.capsule(style: .continuous))
            .matchedGeometryEffect(id: "LoadingWindow", in: namespace)
            .padding(8.0)
            .shadow(radius: 3.0, y: 3.0)
        }
        .transition(.move(edge: .top).animation(.smooth.speed(2.0)))
    }
}
