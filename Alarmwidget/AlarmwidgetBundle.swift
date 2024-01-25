import WidgetKit
import SwiftUI
import Foundation

@main
struct AlarmWidget2: Widget {
    let kind: String = "AlarmWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Alarm Countdown")
        .description("Shows how many hours until your alarm goes off.")
    }
}

struct WidgetEntryView: View {
    let entry: Provider.Entry

    var body: some View {
        // Customize your widget appearance
        VStack {
            Text("Time Until Alarm")
                .font(.headline)
            Text("\(entry.hoursUntilAlarm) hours")
                .font(.caption)
        }
        .padding()
    }
}
