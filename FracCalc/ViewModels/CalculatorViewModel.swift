import SwiftUI
import SwiftData

@Observable
class CalculatorViewModel {
    var state = CalculatorState()
    var maxDenominator: Int64 = 16
    var modelContext: ModelContext?

    func digitPressed(_ digit: String) {
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
            evaluateCurrentInput()
        }
        if let result = state.currentResult {
            state.firstOperand = result
            state.expressionParts.append(FracCalcBridge.fmtFeetInches(result))
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
    }

    func equalsPressed() {
        if !state.inputBuffer.isEmpty {
            if let parsed = try? FracCalcBridge.parse(state.inputBuffer) {
                state.expressionParts.append(FracCalcBridge.fmtFeetInches(parsed))
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

    func toggleDisplayFormat() {
        state.displayFormat = (state.displayFormat == .feetInches) ? .inchesOnly : .feetInches

        // If mid-input, try to reformat just the input buffer text
        if !state.inputBuffer.isEmpty {
            if let parsed = try? FracCalcBridge.parse(state.inputBuffer) {
                let formatted: String
                switch state.displayFormat {
                case .feetInches: formatted = FracCalcBridge.fmtFeetInches(parsed)
                case .inchesOnly: formatted = FracCalcBridge.fmtInchesOnly(parsed)
                }
                state.inputBuffer = formatted
                state.displayText = formatted
            }
        } else if let m = state.currentResult {
            updateDisplay(m)
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
        switch state.displayFormat {
        case .feetInches:
            state.displayText = prefix + FracCalcBridge.fmtFeetInches(m)
        case .inchesOnly:
            state.displayText = prefix + FracCalcBridge.fmtInchesOnly(m)
        }
    }
}
