import SwiftUI

struct SharedBuysActivityPhoto: View {

    let image: UIImage

    var body: some View {
        Color.clear
            .aspectRatio(1.0, contentMode: .fit)
            .frame(minHeight: 0.0, idealHeight: 0.0, maxHeight: .infinity)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(.rect(cornerRadius: 8.0))
    }
}
