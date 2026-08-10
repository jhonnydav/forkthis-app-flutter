import SwiftUI
import WidgetKit

/// Small/medium widget mirroring the app's yellow "Today" daily-snapshot
/// card (You tab) — calories, protein, water logged so far today.
struct TodayWidgetView: View {
    @Environment(\.widgetFamily) var family
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TODAY")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.6)
                    .foregroundColor(AppColor.maroon)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColor.maroon)
            }

            Spacer(minLength: 4)

            if family == .systemSmall {
                Text("\(snapshot.todayCalories)")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(AppColor.maroon)
                Text("calories")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
                Text("\(snapshot.todayProtein)g protein · \(snapshot.todayWater)/8 water")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
                    .lineLimit(1)
            } else {
                HStack(alignment: .top, spacing: 0) {
                    metric("\(snapshot.todayCalories)", "Calories")
                    divider()
                    metric("\(snapshot.todayProtein)g", "Protein")
                    divider()
                    metric("\(snapshot.todayWater)/8", "Water")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(AppColor.accent, for: .widget)
        .widgetURL(URL(string: "forkthis://track?homeWidget=true"))
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(AppColor.maroon)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func divider() -> some View {
        Rectangle()
            .fill(AppColor.maroon.opacity(0.16))
            .frame(width: 1, height: 32)
            .padding(.horizontal, 8)
    }
}

struct TodayWidget: Widget {
    let kind = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            TodayWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Today's Macros")
        .description("Calories, protein, and water logged today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    TodayWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
}

#Preview(as: .systemMedium) {
    TodayWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
}
