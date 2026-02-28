//
//  ActionViewController.swift
//  AttachProductList
//
//  Created by シン・ジャスティン on 2026/02/28.
//

import UIKit
import UniformTypeIdentifiers

@MainActor
class ActionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        extractAndSaveImage()
    }

    func extractAndSaveImage() {
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
                            if let loadedData {
                                self?.saveToGroupContainer(loadedData)
                            }
                            self?.openContainingApp()
                        }
                    }
                    return
                }
            }
        }

        extensionContext?.completeRequest(returningItems: nil)
    }

    func saveToGroupContainer(_ imageData: Data) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.tsubuzaki.CiRCLES"
        ) else { return }

        let pendingDir = containerURL.appending(path: "PendingAttachments")
        try? FileManager.default.createDirectory(at: pendingDir, withIntermediateDirectories: true)

        let fileURL = pendingDir.appending(path: "\(UUID().uuidString).jpg")
        try? imageData.write(to: fileURL)
    }

    func openContainingApp() {
        guard let url = URL(string: "circles-app://attach-product-list") else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }

        // Walk up the responder chain to find an object that can open URLs
        var responder: UIResponder? = self
        let selector = NSSelectorFromString("openURL:")
        while let r = responder {
            if r.responds(to: selector) {
                r.perform(selector, with: url)
                break
            }
            responder = r.next
        }

        extensionContext?.completeRequest(returningItems: nil)
    }
}
