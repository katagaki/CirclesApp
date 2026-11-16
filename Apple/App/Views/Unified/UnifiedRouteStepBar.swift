import AXiS
import SwiftUI

/// Takes the place of the search bar while the Guide sheet is minimized, so the step being
/// walked stays readable with the map in full view.
struct UnifiedRouteStepBar: View {

    @Environment(Database.self) var database
    @Environment(Navigator.self) var navigator
    @Environment(Unifier.self) var unifier

    @Namespace var namespace

    @State var circle: ComiketCircle?

    var isOnStep: Bool {
        navigator.currentStep != nil && !navigator.isFinished && !navigator.isTrapped
    }

    var body: some View {
        Button {
            unifier.expand()
        } label: {
            HStack(spacing: 12.0) {
                icon
                    .frame(width: 48.0, height: 48.0)
                title
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .contentTransition(.opacity)
                Spacer(minLength: 0.0)
                if isOnStep, let circle {
                    CircleCutImage(
                        circle,
                        in: namespace,
                        showVisitStatus: false,
                        showSpaceName: .constant(false),
                        showDay: .constant(false)
                    )
                    .frame(height: 48.0)
                    .transition(.opacity)
                }
            }
            .frame(height: 48.0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Shared.OpenPanel")
        .animation(.easeInOut(duration: 0.2), value: navigator.stepIndex)
        .animation(.easeInOut(duration: 0.2), value: circle?.id)
        .task(id: navigator.currentStop?.circleID) {
            guard let circleID = navigator.currentStop?.circleID else {
                circle = nil
                return
            }
            circle = database.circles([circleID]).first
        }
        .padding(.horizontal, 20.0)
        .padding(.top, 20.0)
        .padding(.bottom, 20.0)
    }

    @ViewBuilder
    var icon: some View {
        if navigator.isFinished {
            badge("flag.checkered", color: .green)
        } else if navigator.isTrapped {
            badge("exclamationmark.triangle.fill", color: .orange)
        } else if let step = navigator.currentStep {
            badge(step.symbolName, color: .accentColor)
        } else {
            ProgressView()
        }
    }

    @ViewBuilder
    var title: some View {
        if navigator.isFinished {
            Text("Navi.Finished.Title")
        } else if navigator.isTrapped {
            Text("Route.Trapped.Title")
        } else if let instruction = navigator.currentInstruction {
            Text(instruction)
        } else {
            Text("Navi.Planning")
        }
    }

    func badge(_ systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.title3.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 48.0, height: 48.0)
            .background(color.gradient, in: .rect(cornerRadius: 14.0))
            .contentTransition(.symbolEffect(.replace))
    }
}
