import SwiftUI
import SwiftData

struct CalculatorView: View {
    @State private var viewModel = CalculatorViewModel()
    @AppStorage("maxDenominator") private var maxDenominator: Int = 16
    @AppStorage("customHotkeys") private var customHotkeysJSON: String = "[]"
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var historyViewModel = HistoryViewModel()
    @Environment(\.modelContext) private var modelContext

    private var customHotkeys: [(Int, Int)] {
        guard let data = customHotkeysJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([[Int]].self, from: data) else {
            return []
        }
        return decoded.compactMap { pair in
            guard pair.count == 2 else { return nil }
            return (pair[0], pair[1])
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button { showHistory = true } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "gear")
                }
            }
            .padding(.horizontal)

            DisplayView(
                text: viewModel.state.displayText,
                hasMemory: viewModel.state.memory != nil
            )

            KeypadView(
                viewModel: viewModel,
                fractionHotkeys: [(1, 2), (1, 4), (1, 8), (1, 16)],
                customHotkeys: customHotkeys
            )
        }
        .padding()
        .onAppear {
            viewModel.modelContext = modelContext
        }
        .onChange(of: maxDenominator) {
            viewModel.maxDenominator = Int64(maxDenominator)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(
                viewModel: historyViewModel,
                onSelect: { entry in
                    viewModel.state.currentResult = entry.resultMeasurement
                    viewModel.state.displayText = FracCalcBridge.fmtFeetInches(entry.resultMeasurement)
                    showHistory = false
                },
                onClearAll: {
                    historyViewModel.clearAll(context: modelContext)
                }
            )
            .onAppear {
                historyViewModel.load(context: modelContext)
            }
        }
    }
}
