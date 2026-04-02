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

    init(expression: String, resultNumerator: Int64, resultDenominator: Int64, displayFormat: DisplayFormat) {
        self.id = UUID()
        self.expression = expression
        self.resultNumerator = resultNumerator
        self.resultDenominator = resultDenominator
        self.displayFormatRaw = displayFormat == .feetInches ? "feetInches" : "inchesOnly"
        self.timestamp = Date()
    }

    var displayFormat: DisplayFormat {
        displayFormatRaw == "feetInches" ? .feetInches : .inchesOnly
    }

    var resultMeasurement: Measurement {
        Measurement(numerator: resultNumerator, denominator: resultDenominator)
    }
}
