import XCTest

/// Stages and captures the App Store screenshots.
///
/// Driven by `Assets/App Store/Screenshots/capture.sh`, which seeds the simulator with a
/// signed-in catalog and says where to write through `SCREENSHOT_DIR`. Without it the
/// test skips, so it stays out of the way of an ordinary test run.
///
/// The app runs in Japanese with Privacy Mode on. Each shot starts from a fresh launch.
@MainActor
final class AppStoreScreenshots: XCTestCase {
    private enum Step {
        case expandPanel
        case showList
        case showFavorites
        case open(circle: String, space: String)
        case translateDescription(startingWith: String)
        case holdSearchResult(circle: String, space: String)
        case writeFavoriteMemo(String)
        case showMy
        case showMore
    }

    private struct Shot {
        let name: String
        let steps: [Step]
        var isLandscape = false
    }

    private static let description = Step.open(circle: "黎明ネルトリンゲン", space: "ア29b")
    private static let links = Step.open(circle: "こいんとす", space: "ア37a")
    private static let unfavorited = Step.open(circle: "あるかねっと", space: "ア36b")

    // The list is chosen in the app's own settings, so it is taken last.
    private static let iPhoneShots = [
        Shot(name: "01-map", steps: []),
        Shot(name: "02-grid", steps: [.expandPanel]),
        Shot(name: "04-detail", steps: [description]),
        Shot(name: "05-translate", steps: [description, .translateDescription(startingWith: "トリニティ")]),
        Shot(name: "06-links", steps: [links]),
        Shot(name: "07-context-menu", steps: [.holdSearchResult(circle: "黎明ネルトリンゲン", space: "ア29b")]),
        Shot(name: "08-favorite", steps: [unfavorited, .writeFavoriteMemo("新譜を買う")]),
        Shot(name: "09-my", steps: [.showMy]),
        Shot(name: "10-more", steps: [.showMore]),
        Shot(name: "11-visits", steps: [.showFavorites, .expandPanel]),
        Shot(name: "03-list", steps: [.showList, .expandPanel]),
    ]

    private static let iPadShots = [
        Shot(name: "01-map", steps: []),
        Shot(name: "03-grid", steps: [], isLandscape: true),
        Shot(name: "04-detail", steps: [description]),
        Shot(name: "06-links", steps: [links]),
        Shot(name: "07-context-menu", steps: [.holdSearchResult(circle: "黎明ネルトリンゲン", space: "ア29b")]),
        Shot(name: "08-favorite", steps: [unfavorited, .writeFavoriteMemo("新譜を買う")]),
        Shot(name: "09-my", steps: [.showMy], isLandscape: true),
        Shot(name: "10-more", steps: [.showMore], isLandscape: true),
        Shot(name: "11-visits", steps: [.showFavorites], isLandscape: true),
        Shot(name: "02-list", steps: [.showList], isLandscape: true),
    ]

    private var directory: URL!
    private var app: XCUIApplication!

    func testScreens() throws {
        continueAfterFailure = false
        let environment = ProcessInfo.processInfo.environment
        guard let path = environment["SCREENSHOT_DIR"], !path.isEmpty else {
            throw XCTSkip("run through Assets/App Store/Screenshots/capture.sh")
        }
        directory = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { XCUIDevice.shared.orientation = .portrait }
        let only = Set((environment["SCREENSHOT_ONLY"] ?? "").split(separator: ",").map(String.init))
        let shots = UIDevice.current.userInterfaceIdiom == .pad ? Self.iPadShots : Self.iPhoneShots
        for shot in shots where only.isEmpty || only.contains(shot.name) {
            // A busy simulator now and then drops a tap or a long press, so a shot is
            // retaken from a fresh launch before the run gives up.
            for attempt in 1...3 {
                do {
                    try capture(shot)
                    break
                } catch let failure as ShotFailure where attempt < 3 {
                    print("retaking \(shot.name): \(failure.message)")
                }
            }
        }
    }

    private struct ShotFailure: Error {
        let message: String
    }

    private func require(_ condition: Bool, _ message: @autoclosure () -> String) throws {
        if !condition { throw ShotFailure(message: message()) }
    }

