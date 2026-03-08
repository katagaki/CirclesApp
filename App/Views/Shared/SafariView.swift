//
//  SafariView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/09.
//

import SafariServices
import SwiftUI
import UIKit

#if !os(visionOS)
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context _: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.barCollapsingEnabled = false

        let safariViewController = SFSafariViewController(
            url: url,
            configuration: configuration)
        safariViewController.dismissButtonStyle = .cancel
        safariViewController.hidesBottomBarWhenPushed = false

        return safariViewController
    }

    func updateUIViewController(_ safariViewController: SFSafariViewController, context _: Context) {
        // No updates needed; SFSafariViewController manages its own state.
    }
}
#endif
