//
//  UIImage.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import UIKit

// Adapted from:
// https://www.hackingwithswift.com/example-code/media/how-to-read-the-average-color-of-a-uiimage-using-ciareaaverage
extension UIImage {
    var accentColor: UIColor {
        if let inputImage = CIImage(image: self) {
            let extentVector = CIVector(
                x: inputImage.extent.origin.x,
                y: inputImage.extent.origin.y,
                z: inputImage.extent.size.width,
                w: inputImage.extent.size.height
            )
            if let filter = CIFilter(
                name: "CIAreaAverage",
                parameters: [kCIInputImageKey: inputImage,
                            kCIInputExtentKey: extentVector]
            ),
               let outputImage = filter.outputImage {
                var bitmap = [UInt8](repeating: 0, count: 4)
                let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
                context.render(
                    outputImage,
                    toBitmap: &bitmap,
                    rowBytes: 4,
                    bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                    format: .RGBA8,
                    colorSpace: nil
                )
                let baseColor = UIColor(
                    red: CGFloat(bitmap[0]) / 255,
                    green: CGFloat(bitmap[1]) / 255,
                    blue: CGFloat(bitmap[2]) / 255,
                    alpha: CGFloat(bitmap[3]) / 255
                )
                var hue: CGFloat = 0.0
                var saturation: CGFloat = 0.0
                var brightness: CGFloat = 0.0
                var alpha: CGFloat = 0.0
                baseColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
                return UIColor(
                    hue: hue,
                    saturation: max(saturation + 0.2, 0.5),
                    brightness: brightness,
                    alpha: alpha
                )
            }
        }
        return UIColor.systemGroupedBackground
    }
}
