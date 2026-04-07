import SwiftUI

struct KeypadView: View {
    let viewModel: CalculatorViewModel
    let fractionHotkeys: [(Int, Int)]
    var customHotkeys: [(Int, Int)] = []

    var body: some View {
        VStack(spacing: 8) {
            fractionHotkeyRow
            if !customHotkeys.isEmpty {
                customHotkeyRow
            }
            digitAndOperatorGrid
            bottomRow
        }
        .padding(8)
    }

    private var fractionHotkeyRow: some View {
        HStack(spacing: 8) {
            ForEach(fractionHotkeys, id: \.1) { (num, den) in
                CalcButton(label: "\(num)/\(den)", color: .purple) {
                    viewModel.fractionHotkeyPressed(numerator: num, denominator: den)
                }
            }
        }
        .frame(height: 48)
    }

    private var customHotkeyRow: some View {
        HStack(spacing: 8) {
            ForEach(Array(customHotkeys.enumerated()), id: \.offset) { _, item in
                let (num, den) = item
                CalcButton(label: "\(num)/\(den)", color: .teal) {
                    viewModel.fractionHotkeyPressed(numerator: num, denominator: den)
                }
            }
        }
        .frame(height: 48)
    }

    private var digitAndOperatorGrid: some View {
        let rows: [[KeyDef]] = [
            [.digit("7"), .digit("8"), .digit("9"), .op("\u{00F7}", .divide), .unit("'")],
            [.digit("4"), .digit("5"), .digit("6"), .op("\u{00D7}", .multiply), .unit("\"")],
            [.digit("1"), .digit("2"), .digit("3"), .op("\u{2212}", .subtract), .slash],
            [.digit("0"), .decimal, .equals, .op("+", .add), .clear],
        ]

        return VStack(spacing: 8) {
            ForEach(0..<rows.count, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<rows[row].count, id: \.self) { col in
                        keyButton(rows[row][col])
                    }
                }
            }
        }
    }

    private var bottomRow: some View {
        HStack(spacing: 8) {
            CalcButton(label: "\u{232B}", color: .gray) { viewModel.backspacePressed() }
            CalcButton(label: "\u{00B1}", color: .gray) { viewModel.toggleSign() }
            CalcButton(label: "ft\u{2194}in", color: .blue) { viewModel.toggleDisplayFormat() }
            CalcButton(label: "\u{00BD}\u{2194}0.5", color: .blue) { viewModel.toggleDecimalFormat() }
            CalcButton(label: "MR", color: .gray) { viewModel.memoryRecall() }
            CalcButton(label: "M+", color: .gray) { viewModel.memoryAdd() }
        }
        .frame(height: 48)
    }

    @ViewBuilder
    private func keyButton(_ key: KeyDef) -> some View {
        switch key {
        case .digit(let d):
            CalcButton(label: d, color: .secondary) { viewModel.digitPressed(d) }
        case .op(let label, let op):
            CalcButton(label: label, color: .orange) { viewModel.operatorPressed(op) }
        case .unit(let u):
            CalcButton(label: u, color: .teal) { viewModel.unitPressed(u) }
        case .slash:
            CalcButton(label: "/", color: .teal) { viewModel.fractionSlashPressed() }
        case .decimal:
            CalcButton(label: ".", color: .secondary) { viewModel.digitPressed(".") }
        case .equals:
            CalcButton(label: "=", color: .orange) { viewModel.equalsPressed() }
        case .clear:
            CalcButton(label: "C", color: .red) { viewModel.clearPressed() }
        }
    }
}

private enum KeyDef {
    case digit(String)
    case op(String, Operator)
    case unit(String)
    case slash
    case decimal
    case equals
    case clear
}
