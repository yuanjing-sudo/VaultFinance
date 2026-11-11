import SwiftUI

// MARK: - Reminders
// Lightweight money reminders with repeat rules and enable/disable toggles.

struct RemindersView: View {
    @EnvironmentObject var storage: LocalStorage
    @State private var showingAdd = false

    private var items: [Reminder] {
        storage.reminders.sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VaultCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Reminders").font(.headline).bold()
                            Text("\(items.filter { $0.isEnabled }.count) active")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button {
                            showingAdd = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(VaultTheme.blue)
                        }
                    }
                }

                if items.isEmpty {
                    VaultEmptyState(icon: "bell.slash", title: "No reminders",
                                    message: "Add a reminder to stay on top of your money.",
                                    actionTitle: "Add Reminder") { showingAdd = true }
                } else {
                    ForEach(items) { reminder in
                        ReminderRow(reminder: reminder) {
                            toggle(reminder)
                        } onDelete: {
                            storage.reminders.removeAll { $0.id == reminder.id }
                            storage.save()
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("Reminders")
        .inlineNavigationTitle()
        .sheet(isPresented: $showingAdd) {
            AddReminderSheet { reminder in
                storage.reminders.append(reminder)
                storage.save()
            }
        }
    }

    private func toggle(_ reminder: Reminder) {
        guard let i = storage.reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        storage.reminders[i].isEnabled.toggle()
        storage.save()
    }
}

struct ReminderRow: View {
    let reminder: Reminder
    var onToggle: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(VaultTheme.orange.opacity(0.14)).frame(width: 38, height: 38)
                Image(systemName: "bell.fill")
                    .font(.caption).foregroundColor(VaultTheme.orange)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title).font(.subheadline).bold()
                Text("\(reminder.date.formatted(.dateTime.month(.abbreviated).day().hour().minute())) · \(reminder.repeatRule.localized)")
                    .font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(get: { reminder.isEnabled }, set: { _ in onToggle() }))
                .labelsHidden()
                .scaleEffect(0.8)
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

struct AddReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (Reminder) -> Void

    @State private var title = ""
    @State private var date = Date().addingTimeInterval(3600)
    @State private var rule: Reminder.RepeatRule = .none

    var body: some View {
        NavigationStack {
            Form {
                TextField("Reminder", text: $title)
                DatePicker("When", selection: $date,
                           displayedComponents: [.date, .hourAndMinute])
                Picker("Repeat", selection: $rule) {
                    ForEach(Reminder.RepeatRule.allCases, id: \.self) {
                        Text($0.localized).tag($0)
                    }
                }
            }
            .navigationTitle("New Reminder")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(Reminder(title: title.isEmpty ? "Reminder" : title,
                                        date: date, repeatRule: rule))
                        dismiss()
                    }
                    .bold()
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
