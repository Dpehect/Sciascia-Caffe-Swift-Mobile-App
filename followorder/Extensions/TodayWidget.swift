import WidgetKit
import SwiftUI

struct TodayEntry: TimelineEntry {
    let date: Date
    let todayRevenue: Double
    let todayOrdersCount: Int
}

struct TodayWidgetEntryView: View {
    var entry: TodayEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BUGÜNÜN ÖZETİ")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.neonMagenta)
                .tracking(1)
            
            Text("₺\(String(format: "%.0f", entry.todayRevenue))")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)
            
            Text("\(entry.todayOrdersCount) Sipariş Teslim Edildi")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .padding()
        .containerBackground(Color.themeBackground, for: .widget)
    }
}

struct TodayWidget: Widget {
    let kind: String = "TodayWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            TodayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Günün Özeti")
        .description("Bugünkü toplam ciroyu ve sipariş adedini gösterir.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), todayRevenue: 1250.0, todayOrdersCount: 5)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> ()) {
        let entry = TodayEntry(date: Date(), todayRevenue: 1250.0, todayOrdersCount: 5)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> ()) {
        let entry = TodayEntry(date: Date(), todayRevenue: 0.0, todayOrdersCount: 0)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}
