import XCTest

final class DailyBalanceUITests: XCTestCase {
    var app: XCUIApplication!
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["BALANCE_UI_TEST_SESSION"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_DE"]
        app.launch()
        let skip = app.buttons["skipReminders"]
        XCTAssertTrue(skip.waitForExistence(timeout: 10))
        skip.tap()
        XCTAssertTrue(app.buttons["weightCard"].waitForExistence(timeout: 5))
    }
    func testWeightPersistsAcrossRelaunch() throws {
        app.buttons["weightCard"].tap()
        let input = app.textFields["weightInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap(); input.typeText("94,6")
        app.buttons["saveDay"].tap()
        XCTAssertTrue(app.staticTexts["94,6"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["94,6"].waitForExistence(timeout: 10))
        screenshot("Heute mit gespeichertem Gewicht")
        app.tabBars.buttons["Verlauf"].tap()
        XCTAssertTrue(app.staticTexts["Deine Entwicklung."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["94,6 kg"].firstMatch.waitForExistence(timeout: 5))
        let chart = app.descendants(matching: .any)["trendChart.weight"].firstMatch
        XCTAssertTrue(chart.waitForExistence(timeout: 5))
        chart.tap()
        let detail = app.staticTexts["trendSelection.weight"]
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
        XCTAssertTrue(detail.label.contains("94,6 kg"))
        XCTAssertTrue(detail.label.contains(String(Calendar.current.component(.year, from: Date()))))
        screenshot("Gewichtsdiagramm")
    }
    func testCancelDoesNotPersistAndRatingSavesImmediately() throws {
        app.buttons["weightCard"].tap()
        let input = app.textFields["weightInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap(); input.typeText("94,6")
        app.buttons["Abbrechen"].tap()
        XCTAssertFalse(app.staticTexts["94,6"].exists)
        let mood = app.buttons["rating.mood.4"]
        reveal(mood)
        mood.tap()
        XCTAssertTrue(app.staticTexts["Dein Tag ist festgehalten"].exists)
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["Dein Tag ist festgehalten"].waitForExistence(timeout: 10))
    }
    func testAllTabsAndCalendarAreReachable() throws {
        app.tabBars.buttons["Verlauf"].tap()
        XCTAssertTrue(app.staticTexts["Deine Entwicklung."].waitForExistence(timeout: 5))
        app.tabBars.buttons["Essen"].tap()
        XCTAssertTrue(app.staticTexts["Essen festhalten."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Vorheriger Monat"].firstMatch.exists)
        screenshot("Ernaehrungskalender")
        app.buttons["Vorheriger Monat"].firstMatch.tap()
        app.buttons["Nächster Monat"].firstMatch.tap()
        app.tabBars.buttons["Mehr"].tap()
        XCTAssertTrue(app.switches["Tägliche Erinnerungen"].waitForExistence(timeout: 5))
        screenshot("Einstellungen")
    }
    func testWeeklyMeasurementsPersistAndShowInteractiveCentimeterCharts() throws {
        let openEditor = app.buttons["bodyMeasurementsCard"]
        reveal(openEditor); openEditor.tap()
        let values = [("chest", "107,5"), ("abdomen", "100,4"), ("hips", "112,3"),
                      ("leftThigh", "61,2"), ("rightThigh", "62,1")]
        for (field, value) in values {
            let input = app.textFields["bodyInput." + field]
            XCTAssertTrue(input.waitForExistence(timeout: 5))
            reveal(input); input.tap(); input.typeText(value)
        }
        app.buttons["saveBodyMeasurements"].tap()
        XCTAssertTrue(app.staticTexts["Für diese Woche erfasst"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["Für diese Woche erfasst"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["107,5 cm"].exists)
        XCTAssertTrue(app.staticTexts["61,2 cm"].exists)
        XCTAssertTrue(app.staticTexts["62,1 cm"].exists)
        screenshot("Koerpermasse-Wochenuebersicht")
        reveal(app.buttons["bodyMeasurementsCard"])
        app.buttons["bodyMeasurementsCard"].tap()
        XCTAssertEqual(app.textFields["bodyInput.chest"].value as? String, "107,5")
        app.buttons["Abbrechen"].tap()
        app.tabBars.buttons["Verlauf"].tap()
        app.segmentedControls["historySection"].buttons["Körpermaße"].tap()
        XCTAssertTrue(app.staticTexts["Deine Körpermaße"].waitForExistence(timeout: 5))
        let chart = app.descendants(matching: .any)["trendChart.body.chest"].firstMatch
        reveal(chart); chart.tap()
        let detail = app.staticTexts["trendSelection.body.chest"]
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
        XCTAssertTrue(detail.label.contains("107,5 cm"))
        screenshot("Koerpermasse-Wochenverlauf")
    }
    func testCancelAndEmptyWeeklyMeasurementsDoNotDocumentDay() throws {
        let button = app.buttons["bodyMeasurementsCard"]
        reveal(button); button.tap()
        let input = app.textFields["bodyInput.chest"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap(); input.typeText("107,5")
        app.buttons["Abbrechen"].tap()
        XCTAssertFalse(app.staticTexts["Für diese Woche erfasst"].exists)
        reveal(button); button.tap()
        XCTAssertNotEqual(app.textFields["bodyInput.chest"].value as? String, "107,5")
        app.buttons["saveBodyMeasurements"].tap()
        XCTAssertTrue(app.buttons["bodyMeasurementsCard"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Dein Tag ist festgehalten"].exists)
    }
    func testPastDayIsReadOnlyFromHistoryWhileTodayRemainsEditable() throws {
        app.terminate()
        app.launchEnvironment["BALANCE_UI_TEST_PAST_DAY"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["weightCard"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Verlauf"].tap()
        let list = app.buttons["allHistoryValues"]
        reveal(list); list.tap()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        let row = app.buttons["historyDay." + formatter.string(from: yesterday)]
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        XCTAssertTrue(app.staticTexts["dayReadOnly"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["editDay"].exists)
        XCTAssertFalse(app.buttons["weightCard"].isEnabled)
        XCTAssertFalse(app.buttons["bodyMeasurementsCard"].exists)
        let mood = app.buttons["rating.mood.4"]
        reveal(mood); XCTAssertFalse(mood.isEnabled)
        reveal(app.staticTexts["Tagesnotizen"])
        XCTAssertFalse(app.buttons["addMeal"].exists)
        XCTAssertFalse(app.buttons["Bearbeiten"].exists)
        XCTAssertTrue(app.staticTexts["Vorheriger Tag"].exists)
        screenshot("Vergangener-Tag-nur-ansehen")
        app.tabBars.buttons["Heute"].tap()
        XCTAssertTrue(app.buttons["editDay"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["weightCard"].isEnabled)
    }
    func testWaterSettingsPersistSeparatelyAndBrandingUsesAppLogo() throws {
        app.tabBars.buttons["Mehr"].tap()
        XCTAssertTrue(app.images["Daily Balance App-Logo"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Dein persönlicher Raum."].exists)
        let toggle = app.switches["waterEnabled"]
        reveal(toggle)
        XCTAssertTrue(toggle.isEnabled)
        screenshot("Wasser-vor-Aktivierung")
        let control = toggle.switches.firstMatch
        XCTAssertTrue(control.waitForExistence(timeout: 5))
        control.tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.alerts.firstMatch.waitForExistence(timeout: 3) {
            let allow = springboard.alerts.buttons.matching(NSPredicate(format: "label IN %@", ["Erlauben", "Allow", "Zulassen"])).firstMatch
            if allow.exists { allow.tap() }
        }
        if app.alerts.firstMatch.exists {
            let allow = app.alerts.buttons.matching(NSPredicate(format: "label IN %@", ["Erlauben", "Allow", "Zulassen"])).firstMatch
            if allow.exists { allow.tap() }
        }
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == '1'"), object: toggle)
        let activated = XCTWaiter.wait(for: [enabled], timeout: 10) == .completed
        if !activated {
            screenshot("Wasser-Aktivierung-Diagnose")
            print(app.debugDescription)
            print(springboard.debugDescription)
        }
        XCTAssertTrue(activated)
        let interval = app.buttons["waterInterval"]
        reveal(interval); interval.tap()
        let choice = app.buttons["Alle 2 Stunden"]
        XCTAssertTrue(choice.waitForExistence(timeout: 5)); choice.tap()
        XCTAssertTrue(app.staticTexts["Alle 2 Stunden"].waitForExistence(timeout: 5))
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        start.press(forDuration: 0.05, thenDragTo: end)
        XCTAssertTrue(app.datePickers["waterStart"].exists)
        XCTAssertTrue(app.datePickers["waterEnd"].exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Erinnerungsplanung fehlgeschlagen:")).firstMatch.exists)
        screenshot("Wasser-Erinnerungen")
        app.terminate(); app.launch()
        app.tabBars.buttons["Mehr"].tap()
        let restored = app.switches["waterEnabled"]
        reveal(restored)
        XCTAssertEqual(restored.value as? String, "1")
        XCTAssertTrue(app.staticTexts["Alle 2 Stunden"].exists)
        XCTAssertEqual(app.switches["Tägliche Erinnerungen"].value as? String, "0")
        restored.switches.firstMatch.tap()
        XCTAssertEqual(restored.value as? String, "0")
        XCTAssertFalse(app.buttons["waterInterval"].isEnabled)
    }
    private func reveal(_ element: XCUIElement) {
        for _ in 0..<7 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }
    private func screenshot(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
