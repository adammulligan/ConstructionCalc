import SwiftUI
import SwiftData

@Observable
class CalculatorViewModel {
    var state = CalculatorState()
    var maxDenominator: Int64 = 16
    var modelContext: ModelContext?

    func digitPressed(_ digit: String) {
        if digit == "." {
            state.inputStartedDecimal = true
        }
        state.inputBuffer += digit
        state.displayText = state.inputBuffer
    }

    func unitPressed(_ unit: String) {
        state.inputBuffer += unit
        state.displayText = state.inputBuffer
    }

    func fractionSlashPressed() {
        state.inputBuffer += "/"
        state.displayText = state.inputBuffer
    }

    func fractionHotkeyPressed(numerator: Int, denominator: Int) {
        state.inputBuffer += "-\(numerator)/\(denominator)"
        state.displayText = state.inputBuffer
    }

    func operatorPressed(_ op: Operator) {
        if !state.inputBuffer.isEmpty {
            // Track if the first operand was entered as decimal
            if state.firstOperand == nil {
                state.useDecimal = state.inputStartedDecimal
            }
            evaluateCurrentInput()
        }
        if let result = state.currentResult {
            state.firstOperand = result
            let formatted = state.useDecimal ? FracCalcBridge.fmtDecimal(result) : FracCalcBridge.fmtFeetInches(result)
            state.expressionParts.append(formatted)
        }
        state.pendingOperator = op
        let opSymbol: String
        switch op {
        case .add: opSymbol = "+"
        case .subtract: opSymbol = "\u{2212}"
        case .multiply: opSymbol = "\u{00D7}"
        case .divide: opSymbol = "\u{00F7}"
        }
        state.expressionParts.append(opSymbol)
        state.inputBuffer = ""
        state.inputStartedDecimal = false
    }

    func equalsPressed() {
        if !state.inputBuffer.isEmpty {
            if let parsed = try? FracCalcBridge.parse(state.inputBuffer) {
                let formatted = state.useDecimal ? FracCalcBridge.fmtDecimal(parsed) : FracCalcBridge.fmtFeetInches(parsed)
                state.expressionParts.append(formatted)
            }
            evaluateCurrentInput()
        }
        guard let first = state.firstOperand,
              let op = state.pendingOperator,
              let second = state.currentResult else {
            return
        }

        let result: Measurement
        switch op {
        case .add: result = FracCalcBridge.addMeasurements(first, second)
        case .subtract: result = FracCalcBridge.subtractMeasurements(first, second)
        case .multiply:
            let scalar = second.numerator / second.denominator
            result = FracCalcBridge.multiplyMeasurement(first, by: scalar)
        case .divide:
            let scalar = second.numerator / second.denominator
            result = FracCalcBridge.divideMeasurement(first, by: scalar)
        }

        let snapped = FracCalcBridge.snap(result, maxDenominator: maxDenominator)
        state.currentResult = snapped.value
        state.isApproximate = snapped.isApproximate
        state.firstOperand = nil
        state.pendingOperator = nil
        updateDisplay(snapped.value)
        saveHistory(expression: state.expressionParts.joined(separator: " "), result: snapped.value)
        state.expressionParts = []
        state.inputBuffer = ""
    }

    func clearPressed() {
        state = CalculatorState()
    }

    func backspacePressed() {
        if !state.inputBuffer.isEmpty {
            state.inputBuffer.removeLast()
            state.displayText = state.inputBuffer.isEmpty ? "0\"" : state.inputBuffer
        }
    }

    func toggleSign() {
        if !state.inputBuffer.isEmpty {
            // Toggle sign on the input buffer
            if state.inputBuffer.hasPrefix("-") {
                state.inputBuffer.removeFirst()
            } else {
                state.inputBuffer = "-" + state.inputBuffer
            }
            state.displayText = state.inputBuffer
        } else if let m = state.currentResult {
            // Toggle sign on the current result
            let negated = Measurement(numerator: -m.numerator, denominator: m.denominator)
            state.currentResult = negated
            updateDisplay(negated)
        }
    }

