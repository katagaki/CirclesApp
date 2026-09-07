import SwiftUI
import AXiS

struct UnifiedCompactCircleBar: View {

    @Environment(Unifier.self) var unifier

    @Namespace var namespace

    let circle: ComiketCircle

    var body: some View {
        Button {
            unifier.expand()
        } label: {
            HStack(spacing: 12.0) {
                CircleCutImage(
                    circle,
                    in: namespace,
                    showVisitStatus: false,
                    showSpaceName: .constant(false),
                    showDay: .constant(false)
                )
                .frame(height: 60.0)

                VStack(alignment: .leading, spacing: 4.0) {
                    Text(circle.circleName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    HStack(spacing: 5.0) {
                        CircleBlockPill("Shared.\(circle.day)th.Day")
                        if let circleSpaceName = circle.spaceName() {
                            CircleBlockPill(LocalizedStringKey(circleSpaceName))
                        }
                    }
                }

                Spacer(minLength: 0.0)
            }
            .frame(maxWidth: .infinity, minHeight: 60.0, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Shared.OpenPanel")
        .padding(.horizontal, 28.0)
        .padding(.top, 20.0)
        .padding(.bottom, 20.0)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { newValue in
            unifier.updateCompactBarHeight(newValue)
        }
    }
}
