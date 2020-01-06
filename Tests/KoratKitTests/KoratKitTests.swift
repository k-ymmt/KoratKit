import XCTest
@testable import KoratKit

final class KoratKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(KoratKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
