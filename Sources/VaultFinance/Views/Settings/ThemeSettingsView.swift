import SwiftUI

// MARK: - Appearance & Preferences
// Personalize the vault: accent color, motion, haptics, currency.

struct ThemeSettingsView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var settings: AppThemeSettings

    init() {
        _settings = State(initialValue: LocalStorage.shared.themeSettings)
    }

    private let accents: [(name: String, key: String)] = [
        ("Blue", "blue"), ("Green", "green"), ("Orange", "orange"),
        ("Purple", "purple"), ("Pink", "pink"), ("Teal", "teal"),
        ("Gold", "gold")
    ]

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "INR", "CNY"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VaultGradientCard(gradient: LinearGradient(
                    colors: [VaultTheme.tint(for: settings.accent), VaultTheme.purple],
                    startPoint: .topLeading, endPoint: .bottomTrailing)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Appearance").font(.caption).opacity(0.9)
                            Text("Make it yours").font(.title3).bold()
                        }
                        Spacer()
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 30)).foregroundColor(.white.opacity(0.9))
                    }
                }

                VaultCard {
                    VStack(alignment: .leading, spacing: 12) {
                        VaultSectionHeader(title: "Accent Color")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 12)], spacing: 12) {
                            ForEach(accents.indices, id: \.self) { i in
                                let accent = accents[i]
                                Button {
                                    settings.accent = accent.key
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(VaultTheme.tint(for: accent.key))
                                            .frame(width: 40, height: 40)
                                        if settings.accent == accent.key {
                                            Image(systemName: "checkmark")
                                                .font(.caption).bold()
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                        }
                    }
                }

                VaultCard {
                    VStack(alignment: .leading, spacing: 12) {
                        VaultSectionHeader(title: "Motion & Feedback")
                        Toggle("Show confetti celebrations", isOn: $settings.showConfetti)
                        Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
                        Toggle("Gradient cards", isOn: $settings.useGradients)
                    }
                }

                VaultCard {
                    VStack(alignment: .leading, spacing: 10) {
                        VaultSectionHeader(title: "Currency")
                        Picker("Display currency", selection: $settings.currency) {
                            ForEach(currencies, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                    }
                }

                VaultPrimaryButton(title: "Save Preferences", icon: "checkmark.circle.fill") {
                    storage.themeSettings = settings
                    storage.save()
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Appearance")
        .inlineNavigationTitle()
    }
}
