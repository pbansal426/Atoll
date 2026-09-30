import XCTest
@testable import Atoll

final class StatsStripTests: XCTestCase {
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

    func testHomeCountsAsStatsViewOnlyWhenStripEnabled() {
        XCTAssertEqual(StatsMonitoringPolicy.viewName(for: .home, stripEnabled: true), "stats")
        XCTAssertEqual(StatsMonitoringPolicy.viewName(for: .home, stripEnabled: false), "other")
        XCTAssertEqual(StatsMonitoringPolicy.viewName(for: .stats, stripEnabled: false), "stats")
        XCTAssertEqual(StatsMonitoringPolicy.viewName(for: .shelf, stripEnabled: true), "other")
    }
}
