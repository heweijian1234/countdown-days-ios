import Foundation
import UserNotifications

// MARK: - 倒数事件模型 v2（健哥第四轮4条：
// ①海外节日库 ②准备清单 ③闹钟提醒 ④事件可点进去改）

struct CountdownEvent: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var date: Date
    var repeatsYearly: Bool
    var emoji: String
    var notes: String                  // 健哥令②：准备了什么
    var remindDaysBefore: [Int]        // 健哥令③：闹钟（提前天数数组，最多3个；空=不提醒）
    var holidayName: String            // 健哥令①：关联节日名（可选）

    init(id: UUID = UUID(), title: String, date: Date, repeatsYearly: Bool = false, emoji: String = "❤️",
         notes: String = "", remindDaysBefore: [Int] = [], holidayName: String = "") {
        self.id = id
        self.title = title
        self.date = date
        self.repeatsYearly = repeatsYearly
        self.emoji = emoji
        self.notes = notes
        self.remindDaysBefore = Array(remindDaysBefore.prefix(3))
        self.holidayName = holidayName
    }

    /// 距今天数（负数=已过N天；循环事件按下一年算）
    var daysUntil: Int {
        let cal = Calendar.current
        var target = cal.startOfDay(for: date)
        let today = cal.startOfDay(for: Date())
        if repeatsYearly {
            var comps = cal.dateComponents([.month, .day], from: date)
            comps.year = cal.component(.year, from: today)
            if let thisYear = cal.date(from: comps), thisYear >= today {
                target = thisYear
            } else if let nextYear = cal.date(byAdding: .year, value: 1, to: cal.date(from: comps) ?? date) {
                target = nextYear
            }
        }
        return cal.dateComponents([.day], from: today, to: target).day ?? 0
    }

    /// 候选闹钟（健哥令③：提前天数）
    static let remindOptions: [Int] = [1, 3, 7, 14, 30, 60]

    static func remindLabel(_ days: Int) -> String {
        days >= 30 ? "提前 \(days / 30) 个月" : "提前 \(days) 天"
    }
}

// MARK: - 海外节日库（健哥令①：仪式感——点日期自动识别+手动选）

enum Holidays {
    /// 固定公历节日（月-日 → 名字+emoji）
    static let fixed: [String: (String, String)] = [
        "01-01": ("新年", "🎉"),
        "02-14": ("情人节", "💝"),
        "03-17": ("圣帕特里克节", "🍀"),
        "04-01": ("愚人节", "🃏"),
        "05-04": ("星球大战日", "🌌"),
        "06-01": ("儿童节", "🧒"),
        "06-14": ("国旗日", "🇺🇸"),
        "07-04": ("美国独立日", "🎆"),
        "10-31": ("万圣节", "🎃"),
        "11-11": ("退伍军人节", "🎖️"),
        "12-24": ("平安夜", "🎄"),
        "12-25": ("圣诞节", "🎅"),
        "12-31": ("跨年夜", "🥂"),
        "11-27": ("感恩节(2026)", "🦃"),
        "11-26": ("感恩节(2027)", "🦃"),
        "05-10": ("母亲节(2026)", "💐"),
        "05-09": ("母亲节(2027)", "💐"),
        "06-21": ("父亲节(2026)", "👔"),
        "06-20": ("父亲节(2027)", "👔"),
    ]

    /// 按日期猜节日（循环事件找最近的）
    static func guess(date: Date, repeatsYearly: Bool) -> (String, String)? {
        let cal = Calendar.current
        let key = String(format: "%02d-%02d", cal.component(.month, from: date), cal.component(.day, from: date))
        return fixed[key]
    }

    /// 全部节日（编辑器选择列表）
    static let allOptions: [(String, String)] = [
        ("新年", "🎉"), ("情人节", "💝"), ("圣帕特里克节", "🍀"), ("复活节", "🐣"),
        ("母亲节", "💐"), ("父亲节", "👔"), ("美国独立日", "🎆"), ("万圣节", "🎃"),
        ("感恩节", "🦃"), ("平安夜", "🎄"), ("圣诞节", "🎅"), ("跨年夜", "🥂"),
        ("Back to School", "🎒"), ("Black Friday", "🛍️"), ("Cyber Monday", "💻"),
        ("超级碗", "🏈"), ("婚纪念日", "💍"), ("无需节日", "·"),
    ]
}

// MARK: - 存储

enum EventStore {
    static let key = "countdown.events.v2"

    static func load() -> [CountdownEvent] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([CountdownEvent].self, from: data) else {
            return migrateV1() ?? []
        }
        return list.sorted { $0.daysUntil < $1.daysUntil }
    }

    /// v1（无notes/闹钟/节日）迁移
    private static func migrateV1() -> [CountdownEvent]? {
        guard let raw = UserDefaults.standard.data(forKey: "events"),
              let old = try? JSONDecoder().decode([OldV1].self, from: raw) else { return nil }
        let list = old.map {
            CountdownEvent(id: $0.id, title: $0.title, date: $0.date, repeatsYearly: $0.repeatsYearly, emoji: $0.emoji)
        }
        if let raw2 = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(raw2, forKey: key)
        }
        return list
    }

    private struct OldV1: Codable {
        let id: UUID
        var title: String
        var date: Date
        var repeatsYearly: Bool
        var emoji: String
    }

    static func save(_ events: [CountdownEvent]) {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static let emojiOptions = ["❤️", "🎂", "💍", "✈️", "🎓", "🏠", "🌴", "🎉", "🎁", "⭐️", "🐣", "🦃", "🎅", "🎆", "💐"]
}

// MARK: - 闹钟调度（健哥令③：提前N天早上9点本地通知）

enum EventReminder {
    static func schedule(event: CountdownEvent) {
        cancel(eventId: event.id)
        guard !event.remindDaysBefore.isEmpty else { return }

        let center = UNUserNotificationCenter.current()
        let cal = Calendar.current
        for (idx, days) in event.remindDaysBefore.enumerated() {
            var target = event.date
            if event.repeatsYearly {
                // 找下一次循环日期
                let today = cal.startOfDay(for: Date())
                var comps = cal.dateComponents([.month, .day], from: event.date)
                comps.year = cal.component(.year, from: today)
                if let d = cal.date(from: comps), d >= today {
                    target = d
                } else if let next = cal.date(byAdding: .year, value: 1, to: d ?? event.date) {
                    target = next
                }
            }
            guard let trigger = cal.date(byAdding: .day, value: -days, to: cal.startOfDay(for: target)) else { continue }
            // 通知时间=当天早上 9:00
            var comps = cal.dateComponents([.year, .month, .day], from: trigger)
            comps.hour = 9
            comps.minute = 0
            guard let fire = cal.date(from: comps), fire > Date() else { continue }

            let content = UNMutableNotificationContent()
            let label = CountdownEvent.remindLabel(days)
            content.title = "\(event.emoji) \(event.title) \(label)"
            content.body = event.notes.isEmpty
                ? "\(event.title) 还有 \(event.daysUntil) 天。开始准备点什么吧。"
                : "\(event.title) 还有 \(event.daysUntil) 天。已准备：\(event.notes)"
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "\(event.id.uuidString)-\(idx)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
            center.add(request)
        }
    }

    static func cancel(eventId: UUID) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            let ids = pending.map { $0.identifier }.filter { $0.hasPrefix(eventId.uuidString) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
