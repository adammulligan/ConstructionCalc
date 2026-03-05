import SwiftUI

@Observable
class CalculatorViewModel {
    var state = CalculatorState()
    var maxDenominator: Int64 = 16

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
        }
        state.pendingOperator = op
        state.inputBuffer = ""
    }

    func equalsPressed() {
        if !state.inputBuffer.isEmpty {
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
        if let m = state.currentResult {
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
