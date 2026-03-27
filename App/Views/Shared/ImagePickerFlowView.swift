//
//  ImagePickerFlowView.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/27.
//

import PhotosUI
import SwiftUI

struct ImagePickerFlowView: View {

    let onComplete: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?

    var body: some View {
        Group {
            if let pickedImage {
                ImageCropView(
                    image: pickedImage,
                    onCrop: { croppedImage in
                        onComplete(croppedImage)
                    },
                    onCancel: {
                        onCancel()
                    }
                )
            } else {
                PhotoPickerRepresentable(
                    onPick: { image in
                        pickedImage = image
                    },
                    onCancel: {
                        onCancel()
                    }
                )
                .ignoresSafeArea()
            }
        }
    }
}

struct PhotoPickerRepresentable: UIViewControllerRepresentable {

    let onPick: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (UIImage) -> Void
        let onCancel: () -> Void

        init(onPick: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                onCancel()
                return
            }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                guard let uiImage = image as? UIImage,
                      let imageData = uiImage.pngData() else {
                    DispatchQueue.main.async {
                        self.onCancel()
                    }
                    return
                }
                DispatchQueue.main.async {
                    if let result = UIImage(data: imageData) {
                        self.onPick(result)
                    } else {
                        self.onCancel()
                    }
                }
            }
        }
    }
}
