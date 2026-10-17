import XCTest
#if canImport(BalanceCore)
@testable import BalanceCore
#elseif canImport(DailyBalance)
@testable import DailyBalance
#endif

final class BalanceCoreTests: XCTestCase {
    func calendar(_ zone: String = "Europe/Berlin") -> Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: zone)!
        return value
    }
    func date(_ year: Int = 2026, _ month: Int = 10, _ day: Int = 16, _ hour: Int = 8, _ minute: Int = 0,
              zone: String = "Europe/Berlin") -> Date {
        calendar(zone).date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
    var enabled: SettingsValue { var value = SettingsValue(); value.notificationsEnabled = true; return value }
    func plan(at now: Date, documented: Set<DayKey> = [], settings: SettingsValue? = nil,
              zone: String = "Europe/Berlin") -> [PlannedReminder] {
        ReminderPlanner.plan(now: now, calendar: calendar(zone), settings: settings ?? enabled, documented: documented)
    }
    func testNoEntrySchedulesThreePerDayForTwentyDays() {
        let now = date()
        let reminders = plan(at: now)
        XCTAssertEqual(reminders.count, 60)
        XCTAssertEqual(reminders.filter { $0.day == DayKey(now, calendar: calendar()) }.count, 3)
        XCTAssertEqual(Set(reminders.map(\.id)).count, 60)
        XCTAssertTrue(reminders.allSatisfy { $0.fireDate > now })
    }
    func testDocumentedBeforeFirstReminderCancelsTodayAndPreservesTomorrow() {
        let now = date()
        let day = DayKey(now, calendar: calendar())
        let before = plan(at: now)
        let after = plan(at: now, documented: [day])
        XCTAssertEqual(after.count, 57)
        XCTAssertFalse(after.contains { $0.day == day })
        XCTAssertEqual(before.filter { $0.day != day }, after)
    }
    func testEntryAfterFirstReminderRemovesRemainingTwo() {
        let now = date(2026, 10, 16, 11, 30)
        let day = DayKey(now, calendar: calendar())
        XCTAssertEqual(plan(at: now).filter { $0.day == day }.map(\.slot), [1, 2])
        XCTAssertFalse(plan(at: now, documented: [day]).contains { $0.day == day })
    }
    func testEntryAfterSecondReminderRemovesEvening() {
        let now = date(2026, 10, 16, 15)
        let day = DayKey(now, calendar: calendar())
        XCTAssertEqual(plan(at: now).filter { $0.day == day }.map(\.slot), [2])
        XCTAssertFalse(plan(at: now, documented: [day]).contains { $0.day == day })
    }
    func testDeletingOnlyEntryRestoresOnlyFutureTimes() {
        let now = date(2026, 10, 16, 15)
        let day = DayKey(now, calendar: calendar())
        let complete = plan(at: now, documented: [day])
        let cleared = plan(at: now, documented: [])
        XCTAssertEqual(cleared.count, complete.count + 1)
        XCTAssertEqual(cleared.first?.slot, 2)
    }
    func testDisabledRemindersHaveEmptyPlan() {
        XCTAssertTrue(plan(at: date(), settings: SettingsValue()).isEmpty)
    }
    func testOpeningOrEmptyDraftDoesNotCountAsEntry() {
        var entry = DailyValue(day: DayKey(date()))
        XCTAssertFalse(entry.isDocumented)
        entry.notes = " \n\t "
        XCTAssertFalse(entry.isDocumented)
        XCTAssertEqual(plan(at: date()).count, 60)
    }
    func testEachIndependentMetricAndNoteCounts() {
        for metric in Metric.allCases {
            var entry = DailyValue(day: DayKey(date()))
            entry[metric] = 3
            XCTAssertTrue(entry.isDocumented)
        }
        var entry = DailyValue(day: DayKey(date()))
        entry.weight = 94.6
        XCTAssertTrue(entry.isDocumented)
        entry.weight = nil; entry.notes = "Wenig Appetit"
        XCTAssertTrue(entry.isDocumented)
    }
    func testMealAloneSuppressesReminders() {
        let now = date()
        let meal = MealValue(day: DayKey(now, calendar: calendar()), timestamp: now, category: .breakfast, imageName: "photo.jpg")
        XCTAssertFalse(plan(at: now, documented: [meal.day]).contains { $0.day == meal.day })
    }
    func testFutureEntryDoesNotSuppressToday() {
        let tomorrow = DayKey(date(2026, 10, 17), calendar: calendar())
        XCTAssertEqual(plan(at: date(), documented: [tomorrow]).filter { $0.day.rawValue == "2026-10-16" }.count, 3)
    }
    func testTimeChangeReplacesSameIdentifierWithNewTime() {
        var settings = enabled; settings.reminderMinutes[0] = 10 * 60 + 15
        let original = plan(at: date()).first!
        let changed = plan(at: date(), settings: settings).first!
        XCTAssertEqual(original.id, changed.id)
        XCTAssertEqual(changed.hour, 10); XCTAssertEqual(changed.minute, 15)
        XCTAssertNotEqual(original.fireDate, changed.fireDate)
    }
    func testSpringDSTNonexistentHourResolvedWithinSameDay() {
        var settings = enabled; settings.reminderMinutes = [150, 840, 1200]
        let now = date(2026, 3, 29, 0)
        let results = plan(at: now, settings: settings)
        XCTAssertEqual(results.count, 60)
        XCTAssertEqual(results.first?.day.rawValue, "2026-03-29")
        XCTAssertEqual(results.first?.hour, 3)
        XCTAssertEqual(Set(results.map(\.id)).count, 60)
    }
    func testAutumnDSTRepeatedHourSchedulesOnce() {
        var settings = enabled; settings.reminderMinutes = [150, 840, 1200]
        let results = plan(at: date(2026, 10, 25, 0), settings: settings)
        XCTAssertEqual(results.filter { $0.day.rawValue == "2026-10-25" && $0.slot == 0 }.count, 1)
        XCTAssertEqual(results.first?.hour, 2)
    }
    func testTimeZoneReplanningUsesNewLocalTimes() {
        let now = date(2026, 10, 16, 0, zone: "America/Los_Angeles")
        let laPlan = plan(at: now, zone: "America/Los_Angeles")
        XCTAssertEqual(calendar("America/Los_Angeles").component(.hour, from: laPlan.first!.fireDate), 9)
        XCTAssertEqual(laPlan.first?.day.rawValue, "2026-10-16")
    }
    func testCivilDateDoesNotMoveWhenTraveling() {
        let stored = DayKey(date(2026, 10, 16, 0, 15), calendar: calendar())
        XCTAssertEqual(stored.rawValue, "2026-10-16")
        let inLA = stored.date(calendar: calendar("America/Los_Angeles"))
        XCTAssertEqual(DayKey(inLA, calendar: calendar("America/Los_Angeles")), stored)
        XCTAssertEqual(calendar("America/Los_Angeles").component(.hour, from: inLA), 12)
    }
    func testMidnightAndYearBoundaryDoNotReuseYesterday() {
        let results = plan(at: date(2026, 12, 31, 23, 59))
        XCTAssertEqual(results.first?.day.rawValue, "2027-01-01")
        XCTAssertEqual(results.first?.slot, 0)
    }
    func testGermanDecimalAndEmptyWeight() throws {
        XCTAssertEqual(try WeightInput.parse(" 94,6 "), 94.6)
        XCTAssertEqual(try WeightInput.parse("94.6"), 94.6)
        XCTAssertNil(try WeightInput.parse("   "))
        for invalid in ["0", "-2", "abc", "1,2,3", "NaN", "1e2", "701", "94 kg"] {
            XCTAssertThrowsError(try WeightInput.parse(invalid), invalid)
        }
    }
    func testInvalidMetricAndWeightRejected() {
        var entry = DailyValue(day: DayKey(date()))
        entry.weight = .infinity
        XCTAssertThrowsError(try entry.validated())
        entry.weight = nil; entry.mood = 6
        XCTAssertThrowsError(try entry.validated())
    }
    func testMissingWeightsAndRatingsNeverBecomeZeros() {
        var first = DailyValue(day: DayKey(rawValue: "2026-10-14")); first.weight = 100
        var second = DailyValue(day: DayKey(rawValue: "2026-10-15")); second.mood = 4
        var third = DailyValue(day: DayKey(rawValue: "2026-10-16")); third.weight = 99
        XCTAssertEqual(Trends.points([third, second, first]).map(\.value), [100, 99])
        XCTAssertEqual(Trends.points([first, second, third], metric: .mood).map(\.value), [4])
    }
    func testHungerAndCravingsStaySeparate() {
        var entry = DailyValue(day: DayKey(date())); entry.hunger = 1; entry.cravings = 5
        XCTAssertEqual(Trends.points([entry], metric: .hunger).first?.value, 1)
        XCTAssertEqual(Trends.points([entry], metric: .cravings).first?.value, 5)
    }
    func testCodingRoundTripPreservesHistoricalIdentity() throws {
        var entry = DailyValue(day: DayKey(rawValue: "2023-02-28"))
        entry.weight = 94.6; entry.notes = "Ein Rückblick"; entry.sleep = 4
        let decoded = try JSONDecoder().decode(DailyValue.self, from: JSONEncoder().encode(entry))
        XCTAssertEqual(decoded, entry)
    }
    func testInvalidReminderConfigurationReturnsNoPlan() {
        var value = enabled; value.reminderMinutes = [-1, 840, 1200]
        XCTAssertTrue(plan(at: date(), settings: value).isEmpty)
        value.reminderMinutes = [540]
        XCTAssertTrue(plan(at: date(), settings: value).isEmpty)
    }
    func testMeasurementInputAcceptsGermanDecimalsAndRejectsInvalidValues() throws {
        XCTAssertEqual(try MeasurementInput.parse(" 107,5 "), 107.5)
        XCTAssertEqual(try MeasurementInput.parse("61.2"), 61.2)
        XCTAssertNil(try MeasurementInput.parse(" "))
        for invalid in ["0", "-5", "501", "NaN", "inf", "12 cm", "1,2,3", "0,01"] {
            XCTAssertThrowsError(try MeasurementInput.parse(invalid), invalid)
        }
    }
    func testEachBodyMeasurementDocumentsIndependently() throws {
        let day = DayKey(rawValue: "2026-10-16")
        XCTAssertFalse(BodyMeasurements(day: day).isDocumented)
        for metric in BodyMeasurement.allCases {
            var body = BodyMeasurements(day: day)
            body[metric] = 60.5
            XCTAssertTrue(body.isDocumented)
            XCTAssertNoThrow(try body.validated())
            body[metric] = nil
            XCTAssertFalse(body.isDocumented)
        }
    }
    func testBodyMeasurementValidationRejectsNonFiniteAndOutOfRangeValues() {
        for invalid in [Double.nan, .infinity, -1, 0, 501] {
            var body = BodyMeasurements(day: DayKey(rawValue: "2026-10-16"))
            body.rightThigh = invalid
            XCTAssertThrowsError(try body.validated())
        }
    }
    func testMeasurementsUseMondayToSundayISOWeeksAcrossYearBoundaries() {
        let monday = DayKey(rawValue: "2025-12-29")
        let sunday = DayKey(rawValue: "2026-01-04")
        let followingMonday = DayKey(rawValue: "2026-01-05")
        XCTAssertEqual(WeekKey(monday).rawValue, "2026-W01")
        XCTAssertEqual(WeekKey(monday), WeekKey(sunday))
        XCTAssertNotEqual(WeekKey(sunday), WeekKey(followingMonday))
        XCTAssertEqual(WeekKey(monday, calendar: calendar("America/Los_Angeles")), WeekKey(monday, calendar: calendar()))
        let interval = WeekKey.interval(containing: sunday, calendar: calendar())
        XCTAssertEqual(DayKey(interval.start, calendar: calendar()), monday)
        XCTAssertEqual(DayKey(interval.end.addingTimeInterval(-1), calendar: calendar()), sunday)
    }
    func testBodyTrendsKeepMissingWeeksAndThighSidesSeparate() {
        var first = BodyMeasurements(day: DayKey(rawValue: "2026-10-01"))
        first.chest = 110; first.leftThigh = 61.2; first.rightThigh = 62.1
        var later = BodyMeasurements(day: DayKey(rawValue: "2026-10-16"))
        later.chest = 107.5; later.rightThigh = 60.3
        XCTAssertEqual(Trends.points([later, first], measurement: .chest).map(\.value), [110, 107.5])
        XCTAssertEqual(Trends.points([later, first], measurement: .leftThigh).map(\.value), [61.2])
        XCTAssertEqual(Trends.points([later, first], measurement: .rightThigh).map(\.value), [62.1, 60.3])
        XCTAssertTrue(Trends.points([first, later], measurement: .abdomen).isEmpty)
    }
    func testWeeklyMeasurementsCodingRoundTripPreservesDatesAndValues() throws {
        var value = BodyMeasurements(day: DayKey(rawValue: "2026-10-16"))
        value.chest = 107.5; value.abdomen = 100.4; value.hips = 112.3
        value.leftThigh = 61.2; value.rightThigh = 62.1
        let decoded = try JSONDecoder().decode(BodyMeasurements.self, from: JSONEncoder().encode(value))
        XCTAssertEqual(decoded, value)
        XCTAssertEqual(decoded.week, value.week)
    }

    func testLegacySettingsDecodeWithWaterDisabledAndPreserveExistingPreferences() throws {
        let data = Data(#"{"notificationsEnabled":true,"reminderMinutes":[555,870,1215],"faceIDEnabled":true,"targetWeight":85,"onboardingComplete":true}"#.utf8)
        let settings = try JSONDecoder().decode(SettingsValue.self, from: data)
        XCTAssertTrue(settings.notificationsEnabled); XCTAssertTrue(settings.faceIDEnabled)
        XCTAssertEqual(settings.reminderMinutes, [555,870,1215]); XCTAssertEqual(settings.targetWeight, 85)
        XCTAssertEqual(settings.waterReminders, WaterReminderSettings())
        XCTAssertEqual(try JSONDecoder().decode(SettingsValue.self, from: JSONEncoder().encode(settings)), settings)
    }
    func testWaterIntervalsStartAtChosenTimeAndNeverLeaveWindow() {
        var settings = WaterReminderSettings(); settings.enabled = true
        settings.startMinute = 8 * 60 + 15; settings.endMinute = 20 * 60 + 15
        for interval in WaterReminderSettings.intervals {
            settings.intervalMinutes = interval
            let plan = WaterReminderPlanner.plan(settings: settings)
            XCTAssertEqual(plan.first?.minuteOfDay, settings.startMinute)
            XCTAssertEqual(plan.last?.minuteOfDay, settings.endMinute)
            XCTAssertEqual(plan.count, 720 / interval + 1)
            XCTAssertTrue(plan.allSatisfy { (settings.startMinute...settings.endMinute).contains($0.minuteOfDay) })
            XCTAssertEqual(Set(plan.map(\.id)).count, plan.count)
            for pair in zip(plan, plan.dropFirst()) { XCTAssertEqual(pair.1.minuteOfDay - pair.0.minuteOfDay, interval) }
        }
        settings.endMinute = 20 * 60
        XCTAssertEqual(WaterReminderPlanner.plan(settings: settings).last?.minuteOfDay, 16 * 60 + 15)
    }
    func testDisabledAndInvalidWaterWindowsCreateNoRequests() {
        var settings = WaterReminderSettings()
        XCTAssertTrue(WaterReminderPlanner.plan(settings: settings).isEmpty)
        settings.enabled = true; settings.endMinute = settings.startMinute
        XCTAssertTrue(WaterReminderPlanner.plan(settings: settings).isEmpty)
        settings.endMinute = settings.startMinute - 1
        XCTAssertTrue(WaterReminderPlanner.plan(settings: settings).isEmpty)
        settings.endMinute = 1440
        XCTAssertTrue(WaterReminderPlanner.plan(settings: settings).isEmpty)
        settings.endMinute = 1200; settings.intervalMinutes = 45
        XCTAssertTrue(WaterReminderPlanner.plan(settings: settings).isEmpty)
    }

}
