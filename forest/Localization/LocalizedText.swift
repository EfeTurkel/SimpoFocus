import SwiftUI

struct LocalizedText: View {
    @EnvironmentObject private var localization: LocalizationManager
    private let key: String
    private let arguments: [CVarArg]

    init(_ key: String, _ arguments: CVarArg...) {
        self.key = key
        self.arguments = arguments
    }

    var body: some View {
        Text(localization.translate(key, arguments: arguments))
    }
}

extension View {
    func localizedString(_ key: String, _ arguments: CVarArg...) -> String {
        LocalizationManager.shared.translate(key, arguments: arguments)
    }
}

