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
            for provider in attachments
            where provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
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

        extractTextAndOpenApp(from: extensionItems)
    }

    /// Posts are shared as their text, their link, or both; the app reads whichever it
    /// gets, and fetches the text of a link to an X post itself.
    func extractTextAndOpenApp(from extensionItems: [NSExtensionItem]) {
        let providers = extensionItems.flatMap { $0.attachments ?? [] }
        let texts = extensionItems.compactMap { $0.attributedContentText?.string }
        Task {
            var loaded = texts
            for provider in providers {
                if let text = await Self.loadString(from: provider) {
                    loaded.append(text)
                }
            }
            let text = loaded
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .reduce(into: [String]()) { result, text in
                    if !result.contains(text) { result.append(text) }
                }
                .joined(separator: "\n")
            if text.isEmpty {
                extensionContext?.completeRequest(returningItems: nil)
            } else {
                openContainingApp(withText: text)
            }
        }
    }

    static func loadString(from provider: NSItemProvider) async -> String? {
        let typeIdentifier: String
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            typeIdentifier = UTType.url.identifier
        } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            typeIdentifier = UTType.plainText.identifier
        } else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                let string: String? = if let url = item as? URL {
                    url.absoluteString
                } else if let text = item as? String {
                    text
                } else if let data = item as? Data {
                    String(data: data, encoding: .utf8)
                } else {
                    nil
                }
                continuation.resume(returning: string)
            }
        }
    }

    func openContainingApp(with imageData: Data) {
        let base64 = imageData.base64EncodedString()
        var components = URLComponents()
        components.scheme = "circles-app"
        components.host = "attach-product-list"
        components.queryItems = [URLQueryItem(name: "image", value: base64)]
        open(components.url)
    }

    func openContainingApp(withText text: String) {
        var components = URLComponents()
        components.scheme = "circles-app"
        components.host = "find-circles"
        components.queryItems = [URLQueryItem(name: "text", value: text)]
        open(components.url)
    }

    func open(_ url: URL?) {
        guard let url else {
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
