import SwiftUI

struct BuysOnboardingView: View {

    @Environment(Unifier.self) var unifier

    @AppStorage(wrappedValue: false, "Buys.HasSeenOnboarding") var hasSeenOnboarding: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28.0) {
                BuysOnboardingHero()
                    .padding(.horizontal, 24.0)
                    .padding(.top, 16.0)
                    .padding(.bottom, 28.0)
                    .frame(maxWidth: .infinity)
                    .background {
                        Color(.systemGroupedBackground)
                            .padding(.top, -1000.0)
                    }
                VStack(alignment: .leading, spacing: 8.0) {
                    Text("Buys.Onboarding.Title")
                        .font(.largeTitle.weight(.bold))
                    Text("Buys.Onboarding.Subtitle")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24.0)
                VStack(alignment: .leading, spacing: 22.0) {
                    OnboardingRow(
                        title: "Buys.Onboarding.Add.Title",
                        message: "Buys.Onboarding.Add.Message"
                    ) {
                        BuysOnboardingIcon(kind: .add)
                    }
                    OnboardingRow(
                        title: "Buys.Onboarding.Track.Title",
                        message: "Buys.Onboarding.Track.Message"
                    ) {
                        BuysOnboardingIcon(kind: .track)
                    }
                    OnboardingRow(
                        title: "Buys.Onboarding.Share.Title",
                        message: "Buys.Onboarding.Share.Message"
                    ) {
                        BuysOnboardingIcon(kind: .share)
                    }
                    OnboardingRow(
                        title: "Buys.Onboarding.Split.Title",
                        message: "Buys.Onboarding.Split.Message"
                    ) {
                        BuysOnboardingIcon(kind: .split)
                    }
                }
                .padding(.horizontal, 24.0)
            }
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