    private func capture(_ shot: Shot) throws {
        XCUIDevice.shared.orientation = shot.isLandscape ? .landscapeLeft : .portrait
        try launch()
        for step in shot.steps {
            try perform(step)
        }
        // Let sheets, menus and the blurred cuts finish settling.
        Thread.sleep(forTimeInterval: 2.5)
        let file = directory.appendingPathComponent("\(shot.name).png")
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: file)
    }

    // MARK: - Steps

    private func launch() throws {
        app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP",
            "-PrivacyMode.On", "YES", "-HidesAllTips",
        ]
        app.launch()
        try require(app.buttons["サークル"].firstMatch.waitForExistence(timeout: 60), "the catalog never opened")
        Thread.sleep(forTimeInterval: 2)
    }

    private func perform(_ step: Step) throws {
        switch step {
        case .expandPanel:
            let grabber = app.buttons["シートグラバー"].firstMatch
            try require(grabber.waitForExistence(timeout: 5), "missing the panel grabber")
            grabber.press(forDuration: 0.1, thenDragTo: app.statusBars.firstMatch.exists
                ? app.statusBars.firstMatch : app.buttons["マイコミケ"].firstMatch)
        case .showList:
            try tap(app.buttons["表示設定"].firstMatch)
            try tap(app.buttons["リスト"].firstMatch)
            dismissMenu()
        case .showFavorites:
            try tap(app.segmentedControls.buttons["お気に入り"].firstMatch)
        case let .open(circle, space):
            try search(circle)
            try tap(app.staticTexts[space].firstMatch)
            try require(app.navigationBars[circle].firstMatch.waitForExistence(timeout: 10), "\(circle) never opened")
        case let .translateDescription(start):
            let description = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", start)).firstMatch
            try require(description.waitForExistence(timeout: 5), "missing the description")
            description.press(forDuration: 1.0)
            try tap(app.buttons["翻訳"].firstMatch)
            // Shown once per device, before the first translation.
            let proceed = app.buttons["続ける"].firstMatch
            if proceed.waitForExistence(timeout: 5) {
                proceed.tap()
            }
            let copy = app.buttons["翻訳をコピー"].firstMatch
            try require(copy.waitForExistence(timeout: 30), "the translation never arrived")
        case let .holdSearchResult(circle, space):
            try search(circle)
            let cut = app.staticTexts[space].firstMatch
            try require(cut.waitForExistence(timeout: 10), "\(space) is not in the results")
            cut.press(forDuration: 1.2)
        case let .writeFavoriteMemo(memo):
            let favorite = app.toolbars.buttons["お気に入り"].firstMatch
            try tap(favorite)
            // The swatches are unlabelled 56pt circles, 8pt apart, under their title.
            // Choosing one only marks it; nothing is saved until the add button.
            let swatches = app.staticTexts["色を選択"].firstMatch
            try require(swatches.waitForExistence(timeout: 5), "missing the colour picker")
            swatches.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: 28 + 64 * 3, dy: swatches.frame.height + 36)).tap()
            let field = app.textFields["メモを入力（任意）"].firstMatch
            let view = field.waitForExistence(timeout: 5) ? field : app.textViews.firstMatch
            try tap(view)
            view.typeText(memo)
            // Only the iPad keyboard can be put away, by its bottom-right key, which is
            // not exposed to UI tests. The iPhone one stays up. With a hardware keyboard
            // the simulator shows only a slim bar, and there is nothing to put away.
            let keyboard = app.keyboards.firstMatch
            if UIDevice.current.userInterfaceIdiom == .pad, keyboard.waitForExistence(timeout: 3),
               keyboard.frame.height > 200 {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.955, dy: 0.96)).tap()
            }
            try require(swatches.waitForExistence(timeout: 2), "the colour picker closed")
        case .showMy:
            try tap(app.buttons["マイコミケ"].firstMatch)
        case .showMore:
            try tap(app.buttons["その他"].firstMatch)
        }
        Thread.sleep(forTimeInterval: 1)
    }

    private func search(_ text: String) throws {
        let field = app.searchFields.firstMatch
        try require(field.waitForExistence(timeout: 10), "missing the search field")
        field.tap()
        field.typeText(text)
        // The results replace the catalog once typing settles.
        Thread.sleep(forTimeInterval: 2)
    }

    private func dismissMenu() {
        app.buttons["マイコミケ"].firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .withOffset(CGVector(dx: 0, dy: 200)).tap()
    }

    private func tap(_ element: XCUIElement) throws {
        try require(element.waitForExistence(timeout: 10), "missing \(element.description)")
        element.tap()
    }
}
