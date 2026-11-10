import SwiftUI

struct MyCircleAppearanceSection: View {

    @AppStorage(wrappedValue: false, "Customization.ShowWebCut") var showWebCut: Bool
    @AppStorage(wrappedValue: true, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool
    @AppStorage(wrappedValue: true, "Customization.DoubleTapToVisit") var isDoubleTapToVisitEnabled: Bool

    var body: some View {
        Section {
            Toggle("More.Customization.Circles.ShowWebCut", isOn: $showWebCut)
            Toggle("More.Customization.Circles.ShowHallAndBlock", isOn: $showSpaceName)
            Toggle("More.Customization.Circles.ShowDay", isOn: $showDay)
            Toggle("More.Customization.Circles.DoubleTapToVisit", isOn: $isDoubleTapToVisitEnabled)
        } header: {
            Text("My.CircleAppearance")
        }
    }
}
