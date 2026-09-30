import XCTest
@testable import Atoll

final class NotchForkSmokeTests: XCTestCase {
    /// Tests are hosted in the app, so this proves both that the test target runs
    /// and that Task 1's bundle-ID change is what actually got built.
    func testHostAppIsTheForkBuild() {
        XCTAssertEqual(Bundle.main.bundleIdentifier, "com.prathambansal.notch.dev")
    }
}
