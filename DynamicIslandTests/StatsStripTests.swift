import XCTest
@testable import Atoll

final class StatsStripTests: XCTestCase {
    func testNonFiniteValuesShowDash() {
        XCTAssertEqual(StatsStripFormatter.percent(.nan), "—")
        XCTAssertEqual(StatsStripFormatter.rpm(.infinity), "—")
        XCTAssertEqual(StatsStripFormatter.fanPercent(FanReading(rpm: .nan, maxRPM: 7826)), "—")
    }

    func testPercentRoundsAndClamps() {
        XCTAssertEqual(StatsStripFormatter.percent(12.4), "12%")
        XCTAssertEqual(StatsStripFormatter.percent(12.5), "13%")
        XCTAssertEqual(StatsStripFormatter.percent(-3), "0%")
        XCTAssertEqual(StatsStripFormatter.percent(140), "100%")
    }

    func testRPMShowsZeroAndDashWhenUnknown() {
        XCTAssertEqual(StatsStripFormatter.rpm(0), "0 rpm")
        XCTAssertEqual(StatsStripFormatter.rpm(3913.4), "3913 rpm")
        XCTAssertEqual(StatsStripFormatter.rpm(nil), "—")
    }

    func testRAMTintFollowsMemoryPressure() {
        XCTAssertEqual(StatsStripFormatter.ramTint(.normal), .normal)
        XCTAssertEqual(StatsStripFormatter.ramTint(.warning), .warning)
        XCTAssertEqual(StatsStripFormatter.ramTint(.critical), .critical)
    }

    func testFanPercentIsShareOfMaximum() {
        XCTAssertEqual(StatsStripFormatter.fanPercent(FanReading(rpm: 3913, maxRPM: 7826)), "50%")
        XCTAssertEqual(StatsStripFormatter.fanPercent(FanReading(rpm: 2317, maxRPM: 7826)), "30%")
        XCTAssertEqual(StatsStripFormatter.fanPercent(FanReading(rpm: 0, maxRPM: 7826)), "0%")
        XCTAssertEqual(StatsStripFormatter.fanPercent(FanReading(rpm: 9000, maxRPM: 7826)), "100%")
        XCTAssertEqual(StatsStripFormatter.fanPercent(nil), "—")
    }

    func testHomeCountsAsStatsViewOnlyWhenStripEnabled() {
        XCTAssertEqual(StatsMonitoringPolicy.viewName(for: .home, stripEnabled: true), "stats")
        XCTAssertEqual(StatsMonitoringPolicy.viewName(for: .home, stripEnabled: false), "other")
        XCTAssertEqual(StatsMonitoringPolicy.viewName(for: .stats, stripEnabled: false), "stats")
        XCTAssertEqual(StatsMonitoringPolicy.viewName(for: .shelf, stripEnabled: true), "other")
    }
}
