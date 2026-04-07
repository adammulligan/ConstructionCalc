import SwiftUI

struct HistoryView: View {
    let viewModel: HistoryViewModel
    let onSelect: (HistoryEntry) -> Void
    let onClearAll: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.entries, id: \.id) { entry in
                    Button {
                        onSelect(entry)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(entry.expression)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formattedResult(entry))
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                Button("Clear All", role: .destructive) { onClearAll() }
            }
        }
    }

    private func formattedResult(_ entry: HistoryEntry) -> String {
        let m = entry.resultMeasurement
        switch entry.displayMode {
        case .feetInches: return FracCalcBridge.fmtFeetInches(m)
        case .inchesOnly: return FracCalcBridge.fmtInchesOnly(m)
        case .decimal:    return FracCalcBridge.fmtDecimal(m)
        }
    }
}
