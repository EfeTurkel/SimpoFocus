import Foundation

enum TokenFormatter {
    static func format(_ value: Double, maximumFractionDigits: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = max(0, maximumFractionDigits)
        formatter.minimumFractionDigits = 0
        formatter.locale = Locale(identifier: LocalizationManager.shared.language.localeIdentifier)
        let number = formatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(number) Sim"
    }

    static func abbreviatedTokens(_ value: Double, maximumFractionDigits: Int = 2) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        let decimalFormatter = NumberFormatter()
        decimalFormatter.numberStyle = .decimal
        decimalFormatter.maximumFractionDigits = max(0, maximumFractionDigits)
        decimalFormatter.minimumFractionDigits = 0
        decimalFormatter.locale = Locale(identifier: LocalizationManager.shared.language.localeIdentifier)

        if absValue >= 1_000_000_000 {
            let scaled = absValue / 1_000_000_000
            let number = decimalFormatter.string(from: NSNumber(value: scaled)) ?? "0"
            return "\(sign)\(number)B Sim"
        }

        if absValue >= 1_000_000 {
            let scaled = absValue / 1_000_000
            let number = decimalFormatter.string(from: NSNumber(value: scaled)) ?? "0"
            return "\(sign)\(number)M Sim"
        }

        if absValue >= 1_000 {
            let scaled = absValue / 1_000
            let number = decimalFormatter.string(from: NSNumber(value: scaled)) ?? "0"
            return "\(sign)\(number)K Sim"
        }

        let formatted = decimalFormatter.string(from: NSNumber(value: absValue)) ?? "0"
        return "\(sign)\(formatted) Sim"
    }
}

