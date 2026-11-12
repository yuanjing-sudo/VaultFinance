import SwiftUI

// MARK: - Money Lab Shared UI

struct LabHeroCard: View {
    var eyebrow: String
    var title: String
    var subtitle: String
    var icon: String
    var gradient: LinearGradient = VaultTheme.brandGradient

    var body: some View {
        VaultGradientCard(gradient: gradient) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(eyebrow.uppercased())
                        .font(.caption2).fontWeight(.bold)
                        .opacity(0.8)
                    Text(title)
                        .font(.title2).bold()
                    Text(subtitle)
                        .font(.caption).opacity(0.9)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: icon)
                    .font(.system(size: 34, weight: .semibold))
                    .opacity(0.85)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

struct LabLinkRow<Destination: View>: View {
    var title: String
    var subtitle: String
    var icon: String
    var tint: Color
    var badge: String? = nil
    @ViewBuilder var destination: () -> Destination

    init(title: String, subtitle: String, icon: String, tint: Color, badge: String? = nil,
         @ViewBuilder destination: @escaping () -> Destination) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
        self.badge = badge
        self.destination = destination
    }

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.14))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline).bold()
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 4)
                if let badge {
                    Text(badge)
                        .font(.caption2).bold()
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(tint.opacity(0.14))
                        .foregroundColor(tint)
                        .cornerRadius(7)
                }
                Image(systemName: "chevron.right")
                    .font(.caption2).foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color.gray.opacity(0.08))
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct LabStat: View {
    var label: String
    var value: String
    var icon: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.caption2)
                Text(label).font(.caption2)
            }
            .foregroundColor(tint)
            Text(value)
                .font(.headline).bold()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(tint.opacity(0.10))
        )
    }
}

struct LabSection<Content: View>: View {
    var title: String
    var subtitle: String? = nil
    var icon: String? = nil
    @ViewBuilder var content: () -> Content

    init(title: String, subtitle: String? = nil, icon: String? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption).foregroundColor(.secondary)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.headline)
                    if let subtitle {
                        Text(subtitle).font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
            content()
        }
    }
}

struct LabCallout: View {
    var icon: String
    var title: String
    var message: String
    var tint: Color = VaultTheme.blue

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(tint)
                .font(.subheadline)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption).bold()
                Text(message).font(.caption2).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(tint.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

struct LabProgressRow: View {
    var title: String
    var detail: String
    var progress: Double
    var tint: Color
    var trailing: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.subheadline).bold()
                    Text(detail).font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                Text(trailing).font(.caption).bold().foregroundColor(tint)
            }
            VaultProgressBar(progress: max(0, min(progress, 1)), height: 8,
                             gradient: LinearGradient(colors: [tint.opacity(0.7), tint],
                                                      startPoint: .leading, endPoint: .trailing))
        }
        .padding(.vertical, 3)
    }
}

struct LabSheetHeader: View {
    var title: String
    var subtitle: String? = nil
    var icon: String
    var tint: Color = VaultTheme.blue

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.headline)
                if let subtitle {
                    Text(subtitle).font(.caption2).foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }
}
