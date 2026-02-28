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
        view.isHidden = true
        extractAndOpenApp()
    }

    func extractAndOpenApp() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    provider.loadItem(
                        forTypeIdentifier: UTType.image.identifier,
                        options: nil
                    ) { [weak self] item, _ in
                        let loadedData: Data? = if let url = item as? URL {
                            try? Data(contentsOf: url)
                        } else if let image = item as? UIImage {
                            image.jpegData(compressionQuality: 0.9)
                        } else {
                            item as? Data
                        }
                        Task { @MainActor in
                            if let loadedData {
                                self?.openContainingApp(with: loadedData)
                            } else {
                                self?.extensionContext?.completeRequest(returningItems: nil)
                            }
                        }
                    }
                    return
                }
            }
        }

        extensionContext?.completeRequest(returningItems: nil)
    }

    func openContainingApp(with imageData: Data) {
        let base64 = imageData.base64EncodedString()
        var components = URLComponents()
        components.scheme = "circles-app"
        components.host = "attach-product-list"
        components.queryItems = [URLQueryItem(name: "image", value: base64)]

        guard let url = components.url else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }

        var responder: UIResponder? = self
        while let current = responder {
            if let application = current as? UIApplication {
                application.open(url, options: [:]) { [weak self] _ in
                    self?.extensionContext?.completeRequest(returningItems: nil)
                }
                return
            }
            responder = current.next
        }

        extensionContext?.completeRequest(returningItems: nil)
    }
}
