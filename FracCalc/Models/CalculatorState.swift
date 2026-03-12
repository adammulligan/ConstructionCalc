import Foundation

enum Operator {
    case add, subtract, multiply, divide
}

enum InputMode {
    case inches
    case feet
}

enum DisplayFormat {
    case feetInches
    case inchesOnly
}

struct CalculatorState {
    var displayText: String = "0\""
    var inputBuffer: String = ""
    var firstOperand: Measurement? = nil
    var pendingOperator: Operator? = nil
    var currentResult: Measurement? = nil
    var displayFormat: DisplayFormat = .feetInches
    var memory: Measurement? = nil
    var isApproximate: Bool = false
    var expressionParts: [String] = []
}
