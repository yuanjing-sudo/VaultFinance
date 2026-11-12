import SwiftUI

// MARK: - Accessibility & Delight

struct AccessibilitySettingsView: View {
    @AppStorage("vault.reduceMotion") private var reduceMotion = false
    @AppStorage("vault.highContrast") private var highContrast = false
    @AppStorage("vault.haptics") private var haptics = true
    @AppStorage("vault.sounds") private var sounds = true
    @AppStorage("vault.largeText") private var largeText = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LabHeroCard(
                    eyebrow: "Accessibility & Delight",
                    title: "Comfortable for every brain",
                    subtitle: "Tune motion, contrast, feedback and text so the app fits the way you use it.",
                    icon: "accessibility",
                    gradient: VaultTheme.tealGradient
                )

                VaultCard {
                    VStack(alignment: .leading, spacing: 12) {
                        VaultSectionHeader(title: "Motion & contrast",
                                           subtitle: "Applies to the animated piggy and previews")
                        toggleRow("Reduce motion", detail: "Calm animations and no bouncing coins.",
                                  icon: "figure.walk.motion", isOn: $reduceMotion)
                        Divider()
                        toggleRow("High contrast", detail: "Stronger borders in the preview and charts.",
                                  icon: "circle.lefthalf.filled", isOn: $highContrast)
                        Divider()
                        toggleRow("Larger reading text", detail: "Prefer the system's larger text sizes.",
                                  icon: "textformat.size", isOn: $largeText)
                    }
                }

                VaultCard(tint: VaultTheme.pink) {
                    VStack(alignment: .leading, spacing: 12) {
                        VaultSectionHeader(title: "Feedback",
                                           subtitle: "Haptics are optional and never required")
                        toggleRow("Haptic feedback", detail: "A gentle tap on successful savings actions.",
                                  icon: "hand.tap.fill", isOn: $haptics)
                        Divider()
                        toggleRow("Soft sounds", detail: "A quiet chime when feeding the piggy.",
                                  icon: "speaker.wave.2.fill", isOn: $sounds)
                        HStack {
                            Button("Preview tap") { FeedbackService.success() }
                                .font(.caption2).bold()
                            Spacer()
                            Text(haptics ? "Haptics on" : "Haptics off")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }

                previewCard

                VaultCard {
                    VStack(alignment: .leading, spacing: 9) {
                        VaultSectionHeader(title: "Built-in accessibility")
                        accessibilityRow(icon: "textformat", title: "Dynamic Type",
                                         detail: "Text uses system styles and scales with your settings.")
                        accessibilityRow(icon: "waveform", title: "VoiceOver labels",
                                         detail: "The piggy, gauges and progress rows expose descriptive labels.")
                        accessibilityRow(icon: "hand.raised.fill", title: "No color-only meaning",
                                         detail: "Badges pair color with icons and words.")
                        accessibilityRow(icon: "figure.roll", title: "Large tap targets",
                                         detail: "Primary actions use full-width buttons and generous spacing.")
                    }
                }

                Text("System-wide settings such as VoiceOver, Reduce Motion and Bold Text are respected by the platform. These app preferences add extra control on top.")
                    .font(.caption2).foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Accessibility")
        .inlineNavigationTitle()
        .onChange(of: reduceMotion) { _, _ in FeedbackService.tap() }
    }

    private var previewCard: some View {
        VStack(spacing: 10) {
            Text("Preview").font(.caption).bold().foregroundColor(.secondary)
            HStack(spacing: 14) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 34))
                    .foregroundColor(VaultTheme.orange)
                    .padding(14)
                    .background(
                        Circle().fill(VaultTheme.orange.opacity(highContrast ? 0.28 : 0.12))
                    )
                    .overlay(
                        Circle().stroke(VaultTheme.orange.opacity(highContrast ? 0.8 : 0.2),
                                        lineWidth: highContrast ? 2 : 1)
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vault Piggy").font(largeText ? .title3 : .headline).bold()
                    Text("Motion: \(reduceMotion ? "calm" : "lively") · Contrast: \(highContrast ? "high" : "standard")")
                        .font(largeText ? .caption : .caption2)
                        .foregroundColor(.secondary)
                    VaultProgressBar(progress: 0.64, height: 8,
                                     gradient: highContrast ? VaultTheme.brandGradient : VaultTheme.savingsGradient)
                        .frame(width: 150)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(highContrast ? 0.14 : 0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(highContrast ? Color.primary.opacity(0.25) : Color.clear, lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func toggleRow(_ title: String, detail: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(VaultTheme.teal)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).bold()
                Text(detail).font(.caption2).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(VaultTheme.teal)
        }
    }

    private func accessibilityRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon).font(.caption).foregroundColor(VaultTheme.blue).frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.caption).bold()
                Text(detail).font(.caption2).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
