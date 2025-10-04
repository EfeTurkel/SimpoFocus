import Foundation

enum CurrencyFormatter {
    static func abbreviatedCurrency(_ value: Double, currencyCode: String = "TRY") -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = currencyCode
        currencyFormatter.maximumFractionDigits = 2
        currencyFormatter.minimumFractionDigits = 0

        let decimalFormatter = NumberFormatter()
        decimalFormatter.numberStyle = .decimal
        decimalFormatter.maximumFractionDigits = 2
        decimalFormatter.minimumFractionDigits = 0

        let symbol = currencyFormatter.currencySymbol ?? "₺"

        if absValue >= 1_000_000_000 {
            let scaled = absValue / 1_000_000_000
            let number = decimalFormatter.string(from: NSNumber(value: scaled)) ?? "0"
            return "\(sign)\(symbol)\(number)B"
        }

        if absValue >= 1_000_000 {
            let scaled = absValue / 1_000_000
            let number = decimalFormatter.string(from: NSNumber(value: scaled)) ?? "0"
            return "\(sign)\(symbol)\(number)M"
        }

        let formatted = currencyFormatter.string(from: NSNumber(value: absValue)) ?? "₺0"
        return sign + formatted
    }
}

