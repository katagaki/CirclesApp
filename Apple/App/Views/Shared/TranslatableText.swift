import SwiftUI
#if !targetEnvironment(macCatalyst) && !os(visionOS)
import Translation
#endif

struct TranslatableText: View {
    let text: String
    let canTranslate: Bool

#if !targetEnvironment(macCatalyst) && !os(visionOS)
    @State private var translatedText: String?
    @State private var configuration: TranslationSession.Configuration?
#endif

    init(_ text: String, canTranslate: Bool = true) {
        self.text = text
        self.canTranslate = canTranslate
    }

    var body: some View {
#if !targetEnvironment(macCatalyst) && !os(visionOS)
        ZStack(alignment: .leading) {
            Text(translatedText ?? text)
                .textSelection(.enabled)
                .id(translatedText == nil)
                .transition(.blurReplace)
        }
        .contextMenu {
            copyButton
            if canTranslate && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if translatedText == nil {
                    Button("Shared.Translate", systemImage: "character.bubble") {
                        translate()
                    }
                } else {
                    Button("Shared.ShowOriginal", systemImage: "character.bubble.fill") {
                        withAnimation(.smooth) {
                            translatedText = nil
                        }
                    }
                }
            }
        }
        .translationTask(configuration) { session in
            guard let result = await Self.translate(text, in: SessionBox(session: session)) else { return }
            withAnimation(.smooth) {
                translatedText = result
            }
        }
        .onChange(of: text) {
            translatedText = nil
        }
#else
        Text(text)
            .textSelection(.enabled)
            .contextMenu {
                copyButton
            }
#endif
    }

    var copyButton: some View {
        Button("Shared.Copy", systemImage: "doc.on.doc") {
            UIPasteboard.general.string = text
        }
    }

#if !targetEnvironment(macCatalyst) && !os(visionOS)
    struct SessionBox: @unchecked Sendable {
        let session: TranslationSession
    }

    nonisolated static func translate(_ text: String, in box: SessionBox) async -> String? {
        try? await box.session.translate(text).targetText
    }

    func translate() {
        // Set by the AppStoreScreenshots UI test: simulators cannot run the translator.
        if let stub = UserDefaults.standard.string(forKey: "ScreenshotTranslation") {
            withAnimation(.smooth) {
                translatedText = stub
            }
            return
        }
        if configuration == nil {
            configuration = TranslationSession.Configuration()
        } else {
            configuration?.invalidate()
        }
    }
#endif
}
