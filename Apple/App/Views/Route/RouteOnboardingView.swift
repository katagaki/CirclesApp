import SwiftUI

struct RouteOnboardingView: View {

    @Environment(Navigator.self) var navigator
    @Environment(Unifier.self) var unifier

    @AppStorage(wrappedValue: false, "Route.HasSeenOnboarding") var hasSeenOnboarding: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28.0) {
                RouteOnboardingHero()
                    .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 8.0) {
                    Text("Route.Onboarding.Title")
                        .font(.largeTitle.weight(.bold))
                    Text("Route.Onboarding.Subtitle")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 22.0) {
                    OnboardingRow(
                        systemImage: "list.number",
                        title: "Route.Onboarding.Modes.Title",
                        message: "Route.Onboarding.Modes.Message"
                    )
                    OnboardingRow(
                        systemImage: "hand.point.up.left.fill",
                        title: "Route.Onboarding.Origin.Title",
                        message: "Route.Onboarding.Origin.Message"
                    )
                    OnboardingRow(
                        systemImage: "chevron.forward.circle.fill",
                        title: "Route.Onboarding.Steps.Title",
                        message: "Route.Onboarding.Steps.Message"
                    )
                    OnboardingRow(
                        systemImage: "arrow.triangle.branch",
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
                unifier.closeRouteScreen(.routeOnboarding)
                navigator.onboardingDismissals += 1
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
        .navigationBarBackButtonHidden(!hasSeenOnboarding)
        .toolbarVisibility(.hidden, for: .bottomBar)
    }
}
