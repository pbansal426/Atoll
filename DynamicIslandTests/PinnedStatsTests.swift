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

    func testForkKeyNamesHaveNoDots() {
        let names = [
            Defaults.Keys.showHomeStatsStrip.name,
            Defaults.Keys.enableFanLiveActivity.name,
            Defaults.Keys.pinnedMode.name,
            Defaults.Keys.pinnedLeft.name,
            Defaults.Keys.pinnedRight.name,
        ]
        XCTAssertEqual(names, [
            "notchForkShowHomeStatsStrip",
            "notchForkEnableFanLiveActivity",
            "notchForkPinnedMode",
            "notchForkPinnedLeft",
            "notchForkPinnedRight",
        ])
        XCTAssertTrue(names.allSatisfy { !$0.contains(".") })
    }
}

final class NotchForkDefaultsMigrationTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "NotchForkDefaultsMigrationTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func persisted(_ key: String) -> Any? {
        defaults.persistentDomain(forName: suiteName)?[key]
    }

    private func persistedBool(_ key: String) -> Bool? {
        (persisted(key) as? NSNumber)?.boolValue
    }

    func testCopiesDottedValuesOnlyWhenNewKeyIsUnset() {
        defaults.set(false, forKey: "notchFork.showHomeStatsStrip")
        defaults.set(false, forKey: "notchFork.enableFanLiveActivity")
        defaults.set(true, forKey: "notchFork.pinnedMode")
        defaults.set("fan", forKey: "notchFork.pinnedLeft")
        defaults.set("clock", forKey: "notchFork.pinnedRight")

        NotchForkDefaultsMigration.migrate(defaults, persistentDomainName: suiteName)

        XCTAssertEqual(persistedBool("notchForkShowHomeStatsStrip"), false)
        XCTAssertEqual(persistedBool("notchForkEnableFanLiveActivity"), false)
        XCTAssertEqual(persistedBool("notchForkPinnedMode"), true)
        XCTAssertEqual(persisted("notchForkPinnedLeft") as? String, "fan")
        XCTAssertEqual(persisted("notchForkPinnedRight") as? String, "clock")
        XCTAssertEqual(persistedBool("notchFork.showHomeStatsStrip"), false)
        XCTAssertEqual(persisted("notchFork.pinnedLeft") as? String, "fan")
    }

    func testDoesNotOverwriteAnExistingNewKeyAndIsIdempotent() {
        defaults.set(true, forKey: "notchFork.pinnedMode")
        defaults.set(false, forKey: "notchForkPinnedMode")
        defaults.set("cpu", forKey: "notchFork.pinnedLeft")
        defaults.set("ram", forKey: "notchForkPinnedLeft")

        NotchForkDefaultsMigration.migrate(defaults, persistentDomainName: suiteName)
        NotchForkDefaultsMigration.migrate(defaults, persistentDomainName: suiteName)

        XCTAssertEqual(persistedBool("notchForkPinnedMode"), false)
        XCTAssertEqual(persistedBool("notchFork.pinnedMode"), true)
        XCTAssertEqual(persisted("notchForkPinnedLeft") as? String, "ram")
        XCTAssertEqual(persisted("notchFork.pinnedLeft") as? String, "cpu")
    }

    func testSkipsWhenTheOldKeyIsMissing() {
        NotchForkDefaultsMigration.migrate(defaults, persistentDomainName: suiteName)
        XCTAssertNil(persisted("notchForkPinnedMode"))
        XCTAssertNil(persisted("notchForkShowHomeStatsStrip"))
        XCTAssertNil(persisted("notchForkPinnedLeft"))
    }
}
