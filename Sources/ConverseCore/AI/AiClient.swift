import Foundation

public enum AiError: Error, Equatable {
    case notConfigured
    case unauthorized
    case rateLimited
    case http(Int)
    case transport(String)
    case decodeFailed
}

public protocol AiTransport {
    func send(request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct UrlSessionTransport: AiTransport {
    public let session: URLSession
    public init(session: URLSession = .shared) { self.session = session }
    public func send(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, resp) = try await session.data(for: request)
        guard let http = resp as? HTTPURLResponse else { throw AiError.transport("non-http") }
        return (data, http)
    }
}

public struct AiConfig: Equatable, Sendable {
    public let apiBaseUrl: String
    public let model: String
    public let apiKey: String
    public let promptVersion: String
    public init(apiBaseUrl: String, model: String, apiKey: String, promptVersion: String) {
        self.apiBaseUrl = apiBaseUrl; self.model = model
        self.apiKey = apiKey; self.promptVersion = promptVersion
    }
}

public struct AiProposal: Equatable, Sendable {
    public let command: String
    public let explanation: String?
    public let provider: String
    public let model: String
    public let promptVersion: String
    public init(command: String, explanation: String?, provider: String, model: String, promptVersion: String) {
        self.command = command; self.explanation = explanation
        self.provider = provider; self.model = model; self.promptVersion = promptVersion
    }
}

public final class AiClient {
    public let config: AiConfig
    private let transport: AiTransport
    private let fewShot: FewShotStore

    public init(config: AiConfig, transport: AiTransport = UrlSessionTransport(), fewShot: FewShotStore = .bundled) {
        self.config = config
        self.transport = transport
        self.fewShot = fewShot
    }

    public func translate(
        naturalLanguage: String,
        context: String,
        fewShotLimit: Int = 3
    ) async throws -> AiProposal {
        guard !config.apiKey.isEmpty else { throw AiError.notConfigured }
        let few = fewShot.retrieve(for: naturalLanguage, limit: fewShotLimit)
        let system = PromptBuilder.buildSystemPrompt(cwd: context, sessionName: "", fewShot: few)
        let user = PromptBuilder.buildUserMessage(naturalLanguage)
        let body = RequestBody(
            model: config.model,
            temperature: 0.0,
            messages: [.init(role: "system", content: system), .init(role: "user", content: user)]
        )
        guard let url = URL(string: "\(config.apiBaseUrl)/v1/chat/completions") else {
            throw AiError.transport("bad_url")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let resp: HTTPURLResponse
        do {
            (data, resp) = try await transport.send(request: req)
        } catch let e as AiError {
            throw e
        } catch {
            throw AiError.transport("\(error)")
        }
        switch resp.statusCode {
        case 200...299: break
        case 401: throw AiError.unauthorized
        case 429: throw AiError.rateLimited
        default: throw AiError.http(resp.statusCode)
        }
        guard let decoded = try? JSONDecoder().decode(ResponseBody.self, from: data),
              let content = decoded.choices.first?.message.content else {
            throw AiError.decodeFailed
        }
        let (command, explanation) = Self.cleanOutput(content)
        return AiProposal(
            command: command,
            explanation: explanation,
            provider: config.apiBaseUrl,
            model: config.model,
            promptVersion: config.promptVersion
        )
    }

    public static func cleanOutput(_ content: String) -> (command: String, explanation: String?) {
        var lines = content.split(separator: "\n", omittingEmptySubsequences: true)
            .map { String($0).trimmingCharacters(in: .whitespaces) }
        lines = lines.map { line -> String in
            var l = line
            if l.hasPrefix("```") {
                l = String(l.dropFirst(3))
                if l.hasPrefix("bash") || l.hasPrefix("zsh") || l.hasPrefix("sh") {
                    l = String(l.drop(while: { $0.isLetter }))
                }
            }
            if l.hasSuffix("```") && l.count > 3 { l = String(l.dropLast(3)) }
            return l.trimmingCharacters(in: .whitespaces)
        }
        lines = lines.filter { !$0.isEmpty && !$0.hasPrefix("```") }
        guard let first = lines.first else { return ("", nil) }
        let rest = Array(lines.dropFirst())
        let explanation = rest.isEmpty ? nil : rest.joined(separator: " ")
        return (first, explanation)
    }
}

struct RequestBody: Encodable {
    let model: String
    let temperature: Double
    let messages: [Message]
    struct Message: Encodable { let role: String; let content: String }
}

struct ResponseBody: Decodable {
    let choices: [Choice]
    struct Choice: Decodable { let message: Message }
    struct Message: Decodable { let content: String }
}
