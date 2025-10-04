import Foundation

struct BankSnapshot: Codable {
    let annualInterestRate: Double
    let lastRateUpdate: Date
    let lastInterestApplied: Date
}

