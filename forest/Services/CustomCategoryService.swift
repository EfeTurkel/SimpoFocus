import Foundation
import SwiftUI

final class CustomCategoryService: ObservableObject {
    static let shared = CustomCategoryService()
    
    @Published var customCategories: [CustomCategory] = []
    
    private let storageKey = "custom_categories"
    
    private init() {
        loadCustomCategories()
    }
    
    func addCustomCategory(_ category: CustomCategory) {
        customCategories.append(category)
        saveCustomCategories()
    }
    
    func updateCustomCategory(_ category: CustomCategory) {
        if let index = customCategories.firstIndex(where: { $0.id == category.id }) {
            customCategories[index] = category
            saveCustomCategories()
        }
    }
    
    func deleteCustomCategory(_ category: CustomCategory) {
        customCategories.removeAll { $0.id == category.id }
        saveCustomCategories()
    }
    
    func getAllCategories() -> [FocusCategory] {
        let predefined = FocusCategory.PredefinedCategory.allCases.map { FocusCategory.predefined($0) }
        let custom = customCategories.map { FocusCategory.custom($0) }
        return predefined + custom
    }
    
    private func loadCustomCategories() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let categories = try? JSONDecoder().decode([CustomCategory].self, from: data) {
            customCategories = categories
        }
    }
    
    private func saveCustomCategories() {
        if let data = try? JSONEncoder().encode(customCategories) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

// MARK: - Icon Options
extension CustomCategoryService {
    static let availableIcons = [
        "book.fill", "brain.head.profile", "pencil.and.outline", "paintbrush.fill",
        "music.note", "camera.fill", "gamecontroller.fill", "heart.fill",
        "leaf.fill", "flame.fill", "drop.fill", "snowflake",
        "sun.max.fill", "moon.fill", "star.fill", "sparkles",
        "bolt.fill", "wifi", "antenna.radiowaves.left.and.right", "waveform",
        "mic.fill", "speaker.wave.2.fill", "tv.fill", "laptopcomputer",
        "iphone", "ipad", "applewatch", "airpods",
        "car.fill", "bicycle", "figure.walk", "figure.run",
        "figure.yoga", "figure.strengthtraining.traditional", "figure.pool.swim", "figure.skiing.downhill",
        "soccerball", "basketball.fill", "tennisball", "baseball.fill",
        "football.fill", "hockey.puck", "figure.archery", "figure.bowling",
        "figure.climbing", "figure.fishing", "figure.hiking", "figure.sailing",
        "airplane", "train.side.front.car", "bus.fill", "tram.fill",
        "ferry.fill", "sailboat.fill", "bicycle", "scooter",
        "house.fill", "building.2.fill", "building.columns.fill", "graduationcap.fill",
        "briefcase.fill", "person.2.fill", "person.3.fill", "person.crop.circle.fill",
        "person.crop.square.fill", "person.crop.rectangle.fill", "person.crop.artframe",
        "person.crop.circle.badge.plus", "person.crop.circle.badge.minus", "person.crop.circle.badge.checkmark",
        "person.crop.circle.badge.xmark", "person.crop.circle.badge.questionmark", "person.crop.circle.badge.exclamationmark",
        "person.crop.circle.badge.clock", "person.crop.circle.badge.timer", "person.crop.circle.badge.moon",
        "person.crop.circle.badge.sun.max", "person.crop.circle.badge.bolt", "person.crop.circle.badge.plus",
        "person.crop.circle.badge.minus", "person.crop.circle.badge.checkmark", "person.crop.circle.badge.xmark",
        "person.crop.circle.badge.questionmark", "person.crop.circle.badge.exclamationmark", "person.crop.circle.badge.clock",
        "person.crop.circle.badge.timer", "person.crop.circle.badge.moon", "person.crop.circle.badge.sun.max",
        "person.crop.circle.badge.bolt", "person.crop.circle.badge.plus", "person.crop.circle.badge.minus",
        "person.crop.circle.badge.checkmark", "person.crop.circle.badge.xmark", "person.crop.circle.badge.questionmark",
        "person.crop.circle.badge.exclamationmark", "person.crop.circle.badge.clock", "person.crop.circle.badge.timer",
        "person.crop.circle.badge.moon", "person.crop.circle.badge.sun.max", "person.crop.circle.badge.bolt"
    ]
}
