import SwiftUI
import SwiftData

@main
struct FracCalcApp: App {
    var body: some Scene {
        WindowGroup {
            CalculatorView()
        }
        .modelContainer(for: HistoryEntry.self)
    }
}
