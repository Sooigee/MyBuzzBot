import WidgetKit
import SwiftUI
import Foundation

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), hoursUntilAlarm: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), hoursUntilAlarm: 0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        let currentDate = Date()
        let alarmTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: currentDate)!
        let hoursUntil = hoursUntilAlarm(currentTime: currentDate, alarmTime: alarmTime)
        
        for minuteOffset in stride(from: 0, to: 60 * 24, by: 10) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, hoursUntilAlarm: hoursUntil)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Timeline Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let hoursUntilAlarm: Int
}

// MARK: - Helper Functions
func hoursUntilAlarm(currentTime: Date, alarmTime: Date) -> Int {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour], from: currentTime, to: alarmTime)
    return components.hour ?? 0
}

// MARK: - Entry View
struct SimpleEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        Text("Hours until alarm: \(entry.hoursUntilAlarm)")
            .widgetBackground(Color.white) // Using the custom modifier for the background
    }
}

// MARK: - View Extension for Conditional Background
extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.4, macOSApplicationExtension 14.0, *) {
            return self.containerBackground(color, for: .widget)
        } else {
            return self.background(color)
        }
    }
}

// MARK: - Widget Declaration
struct AlarmWidget: Widget {
    let kind: String = "AlarmWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SimpleEntryView(entry: entry)
        }
        .configurationDisplayName("Alarm Widget")
        .description("Shows hours until the next alarm.")
    }
}

// MARK: - Widget Previews
struct AlarmWidget_Previews: PreviewProvider {
    static var previews: some View {
        SimpleEntryView(entry: SimpleEntry(date: Date(), hoursUntilAlarm: 5))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
