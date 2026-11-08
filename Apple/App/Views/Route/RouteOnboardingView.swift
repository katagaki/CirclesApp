import SwiftUI

struct RouteOnboardingView: View {

    @Environment(\.dismiss) var dismiss

    @AppStorage(wrappedValue: false, "Route.HasSeenOnboarding") var hasSeenOnboarding: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28.0) {
                RouteOnboardingHero()
                    .frame(height: 200.0)
                    .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 8.0) {
                    Text("Route.Onboarding.Title")
                        .font(.largeTitle.weight(.bold))
                    Text("Route.Onboarding.Subtitle")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 22.0) {
                    RouteOnboardingRow(
                        systemImage: "list.number",
                        title: "Route.Onboarding.Modes.Title",
                        message: "Route.Onboarding.Modes.Message"
                    )
                    RouteOnboardingRow(
                        systemImage: "hand.point.up.left.fill",
                        title: "Route.Onboarding.Origin.Title",
                        message: "Route.Onboarding.Origin.Message"
                    )
                    RouteOnboardingRow(
                        systemImage: "chevron.forward.circle.fill",
                        title: "Route.Onboarding.Steps.Title",
                        message: "Route.Onboarding.Steps.Message"
                    )
                    RouteOnboardingRow(
                        systemImage: "nosign",
                        title: "Route.Onboarding.Detour.Title",
                        message: "Route.Onboarding.Detour.Message"
                    )
                }
            }
            .padding(.horizontal, 24.0)
            .padding(.top, 32.0)
            .padding(.bottom, 16.0)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                hasSeenOnboarding = true
                dismiss()
            } label: {
                Text("Route.Onboarding.Start")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6.0)
            }
            .buttonStyle(.glassProminent)
            .padding(.horizontal, 24.0)
            .padding(.bottom, 12.0)
        }
        .interactiveDismissDisabled(!hasSeenOnboarding)
    }
}
