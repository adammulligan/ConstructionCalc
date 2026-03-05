import SwiftUI

struct CalculatorView: View {
    @State private var viewModel = CalculatorViewModel()
    @AppStorage("maxDenominator") private var maxDenominator: Int = 16
    @State private var showSettings = false
    @State private var showHistory = false

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
                fractionHotkeys: [(1, 2), (1, 4), (1, 8), (1, 16)]
            )
        }
        .padding()
        .onChange(of: maxDenominator) {
            viewModel.maxDenominator = Int64(maxDenominator)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(
                viewModel: HistoryViewModel(),
                onSelect: { entry in
                    viewModel.state.currentResult = entry.resultMeasurement
                    viewModel.state.displayText = FracCalcBridge.formatFeetInches(entry.resultMeasurement)
                    showHistory = false
                },
                onClearAll: {}
            )
        }
    }
}
