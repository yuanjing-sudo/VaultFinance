import SwiftUI

// MARK: - Piggy Bank View

/// The star feature: a piggy bank that grows fatter as the user deposits savings.
/// Displays fullness level, progress, deposit history, and allows deposits.
struct PiggyBankView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var piggy: PiggyBank
    @State private var deposits: [PiggyDeposit]
    @State private var showingDeposit = false
    @State private var showingEdit = false

    init() {
        _piggy = State(initialValue: LocalStorage.shared.piggyBank)
        _deposits = State(initialValue: LocalStorage.shared.piggyDeposits)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Piggy header
                piggyHeader

                // Visual piggy (grows fatter)
                piggyVisual

                // Progress bar
                progressSection

                // Stats row
                statsRow

                // Actions
                actionButtons

                // Deposit history
                depositHistorySection
            }
            .padding()
        }
        .navigationTitle("Piggy Bank")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingEdit = true }) {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingDeposit) {
            PiggyDepositView(piggy: $piggy, deposits: $deposits)
        }
        .sheet(isPresented: $showingEdit) {
            EditPiggyView(piggy: $piggy)
        }
        .onChange(of: piggy) { _, newValue in
            storage.piggyBank = newValue
            storage.save()
        }
        .onChange(of: deposits) { _, newValue in
            storage.piggyDeposits = newValue
            storage.save()
        }
    }

    // MARK: - Subviews

    private var piggyHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text(piggy.name)
                    .font(.title2).bold()
                Spacer()
                Text(piggy.levelEmoji)
                    .font(.largeTitle)
            }
            Text(piggy.levelDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }

    private var piggyVisual: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background "bubble"
                Circle()
                    .fill(Color.piggyColor(piggy.colorTheme).opacity(0.15))
                    .frame(width: 220, height: 220)

                // The piggy - scales with fatness
                Text(piggy.levelEmoji)
                    .font(.system(size: piggySize))
                    .scaleEffect(piggy.fatnessScale)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: piggy.fatnessScale)
            }

            Text("\(piggy.level.rawValue) — \(piggy.levelDescription)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var piggySize: CGFloat {
        // Base size scaled by fatness
        let base: CGFloat = 90
        return base * CGFloat(piggy.fatnessScale)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Savings Progress").font(.headline).bold()
                Spacer()
                Text("\(piggy.percentFull, specifier: "%.0f")%")
                    .font(.headline).bold()
                    .foregroundColor(Color.piggyColor(piggy.colorTheme))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 14)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.piggyColor(piggy.colorTheme))
                        .frame(width: min(geo.size.width * piggy.progress, geo.size.width), height: 14)
                        .animation(.easeInOut(duration: 0.6), value: piggy.progress)
                }
            }
            .frame(height: 14)
            HStack {
                Text(Money(amount: piggy.depositedAmount, currency: piggy.currency).formatted())
                    .font(.subheadline).bold()
                Spacer()
                Text("of \(Money(amount: piggy.targetAmount, currency: piggy.currency).formatted())")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            if piggy.isFull {
                Text("🎉 Goal reached! The piggy is full!")
                    .font(.caption).bold().foregroundColor(.green)
            } else {
                Text("\(Money(amount: piggy.remaining, currency: piggy.currency).formatted()) to go")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            PiggyStatCard(title: "Deposits", value: "\(piggy.depositCount)", icon: "plus.circle.fill", color: .blue)
            PiggyStatCard(title: "Deposited", value: Money(amount: piggy.depositedAmount).formatted(), icon: "banknote.fill", color: .green)
            PiggyStatCard(title: "Remaining", value: Money(amount: piggy.remaining).formatted(), icon: "minus.circle.fill", color: .orange)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: { showingDeposit = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Deposit")
                }
                .font(.headline).bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.piggyColor(piggy.colorTheme))
                .foregroundColor(.white)
                .cornerRadius(14)
            }

            if piggy.isFull && !piggy.isBroken {
                Button(action: breakPiggy) {
                    HStack {
                        Image(systemName: "hammer.fill")
                        Text("Break Piggy")
                    }
                    .font(.headline).bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
            }

            if piggy.isBroken {
                Button(action: resetPiggy) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .font(.headline).bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
            }
        }
    }

    private var depositHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Deposit History").font(.headline).bold()
                Spacer()
            }
            if deposits.isEmpty {
                EmptyState(message: "No deposits yet. Feed your piggy!")
            } else {
                ForEach(deposits.sorted { $0.date > $1.date }, id: \.id) { deposit in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(deposit.note.isEmpty ? deposit.source.localized : deposit.note)
                                .font(.subheadline)
                                .bold()
                            Text(deposit.date, style: .relative)
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("+\(Money(amount: deposit.amount, currency: piggy.currency).formatted())")
                            .font(.subheadline).bold().foregroundColor(.green)
                    }
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Actions

    private func breakPiggy() {
        piggy.isBroken = true
        piggy.breakDate = Date()
        // Add the broken piggy funds back to savings
        storage.profile.existingSavings += piggy.depositedAmount
        storage.save()
    }

    private func resetPiggy() {
        piggy = PiggyBank(name: piggy.name, targetAmount: piggy.targetAmount, currency: piggy.currency,
                          personality: piggy.personality, colorTheme: piggy.colorTheme)
        deposits = []
        storage.save()
    }
}

