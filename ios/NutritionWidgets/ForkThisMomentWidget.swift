import SwiftUI
import WidgetKit

/// Medium/large widget mirroring the app's signature red "ForkThis! Moment"
/// hero card on Home — the app's flagship feature, so this is the one
/// widget that gets the halftone background treatment instead of a flat fill.
struct ForkThisMomentWidgetView: View {
    @Environment(\.widgetFamily) var family
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemLarge ? 14 : 10) {
            Text("FORKTHIS! MOMENT")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.6)
                .foregroundColor(AppColor.maroon)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppColor.accent)
                .cornerRadius(999)

            Text("What would make this meal easier?")
                .font(.system(size: family == .systemLarge ? 22 : 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if family == .systemLarge {
                Text("Pick the real-life situation first. We'll narrow it to one order, recipe, or next step.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.82))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Text("Open ForkThis!")
                        .font(.system(size: 12, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(AppColor.maroon)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColor.accent)
                .cornerRadius(999)

                Spacer()

                miniStat("\(snapshot.momentumPoints)", "pts")
                miniStat("\(snapshot.todayProtein)g", "protein")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            ZStack {
                AppColor.primary
                HalftoneBackground()
            }
        }
        .widgetURL(URL(string: "forkthis://forkthis-moment?homeWidget=true"))
    }

    private func miniStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 0) {
            Text(value)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

/// Lightweight recreation of the app's `_WarmRedHalftonePainter` — a sparse
/// dot field fading toward the top-right, drawn once per render (no
/// animation, so it's cheap enough for a widget's tight render budget).
private struct HalftoneBackground: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 10
            var y: CGFloat = -10
            while y < size.height + 10 {
                var x: CGFloat = -10
                while x < size.width + 10 {
                    let dx = (x / size.width) - 0.75
                    let dy = (y / size.height) - 0.2
                    let distance = min(max(dx * dx + dy * dy, 0), 1)
                    let radius = 0.4 + ((1 - distance) * 1.1)
                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(0.06)))
                    x += spacing
                }
                y += spacing
            }
        }
    }
}

struct ForkThisMomentWidget: Widget {
    let kind = "ForkThisMomentWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            ForkThisMomentWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("ForkThis! Moment")
        .description("Jump straight into picking today's ForkThis! moment.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    ForkThisMomentWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
}

#Preview(as: .systemLarge) {
    ForkThisMomentWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
}
