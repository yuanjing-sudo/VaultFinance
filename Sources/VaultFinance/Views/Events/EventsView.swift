import SwiftUI

// MARK: - Financial Events
// A calendar of money events: paychecks, bill due dates, goal deadlines,
// subscription renewals and custom reminders — all in one timeline.

struct EventsView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingAdd = false
    @State private var selectedMonth = Date()
    @State private var filter: FinancialEvent.EventType? = nil

    private var calendar: Calendar { Calendar.current }

    private var filtered: [FinancialEvent] {
        storage.financialEvents
            .filter { filter == nil || $0.type == filter }
            .sorted { $0.date < $1.date }
    }

    private var monthEvents: [FinancialEvent] {
        filtered.filter { calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
    }

    private var income: Double {
        monthEvents.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var outflow: Double {
        monthEvents.filter { $0.type != .income }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                monthCard
                filterRow
                if monthEvents.isEmpty {
                    VaultEmptyState(icon: "calendar.badge.exclamationmark",
                                    title: "Nothing scheduled",
                                    message: "Add an event to see it on your money calendar.",
                                    actionTitle: "Add Event") { showingAdd = true }
                } else {
                    ForEach(groupedByDay) { group in
                        daySection(group)
                    }
                }
                comingUpCard
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Money Calendar")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddEventSheet { event in
                storage.financialEvents.append(event)
                storage.save()
            }
        }
    }

    private var monthCard: some View {
        VaultGradientCard(gradient: VaultTheme.sunsetGradient) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button {
                        shiftMonth(-1)
                    } label: { Image(systemName: "chevron.left").foregroundColor(.white) }
                    Spacer()
                    Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.headline).bold()
                    Spacer()
                    Button {
                        shiftMonth(1)
                    } label: { Image(systemName: "chevron.right").foregroundColor(.white) }
                }
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Income").font(.caption2).opacity(0.9)
                        Text(Money(amount: income).formatted()).font(.subheadline).bold()
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Outflow").font(.caption2).opacity(0.9)
                        Text(Money(amount: outflow).formatted()).font(.subheadline).bold()
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Net").font(.caption2).opacity(0.9)
                        Text(Money(amount: income - outflow).formatted()).font(.subheadline).bold()
                    }
                }
            }
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(nil, "All")
                ForEach(FinancialEvent.EventType.allCases, id: \.self) { type in
                    filterChip(type, type.rawValue)
                }
            }
        }
    }

    private func filterChip(_ type: FinancialEvent.EventType?, _ label: String) -> some View {
        let selected = filter == type
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { filter = type }
        } label: {
            HStack(spacing: 4) {
                if let type {
                    Image(systemName: type.icon).font(.caption2)
                }
                Text(label).font(.caption2).bold()
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Capsule().fill(selected
                                       ? (type.map { VaultTheme.tint(for: $0.color) } ?? VaultTheme.blue)
                                       : Color.gray.opacity(0.14)))
            .foregroundColor(selected ? .white : .secondary)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var groupedByDay: [EventDayGroup] {
        let groups = Dictionary(grouping: monthEvents) {
            calendar.startOfDay(for: $0.date)
        }
        return groups.map { key, value in
            EventDayGroup(day: key, events: value.sorted { $0.date < $1.date })
        }
        .sorted { $0.day < $1.day }
    }

    private func daySection(_ group: EventDayGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(group.day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.caption).bold().foregroundColor(.secondary)
                if calendar.isDateInToday(group.day) {
                    VaultPill(text: "Today", color: VaultTheme.green)
                }
                Spacer()
            }
            ForEach(group.events) { event in
                EventRow(event: event) {
                    storage.financialEvents.removeAll { $0.id == event.id }
                    storage.save()
                }
            }
        }
    }

    private var comingUpCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 8) {
                VaultSectionHeader(title: "Next 7 Days")
                let soon = filtered.filter {
                    $0.date >= Date() && $0.date < Date().addingTimeInterval(86400 * 7)
                }
                if soon.isEmpty {
                    Text("No events this week.").font(.caption).foregroundColor(.secondary)
                } else {
                    ForEach(soon) { event in
                        HStack(spacing: 8) {
                            Image(systemName: event.type.icon)
                                .foregroundColor(VaultTheme.tint(for: event.type.color))
                                .font(.caption)
                            Text(event.title).font(.caption)
                            Spacer()
                            Text(event.date.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func shiftMonth(_ delta: Int) {
        if let newDate = calendar.date(byAdding: .month, value: delta, to: selectedMonth) {
            withAnimation { selectedMonth = newDate }
        }
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: FinancialEvent
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(VaultTheme.tint(for: event.type.color).opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: event.type.icon)
                    .font(.caption)
                    .foregroundColor(VaultTheme.tint(for: event.type.color))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title).font(.subheadline).bold()
                Text(event.type.rawValue).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            if event.amount > 0 {
                Text("\(event.type == .income ? "+" : "-")\(Money(amount: event.amount).formatted())")
                    .font(.caption).bold()
                    .foregroundColor(event.type == .income ? VaultTheme.green : .primary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.08)))
        .contextMenu {
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Event Sheet

struct AddEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (FinancialEvent) -> Void

    @State private var title = ""
    @State private var amount = ""
    @State private var type: FinancialEvent.EventType = .custom
    @State private var date = Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $type) {
                        ForEach(FinancialEvent.EventType.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    TextField("Amount (optional)", text: $amount)
                        .keyboardType(.decimalPad)
                }
                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                Section("Notes") {
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle("New Event")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(FinancialEvent(title: title.isEmpty ? "Event" : title,
                                              date: date,
                                              amount: Double(amount) ?? 0,
                                              type: type,
                                              notes: notes))
                        dismiss()
                    }
                    .bold()
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct EventDayGroup: Identifiable {
    var id: Date { day }
    var day: Date
    var events: [FinancialEvent]
}
