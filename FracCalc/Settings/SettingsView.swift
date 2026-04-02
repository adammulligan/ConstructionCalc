import SwiftUI

struct SettingsView: View {
    @AppStorage("maxDenominator") private var maxDenominator: Int = 16
    @AppStorage("customHotkeys") private var customHotkeysJSON: String = "[]"
    @State private var showAddCustom = false
    @State private var customNumerator = ""
    @State private var customDenominator = ""

    private let precisionOptions = [
        (2, "1/2\""),
        (4, "1/4\""),
        (8, "1/8\""),
        (16, "1/16\""),
        (32, "1/32\""),
    ]

    private let presetFractions: [(Int, Int)] = [
        (1, 3), (3, 8), (5, 8), (7, 8),
        (3, 16), (5, 16), (7, 16), (9, 16),
        (3, 32), (5, 32), (7, 32),
    ]

    private var customHotkeys: [(Int, Int)] {
        get {
            guard let data = customHotkeysJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([[Int]].self, from: data) else {
                return []
            }
            return decoded.compactMap { pair in
                guard pair.count == 2 else { return nil }
                return (pair[0], pair[1])
            }
        }
    }

    private func saveHotkeys(_ hotkeys: [(Int, Int)]) {
        let encoded = hotkeys.map { [$0.0, $0.1] }
        if let data = try? JSONEncoder().encode(encoded),
           let json = String(data: data, encoding: .utf8) {
            customHotkeysJSON = json
        }
    }

    private func isSelected(_ fraction: (Int, Int)) -> Bool {
        customHotkeys.contains { $0.0 == fraction.0 && $0.1 == fraction.1 }
    }

    private func togglePreset(_ fraction: (Int, Int)) {
        var hotkeys = customHotkeys
        if let idx = hotkeys.firstIndex(where: { $0.0 == fraction.0 && $0.1 == fraction.1 }) {
            hotkeys.remove(at: idx)
        } else if hotkeys.count < 4 {
            hotkeys.append(fraction)
        }
        saveHotkeys(hotkeys)
    }

    private func removeFraction(at index: Int) {
        var hotkeys = customHotkeys
        hotkeys.remove(at: index)
        saveHotkeys(hotkeys)
    }

    private func addCustomFraction() {
        guard let num = Int(customNumerator),
              let den = Int(customDenominator),
              num > 0, den > 0,
              customHotkeys.count < 4 else { return }
        var hotkeys = customHotkeys
        if !hotkeys.contains(where: { $0.0 == num && $0.1 == den }) {
            hotkeys.append((num, den))
            saveHotkeys(hotkeys)
        }
        customNumerator = ""
        customDenominator = ""
    }

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

                Section("Custom Fraction Hotkeys") {
                    if customHotkeys.isEmpty {
                        Text("No custom fractions configured.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(customHotkeys.enumerated()), id: \.offset) { index, item in
                            HStack {
                                Text("\(item.0)/\(item.1)")
                                    .font(.body.monospaced())
                                Spacer()
                                Button {
                                    removeFraction(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("Presets") {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(Array(presetFractions.enumerated()), id: \.offset) { _, fraction in
                            Button {
                                togglePreset(fraction)
                            } label: {
                                Text("\(fraction.0)/\(fraction.1)")
                                    .font(.callout.monospaced())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(isSelected(fraction) ? Color.teal : Color.gray.opacity(0.2))
                                    .foregroundColor(isSelected(fraction) ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .disabled(!isSelected(fraction) && customHotkeys.count >= 4)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button("Add custom fraction") {
                        showAddCustom = true
                    }
                    .disabled(customHotkeys.count >= 4)
                }
            }
            .navigationTitle("Settings")
            .alert("Add Custom Fraction", isPresented: $showAddCustom) {
                TextField("Numerator", text: $customNumerator)
                    .keyboardType(.numberPad)
                TextField("Denominator", text: $customDenominator)
                    .keyboardType(.numberPad)
                Button("Add") { addCustomFraction() }
                Button("Cancel", role: .cancel) {
                    customNumerator = ""
                    customDenominator = ""
                }
            } message: {
                Text("Enter a fraction (e.g. 3/8)")
            }
        }
    }
}
