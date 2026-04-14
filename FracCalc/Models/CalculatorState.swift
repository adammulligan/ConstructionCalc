import Foundation

enum Operator {
    case add, subtract, multiply, divide
}

enum InputMode {
    case inches
    case feet
}

enum DisplayMode: String, Codable {
    case feetInches
    case inchesOnly
    case decimal
}

struct MemoryBank: Codable, Equatable {
    let numerator: Int64
    let denominator: Int64
    let displayMode: DisplayMode
}

struct CalculatorState {
    var displayText: String = "0\""
    var inputBuffer: String = ""
    var firstOperand: Measurement? = nil
    var pendingOperator: Operator? = nil
    var currentResult: Measurement? = nil
    var displayMode: DisplayMode = .feetInches
    var lastFractionalMode: DisplayMode = .feetInches
    var memory: Measurement? = nil
    var isApproximate: Bool = false
    var expressionParts: [String] = []
}
