import SwiftUI

struct CategoryPickerSheet: View {
    @Binding var selectedCategory: FocusCategory
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localization: LocalizationManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var customCategoryService = CustomCategoryService.shared
    @State private var showingAddCategory = false
    @State private var searchText = ""
    @State private var appeared = false

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
        NavigationStack {
            ZStack {
                themeManager.currentTheme.getBackgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection
                    contentSection
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddCategory) {
                AddCategorySheet()
                    .environmentObject(localization)
            }
            .onAppear {
                withAnimation(DS.Animation.defaultSpring.delay(0.1)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: DS.Padding.card) {
            HStack {
                VStack(alignment: .leading, spacing: DS.Padding.element) {
                    Text(loc("CATEGORY_PICKER_TITLE"))
                        .font(DS.Typography.heroTitle)
                        .onGlassPrimary()

                    Text(loc("CATEGORY_PICKER_SUBTITLE"))
                        .font(DS.Typography.body)
                        .onGlassSecondary()
                }

                Spacer()

                Button(action: { showingAddCategory = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color("ForestGreen"))
                        .frame(width: DS.IconSize.medium, height: DS.IconSize.medium)
                }
                .buttonStyle(ScaleButtonStyle())
            }

            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .onGlassSecondary()

                TextField(loc("SEARCH_CATEGORIES"), text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .onGlassPrimary()
            }
            .padding(.horizontal, DS.Padding.section)
            .padding(.vertical, DS.Padding.element)
        }
        .padding(.horizontal, DS.Padding.screen)
        .padding(.top, DS.Padding.card)
        .padding(.bottom, DS.Padding.screen)
    }

    // MARK: - Content

    private var contentSection: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: DS.Padding.screen) {
                CategorySection(
                    title: loc("CATEGORY_PREDEFINED"),
                    categories: filteredPredefinedCategories,
                    selectedCategory: selectedCategory,
                    onCategorySelected: { category in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedCategory = category
                        dismiss()
                    }
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

                if !customCategoryService.customCategories.isEmpty {
                    CategorySection(
                        title: loc("CATEGORY_CUSTOM"),
                        categories: filteredCustomCategories,
                        selectedCategory: selectedCategory,
                        onCategorySelected: { category in
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedCategory = category
                            dismiss()
                        },
                        onDelete: { category in
                            if case .custom(let customCategory) = category {
                                customCategoryService.deleteCustomCategory(customCategory)
                            }
                        }
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)
                }

                if customCategoryService.customCategories.isEmpty && searchText.isEmpty {
                    emptyState
                        .opacity(appeared ? 1 : 0)
                }
            }
            .padding(.horizontal, DS.Padding.screen)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        GlassSection(cornerRadius: DS.Radius.medium) {
            VStack(spacing: DS.Padding.section) {
                Image(systemName: "star.circle")
                    .font(.system(size: 48, weight: .light))
                    .onGlassSecondary()

                Text(loc("NO_CUSTOM_CATEGORIES"))
                    .font(.headline)
                    .onGlassPrimary()

                Text(loc("NO_CUSTOM_CATEGORIES_SUBTITLE"))
                    .font(.subheadline)
                    .onGlassSecondary()
                    .multilineTextAlignment(.center)

                Button(action: { showingAddCategory = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.semibold))
                        Text(loc("CREATE_FIRST_CATEGORY"))
                    }
                }
                .buttonStyle(PrimaryCTAStyle())
                .padding(.horizontal, DS.Padding.screen)
            }
            .padding(.vertical, DS.Padding.card)
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
        VStack(alignment: .leading, spacing: DS.Padding.section) {
            HStack {
                Text(title)
                    .font(.title3.weight(.bold))
                    .onGlassPrimary()

                Spacer()

                Text("\(categories.count)")
                    .font(.caption.weight(.semibold))
                    .onGlassSecondary()
                    .padding(.horizontal, DS.Padding.element)
                    .padding(.vertical, 4)
            }

            LazyVGrid(columns: columns, spacing: DS.Padding.section) {
                ForEach(categories, id: \.id) { category in
                    ModernCategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: { onCategorySelected(category) },
                        onDelete: onDelete.map { handler in { handler(category) } }
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

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Padding.element) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color : category.color.opacity(0.15))
                        .frame(width: DS.IconSize.large, height: DS.IconSize.large)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? category.color : .clear, lineWidth: 2)
                        )

                    Image(systemName: category.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : category.color)

                    if let onDelete {
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: onDelete) {
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

                Text(category.displayName)
                    .font(.caption.weight(.semibold))
                    .onGlassPrimary()
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Padding.card)
            .padding(.horizontal, DS.Padding.element)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous)
                    .stroke(isSelected ? category.color : .clear, lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
