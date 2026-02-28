//
//  ActionViewController.swift
//  AttachProductList
//
//  Created by シン・ジャスティン on 2026/02/28.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

@MainActor
class ActionViewController: UIViewController {

    var imageData: Data?

    override func viewDidLoad() {
        super.viewDidLoad()
        extractImage()
    }

    func extractImage() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) {
                        [weak self] item, _ in
                        let loadedData: Data? = if let url = item as? URL {
                            try? Data(contentsOf: url)
                        } else if let image = item as? UIImage {
                            image.jpegData(compressionQuality: 0.9)
                        } else {
                            item as? Data
                        }
                        Task { @MainActor in
                            self?.imageData = loadedData
                            self?.showSearchView()
                        }
                    }
                    return
                }
            }
        }
    }

    func showSearchView() {
        guard let imageData else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }

        let searchView = ActionExtensionSearchView(
            imageData: imageData,
            onComplete: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            },
            onCancel: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            }
        )

        let hostingController = UIHostingController(rootView: searchView)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
}
