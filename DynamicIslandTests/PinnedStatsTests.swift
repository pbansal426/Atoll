import Defaults
import XCTest
@testable import Atoll

final class PinnedStatsTests: XCTestCase {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Chicago")!
        return c
    }
    private func snapshot() -> PinnedSnapshot {
        PinnedSnapshot(cpu: 12.4, gpu: 3, memoryPressure: 57, fan: FanReading(rpm: 2317, maxRPM: 7826),
                       now: Date(timeIntervalSince1970: 1_790_764_400)) // 2026-09-30 05:33:20 CDT
    }

    private func chicagoDate(hour: Int, minute: Int) -> Date {
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 9
        parts.day = 30
        parts.hour = hour
        parts.minute = minute
        return calendar.date(from: parts)!
    }

    func testFormatsEachValue() {
        XCTAssertEqual(PinnedFormatter.text(.cpu, snapshot(), calendar: calendar), "CPU 12%")
        XCTAssertEqual(PinnedFormatter.text(.gpu, snapshot(), calendar: calendar), "GPU 3%")
        XCTAssertEqual(PinnedFormatter.text(.ram, snapshot(), calendar: calendar), "MEM 57%")
        XCTAssertEqual(PinnedFormatter.text(.fan, snapshot(), calendar: calendar), "FAN 30%")
        XCTAssertEqual(PinnedFormatter.text(.clock, snapshot(), calendar: calendar), "5:33")
    }

    func testClockWrapsTwelveHour() {
        let midnight = PinnedSnapshot(cpu: 0, gpu: 0, memoryPressure: nil, fan: nil, now: chicagoDate(hour: 0, minute: 7))
        let afternoon = PinnedSnapshot(cpu: 0, gpu: 0, memoryPressure: nil, fan: nil, now: chicagoDate(hour: 13, minute: 5))
        XCTAssertEqual(PinnedFormatter.text(.clock, midnight, calendar: calendar), "12:07")
        XCTAssertEqual(PinnedFormatter.text(.clock, afternoon, calendar: calendar), "1:05")
    }

    func testUnknownValuesShowDash() {
        let s = PinnedSnapshot(cpu: .nan, gpu: 0, memoryPressure: nil, fan: nil, now: Date())
        XCTAssertEqual(PinnedFormatter.text(.cpu, s, calendar: calendar), "CPU —")
        XCTAssertEqual(PinnedFormatter.text(.ram, s, calendar: calendar), "MEM —")
        XCTAssertEqual(PinnedFormatter.text(.fan, s, calendar: calendar), "FAN —")
    }

    func testDefaultsAreOffWithCPULeftMEMRight() {
        XCTAssertFalse(Defaults.Keys.pinnedMode.defaultValue)
        XCTAssertEqual(Defaults.Keys.pinnedLeft.defaultValue, .cpu)
        XCTAssertEqual(Defaults.Keys.pinnedRight.defaultValue, .ram)
    }

    func testPinnedModeKeepsStatsSamplingOnAnyView() {
        XCTAssertEqual(StatsMonitoringPolicy.viewName(for: .shelf, stripEnabled: false, pinned: true), "stats")
        XCTAssertEqual(StatsMonitoringPolicy.viewName(for: .shelf, stripEnabled: true, pinned: false), "other")
    }
}
