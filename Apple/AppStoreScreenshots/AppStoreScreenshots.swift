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
        case showMyComiket
        case showAccount
        case scrollToInfo
        case showSharedBuys
        case startGuide
    }

    private struct Shot {
        let name: String
        let steps: [Step]
        var isLandscape = false
    }

    private static let translation = "A heartwarming manga mainly about Mika of the Trinity General School Tea Party. I also plan to bring a book about RABBIT Squad."

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
        Shot(name: "09-my", steps: [.showMyComiket, .showAccount]),
        Shot(name: "10-more", steps: [.showMyComiket, .scrollToInfo]),
        Shot(name: "11-visits", steps: [.showFavorites, .expandPanel]),
        Shot(name: "12-shared-buys", steps: [.showSharedBuys, .expandPanel]),
        Shot(name: "13-guide", steps: [.startGuide]),
        Shot(name: "03-list", steps: [.showList, .expandPanel]),
    ]

    private static let iPadShots = [
        Shot(name: "01-map", steps: []),
        Shot(name: "03-grid", steps: [], isLandscape: true),
        Shot(name: "04-detail", steps: [description]),
        Shot(name: "06-links", steps: [links]),
        Shot(name: "07-context-menu", steps: [.holdSearchResult(circle: "黎明ネルトリンゲン", space: "ア29b")]),
        Shot(name: "08-favorite", steps: [unfavorited, .writeFavoriteMemo("新譜を買う")]),
        Shot(name: "09-my", steps: [.showMyComiket, .showAccount], isLandscape: true),
        Shot(name: "10-more", steps: [.showMyComiket, .scrollToInfo], isLandscape: true),
        Shot(name: "11-visits", steps: [.showFavorites], isLandscape: true),
        Shot(name: "12-shared-buys", steps: [.showSharedBuys], isLandscape: true),
        Shot(name: "13-guide", steps: [.startGuide], isLandscape: true),
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
            // capture.sh runs `npm run dev`; the production relay needs App Attest.
            "-SharedBuysRelayURL", "ws://127.0.0.1:8787",
            // Simulators cannot translate, so the 翻訳 action shows this in place instead.
            "-ScreenshotTranslation", Self.translation,
        ]
        app.launch()
        try require(app.buttons["サークル"].firstMatch.waitForExistence(timeout: 60), "the catalog never opened")
        Thread.sleep(forTimeInterval: 2)
    }

    private func perform(_ step: Step) throws {
        switch step {
        case .expandPanel:
            let grabber = app.buttons["シートグラバー"].firstMatch
            let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05))
            if grabber.waitForExistence(timeout: 5) {
                grabber.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.1, thenDragTo: top)
            } else {
                // The iPad's panel has no grabber; it is dragged by its edge above the tabs.
                let tabs = app.segmentedControls.firstMatch
                try require(tabs.exists, "missing the panel")
                tabs.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: -0.6)).press(forDuration: 0.1, thenDragTo: top)
            }
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
            // The description is translated in place.
            let translated = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "A heartwarming")).firstMatch
            try require(translated.waitForExistence(timeout: 10), "the translation never appeared")
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
        case .showMyComiket:
            try tap(app.buttons["マイコミケ"].firstMatch)
            try require(app.buttons["閉じる"].firstMatch.waitForExistence(timeout: 5), "My Comiket never opened")
        case .showAccount:
            // The profile row sums up the tickets, one day after another.
            let profile = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "1日目")).firstMatch
            try tap(profile)
            try require(app.navigationBars["アカウント"].firstMatch.waitForExistence(timeout: 5), "the account never opened")
        case .scrollToInfo:
            let info = app.staticTexts["便利な情報"].firstMatch
            for _ in 0..<6 where !(info.exists && info.isHittable) {
                app.collectionViews.firstMatch.swipeUp(velocity: .slow)
            }
            try require(info.isHittable, "the useful links never came into view")
            // The slide covers the bottom of the screen, so the section is drawn up to a
            // quarter of the way down, held still so the list does not coast past it.
            let window = app.windows.firstMatch.frame
            let target = app.windows.firstMatch.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: window.width / 2, dy: window.height * 0.25))
            info.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.1, thenDragTo: target, withVelocity: .slow, thenHoldForDuration: 0.5)
        case .showSharedBuys:
            try tap(app.segmentedControls.buttons["宝物"].firstMatch)
            try tap(app.buttons["共同購入"].firstMatch)
            let members = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "参加中")).firstMatch
            try require(members.waitForExistence(timeout: 10), "the shared list never loaded")
            // Shown until the relay has everything, which takes a moment after launch.
            let unsent = app.staticTexts["まだ全員に届いていない変更があります。"].firstMatch
            for _ in 0..<20 where unsent.exists {
                Thread.sleep(forTimeInterval: 1)
            }
            try require(!unsent.exists, "the shared list never reached the relay")
        case .startGuide:
            try tap(app.segmentedControls.buttons["ナビ"].firstMatch)
            try tap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "おまかせ")).firstMatch)
            let end = app.buttons["終了"].firstMatch
            try require(end.waitForExistence(timeout: 20), "the route never started")
            // On iPhone the panel opens over the map; it is lowered to show the route.
            if UIDevice.current.userInterfaceIdiom == .phone {
                let grabber = app.buttons["シートグラバー"].firstMatch
                grabber.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(
                    forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62))
                )
            }
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
