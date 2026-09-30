import XCTest
@testable import Atoll

final class SmctlStatusTests: XCTestCase {
    private let fanJSON = """
    {"fans":[{"actualRPM":2316,"index":0,"maximumRPM":7826,"minimumRPM":2317,"mode":"manual","targetRPM":2317},
             {"actualRPM":2320,"index":1,"maximumRPM":7826,"minimumRPM":2317,"mode":"manual","targetRPM":2317}],
     "profile":"anti-throttle","timestamp":"2026-09-30T06:34:22Z"}
    """.data(using: .utf8)!

    private let powerJSON = """
    {"cpu":{"recorded":false},"inputPowerWatts":12.1,"packagePowerWatts":12.1,"systemPowerWatts":11.5,
     "thermalPressure":"nominal","timestamp":"2026-09-30T06:34:22Z"}
    """.data(using: .utf8)!

    func testParsesFanStatus() {
        let status = SmctlStatusParser.fan(fanJSON)
        XCTAssertEqual(status?.profile, "anti-throttle")
        XCTAssertEqual(status?.fans.count, 2)
        XCTAssertEqual(status?.fans.first, SmctlFan(index: 0, actualRPM: 2316, minimumRPM: 2317, maximumRPM: 7826, mode: "manual"))
    }

    func testParsesPowerStatusWithoutRecordedThrottling() {
        XCTAssertEqual(SmctlStatusParser.power(powerJSON),
                       SmctlPowerStatus(thermalPressure: "nominal", throttlingRecorded: false, speedLimitPercent: nil))
    }

    func testParsesRecordedSpeedLimit() {
        let json = #"{"cpu":{"recorded":true,"speedLimit":85},"thermalPressure":"moderate"}"#.data(using: .utf8)!
        XCTAssertEqual(SmctlStatusParser.power(json),
                       SmctlPowerStatus(thermalPressure: "moderate", throttlingRecorded: true, speedLimitPercent: 85))
    }

    func testGarbageIsNil() {
        XCTAssertNil(SmctlStatusParser.fan(Data("nope".utf8)))
        XCTAssertNil(SmctlStatusParser.power(Data()))
    }

    func testLastKeeperEventStripsSecondsAndZone() {
        let log = """
        2026-09-30 01:01:34 -0500 OK: profile 'anti-throttle' is active
        2026-09-30 03:10:02 -0500 GUARD TRIPPED: temperature Tp00 111C (hottest: Tp00=111.0)

        """
        XCTAssertEqual(SmctlStatusParser.lastKeeperEvent(log),
                       "2026-09-30 03:10 — GUARD TRIPPED: temperature Tp00 111C (hottest: Tp00=111.0)")
        XCTAssertNil(SmctlStatusParser.lastKeeperEvent(""))
    }
}
