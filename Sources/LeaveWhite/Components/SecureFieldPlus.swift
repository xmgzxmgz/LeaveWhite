import SwiftUI

struct SecureFieldPlus: View {
    @Binding var text: String
    var placeholderKey: String

    @State private var isRevealed = false
    @State private var maskPulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Group {
                    if isRevealed {
                        TextField(String(localized: String.LocalizationValue(placeholderKey), bundle: .module), text: $text)
                            .platformTextInputAutocapitalizationNever()
                            .platformAutocorrectionDisabled()
                    } else {
                        SecureField(String(localized: String.LocalizationValue(placeholderKey), bundle: .module), text: $text)
                            .platformTextInputAutocapitalizationNever()
                            .platformAutocorrectionDisabled()
                    }
                }
                .foregroundStyle(Theme.textPrimary)
                .font(.system(size: 16, weight: .regular))
                .padding(.vertical, 10)

                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        isRevealed.toggle()
                        maskPulse.toggle()
                    }
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .foregroundStyle(Theme.textPrimary.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.secondaryBackground.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Theme.gold.opacity(maskPulse ? 0.55 : 0.20), lineWidth: 1)
                    )
            )

            StrengthBar(strength: strength(for: text))
        }
    }

    private func strength(for value: String) -> Double {
        let lengthScore = min(1.0, Double(value.count) / 12.0)
        let hasLower = value.range(of: "[a-z]", options: .regularExpression) != nil
        let hasUpper = value.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumber = value.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSymbol = value.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        let variety = [hasLower, hasUpper, hasNumber, hasSymbol].filter { $0 }.count
        let varietyScore = Double(variety) / 4.0
        return min(1.0, (lengthScore * 0.65) + (varietyScore * 0.35))
    }
}

private struct StrengthBar: View {
    var strength: Double

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let filled = max(0, min(1, strength)) * width

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.gold.opacity(0.25),
                                Theme.gold
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: filled)
            }
        }
        .frame(height: 6)
        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: strength)
    }
}
