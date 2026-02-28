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

    var loadedImageData: Data?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        extractImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let loadedImageData {
            openContainingApp(with: loadedImageData)
        } else {
            // Image not loaded yet; wait for the async callback
        }
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
                            guard let self, let loadedData else {
                                self?.extensionContext?.completeRequest(returningItems: nil)
                                return
                            }
                            self.loadedImageData = loadedData
                            // Only open if viewDidAppear already fired
                            if self.viewIfLoaded?.window != nil {
                                self.openContainingApp(with: loadedData)
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

        // Walk up the responder chain to find an object that can open URLs.
        // The view must be in the window hierarchy for the chain to reach
        // the top-level object that responds to openURL:.
        var responder: UIResponder? = self
        let selector = NSSelectorFromString("openURL:")
        while let r = responder {
            if r.responds(to: selector) {
                r.perform(selector, with: url)
                break
            }
            responder = r.next
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
