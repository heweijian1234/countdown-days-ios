import Foundation

// MARK: - 倒数事件模型（App Group 共享——Widget 同读一份）
struct CountdownEvent: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String        // "纪念日"/"她的生日"…
    var date: Date
    var repeatsYearly: Bool  // 循环纪念日（每年自动续）
    var emoji: String

    /// 距今天数（负数=已过 N 天；循环事件按下一年算）
    var daysUntil: Int {
        let cal = Calendar.current
        var target = cal.startOfDay(for: date)
        let today = cal.startOfDay(for: Date())
        if repeatsYearly {
            // 找今年（或明年）的目标日
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
}

enum EventStore {
    static let suiteName = "group.com.zeronelabs.countdown"
    static var defaults: UserDefaults { UserDefaults(suiteName: suiteName) ?? .standard }

    static func load() -> [CountdownEvent] {
        guard let data = defaults.data(forKey: "events"),
              let list = try? JSONDecoder().decode([CountdownEvent].self, from: data) else { return [] }
        return list.sorted { $0.daysUntil < $1.daysUntil }
    }

    static func save(_ events: [CountdownEvent]) {
        if let data = try? JSONEncoder().encode(events) {
            defaults.set(data, forKey: "events")
        }
    }

    static let emojiOptions = ["❤️", "🎂", "💍", "✈️", "🎓", "🏠", "🌴", "🎉", "🎁", "⭐️"]
}
