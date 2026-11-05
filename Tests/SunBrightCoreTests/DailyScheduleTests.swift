import XCTest
@testable import SunBrightCore

final class DailyScheduleTests: XCTestCase {
    func testDaytimeWindowIncludesStartAndExcludesEnd() {
        let schedule = DailySchedule(isEnabled: true, startMinute: 540, endMinute: 1080)
        for (minute, expected) in [(539, false), (540, true), (720, true), (1079, true), (1080, false)] {
            XCTAssertEqual(schedule.contains(minuteOfDay: minute), expected, "Minute \(minute)")
        }
    }

    func testOvernightWindowSpansMidnight() {
        let schedule = DailySchedule(isEnabled: true, startMinute: 1320, endMinute: 360)
        for (minute, expected) in [(1319, false), (1320, true), (1439, true), (0, true), (359, true), (360, false)] {
            XCTAssertEqual(schedule.contains(minuteOfDay: minute), expected, "Minute \(minute)")
        }
    }

    func testEqualTimesAreAnEmptyWindow() {
        let schedule = DailySchedule(isEnabled: true, startMinute: 540, endMinute: 540)
        XCTAssertFalse((0..<1440).contains { schedule.contains(minuteOfDay: $0) })
    }

    func testDisabledScheduleNeverMatches() {
        let schedule = DailySchedule(isEnabled: false, startMinute: 540, endMinute: 1080)
        XCTAssertFalse(schedule.contains(minuteOfDay: 720))
    }

    func testInvalidTimesDoNotActivate() {
        XCTAssertFalse(DailySchedule(isEnabled: true, startMinute: -1, endMinute: 100).contains(minuteOfDay: 50))
        XCTAssertFalse(DailySchedule(isEnabled: true, startMinute: 100, endMinute: 1440).contains(minuteOfDay: 720))
        let valid = DailySchedule(isEnabled: true)
        XCTAssertFalse(valid.contains(minuteOfDay: -1))
        XCTAssertFalse(valid.contains(minuteOfDay: 1440))
    }
}
