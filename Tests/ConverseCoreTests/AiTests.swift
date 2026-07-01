import XCTest
@testable import ConverseCore

// MARK: - Test helpers

private final class StubTransport: AiTransport {
    var data: Data
    var status: Int
    var error: Error?
    var lastRequest: URLRequest?
    init(content: String, status: Int = 200) {
        let json = "{\"choices\":[{\"message\":{\"content\":\(Self.encodeJSON(content))}}]}"
        self.data = Data(json.utf8)
        self.status = status
    }
    init(emptyStatus: Int) {
        self.data = Data("{}".utf8)
        self.status = emptyStatus
    }
    func send(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lastRequest = request
        if let e = error { throw e }
        let url = request.url ?? URL(string: "https://stub.local")!
        let resp = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (data, resp)
    }
    private static func encodeJSON(_ s: String) -> String {
        let d = try! JSONEncoder().encode(s)
        return String(data: d, encoding: .utf8)!
    }
}

private func makeClient(content: String, status: Int = 200) -> AiClient {
    let cfg = AiConfig(apiBaseUrl: "https://stub.local", model: "test-m", apiKey: "k", promptVersion: "v1")
    return AiClient(config: cfg, transport: StubTransport(content: content, status: status))
}

// MARK: - SanitizerTests

final class SanitizerTests: XCTestCase {

    func testPrivateKeyBlockRedacted() {
        let pem = "-----BEGIN RSA PRIVATE KEY-----\nMIIEpQIBAAKCAQEAxxxxxx\n-----END RSA PRIVATE KEY-----"
        let out = Sanitizer.sanitize("key: \(pem)")
        XCTAssertFalse(out.contains("MIIEpQ"))
        XCTAssertTrue(out.contains("[REDACTED]"))
    }

    func testSkTokenRedacted() {
        let out = Sanitizer.sanitize("export OPENAI_API_KEY=sk-abcdefghijklmnopqrstuvwxyz1234567890")
        XCTAssertTrue(out.contains("[REDACTED]"))
        XCTAssertFalse(out.contains("sk-abcdef"))
    }

    func testEnvPasswordValueRedactedKeyKept() {
        let out = Sanitizer.sanitize("PASSWORD=secret123")
        XCTAssertTrue(out.contains("PASSWORD=[REDACTED]"))
        XCTAssertFalse(out.contains("secret123"))
    }

    func testPlainCommandUnchanged() {
        XCTAssertEqual(Sanitizer.sanitize("git status"), "git status")
        XCTAssertEqual(Sanitizer.sanitize("ls -la"), "ls -la")
    }

    func testBearerTokenRedacted() {
        let out = Sanitizer.sanitize("Authorization: Bearer eyJhbGci_abc_def_1234567890")
        XCTAssertTrue(out.contains("Bearer [REDACTED]"))
        XCTAssertFalse(out.contains("eyJhbGci"))
    }

    func testSanitizeContextJoinsAndSanitizes() {
        let ctx = Sanitizer.sanitizeContext(
            cwd: "/work/repo",
            sessionName: "dev",
            recentCommands: ["git status"],
            recentOutput: "PASSWORD=pwd456"
        )
        XCTAssertTrue(ctx.contains("/work/repo"))
        XCTAssertTrue(ctx.contains("git status"))
        XCTAssertTrue(ctx.contains("[REDACTED]"))
        XCTAssertFalse(ctx.contains("pwd456"))
    }
}

// MARK: - FewShotStoreTests

final class FewShotStoreTests: XCTestCase {

    func testRetrieveBigFilesHitsDu() {
        let hits = FewShotStore.bundled.retrieve(for: "列出大文件", limit: 3)
        XCTAssertFalse(hits.isEmpty)
        XCTAssertTrue(hits.contains { $0.command.contains("du -sh") })
    }

    func testRetrieveNoMatchReturnsEmpty() {
        let hits = FewShotStore.bundled.retrieve(for: "zzzqqqxx", limit: 3)
        XCTAssertTrue(hits.isEmpty)
    }

    func testRetrieveLimitRespected() {
        let limited = FewShotStore.bundled.retrieve(for: "git", limit: 1)
        XCTAssertLessThanOrEqual(limited.count, 1)
        let more = FewShotStore.bundled.retrieve(for: "git", limit: 5)
        XCTAssertGreaterThan(more.count, limited.count)
    }

    func testNormalizeSplitsCjk() {
        let tokens = FewShotStore.normalize("列出大文件")
        XCTAssertTrue(tokens.contains("列"))
        XCTAssertTrue(tokens.contains("大"))
    }

    func testNormalizeLatinTokens() {
        let tokens = FewShotStore.normalize("git status here")
        XCTAssertTrue(tokens.contains("git"))
        XCTAssertTrue(tokens.contains("status"))
        XCTAssertTrue(tokens.contains("here"))
    }

