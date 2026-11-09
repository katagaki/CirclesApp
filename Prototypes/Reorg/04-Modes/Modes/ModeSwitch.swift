import SwiftUI

struct ModeSwitch: View {

    @Binding var mode: AppMode
    @Namespace var namespace

    var body: some View {
        HStack(spacing: 2.0) {
            ForEach(AppMode.allCases) { option in
                Button {
                    withAnimation(.snappy) { mode = option }
                } label: {
                    Label(option.title, systemImage: option.symbol)
                        .font(.subheadline.weight(.semibold))
                        .labelStyle(ModeSwitchLabelStyle(isSelected: mode == option))
                        .foregroundStyle(mode == option ? Color.white : Color.primary)
                        .padding(.horizontal, 12.0)
                        .frame(height: 32.0)
                        .background {
                            if mode == option {
                                Capsule().fill(option.tint.gradient)
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4.0)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}
