import SwiftUI

// MARK: - Deep Breadcrumb Navigation

/// Horizontal breadcrumb trail. Tapping a crumb navigates back to that level.
struct BreadcrumbsView: View {
    let items: [BreadcrumbItem]
    let onSelect: (Int) -> Void
    let router: AppRouter

    var body: some View {
        if items.count <= 1 { return AnyView(EmptyView()) }

        return AnyView(
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        BreadcrumbChip(item: item, isCurrent: index == items.count - 1) {
                            router.navigateToBreadcrumb(at: index)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal)
            }
            .frame(height: 34)
            .background(Color(white: 0.97))
        )
    }
}

struct BreadcrumbChip: View {
    let item: BreadcrumbItem
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.caption2)
                Text(item.label)
                    .font(.caption)
                    .bold(isCurrent)
            }
            .foregroundColor(isCurrent ? .blue : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isCurrent ? Color.blue.opacity(0.1) : Color.gray.opacity(0.12))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
