import Foundation
import SwiftData

@Model
class HistoryEntry {
    var id: UUID
    var expression: String
    var resultNumerator: Int64
    var resultDenominator: Int64
    var displayFormatRaw: String
    var timestamp: Date

    init(expression: String, resultNumerator: Int64, resultDenominator: Int64, displayMode: DisplayMode) {
        self.id = UUID()
        self.expression = expression
        self.resultNumerator = resultNumerator
        self.resultDenominator = resultDenominator
        self.displayFormatRaw = displayMode.rawValue
        self.timestamp = Date()
    }

    var displayMode: DisplayMode {
        DisplayMode(rawValue: displayFormatRaw) ?? .feetInches
    }

    var resultMeasurement: Measurement {
        Measurement(numerator: resultNumerator, denominator: resultDenominator)
    }
}
