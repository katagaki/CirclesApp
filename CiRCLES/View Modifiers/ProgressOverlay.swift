//
//  ProgressOverlay.swift
//  CiRCLES
//
//  Created by GitHub Copilot on 2025/11/03.
//

import SwiftUI

struct ProgressOverlay: View {
    @Binding var headerText: String?
    @Binding var bodyText: String?
    @Binding var progress: Double?
    @Binding var showOfflineOption: Bool
    var onUseOfflineMode: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent fullscreen background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // Dialog-like content
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    if let headerText {
                        Text(NSLocalizedString(headerText, comment: ""))
                            .font(.headline)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let bodyText {
                        Text(NSLocalizedString(bodyText, comment: ""))
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                if let progress {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .tint(.accentColor)
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                
                if showOfflineOption {
                    Button(action: onUseOfflineMode) {
                        Text(NSLocalizedString("Shared.UseOfflineMode", comment: ""))
                            .font(.body)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
            }
            .padding(24)
            .frame(maxWidth: 350)
            .background(Material.regular)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(32)
        }
        .transition(.opacity.animation(.smooth.speed(2.0)))
    }
}
