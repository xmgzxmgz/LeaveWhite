import Testing
@testable import LeaveWhiteCore

@Suite("HeuristicClassifier Tests")
struct HeuristicClassifierTests {

    @Test("Empty text returns .other with zero confidence")
    func emptyText() {
        let result = HeuristicClassifier.classify(text: "")
        #expect(result.type == .other)
        #expect(result.confidence == 0.0)
    }

    @Test("Whitespace-only text returns .other")
    func whitespaceOnly() {
        let result = HeuristicClassifier.classify(text: "   \n  ")
        #expect(result.type == .other)
        #expect(result.confidence == 0.0)
    }

    @Test("12+ word mnemonic classified as crypto")
    func mnemonicWords() {
        let text = "abandon ability able about above absent absorb abstract absurd abuse access accident"
        let result = HeuristicClassifier.classify(text: text)
        #expect(result.type == .crypto)
        #expect(result.confidence >= 0.9)
    }

    @Test("Hex private key classified as crypto")
    func hexKey() {
        let text = "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab"
        let result = HeuristicClassifier.classify(text: text)
        #expect(result.type == .crypto)
    }

    @Test("Password hint classified as password")
    func passwordHint() {
        let result = HeuristicClassifier.classify(text: "My password is very strong")
        #expect(result.type == .password)
        #expect(result.confidence >= 0.75)
    }

    @Test("Chinese password keyword classified as password")
    func chinesePassword() {
        let result = HeuristicClassifier.classify(text: "这是我的密码")
        #expect(result.type == .password)
    }

    @Test("Email classified as account")
    func emailText() {
        let result = HeuristicClassifier.classify(text: "contact me at user@example.com")
        #expect(result.type == .account)
    }

    @Test("URL classified as account")
    func urlText() {
        let result = HeuristicClassifier.classify(text: "Visit https://example.com for details")
        #expect(result.type == .account)
    }

    @Test("Long text (120+ chars) classified as reflection")
    func longText() {
        let text = String(repeating: "This is a long reflective journal entry about life and everything that matters deeply. ", count: 3)
        let result = HeuristicClassifier.classify(text: text)
        #expect(result.type == .reflection)
        #expect(result.confidence >= 0.6)
    }

    @Test("Short ambiguous text returns .other")
    func shortText() {
        let result = HeuristicClassifier.classify(text: "Hello world")
        #expect(result.type == .other)
        #expect(result.confidence == 0.50)
    }
}
