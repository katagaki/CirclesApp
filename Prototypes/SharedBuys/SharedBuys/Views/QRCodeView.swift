//
//  QRCodeView.swift
//  SharedBuys
//

import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRCodeView: View {

    let contents: String
    var size: CGFloat = 180.0

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 8.0)
                    .fill(Color(.systemGray5))
            }
        }
        .frame(width: size, height: size)
        .padding(12.0)
        .background(.white, in: RoundedRectangle(cornerRadius: 16.0))
    }

    var image: UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(contents.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 8.0, y: 8.0))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
