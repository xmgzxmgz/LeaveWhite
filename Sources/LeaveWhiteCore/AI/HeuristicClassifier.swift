import Foundation

public struct HeuristicClassification: Sendable {
    public var type: AutoClassifiedType
    public var confidence: Double

    public init(type: AutoClassifiedType, confidence: Double) {
        self.type = type
        self.confidence = confidence
    }
}

public enum HeuristicClassifier {
    public static func classify(text: String) -> HeuristicClassification {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return HeuristicClassification(type: .other, confidence: 0.0)
        }

        let lower = trimmed.lowercased()

        let hasMnemonicWords = trimmed.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count >= 12
        let hasUrl = lower.contains("http://") || lower.contains("https://") || lower.contains("www.")
        let hasEmail = lower.range(of: "[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}", options: .regularExpression) != nil
        let hasPasswordHint = lower.contains("password") || lower.contains("密码") || lower.contains("passcode")
        let hasAccountHint = lower.contains("账号") || lower.contains("username") || lower.contains("account")
        let looksLikeKey = lower.range(of: "0x[0-9a-f]{32,}", options: .regularExpression) != nil

        if hasMnemonicWords || looksLikeKey {
            return HeuristicClassification(type: .crypto, confidence: 0.92)
        }

        if hasPasswordHint {
            return HeuristicClassification(type: .password, confidence: 0.80)
        }

        if hasAccountHint || hasEmail || hasUrl {
            return HeuristicClassification(type: .account, confidence: 0.68)
        }

        if trimmed.count >= 120 {
            return HeuristicClassification(type: .reflection, confidence: 0.62)
        }

        return HeuristicClassification(type: .other, confidence: 0.50)
    }
}
