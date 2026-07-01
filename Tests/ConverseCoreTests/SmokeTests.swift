import XCTest
@testable import ConverseCore

/// 冒烟测试：验证核心域类型与脚手架可编译可测。
final class SmokeTests: XCTestCase {

    func testRiskLevelLabels() {
        XCTAssertEqual(RiskLevel.low.label, "低")
        XCTAssertEqual(RiskLevel.medium.label, "中")
        XCTAssertEqual(RiskLevel.high.label, "高")
        XCTAssertEqual(RiskLevel.critical.label, "极高")
    }

    func testAiModeRoundTrip() throws {
        for mode in AiMode.allCases {
            let encoded = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(AiMode.self, from: encoded)
            XCTAssertEqual(decoded, mode)
        }
    }

    func testSessionStatusLabel() {
        XCTAssertEqual(SessionStatus.running.label, "运行")
        XCTAssertEqual(SessionStatus.missing.label, "丢失")
    }
}
