//
//  SharedBuysScannerView.swift
//  CiRCLES
//

import AVFoundation
import ORBiT
import SwiftUI
import VisionKit

/// Scans the code shown by `SharedBuysSheet` and hands back the join URL.
///
/// The code is a `circles-app://buys-join` link, so a member who already has the app can
/// point the system camera at it and be taken straight in. A guest cannot: they arrive at
/// a login screen with no way to feed it a URL. This is that way in.
struct SharedBuysScannerView: View {

    @Environment(\.dismiss) var dismiss

    /// Called with a URL that is shaped like a join link. Whether the key inside it is
    /// usable is `join(url:nickname:)`'s call to make, not ours.
    let onScan: (URL) -> Void

    @State private var isCameraDenied: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if isCameraDenied {
                    ContentUnavailableView {
                        Label("Buys.Guest.Scan.NoCamera", systemImage: "video.slash")
                    } description: {
                        Text("Buys.Guest.Scan.NoCamera.Description")
                    } actions: {
                        Button("Buys.Guest.Scan.OpenSettings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    CodeScanner { url in
                        onScan(url)
                        dismiss()
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .overlay(alignment: .bottom) {
                        Text("Buys.Guest.Scan.Hint")
                            .font(.subheadline)
                            .padding()
                            .background(.regularMaterial, in: Capsule())
                            .padding(.bottom, 32.0)
                    }
                } else {
                    // Simulators and devices without a Neural Engine cannot run the
                    // scanner at all. Saying so beats a permanently black viewfinder.
                    ContentUnavailableView(
                        "Buys.Guest.Scan.Unsupported",
                        systemImage: "qrcode.viewfinder",
                        description: Text("Buys.Guest.Scan.Unsupported.Description")
                    )
                }
            }
            .navigationTitle("Buys.Guest.Scan.Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Shared.Cancel") { dismiss() }
                }
            }
        }
        .task {
            guard AVCaptureDevice.authorizationStatus(for: .video) != .authorized else { return }
            isCameraDenied = !(await AVCaptureDevice.requestAccess(for: .video))
        }
    }
}

private struct CodeScanner: UIViewControllerRepresentable {

    let onScan: (URL) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        // `startScanning` throws if the view is not yet in a window, and SwiftUI calls
        // this again once it is, so a failure here is a state to retry rather than an
        // error to surface.
        try? controller.startScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {

        let onScan: (URL) -> Void

        /// The scanner keeps recognising the same code many times a second while it is
        /// in frame. Only the first one is a join.
        private var hasScanned = false

        init(onScan: @escaping (URL) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            handle(addedItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didTapOn item: RecognizedItem
        ) {
            handle([item])
        }

        private func handle(_ items: [RecognizedItem]) {
            guard !hasScanned else { return }
            for case .barcode(let barcode) in items {
                guard let payload = barcode.payloadStringValue,
                      let url = URL(string: payload),
                      url.scheme == "circles-app",
                      url.host() == SharedBuysSession.joinHost
                else { continue }
                hasScanned = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onScan(url)
                return
            }
        }
    }
}
