import SwiftUI

struct MyCircleAppearanceSection: View {

    @AppStorage(wrappedValue: false, "Customization.ShowWebCut") var showWebCut: Bool
    @AppStorage(wrappedValue: true, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool
    @AppStorage(wrappedValue: true, "Customization.DoubleTapToVisit") var isDoubleTapToVisitEnabled: Bool

    var body: some View {
        Section {
            MyCircleAppearancePreview(
                showsWebCut: showWebCut,
                showsSpaceName: showSpaceName,
                showsDay: showDay,
                isDoubleTapToVisitEnabled: isDoubleTapToVisitEnabled
            )
            .padding(.vertical, 4.0)
            .animation(.smooth, value: showWebCut)
            .animation(.smooth, value: showSpaceName)
            .animation(.smooth, value: showDay)
            .animation(.smooth, value: isDoubleTapToVisitEnabled)
            Toggle("More.Customization.Circles.ShowWebCut", isOn: $showWebCut)
            Toggle("More.Customization.Circles.ShowHallAndBlock", isOn: $showSpaceName)
            Toggle("More.Customization.Circles.ShowDay", isOn: $showDay)
            Toggle("More.Customization.Circles.DoubleTapToVisit", isOn: $isDoubleTapToVisitEnabled)
        } header: {
            Text("My.CircleAppearance")
        }
    }
}
