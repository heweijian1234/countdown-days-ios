import SwiftUI

// 主页：事件列表 + 添加（中文 UI——2026-11-07 健哥令：两 App 改中文给健哥真机测试）
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
                        Text("记住重要的日子")
                            .font(.headline)
                        Text("纪念日、生日、旅行——在桌面小组件上一目了然。")
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
            .navigationTitle("倒数日")
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
                Text(event.date.formatted(.dateTime.year().month().day()) + (event.repeatsYearly ? " · 每年循环" : ""))
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(abs(event.daysUntil))")
                    .font(.title2.bold())
                    .foregroundColor(.pink)
                Text(event.daysUntil >= 0 ? "天后" : "天前")
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
                Section("你在倒数哪个日子？") {
                    TextField("纪念日、生日、旅行…", text: $title)
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                    Toggle("每年循环", isOn: $repeats)
                }
                Section("图标") {
                    Picker("图标", selection: $emoji) {
                        ForEach(EventStore.emojiOptions, id: \.self) { e in
                            Text(e).tag(e)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section("桌面小组件") {
                    Text("保存后，长按桌面 → ＋ → 搜索「倒数小组件」。")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("新建倒数")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { onSave(nil) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let ev = CountdownEvent(id: UUID(), title: title.isEmpty ? "重要的日子" : title,
                                                date: date, repeatsYearly: repeats, emoji: emoji)
                        onSave(ev)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