    func toggleDisplayFormat() {
        let wasDecimal = state.useDecimal
        state.useDecimal = false

        // If exiting decimal mode, just show current fractional format without toggling
        if !wasDecimal {
            state.displayFormat = (state.displayFormat == .feetInches) ? .inchesOnly : .feetInches
        }

        // If mid-input, try to reformat just the input buffer text
        if !state.inputBuffer.isEmpty {
            if let parsed = try? FracCalcBridge.parse(state.inputBuffer) {
                let snapped = FracCalcBridge.snap(parsed, maxDenominator: maxDenominator)
                let feetInches = FracCalcBridge.fmtFeetInches(snapped.value)
                let inchesOnly = FracCalcBridge.fmtInchesOnly(snapped.value)
                let formatted: String
                if state.inputBuffer == feetInches || state.displayText == feetInches {
                    formatted = inchesOnly
                    state.displayFormat = .inchesOnly
                } else {
                    formatted = feetInches
                    state.displayFormat = .feetInches
                }
                state.inputBuffer = formatted
                state.displayText = formatted
            }
        } else if let m = state.currentResult {
            let snapped = FracCalcBridge.snap(m, maxDenominator: maxDenominator)
            state.currentResult = snapped.value
            state.isApproximate = snapped.isApproximate
            updateDisplay(snapped.value)
        }
    }

    func toggleDecimalFormat() {
        if !state.inputBuffer.isEmpty {
            if let parsed = try? FracCalcBridge.parse(state.inputBuffer) {
                let decimalText = FracCalcBridge.fmtDecimal(parsed)
                let snapped = FracCalcBridge.snap(parsed, maxDenominator: maxDenominator)
                let fracText = (state.displayFormat == .feetInches)
                    ? FracCalcBridge.fmtFeetInches(snapped.value)
                    : FracCalcBridge.fmtInchesOnly(snapped.value)

                let formatted: String
                if state.inputBuffer == decimalText || state.displayText == decimalText {
                    formatted = fracText
                    state.useDecimal = false
                } else {
                    formatted = decimalText
                    state.useDecimal = true
                }
                state.inputBuffer = formatted
                state.displayText = formatted
            }
        } else if let m = state.currentResult {
            state.useDecimal.toggle()
            if !state.useDecimal {
                let snapped = FracCalcBridge.snap(m, maxDenominator: maxDenominator)
                state.currentResult = snapped.value
                state.isApproximate = snapped.isApproximate
                updateDisplay(snapped.value)
            } else {
                updateDisplay(m)
            }
        }
    }

    // MARK: - Memory

    func memoryAdd() {
        guard let current = state.currentResult else { return }
        if let mem = state.memory {
            state.memory = FracCalcBridge.addMeasurements(mem, current)
        } else {
            state.memory = current
        }
    }

    func memorySubtract() {
        guard let current = state.currentResult else { return }
        if let mem = state.memory {
            state.memory = FracCalcBridge.subtractMeasurements(mem, current)
        } else {
            state.memory = Measurement(numerator: -current.numerator, denominator: current.denominator)
        }
    }

    func memoryRecall() {
        guard let mem = state.memory else { return }
        state.currentResult = mem
        updateDisplay(mem)
    }

    func memoryClear() {
        state.memory = nil
    }

    // MARK: - Private

    private func evaluateCurrentInput() {
        guard let parsed = try? FracCalcBridge.parse(state.inputBuffer) else {
            state.displayText = "Error"
            return
        }
        state.currentResult = parsed
    }

    private func saveHistory(expression: String, result: Measurement) {
        guard let context = modelContext else { return }
        let entry = HistoryEntry(
            expression: expression,
            resultNumerator: result.numerator,
            resultDenominator: result.denominator,
            displayFormat: state.displayFormat
        )
        context.insert(entry)
        try? context.save()
    }

    private func updateDisplay(_ m: Measurement) {
        let prefix = state.isApproximate ? "\u{2248} " : ""
        if state.useDecimal {
            state.displayText = prefix + FracCalcBridge.fmtDecimal(m)
        } else {
            switch state.displayFormat {
            case .feetInches:
                state.displayText = prefix + FracCalcBridge.fmtFeetInches(m)
            case .inchesOnly:
                state.displayText = prefix + FracCalcBridge.fmtInchesOnly(m)
            }
        }
    }
}
