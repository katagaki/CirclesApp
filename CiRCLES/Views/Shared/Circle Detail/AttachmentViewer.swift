//
//  AttachmentViewer.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/02/28.
//

import SwiftUI

struct AttachmentViewer: View {

    @Environment(\.dismiss) var dismiss

    let attachment: CircleAttachment

    var body: some View {
        NavigationStack {
            ScrollView {
                if let image = UIImage(data: attachment.attachmentBlob) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Circles.Attachments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Shared.Back", systemImage: "chevron.left") {
                        dismiss()
                    }
                }
            }
        }
    }
}
