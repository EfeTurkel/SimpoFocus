import SwiftUI

struct GlassCard<Content: View>: View {
    var title: String? = nil
    var subtitle: String? = nil
    var icon: String? = nil
    var cornerRadius: CGFloat = DS.Radius.large
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Padding.section) {
            if title != nil || icon != nil {
                header
            }
            content
        }
        .padding(DS.Padding.card)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.clear)
        )
        .liquidGlass(.card, edgeMask: [.top])
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var header: some View {
        HStack(spacing: DS.Padding.element) {
            if let icon {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .onGlassPrimary()
            }

            VStack(alignment: .leading, spacing: 3) {
                if let title {
                    Text(title)
                        .font(DS.Typography.cardTitle)
                        .onGlassPrimary()
                }
                if let subtitle {
                    Text(subtitle)
                        .font(DS.Typography.caption)
                        .onGlassSecondary()
                }
            }

            Spacer()
        }
    }
}

struct GlassSection<Content: View>: View {
    var cornerRadius: CGFloat = DS.Radius.large
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(DS.Padding.card)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.clear)
            )
            .liquidGlass(.card, edgeMask: [.top])
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
