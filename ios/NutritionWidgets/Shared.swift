import SwiftUI
import WidgetKit

/// Must match `appGroupId` in `lib/home_widgets.dart` and the App Groups
/// entitlement on both the Runner and NutritionWidgets targets.
enum AppGroup {
    static let id = "group.com.nutritionplatform.nutritionPlatform"
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Mirrors `lib/theme/tokens.dart`'s `AppColors` — kept to the handful of
/// values the widgets actually use rather than the full app palette.
enum AppColor {
    static let primary = Color(hex: 0xCF161A)
    static let maroon = Color(hex: 0x4A140E)
    static let accent = Color(hex: 0xF5D630)
    static let textSecondary = Color(hex: 0x6E4740)
}

/// The data every widget reads. Written from Flutter via
/// `HomeWidget.saveWidgetData` (see `lib/home_widgets.dart`) into the App
/// Group's `UserDefaults` suite; read back here with the same keys.
struct WidgetSnapshot {
    let momentumPoints: Int
    let streakDays: Int
    let todayCalories: Int
    let todayProtein: Int
    let todayWater: Int

    static func load() -> WidgetSnapshot {
        let defaults = UserDefaults(suiteName: AppGroup.id)
        return WidgetSnapshot(
            momentumPoints: defaults?.integer(forKey: "momentum_points") ?? 0,
            streakDays: defaults?.integer(forKey: "streak_days") ?? 0,
            todayCalories: defaults?.integer(forKey: "today_calories") ?? 0,
            todayProtein: defaults?.integer(forKey: "today_protein") ?? 0,
            todayWater: defaults?.integer(forKey: "today_water") ?? 0
        )
    }

    /// Shown in the widget gallery preview and Xcode canvas, before any real
    /// app data has ever been saved.
    static let placeholder = WidgetSnapshot(
        momentumPoints: 12,
        streakDays: 3,
        todayCalories: 950,
        todayProtein: 62,
        todayWater: 5
    )
}

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

/// One provider shared by all three widget kinds — they only ever differ in
/// how they lay the same snapshot out.
struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: Date(), snapshot: context.isPreview ? .placeholder : .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        // Data only ever changes when the app pushes new values and calls
        // WidgetCenter.reloadTimelines — there's nothing to recompute on a
        // schedule, so a single-entry, never-expiring timeline is correct.
        let entry = SnapshotEntry(date: Date(), snapshot: .load())
        completion(Timeline(entries: [entry], policy: .never))
    }
}
