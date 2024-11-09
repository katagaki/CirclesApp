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
                        .frame(maxWidth: .infinity, maxHeight: 300.0, alignment: .center)
                }
                Image(.arrow)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 10.0, alignment: .center)
                    .rotationEffect(isShowing ? Angle.degrees(180.0) : Angle.degrees(0.0))
            }
        }
        .padding(.bottom, UIDevice.current.userInterfaceIdiom != .pad ? 6.0 : 12.0)
        .contentShape(.rect)
        .onTapGesture {
            withAnimation(.smooth.speed(2.0)) {
                isShowing.toggle()
            }
        }

    }
}