import XCTest
@testable import Atoll

final class NotchForkLayoutTests: XCTestCase {
    func testClosedHoverZoneAddsMarginOnBothSides() {
        XCTAssertEqual(NotchForkLayout.closedHoverWidth(contentWidth: 185), 217)
        XCTAssertEqual(NotchForkLayout.closedHoverWidth(contentWidth: 0), 32)
    }

    func testClosedHoverRectWidensSidesOnly() {
        let pill = CGRect(x: 100, y: 0, width: 185, height: 32)
        XCTAssertEqual(NotchForkLayout.closedHoverRect(pillRect: pill),
                       CGRect(x: 84, y: 0, width: 217, height: 32))
    }
}
