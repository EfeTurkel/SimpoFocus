import Foundation

struct FocusSession: Codable, Identifiable {
    let id: UUID
    let date: Date
    let durationMinutes: Double
    let category: FocusCategory
    let coinsEarned: Double
    
    init(id: UUID = UUID(), date: Date = Date(), durationMinutes: Double, category: FocusCategory, coinsEarned: Double) {
        self.id = id
        self.date = date
        self.durationMinutes = durationMinutes
        self.category = category
        self.coinsEarned = coinsEarned
    }
    
    var hours: Double {
        durationMinutes / 60.0
    }
}

