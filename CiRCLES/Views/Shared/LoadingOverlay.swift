//
//  LoadingOverlay.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/08.
//

import SwiftUI

struct LoadingOverlay: View {

    @Environment(Database.self) var database

    var namespace: Namespace.ID
    @Binding var progressHeaderText: String?

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
            VStack(spacing: 12.0) {
                if progressHeaderText != nil || database.progressTextKey != nil {
                    VStack(spacing: 6.0) {
                        if let progressHeaderText {
                            Text(NSLocalizedString(progressHeaderText, comment: ""))
                                .fontWeight(.bold)
                                .matchedGeometryEffect(id: "LoadingProgressHeader", in: namespace)
                        }
                        if let progressTextKey = database.progressTextKey {
                            Text(NSLocalizedString(progressTextKey, comment: ""))
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .matchedGeometryEffect(id: "LoadingProgressText", in: namespace)
                        }
                    }
                }
                if database.isDownloading {
                    ProgressView(value: database.downloadProgress, total: 1.0)
                        .progressViewStyle(.linear)
                } else {
                    ProgressView()
                        .matchedGeometryEffect(id: "LoadingProgressIndicator", in: namespace)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Material.regular)
            .clipShape(RoundedRectangle(cornerRadius: 16.0))
            .matchedGeometryEffect(id: "LoadingWindow", in: namespace)
            .padding(32.0)
        }
        .ignoresSafeArea()
        .transition(.opacity.animation(.snappy.speed(2.0)))
    }
}
