import SwiftUI

struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var entitlements: EntitlementManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var customCategoryService = CustomCategoryService.shared

    @State private var categoryName = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = CategoryColor.blue
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    @State private var showingPaywall = false

    private let iconColumns = Array(repeating: GridItem(.flexible()), count: 6)
    private let colorColumns = Array(repeating: GridItem(.flexible()), count: 5)

    private var isAtFreeLimit: Bool {
        !entitlements.canAddCategory(currentCount: customCategoryService.customCategories.count)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: DS.Padding.element) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loc("ADD_CATEGORY_TITLE"))
                                .font(.largeTitle.weight(.bold))
                                .onGlassPrimary()

                            Text(loc("ADD_CATEGORY_SUBTITLE"))
                                .font(.subheadline)
                                .onGlassSecondary()

                            if !entitlements.isPro {
                                Text(localization.translate("ADD_CATEGORY_LIMIT", fallback: "ADD_CATEGORY_LIMIT", arguments: [customCategoryService.customCategories.count, entitlements.maxFreeCategoryCount]))
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .padding(.top, 2)
                            }
                        }

                        Spacer()
                    }
                }
                .padding(.horizontal, DS.Padding.screen)
                .padding(.top, DS.Padding.card)
                .padding(.bottom, DS.Padding.screen)
                .liquidGlass(.hero, edgeMask: .all)

                ScrollView {
                    VStack(spacing: DS.Padding.card) {
                        nameSection
                        iconSection
                        colorSection
                        previewSection
                        Spacer(minLength: 100)
                    }
                    .padding(.top, DS.Padding.section)
                }
            }
            .background(
                themeManager.currentTheme.getBackgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc("CANCEL")) { dismiss() }
                        .onGlassPrimary()
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(loc("SAVE")) {
                        if isAtFreeLimit {
                            showingPaywall = true
                        } else {
                            saveCategory()
                        }
                    }
                    .onGlassPrimary()
                    .disabled(categoryName.isEmpty)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: DS.Padding.element) {
            Text(loc("CATEGORY_NAME"))
                .font(.headline.weight(.semibold))
                .onGlassPrimary()

            TextField(loc("CATEGORY_NAME_PLACEHOLDER"), text: $categoryName)
                .textFieldStyle(.plain)
                .font(.body)
                .onGlassPrimary()
                .padding(.horizontal, DS.Padding.section)
                .padding(.vertical, DS.Padding.element)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
                        .fill(.clear)
                )
                .liquidGlass(.card, edgeMask: [.top])
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
        }
        .padding(.horizontal, DS.Padding.screen)
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: DS.Padding.element) {
            HStack {
                Text(loc("CATEGORY_ICON"))
                    .font(.headline.weight(.semibold))
                    .onGlassPrimary()

                Spacer()

                Button(action: {
                    withAnimation(DS.Animation.quickSpring) {
                        showingIconPicker.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: selectedIcon)
                            .font(.title3)
                            .foregroundStyle(selectedColor.color)
                        Image(systemName: showingIconPicker ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .onGlassSecondary()
                    }
                    .padding(.horizontal, DS.Padding.element)
                    .padding(.vertical, 6)
                }
            }

            if showingIconPicker {
                LazyVGrid(columns: iconColumns, spacing: DS.Padding.element) {
                    ForEach(CustomCategoryService.availableIcons.prefix(24), id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                            withAnimation(DS.Animation.quickSpring) {
                                showingIconPicker = false
                            }
                        }) {
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundStyle(selectedColor.color)
                                .frame(width: DS.IconSize.medium, height: DS.IconSize.medium)
                                .background(
                                    Circle()
                                        .fill(selectedIcon == icon ? selectedColor.color.opacity(0.2) : .clear)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(DS.Padding.section)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                        .fill(.clear)
                )
                .liquidGlass(.card, edgeMask: [.top])
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(.horizontal, DS.Padding.screen)
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: DS.Padding.element) {
            HStack {
                Text(loc("CATEGORY_COLOR"))
                    .font(.headline.weight(.semibold))
                    .onGlassPrimary()

                Spacer()

                Button(action: {
                    withAnimation(DS.Animation.quickSpring) {
                        showingColorPicker.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(selectedColor.color)
                            .frame(width: 20, height: 20)
                        Text(selectedColor.displayName)
                            .font(.subheadline)
                            .onGlassPrimary()
                        Image(systemName: showingColorPicker ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .onGlassSecondary()
                    }
                    .padding(.horizontal, DS.Padding.element)
                    .padding(.vertical, 6)
                }
            }

            if showingColorPicker {
                LazyVGrid(columns: colorColumns, spacing: DS.Padding.element) {
                    ForEach(CategoryColor.allCases, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                            withAnimation(DS.Animation.quickSpring) {
                                showingColorPicker = false
                            }
                        }) {
                            Circle()
                                .fill(color.color)
                                .frame(width: DS.IconSize.medium, height: DS.IconSize.medium)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? .white : .clear, lineWidth: 3)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(DS.Padding.section)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                        .fill(.clear)
                )
                .liquidGlass(.card, edgeMask: [.top])
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(.horizontal, DS.Padding.screen)
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: DS.Padding.element) {
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
            .padding(.horizontal, DS.Padding.section)
            .padding(.vertical, DS.Padding.element)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                    .fill(.clear)
            )
            .liquidGlass(.card, edgeMask: [.top])
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
        }
        .padding(.horizontal, DS.Padding.screen)
    }

    // MARK: - Actions

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
