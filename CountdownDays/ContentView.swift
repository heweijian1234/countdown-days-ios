import SwiftUI

// 主页：事件列表 + 添加（英文上架版——小组件无中文测试期，直接英文：健哥不深度测试此 App，走 G/H 教训直接英文省一轮）
struct ContentView: View {
    @State private var events: [CountdownEvent] = EventStore.load()
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if events.isEmpty {
                    VStack(spacing: 14) {
                        Spacer()
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 52))
                            .foregroundColor(.pink)
                        Text("Count the days that matter")
                            .font(.headline)
                        Text("Anniversaries, birthdays, trips — see them on your Home Screen widget.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(events) { ev in
                            EventRow(event: ev)
                        }
                        .onDelete { indexSet in
                            events.remove(atOffsets: indexSet)
                            EventStore.save(events)
                        }
                    }
                }
            }
            .navigationTitle("Countdown Days")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: { events = EventStore.load() }) {
                EventEditor { new in
                    if let new {
                        events.append(new)
                        EventStore.save(events)
                    }
                    showAdd = false
                }
            }
        }
    }
}

struct EventRow: View {
    let event: CountdownEvent

    var body: some View {
        HStack(spacing: 14) {
            Text(event.emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.pink.opacity(0.12)))
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title).font(.subheadline.weight(.semibold))
                Text(event.date.formatted(.dateTime.year().month().day()) + (event.repeatsYearly ? " · every year" : ""))
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(abs(event.daysUntil))")
                    .font(.title2.bold())
                    .foregroundColor(.pink)
                Text(event.daysUntil >= 0 ? "days left" : "days ago")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}

struct EventEditor: View {
    var onSave: (CountdownEvent?) -> Void

    @State private var title = ""
    @State private var date = Date()
    @State private var repeats = true
    @State private var emoji = "❤️"

    var body: some View {
        NavigationStack {
            Form {
                Section("What are you counting down to?") {
                    TextField("Anniversary, birthday, trip…", text: $title)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Toggle("Repeats every year", isOn: $repeats)
                }
                Section("Icon") {
                    Picker("Icon", selection: $emoji) {
                        ForEach(EventStore.emojiOptions, id: \.self) { e in
                            Text(e).tag(e)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section("Home Screen widget") {
                    Text("After saving, touch and hold your Home Screen → ＋ → Countdown Widget.")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("New countdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onSave(nil) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let ev = CountdownEvent(id: UUID(), title: title.isEmpty ? "Special day" : title,
                                                date: date, repeatsYearly: repeats, emoji: emoji)
                        onSave(ev)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
