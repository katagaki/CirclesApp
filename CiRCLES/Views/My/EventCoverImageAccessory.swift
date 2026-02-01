//
//  EventCoverImageAccessory.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/09.
//

import SwiftUI

struct EventCoverImageAccessory: View {
    @Binding var isShowing: Bool
    @Binding var image: UIImage?

    var body: some View {
        VStack {
            if let image {
                if isShowing {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8.0))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8.0)
                                .stroke(Color.primary.opacity(0.5), lineWidth: 1/3)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    Image(.arrow)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 10.0, alignment: .center)
                        .rotationEffect(isShowing ? Angle.degrees(180.0) : Angle.degrees(0.0))
                }
            }
        }
        .padding(.bottom)
        .contentShape(.rect)
        .onTapGesture {
            if image != nil {
                withAnimation(.smooth.speed(2.0)) {
                    isShowing.toggle()
                }
            }
        }
    }

//    func bottomPadding() -> CGFloat {
//        if image != nil {
//            return UIDevice.current.userInterfaceIdiom != .pad ? 6.0 : 12.0
//        } else {
//            return 0.0
//        }
//    }
}
