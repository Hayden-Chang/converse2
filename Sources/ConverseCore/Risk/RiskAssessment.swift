import Foundation

public struct RiskAssessment: Equatable, Sendable {
    public let level: RiskLevel
    public let matchedRules: [String]
    public let impactScope: String
    public let requiresConfirmation: Bool

    public init(level: RiskLevel, matchedRules: [String], impactScope: String, requiresConfirmation: Bool) {
        self.level = level
        self.matchedRules = matchedRules
        self.impactScope = impactScope
        self.requiresConfirmation = requiresConfirmation
    }

    public static let safe = RiskAssessment(
        level: .low,
        matchedRules: [],
        impactScope: "",
        requiresConfirmation: false
    )
}
