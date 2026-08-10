import SwiftUI
import WidgetKit

@main
struct NutritionWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MomentumWidget()
        TodayWidget()
        ForkThisMomentWidget()
    }
}
