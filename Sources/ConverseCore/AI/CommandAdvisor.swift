import Foundation

public struct AiCommandSuggestion: Equatable, Sendable {
    public let command: String
    public let explanation: String?
    public let riskLevel: RiskLevel
    public let impactScope: String
    public let requiresConfirmation: Bool
    public let provider: String
    public let model: String
    public let promptVersion: String

    public init(
        command: String,
        explanation: String?,
        riskLevel: RiskLevel,
        impactScope: String,
        requiresConfirmation: Bool,
        provider: String,
        model: String,
        promptVersion: String
    ) {
        self.command = command; self.explanation = explanation
        self.riskLevel = riskLevel; self.impactScope = impactScope
        self.requiresConfirmation = requiresConfirmation
        self.provider = provider; self.model = model; self.promptVersion = promptVersion
    }
}

public struct CommandAdvisor {
    public let client: AiClient
    public let riskDetector: RiskDetector

    public init(client: AiClient, riskDetector: RiskDetector = RiskDetector()) {
        self.client = client; self.riskDetector = riskDetector
    }

    public func suggest(
        naturalLanguage: String,
        context: String,
        policy: ConfirmationPolicy = .standard
    ) async throws -> AiCommandSuggestion {
        let proposal = try await client.translate(naturalLanguage: naturalLanguage, context: context)
        let risk = riskDetector.assess(proposal.command, policy: policy)
        return AiCommandSuggestion(
            command: proposal.command,
            explanation: proposal.explanation,
            riskLevel: risk.level,
            impactScope: risk.impactScope,
            requiresConfirmation: risk.requiresConfirmation,
            provider: proposal.provider,
            model: proposal.model,
            promptVersion: proposal.promptVersion
        )
    }
}