    func testCustomStoreRetrieve() {
        let store = FewShotStore(examples: [
            .init(input: "kill process", command: "kill -9 1", risk: .medium)
        ])
        let hits = store.retrieve(for: "kill the process", limit: 2)
        XCTAssertEqual(hits.count, 1)
        XCTAssertEqual(hits.first?.command, "kill -9 1")
    }
}

// MARK: - PromptBuilderTests

final class PromptBuilderTests: XCTestCase {

    func testSystemPromptContainsCwdAndFewShot() {
        let few = Array(FewShotStore.bundled.examples.prefix(2))
        let prompt = PromptBuilder.buildSystemPrompt(cwd: "/Users/me/proj", sessionName: "s1", fewShot: few)
        XCTAssertFalse(prompt.isEmpty)
        XCTAssertTrue(prompt.contains("/Users/me/proj"))
        XCTAssertTrue(prompt.contains(few[0].command))
        XCTAssertTrue(prompt.contains("规则"))
    }

    func testVersionIsV1() {
        XCTAssertEqual(PromptBuilder.version, "v1")
    }

    func testUserMessageIsSanitized() {
        let msg = PromptBuilder.buildUserMessage("do something with sk-abcdefghijklmnopqrstuvwxyz1234567890")
        XCTAssertTrue(msg.contains("[REDACTED]"))
    }
}

// MARK: - AiClientTests

final class AiClientTests: XCTestCase {

    func testTranslateParsesCommand() async throws {
        let client = makeClient(content: "git status")
        let p = try await client.translate(naturalLanguage: "看看状态", context: "cwd: /x")
        XCTAssertEqual(p.command, "git status")
        XCTAssertEqual(p.model, "test-m")
        XCTAssertEqual(p.promptVersion, "v1")
    }

    func testTranslateStripsCodeFence() async throws {
        let client = makeClient(content: "```bash\ngit diff\n```")
        let p = try await client.translate(naturalLanguage: "看改动", context: "")
        XCTAssertEqual(p.command, "git diff")
    }

    func testTranslateKeepsExplanation() async throws {
        let client = makeClient(content: "kill -9 1234\n结束指定进程")
        let p = try await client.translate(naturalLanguage: "结束进程", context: "")
        XCTAssertEqual(p.command, "kill -9 1234")
        XCTAssertEqual(p.explanation, "结束指定进程")
    }

    func testTranslateUnauthorized() async {
        let client = makeClient(content: "", status: 401)
        do {
            _ = try await client.translate(naturalLanguage: "x", context: "")
            XCTFail("expected unauthorized")
        } catch AiError.unauthorized {
        } catch {
            XCTFail("expected unauthorized got \(error)")
        }
    }

    func testTranslateRateLimited() async {
        let client = makeClient(content: "", status: 429)
        do {
            _ = try await client.translate(naturalLanguage: "x", context: "")
            XCTFail("expected rateLimited")
        } catch AiError.rateLimited {
        } catch {
            XCTFail("expected rateLimited got \(error)")
        }
    }

    func testTranslateHttpError() async {
        let client = makeClient(content: "", status: 500)
        do {
            _ = try await client.translate(naturalLanguage: "x", context: "")
            XCTFail("expected http")
        } catch AiError.http(let code) {
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("expected http got \(error)")
        }
    }

    func testTranslateNotConfiguredWhenEmptyKey() async {
        let cfg = AiConfig(apiBaseUrl: "https://x", model: "m", apiKey: "", promptVersion: "v1")
        let client = AiClient(config: cfg, transport: StubTransport(content: "ok"))
        do {
            _ = try await client.translate(naturalLanguage: "x", context: "")
            XCTFail("expected notConfigured")
        } catch AiError.notConfigured {
        } catch {
            XCTFail("expected notConfigured got \(error)")
        }
    }

    func testCleanOutputPlainText() {
        let (cmd, exp) = AiClient.cleanOutput("ls -la")
        XCTAssertEqual(cmd, "ls -la")
        XCTAssertNil(exp)
    }

    func testCleanOutputEmpty() {
        let (cmd, _) = AiClient.cleanOutput("")
        XCTAssertEqual(cmd, "")
    }
}

// MARK: - CommandAdvisorTests

final class CommandAdvisorTests: XCTestCase {

    func testSuggestHighRiskForRmRf() async throws {
        let client = makeClient(content: "rm -rf node_modules")
        let advisor = CommandAdvisor(client: client)
        let s = try await advisor.suggest(naturalLanguage: "重装依赖", context: "", policy: .standard)
        XCTAssertEqual(s.command, "rm -rf node_modules")
        XCTAssertEqual(s.riskLevel, .high)
        XCTAssertTrue(s.requiresConfirmation)
        XCTAssertTrue(s.impactScope.contains("node_modules"))
    }

    func testSuggestLowRiskForGitStatus() async throws {
        let client = makeClient(content: "git status")
        let advisor = CommandAdvisor(client: client)
        let s = try await advisor.suggest(naturalLanguage: "看状态", context: "", policy: .standard)
        XCTAssertEqual(s.riskLevel, .low)
        XCTAssertFalse(s.requiresConfirmation)
    }
}