// MARK: - Piggy Stat Card

struct PiggyStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value).font(.subheadline).bold()
            Text(title).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Deposit Sheet

struct PiggyDepositView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var piggy: PiggyBank
    @Binding var deposits: [PiggyDeposit]
    @EnvironmentObject var storage: LocalStorage

    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var source: PiggyDeposit.DepositSource = .manual

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Feed the Piggy")) {
                    HStack {
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                        Text(piggy.currency).font(.caption).foregroundColor(.secondary)
                    }
                    Picker("Source", selection: $source) {
                        ForEach(PiggyDeposit.DepositSource.allCases, id: \.self) { s in
                            Text(s.localized).tag(s)
                        }
                    }
                    TextField("Note (optional)", text: $note)
                }
                Section {
                    Button("Deposit") {
                        makeDeposit()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Deposit")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func makeDeposit() {
        guard let amt = Double(amount), amt > 0 else { return }
        piggy.depositedAmount += amt
        piggy.depositCount += 1
        piggy.lastDepositDate = Date()
        let deposit = PiggyDeposit(piggyId: piggy.id, amount: amt, note: note, source: source)
        deposits.append(deposit)

        // Also record as a spending day entry (negative spending = saving)
        storage.recordSpending(date: Date(), amount: -amt, category: .savings, notes: note)
    }
}

// MARK: - Edit Piggy

struct EditPiggyView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var piggy: PiggyBank

    @State private var name: String
    @State private var targetAmount: String
    @State private var personality: PiggyPersonality
    @State private var colorTheme: String

    init(piggy: Binding<PiggyBank>) {
        self._piggy = piggy
        _name = State(initialValue: piggy.wrappedValue.name)
        _targetAmount = State(initialValue: String(piggy.wrappedValue.targetAmount))
        _personality = State(initialValue: piggy.wrappedValue.personality)
        _colorTheme = State(initialValue: piggy.wrappedValue.colorTheme)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Piggy Details")) {
                    TextField("Name", text: $name)
                    TextField("Target Amount", text: $targetAmount)
                        .keyboardType(.decimalPad)
                    Picker("Personality", selection: $personality) {
                        ForEach(PiggyPersonality.allCases, id: \.self) { p in
                            HStack {
                                Image(systemName: p.icon)
                                Text(p.localized)
                            }
                            .tag(p)
                        }
                    }
                    Picker("Color", selection: $colorTheme) {
                        Text("Orange").tag("#F5A623")
                        Text("Blue").tag("#3B82F6")
                        Text("Green").tag("#10B981")
                        Text("Purple").tag("#8B5CF6")
                        Text("Pink").tag("#EC4899")
                        Text("Gold").tag("#FBBF24")
                    }
                }
                Section {
                    Button("Save") {
                        piggy.name = name
                        piggy.targetAmount = Double(targetAmount) ?? piggy.targetAmount
                        piggy.personality = personality
                        piggy.colorTheme = colorTheme
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Edit Piggy")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Color helper

extension Color {
    static func piggyColor(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hexSanitized.hasPrefix("#") { hexSanitized = String(hexSanitized.dropFirst()) }
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}
