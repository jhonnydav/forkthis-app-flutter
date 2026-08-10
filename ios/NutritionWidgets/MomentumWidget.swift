import SwiftUI
import WidgetKit

/// Small/medium widget mirroring the app's "ForkThis! Momentum" card (You
/// tab and Home) — points and streak, the app's gamification hook.
struct MomentumWidgetView: View {
    @Environment(\.widgetFamily) var family
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FORKTHIS! MOMENTUM")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.6)
                .foregroundColor(AppColor.accent)
                .lineLimit(1)

            Spacer(minLength: 4)

            if family == .systemSmall {
                Text("\(snapshot.momentumPoints)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("points")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundColor(AppColor.accent)
                    Text("\(snapshot.streakDays) day streak")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
            } else {
                HStack(spacing: 10) {
                    statBlock(value: "\(snapshot.momentumPoints)", label: "points")
                    statBlock(value: "\(snapshot.streakDays)", label: "day streak")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(AppColor.primary, for: .widget)
        .widgetURL(URL(string: "forkthis://track?homeWidget=true"))
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.12))
        .cornerRadius(12)
    }
}

struct MomentumWidget: Widget {
    let kind = "MomentumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            MomentumWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("ForkThis! Momentum")
        .description("Your points and streak at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    MomentumWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
}

#Preview(as: .systemMedium) {
    MomentumWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
}
