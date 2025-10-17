import SwiftUI

struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localization: LocalizationManager
    @StateObject private var customCategoryService = CustomCategoryService.shared
    
    @State private var categoryName = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = CategoryColor.blue
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    
    private let iconColumns = Array(repeating: GridItem(.flexible()), count: 6)
    private let colorColumns = Array(repeating: GridItem(.flexible()), count: 5)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loc("ADD_CATEGORY_TITLE"))
                                .font(.largeTitle.weight(.bold))
                                .onGlassPrimary()
                            
                            Text(loc("ADD_CATEGORY_SUBTITLE"))
                                .font(.subheadline)
                                .onGlassSecondary()
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .liquidGlass(.header, edgeMask: .all)
                .clipShape(RoundedRectangle(cornerRadius: 0))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Category Name Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text(loc("CATEGORY_NAME"))
                                .font(.headline.weight(.semibold))
                                .onGlassPrimary()
                            
                            TextField(loc("CATEGORY_NAME_PLACEHOLDER"), text: $categoryName)
                                .textFieldStyle(.plain)
                                .font(.body)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .liquidGlass(.card, edgeMask: .all)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .padding(.horizontal, 24)
                        
                        // Icon Selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(loc("CATEGORY_ICON"))
                                    .font(.headline.weight(.semibold))
                                    .onGlassPrimary()
                                
                                Spacer()
                                
                                Button(action: { showingIconPicker.toggle() }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: selectedIcon)
                                            .font(.title3)
                                            .foregroundStyle(selectedColor.color)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .onGlassSecondary()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .liquidGlass(.card, edgeMask: .all)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                            }
                            
                            if showingIconPicker {
                                LazyVGrid(columns: iconColumns, spacing: 12) {
                                    ForEach(CustomCategoryService.availableIcons.prefix(24), id: \.self) { icon in
                                        Button(action: {
                                            selectedIcon = icon
                                            showingIconPicker = false
                                        }) {
                                            Image(systemName: icon)
                                                .font(.title3)
                                                .foregroundStyle(selectedColor.color)
                                                .frame(width: 44, height: 44)
                                                .background(
                                                    Circle()
                                                        .fill(selectedIcon == icon ? selectedColor.color.opacity(0.2) : .clear)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .liquidGlass(.card, edgeMask: .all)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Color Selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(loc("CATEGORY_COLOR"))
                                    .font(.headline.weight(.semibold))
                                    .onGlassPrimary()
                                
                                Spacer()
                                
                                Button(action: { showingColorPicker.toggle() }) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(selectedColor.color)
                                            .frame(width: 20, height: 20)
                                        Text(selectedColor.displayName)
                                            .font(.subheadline)
                                            .onGlassPrimary()
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .onGlassSecondary()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .liquidGlass(.card, edgeMask: .all)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                            }
                            
                            if showingColorPicker {
                                LazyVGrid(columns: colorColumns, spacing: 12) {
                                    ForEach(CategoryColor.allCases, id: \.self) { color in
                                        Button(action: {
                                            selectedColor = color
                                            showingColorPicker = false
                                        }) {
                                            Circle()
                                                .fill(color.color)
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    Circle()
                                                        .stroke(selectedColor == color ? .white : .clear, lineWidth: 3)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .liquidGlass(.card, edgeMask: .all)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Preview
                        VStack(alignment: .leading, spacing: 12) {
                            Text(loc("CATEGORY_PREVIEW"))
                                .font(.headline.weight(.semibold))
                                .onGlassPrimary()
                            
                            HStack {
                                Image(systemName: selectedIcon)
                                    .font(.title2)
                                    .foregroundStyle(selectedColor.color)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(selectedColor.color.opacity(0.2))
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(categoryName.isEmpty ? loc("CATEGORY_NAME_PLACEHOLDER") : categoryName)
                                        .font(.subheadline.weight(.semibold))
                                        .onGlassPrimary()
                                    
                                    Text(loc("CATEGORY_CUSTOM"))
                                        .font(.caption)
                                        .onGlassSecondary()
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .liquidGlass(.card, edgeMask: .all)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [Color("LakeNight").opacity(0.9), Color("ForestGreen").opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(loc("CANCEL")) {
                        dismiss()
                    }
                    .onGlassPrimary()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(loc("SAVE")) {
                        saveCategory()
                    }
                    .onGlassPrimary()
                    .disabled(categoryName.isEmpty)
                }
            }
        }
    }
    
    private func saveCategory() {
        let customCategory = CustomCategory(
            name: categoryName,
            icon: selectedIcon,
            color: selectedColor
        )
        
        customCategoryService.addCustomCategory(customCategory)
        dismiss()
    }
    
    private func loc(_ key: String) -> String {
        localization.translate(key, fallback: key)
    }
}
