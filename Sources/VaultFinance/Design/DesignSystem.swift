import Foundation
import SwiftUI

// MARK: - VaultFinance Design System
// A shared visual language for the whole app: colors, gradients, cards,
// buttons, badges, and reusable chrome. All platform-safe (no UIKit types).

enum VaultTheme {
    // Core brand palette
    static let blue = Color(red: 0.23, green: 0.51, blue: 0.96)
    static let green = Color(red: 0.06, green: 0.72, blue: 0.51)
    static let orange = Color(red: 0.96, green: 0.62, blue: 0.04)
    static let red = Color(red: 0.94, green: 0.27, blue: 0.27)
    static let purple = Color(red: 0.55, green: 0.36, blue: 0.96)
    static let pink = Color(red: 0.93, green: 0.28, blue: 0.60)
    static let teal = Color(red: 0.08, green: 0.72, blue: 0.65)
    static let gold = Color(red: 0.98, green: 0.74, blue: 0.14)

    // Semantic
    static let positive = green
    static let negative = red
    static let warning = orange
    static let info = blue

    // Surfaces
    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.12) : Color(white: 0.97)
    }
    static func raised(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.17) : Color.white
    }
    static func subtle(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.22) : Color(white: 0.92)
    }

    // Gradients
    static var brandGradient: LinearGradient {
        LinearGradient(colors: [blue, purple], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var savingsGradient: LinearGradient {
        LinearGradient(colors: [green, teal], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var warningGradient: LinearGradient {
        LinearGradient(colors: [orange, red], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var goldGradient: LinearGradient {
        LinearGradient(colors: [gold, orange], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var sunsetGradient: LinearGradient {
        LinearGradient(colors: [pink, purple, blue], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var skyGradient: LinearGradient {
        LinearGradient(colors: [teal, blue], startPoint: .top, endPoint: .bottom)
    }

    static func tint(for key: String) -> Color {
        switch key {
        case "blue": return blue
        case "green": return green
        case "orange": return orange
        case "red": return red
        case "purple": return purple
        case "pink": return pink
        case "teal": return teal
        case "gold": return gold
        default: return blue
        }
    }
}

// MARK: - Hex Color Helper

extension Color {
    /// Create a Color from a hex string like "#3B82F6".
    static func hex(_ hex: String) -> Color {
        var sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if sanitized.count == 3 {
            sanitized = sanitized.map { "\($0)\($0)" }.joined()
        }
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Card Surface

struct VaultCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 18
    var tint: Color? = nil
    @ViewBuilder var content: () -> Content

    init(padding: CGFloat = 16, cornerRadius: CGFloat = 18, tint: Color? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(VaultTheme.raised(scheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke((tint ?? Color.gray).opacity(tint == nil ? 0.12 : 0.30), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(scheme == .dark ? 0.35 : 0.06), radius: 8, x: 0, y: 3)
            )
    }
}

struct VaultGradientCard<Content: View>: View {
    var gradient: LinearGradient = VaultTheme.brandGradient
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: () -> Content

    init(gradient: LinearGradient = VaultTheme.brandGradient,
         cornerRadius: CGFloat = 20,
         @ViewBuilder content: @escaping () -> Content) {
        self.gradient = gradient
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(gradient)
                    .shadow(color: VaultTheme.blue.opacity(0.3), radius: 12, x: 0, y: 6)
            )
            .foregroundColor(.white)
    }
}

// MARK: - Section Header

struct VaultSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).bold()
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle) { action() }
                    .font(.caption).fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Pill Badge

struct VaultPill: View {
    let text: String
    var icon: String? = nil
    var color: Color = VaultTheme.blue
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(.caption2)
            }
            Text(text).font(.caption2).fontWeight(.semibold)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(filled ? color : color.opacity(0.14))
        .foregroundColor(filled ? .white : color)
        .cornerRadius(9)
    }
}

// MARK: - Stat Tile

struct VaultStatTile: View {
    let title: String
    let value: String
    var icon: String = "chart.bar.fill"
    var color: Color = VaultTheme.blue
    var delta: String? = nil
    var deltaPositive: Bool = true

    var body: some View {
        VaultCard(padding: 12, cornerRadius: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                    Spacer()
                    if let delta {
                        Text(delta)
                            .font(.caption2).bold()
                            .foregroundColor(deltaPositive ? VaultTheme.positive : VaultTheme.negative)
                    }
                }
                Text(value).font(.title3).bold().lineLimit(1).minimumScaleFactor(0.7)
                Text(title).font(.caption2).foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Primary Button

struct VaultPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var gradient: LinearGradient = VaultTheme.brandGradient
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(gradient)
            )
            .foregroundColor(.white)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct VaultSecondaryButton: View {
    let title: String
    var icon: String? = nil
    var tint: Color = VaultTheme.blue
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tint.opacity(0.14))
            )
            .foregroundColor(tint)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Press Animation

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Progress Ring

struct VaultProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 8
    var tint: Color = VaultTheme.green
    var track: Color = Color.gray.opacity(0.18)

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(
                    AngularGradient(colors: [tint.opacity(0.7), tint], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)
        }
    }
}

// MARK: - Progress Bar

struct VaultProgressBar: View {
    var progress: Double
    var height: CGFloat = 10
    var gradient: LinearGradient = VaultTheme.brandGradient
    var track: Color = Color.gray.opacity(0.18)

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(gradient)
                    .frame(width: max(0, min(geo.size.width * progress, geo.size.width)))
                    .animation(.easeInOut(duration: 0.7), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Shimmer

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    func body(content: Content) -> some View {
        content.overlay(
            LinearGradient(
                colors: [.clear, Color.white.opacity(0.35), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .offset(x: phase * 320)
            .blendMode(.overlay)
            .onAppear {
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
        )
        .clipped()
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

// MARK: - Empty State

struct VaultEmptyState: View {
    let icon: String
    let title: String
    var message: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 42))
                .foregroundColor(.secondary.opacity(0.7))
            Text(title).font(.headline)
            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            if let actionTitle, let action {
                Button(actionTitle) { action() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

// MARK: - Divider with label

struct VaultLabeledDivider: View {
    let text: String
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
            Text(text).font(.caption2).foregroundColor(.secondary)
            Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
        }
    }
}
