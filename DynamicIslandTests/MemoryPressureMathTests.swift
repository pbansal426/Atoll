import XCTest
@testable import Atoll

final class MemoryPressureMathTests: XCTestCase {
    func testPressureIsInverseOfFreeLevel() {
        XCTAssertEqual(MemoryPressureMath.percent(freeLevel: 43), 57)
        XCTAssertEqual(MemoryPressureMath.percent(freeLevel: 100), 0)
        XCTAssertEqual(MemoryPressureMath.percent(freeLevel: 0), 100)
    }

    func testOutOfRangeIsClampedAndMissingIsNil() {
        XCTAssertEqual(MemoryPressureMath.percent(freeLevel: 140), 0)
        XCTAssertEqual(MemoryPressureMath.percent(freeLevel: -5), 100)
        XCTAssertNil(MemoryPressureMath.percent(freeLevel: nil))
    }
}
