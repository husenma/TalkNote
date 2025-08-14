import XCTest
@testable import LiveTranscribe

final class LiveTranscribeTests: XCTestCase {
    func testTranslatorPassThroughWhenNoKey() async throws {
        let t = TranslatorService()
        let result = try await t.translate(text: "hola", from: "es", to: "en")
        XCTAssertEqual(result, "hola")
    }
}
