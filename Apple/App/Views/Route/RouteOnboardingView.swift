import SwiftUI

struct RouteOnboardingView: View {

    @Environment(\.dismiss) var dismiss

    @AppStorage(wrappedValue: false, "Route.HasSeenOnboarding") var hasSeenOnboarding: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28.0) {
                RouteOnboardingHero()
                    .padding(.horizontal, 24.0)
                    .padding(.top, 16.0)
                    .padding(.bottom, 28.0)
                    .frame(maxWidth: .infinity)
                    .background {
                        Color(.systemGroupedBackground)
                            .padding(.top, -1000.0)
                    }
                VStack(alignment: .leading, spacing: 8.0) {
                    Text("Route.Onboarding.Title")
                        .font(.largeTitle.weight(.bold))
                    Text("Route.Onboarding.Subtitle")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24.0)
                VStack(alignment: .leading, spacing: 22.0) {
                    OnboardingRow(
                        title: "Route.Onboarding.Modes.Title",
                        message: "Route.Onboarding.Modes.Message"
                    ) {
                        RouteOnboardingIcon(kind: .modes)
                    }
                    OnboardingRow(
                        title: "Route.Onboarding.Origin.Title",
                        message: "Route.Onboarding.Origin.Message"
                    ) {
                        RouteOnboardingIcon(kind: .origin)
                    }
                    OnboardingRow(
                        title: "Route.Onboarding.Steps.Title",
                        message: "Route.Onboarding.Steps.Message"
                    ) {
                        RouteOnboardingIcon(kind: .steps)
                    }
                    OnboardingRow(
                        title: "Route.Onboarding.Detour.Title",
                        message: "Route.Onboarding.Detour.Message"
                    ) {
                        RouteOnboardingIcon(kind: .detour)
                    }
                }
                .padding(.horizontal, 24.0)
            }
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
