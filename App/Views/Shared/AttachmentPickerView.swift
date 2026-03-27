//
//  AttachmentPickerView.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/27.
//

import SwiftUI
import AXiS

struct AttachmentPickerView: View {

    let circle: ComiketCircle
    let onSelect: (UIImage) -> Void
    let onCancel: () -> Void

    var attachments: [CircleAttachment] {
        AttachmentsDatabase.shared.attachments(
            eventNumber: circle.eventNumber,
            circleID: circle.id
        )
    }

    let columns = [
        GridItem(.adaptive(minimum: 120.0), spacing: 8.0)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if attachments.isEmpty {
                    ContentUnavailableView(
                        "Buys.NoAttachments",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Buys.NoAttachments.Description")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8.0) {
                            ForEach(attachments) { attachment in
                                if let image = UIImage(data: attachment.attachmentBlob) {
                                    Button {
                                        onSelect(image)
                                    } label: {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(minHeight: 120.0)
                                            .clipShape(RoundedRectangle(cornerRadius: 8.0))
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Buys.SelectFromAttachments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Shared.Cancel") {
                        onCancel()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
