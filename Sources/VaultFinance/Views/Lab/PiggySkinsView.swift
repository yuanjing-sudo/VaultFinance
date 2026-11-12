import SwiftUI

// MARK: - Piggy Skins & Seasons

struct PiggySkinsView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var selectedSkin: PiggySkin?
    @State private var message = ""
    @State private var showingMessage = false
    @AppStorage("vault.piggySeason") private var seasonRaw = PiggySeason.spring.rawValue

    private var season: PiggySeason {
        PiggySeason(rawValue: seasonRaw) ?? .spring
    }

    private var available: [PiggySkin] {
        WealthLabEngine.availableSkins(depositCount: storage.piggyBank.depositCount)
    }

    private var preview: PiggySkin {
        selectedSkin ?? WealthLabEngine.piggySkins.first(where: { $0.hex == storage.piggyBank.colorTheme })
            ?? WealthLabEngine.piggySkins[0]
    }

    private var tint: Color { Color.hex(preview.hex) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                previewCard
                seasonCard
                skinsCard
                unlockProgress
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Piggy Skins")
        .inlineNavigationTitle()
        .alert("Piggy styles", isPresented: $showingMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message)
        }
    }

    private var previewCard: some View {
        VStack(spacing: 12) {
            AnimatedPiggyBank(progress: storage.piggyBank.progress,
                              themeColor: tint,
                              isBroken: storage.piggyBank.isBroken,
                              isCelebrating: storage.piggyBank.isFull)
                .frame(width: 240, height: 220)
                .accessibilityLabel("Piggy preview: \(preview.name), \(Int(storage.piggyBank.percentFull)) percent full")
            Text(preview.name).font(.title3).bold()
            Text("\(preview.personality.localized) personality · \(Int(storage.piggyBank.percentFull))% full")
                .font(.caption).foregroundColor(.secondary)
            VaultPrimaryButton(title: preview.hex == storage.piggyBank.colorTheme ? "Current skin" : "Apply this skin",
                               icon: "paintbrush.fill",
                               gradient: LinearGradient(colors: [tint, tint.opacity(0.7)],
                                                        startPoint: .leading, endPoint: .trailing)) {
                applySkin()
            }
            .disabled(preview.hex == storage.piggyBank.colorTheme)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(tint.opacity(0.10))
        )
    }

    private var seasonCard: some View {
        VaultCard(tint: Color.hex(season.tint)) {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Season", subtitle: "A little seasonal energy for the piggy pen")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(PiggySeason.allCases) { item in
                        Button {
                            seasonRaw = item.rawValue
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: item.icon).font(.caption2)
                                Text(item.rawValue).font(.caption2).bold()
                                Spacer()
                                if season == item {
                                    Image(systemName: "checkmark.circle.fill").font(.caption2)
                                }
                            }
                            .padding(9)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(season == item
                                          ? Color.hex(item.tint).opacity(0.20)
                                          : Color.gray.opacity(0.08))
                            )
                            .foregroundColor(Color.hex(item.tint))
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                Text("\(season.rawValue): the piggy is feeling \(season == .winter ? "cozy" : season == .summer ? "sunny" : season == .autumn ? "harvesty" : "fresh").")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    private var skinsCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 10) {
                VaultSectionHeader(title: "Skins",
                                   subtitle: "\(available.count) of \(WealthLabEngine.piggySkins.count) unlocked")
                ForEach(WealthLabEngine.piggySkins) { skin in
                    let unlocked = available.contains { $0.name == skin.name }
                    Button {
                        if unlocked {
                            selectedSkin = skin
                        } else {
                            message = "Make \(skin.requiredDeposits) deposits to unlock \(skin.name). You have \(storage.piggyBank.depositCount)."
                            showingMessage = true
                        }
                    } label: {
                        HStack(spacing: 11) {
                            Circle()
                                .fill(Color.hex(skin.hex))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Image(systemName: skin.personality.icon)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.9))
                                )
                            VStack(alignment: .leading, spacing: 1) {
                                Text(skin.name).font(.caption).bold().foregroundColor(.primary)
                                Text(unlocked ? skin.unlockHint : "🔒 \(skin.unlockHint)")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            if preview.name == skin.name {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(VaultTheme.green)
                            } else if !unlocked {
                                Image(systemName: "lock.fill").font(.caption2).foregroundColor(.secondary)
                            } else {
                                Image(systemName: "chevron.right").font(.caption2).foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var unlockProgress: some View {
        let next = WealthLabEngine.piggySkins.first { $0.requiredDeposits > storage.piggyBank.depositCount }
        return VaultCard(tint: VaultTheme.gold) {
            VStack(alignment: .leading, spacing: 8) {
                VaultSectionHeader(title: "Next unlock",
                                   subtitle: next.map { "\($0.name) at \($0.requiredDeposits) deposits" } ?? "Every skin unlocked — legend status")
                if let next {
                    VaultProgressBar(progress: Double(storage.piggyBank.depositCount) / Double(max(next.requiredDeposits, 1)),
                                     gradient: VaultTheme.goldGradient)
                    Text("\(storage.piggyBank.depositCount) / \(next.requiredDeposits) deposits")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
        }
    }

    private func applySkin() {
        storage.piggyBank.colorTheme = preview.hex
        storage.piggyBank.personality = preview.personality
        storage.save()
        message = "\(preview.name) applied. Your piggy has a new look."
        showingMessage = true
    }
}
