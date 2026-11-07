import WidgetKit
import SwiftUI

// MARK: - 桌面小组件（systemSmall：单一倒数 / systemMedium：前 4 个事件）——中文 UI
struct CountdownEntry: TimelineEntry {
    let date: Date
    let events: [CountdownEvent]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: Date(), events: [
            CountdownEvent(id: UUID(), title: "纪念日", date: Date().addingTimeInterval(86400 * 14), repeatsYearly: true, emoji: "❤️")
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        completion(CountdownEntry(date: Date(), events: EventStore.load().prefix(4).map { $0 }))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let entry = CountdownEntry(date: Date(), events: EventStore.load().prefix(4).map { $0 })
        // 每天零点后刷新（天数变)
        let cal = Calendar.current
        let nextMidnight = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

struct CountdownWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CountdownEntry

    var body: some View {
        if family == .systemSmall {
            smallView
        } else {
            mediumView
        }
    }

    private var smallView: some View {
        Group {
            if let ev = entry.events.first {
                VStack(spacing: 4) {
                    Text(ev.emoji).font(.title3)
                    Text("\(abs(ev.daysUntil))")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundColor(.pink)
                    Text(ev.daysUntil >= 0 ? "天" : "天前")
                        .font(.caption2).foregroundColor(.secondary)
                    Text(ev.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(4)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock").foregroundColor(.pink)
                    Text("添加倒数").font(.caption2).foregroundColor(.secondary)
                }
            }
        }
        .widgetBackground()
    }

    private var mediumView: some View {
        Group {
            if entry.events.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock").foregroundColor(.pink)
                    Text("添加倒数").font(.caption).foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 6) {
                    ForEach(entry.events) { ev in
                        HStack {
                            Text(ev.emoji)
                            Text(ev.title)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Spacer()
                            Text("\(abs(ev.daysUntil))")
                                .font(.callout.bold())
                                .foregroundColor(.pink)
                            Text("天")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .widgetBackground()
    }
}

// iOS17 的 containerBackground 兼容 iOS16（widgetBackground 修饰符适配）
extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { Color(uiColor: .systemBackground) }
        } else {
            background(Color(uiColor: .systemBackground))
        }
    }
}

@main
struct CountdownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CountdownWidget", provider: Provider()) { entry in
            CountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("倒数小组件")
        .description("距离重要日子还有几天，一目了然。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
