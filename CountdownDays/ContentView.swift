import SwiftUI
import UserNotifications

// 主页：事件列表 + 添加（中文 UI v2——健哥第四轮4条：
// ①海外节日 ②准备清单 ③闹钟 ④事件可点进去改）

struct ContentView: View {
    @State private var events: [CountdownEvent] = EventStore.load()
    @State private var editingEvent: CountdownEvent?     // 健哥令④：点进去编辑
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
                        Text("纪念日、生日、节日、旅行——桌面小组件一目了然，还能提前提醒你准备。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(events) { ev in
                            // 健哥令④：整行可点，进编辑页
                            Button {
                                editingEvent = ev
                            } label: {
                                EventRow(event: ev)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { indexSet in
                            for i in indexSet {
                                EventReminder.cancel(eventId: events[i].id)
                            }
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
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: { events = EventStore.load() }) {
                EventEditor(existing: nil) { _ in
                    events = EventStore.load()
                }
            }
            // 健哥令④：点已有事件→编辑器带原值
            .sheet(item: $editingEvent, onDismiss: { events = EventStore.load() }) { ev in
                EventEditor(existing: ev) { _ in
                    events = EventStore.load()
                }
            }
            .onAppear {
                // 闹钟权限（健哥令③）
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
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
                HStack(spacing: 5) {
                    Text(event.title).font(.subheadline.weight(.semibold))
                    // 节日标（健哥令①）
                    if !event.holidayName.isEmpty {
                        Text(event.holidayName)
                            .font(.caption2)
                            .foregroundColor(.pink)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.pink.opacity(0.1)))
                    }
                }
                Text(event.date.formatted(.dateTime.year().month().day()) + (event.repeatsYearly ? " · 每年循环" : ""))
                    .font(.caption).foregroundColor(.secondary)
                // 准备清单（健哥令②）+ 闹钟（③）
                if !event.notes.isEmpty {
                    Text("已准备：\(event.notes)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if !event.remindDaysBefore.isEmpty {
                    let labels = event.remindDaysBefore.sorted().map { CountdownEvent.remindLabel($0) }.joined(separator: "、")
                    Label(labels + "提醒", systemImage: "bell.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(abs(event.daysUntil))")
                    .font(.title2.bold())
                    .foregroundColor(.pink)
                Text(event.daysUntil >= 0 ? "天后" : "天前")
                    .font(.caption2).foregroundColor(.secondary)
            }
            // 编辑箭头提示（健哥令④）
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.vertical, 3)
    }
}

struct EventEditor: View {
    let existing: CountdownEvent?   // 健哥令④：nil=新建
    var onSave: (CountdownEvent?) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var repeats = false
    @State private var emoji = "❤️"
    @State private var notes = ""
    @State private var holiday = ""           // 空字符串=无节日
    @State private var remindSelections: [Int] = []
    @State private var autoGuessDone = false

    var body: some View {
        NavigationStack {
            Form {
                Section("你在倒数哪个日子？") {
                    TextField("纪念日、生日、节日、旅行…", text: $title)
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                        .onChange(of: date) { newDate in
                            // 健哥令①：选日期自动猜节日（只在新建设置一次，不覆盖手动选择）
                            if !autoGuessDone, existing == nil, let g = Holidays.guess(date: newDate) {
                                holiday = g.0
                                emoji = g.1
                                autoGuessDone = true
                            }
                        }
                    Toggle("每年循环", isOn: $repeats)
                }
                // 节日（健哥令①：仪式感）
                Section("节日关联（可选）") {
                    Picker("节日", selection: $holiday) {
                        Text("不关联节日").tag("")
                        ForEach(Holidays.allOptions, id: \.0) { name, e in
                            Text("\(e) \(name)").tag(name)
                        }
                    }
                    .onChange(of: holiday) { h in
                        // 选节日自动换 emoji
                        if let opt = Holidays.allOptions.first(where: { $0.0 == h }) {
                            emoji = opt.1
                        }
                    }
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
                // 准备清单（健哥令②）
                Section("准备清单（可选）") {
                    TextField("准备了什么？（订蛋糕/买礼物/订机票…）", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                // 闹钟（健哥令③：最多3个，1天/3天/7天/14天/1个月/2个月）
                Section {
                    ForEach(remindSelections.indices, id: \.self) { idx in
                        Picker("闹钟 \(idx + 1)", selection: $remindSelections[idx]) {
                            ForEach(CountdownEvent.remindOptions, id: \.self) { d in
                                Text(CountdownEvent.remindLabel(d)).tag(d)
                            }
                        }
                    }
                    if remindSelections.count < 3 {
                        Button {
                            remindSelections.append(7)
                        } label: {
                            Label("加一个闹钟", systemImage: "plus.circle")
                        }
                    }
                    if !remindSelections.isEmpty {
                        Button(role: .destructive) {
                            remindSelections = []
                        } label: {
                            Label("全部清除", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("提醒（闹钟，最多3个）")
                } footer: {
                    Text("到点当天早上9点系统通知你。最多设3个，如：提前1个月看机票 + 提前1周订蛋糕。")
                }
                Section("桌面小组件") {
                    Text("保存后，长按桌面 → ＋ → 搜索「倒数小组件」。")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle(existing == nil ? "新建倒数" : "编辑倒数")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let ev = existing else { return }
        title = ev.title
        date = ev.date
        repeats = ev.repeatsYearly
        emoji = ev.emoji
        notes = ev.notes
        holiday = ev.holidayName
        remindSelections = ev.remindDaysBefore
        autoGuessDone = true   // 编辑模式不自动猜
    }

    private func save() {
        let ev = CountdownEvent(id: existing?.id ?? UUID(),
                                title: title.isEmpty ? "重要的日子" : title,
                                date: date, repeatsYearly: repeats, emoji: emoji,
                                notes: notes, remindDaysBefore: remindSelections,
                                holidayName: holiday)
        // 闹钟重排（健哥令③）
        EventReminder.schedule(event: ev)
        onSave(ev)
        dismiss()
    }
}
