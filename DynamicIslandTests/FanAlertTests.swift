import XCTest
@testable import Atoll

private struct StubFans: FanSensorReading {
    var actual: [Double?]
    var max: [Double?]
    func fanCount() -> Int { actual.count }
    func actualRPM(fan: Int) -> Double? { actual[fan] }
    func maxRPM(fan: Int) -> Double? { max[fan] }
}

final class FanReadingResolverTests: XCTestCase {
    func testPicksTheFasterFan() {
        let reading = FanReadingResolver.fastest(from: StubFans(actual: [2317, 4100], max: [7826, 7826]))
        XCTAssertEqual(reading, FanReading(rpm: 4100, maxRPM: 7826))
    }

    func testZeroRPMIsAValidReading() {
        // Apple Silicon fans stop at idle; 0 must not read as "no sensor".
        let reading = FanReadingResolver.fastest(from: StubFans(actual: [0, 0], max: [7826, 7826]))
        XCTAssertEqual(reading?.rpm, 0)
        XCTAssertEqual(reading?.fraction, 0)
    }

    func testFansWithoutAMaximumAreIgnored() {
        XCTAssertNil(FanReadingResolver.fastest(from: StubFans(actual: [3000], max: [nil])))
        XCTAssertNil(FanReadingResolver.fastest(from: StubFans(actual: [3000], max: [0])))
    }

    func testNoFansMeansNoReading() {
        XCTAssertNil(FanReadingResolver.fastest(from: StubFans(actual: [], max: [])))
    }

    func testFractionIsOfMaximumNotOfRange() {
        // Spec: 50% of max speed (≈3,913 of 7,826), not of the min–max range.
        XCTAssertEqual(FanReading(rpm: 3913, maxRPM: 7826).fraction, 0.5, accuracy: 0.0001)
    }
}

final class FanAlertStateMachineTests: XCTestCase {
    private let t0 = Date(timeIntervalSinceReferenceDate: 0)

    func testStaysOffBelowTheShowThreshold() {
        var sm = FanAlertStateMachine()
        XCTAssertFalse(sm.update(fraction: 0.49, now: t0))
    }

    func testShowsAtExactlyFiftyPercent() {
        var sm = FanAlertStateMachine()
        XCTAssertTrue(sm.update(fraction: 0.50, now: t0))
    }

    func testStaysOnBetweenHideAndShowThresholds() {
        var sm = FanAlertStateMachine()
        _ = sm.update(fraction: 0.60, now: t0)
        XCTAssertTrue(sm.update(fraction: 0.47, now: t0 + 60))
    }

    func testStaysOnUntilBelowHideThresholdForTheFullDelay() {
        var sm = FanAlertStateMachine()
        _ = sm.update(fraction: 0.60, now: t0)
        XCTAssertTrue(sm.update(fraction: 0.40, now: t0 + 1))
        XCTAssertTrue(sm.update(fraction: 0.40, now: t0 + 10.9))
        XCTAssertFalse(sm.update(fraction: 0.40, now: t0 + 11))
    }

    func testClimbingBackAboveHideThresholdRestartsTheDelay() {
        var sm = FanAlertStateMachine()
        _ = sm.update(fraction: 0.60, now: t0)
        _ = sm.update(fraction: 0.40, now: t0 + 1)
        _ = sm.update(fraction: 0.46, now: t0 + 8)       // back in the band: timer resets
        XCTAssertTrue(sm.update(fraction: 0.40, now: t0 + 12))
        XCTAssertTrue(sm.update(fraction: 0.40, now: t0 + 21.9))
        XCTAssertFalse(sm.update(fraction: 0.40, now: t0 + 22))
    }

    func testLosingTheSensorHidesImmediately() {
        var sm = FanAlertStateMachine()
        _ = sm.update(fraction: 0.90, now: t0)
        XCTAssertFalse(sm.update(fraction: nil, now: t0 + 1))
    }
}
