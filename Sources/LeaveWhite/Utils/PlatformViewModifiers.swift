import SwiftUI

extension View {
    @ViewBuilder
    func platformTextInputAutocapitalizationNever() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    @ViewBuilder
    func platformAutocorrectionDisabled() -> some View {
        #if os(iOS)
        self.autocorrectionDisabled()
        #else
        self
        #endif
    }

    @ViewBuilder
    func platformSensoryImpact(trigger: Bool) -> some View {
        #if os(iOS)
        self.sensoryFeedback(.impact(weight: .medium), trigger: trigger)
        #else
        self
        #endif
    }

    var toolbarPlacementTrailing: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarTrailing
        #else
        return .automatic
        #endif
    }

    var toolbarPlacementLeading: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarLeading
        #else
        return .automatic
        #endif
    }
}

