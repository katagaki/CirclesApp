//
//  LoadingOverlay.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/08.
//

import SwiftUI

struct LoadingOverlay: View {
    var namespace: Namespace.ID
    @Binding var headerText: String?
    @Binding var bodyText: String?
    @Binding var progress: Double?

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
            VStack(spacing: 12.0) {
                if headerText != nil || bodyText != nil {
                    VStack(spacing: 6.0) {
                        if let headerText {
                            Text(NSLocalizedString(headerText, comment: ""))
                                .fontWeight(.bold)
                                .matchedGeometryEffect(id: "LoadingProgressHeader", in: namespace)
                        }
                        if let bodyText {
                            Text(NSLocalizedString(bodyText, comment: ""))
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .matchedGeometryEffect(id: "LoadingProgressText", in: namespace)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                if let progress {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(.linear)
                } else {
                    ProgressView()
                        .matchedGeometryEffect(id: "LoadingProgressIndicator", in: namespace)
                }
            }
            .padding()
            .frame(maxWidth: 350.0)
            .background(Material.regular)
            .clipShape(RoundedRectangle(cornerRadius: 16.0))
            .matchedGeometryEffect(id: "LoadingWindow", in: namespace)
            .padding(32.0)
        }
        .ignoresSafeArea()
        .transition(.opacity.animation(.snappy.speed(2.0)))
    }
}
