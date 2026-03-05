import SwiftUI

struct SettingsView: View {
    @AppStorage("maxDenominator") private var maxDenominator: Int = 16

    private let precisionOptions = [
        (2, "1/2\""),
        (4, "1/4\""),
        (8, "1/8\""),
        (16, "1/16\""),
        (32, "1/32\""),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Precision") {
                    Picker("Maximum fraction", selection: $maxDenominator) {
                        ForEach(precisionOptions, id: \.0) { (value, label) in
                            Text(label).tag(value)
                        }
                    }
                }

                Section("Fraction Hotkeys") {
                    Text("Configure which fraction buttons appear on the keypad.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
