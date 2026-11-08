import SwiftUI

struct BuysOnboardingView: View {

    @Environment(Unifier.self) var unifier

    @AppStorage(wrappedValue: false, "Buys.HasSeenOnboarding") var hasSeenOnboarding: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28.0) {
                BuysOnboardingHero()
                    .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 8.0) {
                    Text("Buys.Onboarding.Title")
                        .font(.largeTitle.weight(.bold))
                    Text("Buys.Onboarding.Subtitle")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 22.0) {
                    OnboardingRow(
                        systemImage: "bag.badge.plus",
                        title: "Buys.Onboarding.Add.Title",
                        message: "Buys.Onboarding.Add.Message"
                    )
                    OnboardingRow(
                        systemImage: "checkmark.circle.fill",
                        title: "Buys.Onboarding.Track.Title",
                        message: "Buys.Onboarding.Track.Message"
                    )
                    OnboardingRow(
                        systemImage: "qrcode",
                        title: "Buys.Onboarding.Share.Title",
                        message: "Buys.Onboarding.Share.Message"
                    )
                    OnboardingRow(
                        systemImage: "person.2.fill",
                        title: "Buys.Onboarding.Split.Title",
                        message: "Buys.Onboarding.Split.Message"
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
                unifier.closePanelScreen(.buysOnboarding)
            } label: {
                Text("Buys.Onboarding.Start")
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
