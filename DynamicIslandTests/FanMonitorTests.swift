import XCTest
@testable import Atoll

private final class MutableFans: FanSensorReading {
    var rpm: Double? = 0
    func fanCount() -> Int { 1 }
    func actualRPM(fan: Int) -> Double? { rpm }
    func maxRPM(fan: Int) -> Double? { 7826 }
}

final class FanMonitorTests: XCTestCase {
    private let t0 = Date(timeIntervalSinceReferenceDate: 0)

    func testTickPublishesReadingAndAlert() {
        let fans = MutableFans()
        let monitor = FanMonitor(reader: fans, policy: FanAlertPolicy(), interval: 2)

        fans.rpm = 2317
        monitor.tick(now: t0)
        XCTAssertEqual(monitor.reading?.rpm, 2317)
        XCTAssertFalse(monitor.isAlerting)

        fans.rpm = 4000                      // 51% of 7826
        monitor.tick(now: t0 + 2)
        XCTAssertTrue(monitor.isAlerting)
    }

    func testUnreadableFansClearTheReading() {
        let fans = MutableFans()
        let monitor = FanMonitor(reader: fans, policy: FanAlertPolicy(), interval: 2)
        fans.rpm = 5000
        monitor.tick(now: t0)
        fans.rpm = nil
        monitor.tick(now: t0 + 2)
        XCTAssertNil(monitor.reading)
        XCTAssertFalse(monitor.isAlerting)
    }
}
