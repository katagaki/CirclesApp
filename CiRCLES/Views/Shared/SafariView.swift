//
//  SafariView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/09.
//

import SafariServices
import SwiftUI
import UIKit

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.barCollapsingEnabled = false

        let safariViewController = SFSafariViewController(
            url: url,
            configuration: configuration)
        safariViewController.dismissButtonStyle = .cancel
        safariViewController.preferredControlTintColor = .accent
        safariViewController.hidesBottomBarWhenPushed = false

        return safariViewController
    }

    func updateUIViewController(_ safariViewController: SFSafariViewController, context: Context) {

    }
}
