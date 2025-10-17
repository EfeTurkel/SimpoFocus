import SwiftUI

struct CategoryPickerSheet: View {
    @Binding var selectedCategory: FocusCategory
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localization: LocalizationManager
    @StateObject private var customCategoryService = CustomCategoryService.shared
    @State private var showingAddCategory = false
    @State private var searchText = ""
    @State private var selectedSection = 0
    
    private var filteredPredefinedCategories: [FocusCategory] {
        if searchText.isEmpty {
            return FocusCategory.allCases
        } else {
            return FocusCategory.allCases.filter { category in
                category.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var filteredCustomCategories: [FocusCategory] {
        if searchText.isEmpty {
            return customCategoryService.customCategories.map { FocusCategory.custom($0) }
        } else {
            return customCategoryService.customCategories
                .map { FocusCategory.custom($0) }
                .filter { category in
                    category.displayName.localizedCaseInsensitiveContains(searchText)
                }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color("LakeNight").opacity(0.95),
                        Color("ForestGreen").opacity(0.8),
                        Color("LakeBlue").opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern Header
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(loc("CATEGORY_PICKER_TITLE"))
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .onGlassPrimary()
                                
                                Text(loc("CATEGORY_PICKER_SUBTITLE"))
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .onGlassSecondary()
                            }
                            
                            Spacer()
                            
                            // Add Category Button
                            Button(action: { showingAddCategory = true }) {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.blue)
                                }
                            }
                            .scaleEffect(1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showingAddCategory)
                        }
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            TextField(loc("SEARCH_CATEGORIES"), text: $searchText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16, weight: .medium))
                                .onGlassPrimary()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .liquidGlass(.card, edgeMask: .all)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    
                    // Content
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            // Predefined Categories
                            CategorySection(
                                title: loc("CATEGORY_PREDEFINED"),
                                categories: filteredPredefinedCategories,
                                selectedCategory: selectedCategory,
                                onCategorySelected: { category in
                                    selectedCategory = category
                                    dismiss()
                                }
                            )
                            
                            // Custom Categories
                            if !customCategoryService.customCategories.isEmpty {
                                CategorySection(
                                    title: loc("CATEGORY_CUSTOM"),
                                    categories: filteredCustomCategories,
                                    selectedCategory: selectedCategory,
                                    onCategorySelected: { category in
                                        selectedCategory = category
                                        dismiss()
                                    },
                                    onDelete: { category in
                                        if case .custom(let customCategory) = category {
                                            customCategoryService.deleteCustomCategory(customCategory)
                                        }
                                    }
                                )
                            }
                            
                            // Empty State for Custom Categories
                            if customCategoryService.customCategories.isEmpty && searchText.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "star.circle")
                                        .font(.system(size: 48, weight: .light))
                                        .foregroundStyle(.secondary)
                                    
                                    Text(loc("NO_CUSTOM_CATEGORIES"))
                                        .font(.system(size: 18, weight: .medium))
                                        .onGlassPrimary()
                                    
                                    Text(loc("NO_CUSTOM_CATEGORIES_SUBTITLE"))
                                        .font(.system(size: 14, weight: .regular))
                                        .onGlassSecondary()
                                        .multilineTextAlignment(.center)
                                    
                                    Button(action: { showingAddCategory = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 14, weight: .semibold))
                                            Text(loc("CREATE_FIRST_CATEGORY"))
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule()
                                                .fill(.blue)
                                        )
                                    }
                                }
                                .padding(.vertical, 40)
                                .padding(.horizontal, 24)
                                .liquidGlass(.card, edgeMask: .all)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddCategory) {
            AddCategorySheet()
                .environmentObject(localization)
        }
    }
    
    private func loc(_ key: String, _ arguments: CVarArg...) -> String {
        localization.translate(key, fallback: key, arguments: arguments)
    }
}

// MARK: - Category Section
private struct CategorySection: View {
    let title: String
    let categories: [FocusCategory]
    let selectedCategory: FocusCategory
    let onCategorySelected: (FocusCategory) -> Void
    let onDelete: ((FocusCategory) -> Void)?
    
    init(title: String, categories: [FocusCategory], selectedCategory: FocusCategory, onCategorySelected: @escaping (FocusCategory) -> Void, onDelete: ((FocusCategory) -> Void)? = nil) {
        self.title = title
        self.categories = categories
        self.selectedCategory = selectedCategory
        self.onCategorySelected = onCategorySelected
        self.onDelete = onDelete
    }
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .onGlassPrimary()
                
                Spacer()
                
                Text("\(categories.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
            }
            
            // Categories Grid
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(categories, id: \.id) { category in
                    ModernCategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: { onCategorySelected(category) },
                        onDelete: onDelete != nil ? { onDelete!(category) } : nil
                    )
                }
            }
        }
    }
}

// MARK: - Modern Category Button
private struct ModernCategoryButton: View {
    let category: FocusCategory
    let isSelected: Bool
    let action: () -> Void
    let onDelete: (() -> Void)?
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon Container
                ZStack {
                    // Background Circle
                    Circle()
                        .fill(isSelected ? category.color : category.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? category.color : .clear, lineWidth: 2)
                        )
                    
                    // Icon
                    Image(systemName: category.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : category.color)
                    
                    // Delete Button for Custom Categories
                    if onDelete != nil {
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: onDelete!) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.red)
                                        .background(
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .frame(width: 24, height: 24)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                            Spacer()
                        }
                        .frame(width: 80, height: 80)
                    }
                }
                
                // Category Name
                Text(category.displayName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .onGlassPrimary()
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .liquidGlass(.card, edgeMask: .all)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? category.color : .clear, lineWidth: isSelected ? 2 : 0)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

