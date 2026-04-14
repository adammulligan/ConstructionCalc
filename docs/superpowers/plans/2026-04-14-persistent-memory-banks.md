# Persistent Memory Banks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add four persistent memory bank slots (M1-M4) that store and recall measurement values across app sessions.

**Architecture:** Banks are stored as JSON in `@AppStorage`, following the existing `customHotkeys` pattern. `CalculatorView` owns the storage, `KeypadView` renders the bank buttons, and `CalculatorViewModel` handles store/recall logic. A new `MemoryBank` Codable struct holds the numerator, denominator, and display mode for each slot.

**Tech Stack:** SwiftUI, @AppStorage, Codable JSON serialization

---

### Task 1: Add MemoryBank model and Codable DisplayMode

**Files:**
- Modify: `FracCalc/Models/CalculatorState.swift`

- [ ] **Step 1: Add Codable conformance to DisplayMode**

In `FracCalc/Models/CalculatorState.swift`, change the `DisplayMode` enum to conform to `Codable`:

```swift
enum DisplayMode: String, Codable {
    case feetInches
    case inchesOnly
    case decimal
}
```

- [ ] **Step 2: Add MemoryBank struct**

Add the following struct below the `DisplayMode` enum in `FracCalc/Models/CalculatorState.swift`:

```swift
struct MemoryBank: Codable, Equatable {
    let numerator: Int64
    let denominator: Int64
    let displayMode: DisplayMode
}
```

- [ ] **Step 3: Verify the project builds**

Run: `xcodebuild -project FracCalc.xcodeproj -scheme FracCalc -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add FracCalc/Models/CalculatorState.swift
git commit -m "feat: add MemoryBank model and Codable DisplayMode"
```

---

### Task 2: Add bank store/recall logic to CalculatorViewModel

**Files:**
- Modify: `FracCalc/ViewModels/CalculatorViewModel.swift`

- [ ] **Step 1: Add a static formatting helper**

Add a static method to `CalculatorViewModel` that formats a measurement in a given display mode, independent of `state.displayMode`. This is needed so bank button labels can show values in their stored mode. Add this in the `// MARK: - Private` section:

```swift
static func formatMeasurement(_ m: Measurement, mode: DisplayMode) -> String {
    switch mode {
    case .feetInches: return FracCalcBridge.fmtFeetInches(m)
    case .inchesOnly: return FracCalcBridge.fmtInchesOnly(m)
    case .decimal:    return FracCalcBridge.fmtDecimal(m)
    }
}
```

- [ ] **Step 2: Add bankTapped method**

Add the following method in a new `// MARK: - Memory Banks` section after the existing `// MARK: - Memory` section:

```swift
// MARK: - Memory Banks

func bankTapped(index: Int, banks: [MemoryBank?]) -> [MemoryBank?] {
    var updated = banks

    if let bank = banks[index] {
        // Bank is filled: recall the value
        let measurement = Measurement(numerator: bank.numerator, denominator: bank.denominator)
        state.currentResult = measurement
        state.inputBuffer = ""
        updateDisplay(measurement)
    } else {
        // Bank is empty: store current value
        finalizeInputIfNeeded()
        guard let current = state.currentResult else { return updated }
        updated[index] = MemoryBank(
            numerator: current.numerator,
            denominator: current.denominator,
            displayMode: state.displayMode
        )
    }

    return updated
}

func bankCleared(index: Int, banks: [MemoryBank?]) -> [MemoryBank?] {
    var updated = banks
    updated[index] = nil
    return updated
}
```

- [ ] **Step 3: Verify the project builds**

Run: `xcodebuild -project FracCalc.xcodeproj -scheme FracCalc -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add FracCalc/ViewModels/CalculatorViewModel.swift
git commit -m "feat: add bank store/recall/clear logic to CalculatorViewModel"
```

---

### Task 3: Add memory banks row to KeypadView

**Files:**
- Modify: `FracCalc/Views/KeypadView.swift`

- [ ] **Step 1: Add banks property and update callback to KeypadView**

Add two new properties to `KeypadView` after `customHotkeys`:

```swift
var memoryBanks: [MemoryBank?] = [nil, nil, nil, nil]
var onBanksChanged: (([MemoryBank?]) -> Void)?
```

- [ ] **Step 2: Add the MemoryBankButton view**

Add a new private view inside `KeypadView` (below the `keyButton` function, before the closing brace of the struct) that handles tap, long-press context menu, and displays the bank state:

```swift
private func memoryBankButton(index: Int) -> some View {
    let bank = memoryBanks[index]
    let label = "M\(index + 1)"

    return Button {
        let updated = viewModel.bankTapped(index: index, banks: memoryBanks)
        onBanksChanged?(updated)
    } label: {
        VStack(spacing: 1) {
            if let bank = bank {
                let m = Measurement(numerator: bank.numerator, denominator: bank.denominator)
                Text(CalculatorViewModel.formatMeasurement(m, mode: bank.displayMode))
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.7))
            } else {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bank != nil ? Color.indigo : Color.gray.opacity(0.5))
        .foregroundColor(.white)
        .cornerRadius(8)
    }
    .contextMenu {
        if let bank = bank {
            let m = Measurement(numerator: bank.numerator, denominator: bank.denominator)
            Text(CalculatorViewModel.formatMeasurement(m, mode: bank.displayMode))
            Button(role: .destructive) {
                let updated = viewModel.bankCleared(index: index, banks: memoryBanks)
                onBanksChanged?(updated)
            } label: {
                Label("Clear", systemImage: "trash")
            }
        }
    }
}
```

- [ ] **Step 3: Add the memory banks row**

Add a computed property for the row:

```swift
private var memoryBanksRow: some View {
    HStack(spacing: 8) {
        ForEach(0..<4, id: \.self) { index in
            memoryBankButton(index: index)
        }
    }
    .frame(height: 48)
}
```

- [ ] **Step 4: Insert the row into the body**

Update the `body` to include `memoryBanksRow` between the hotkeys and the digit grid:

```swift
var body: some View {
    VStack(spacing: 8) {
        fractionHotkeyRow
        if !customHotkeys.isEmpty {
            customHotkeyRow
        }
        memoryBanksRow
        digitAndOperatorGrid
        bottomRow
    }
    .padding(8)
}
```

- [ ] **Step 5: Verify the project builds**

Run: `xcodebuild -project FracCalc.xcodeproj -scheme FracCalc -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add FracCalc/Views/KeypadView.swift
git commit -m "feat: add memory banks row to KeypadView"
```

---

### Task 4: Wire up @AppStorage in CalculatorView

**Files:**
- Modify: `FracCalc/Views/CalculatorView.swift`

- [ ] **Step 1: Add @AppStorage property**

Add the following after the existing `@AppStorage("customHotkeys")` line:

```swift
@AppStorage("memoryBanks") private var memoryBanksJSON: String = "[null,null,null,null]"
```

- [ ] **Step 2: Add decode computed property**

Add the following computed property after the existing `customHotkeys` computed property:

```swift
private var memoryBanks: [MemoryBank?] {
    guard let data = memoryBanksJSON.data(using: .utf8),
          let decoded = try? JSONDecoder().decode([MemoryBank?].self, from: data) else {
        return [nil, nil, nil, nil]
    }
    return decoded
}

private func saveMemoryBanks(_ banks: [MemoryBank?]) {
    guard let data = try? JSONEncoder().encode(banks),
          let json = String(data: data, encoding: .utf8) else { return }
    memoryBanksJSON = json
}
```

- [ ] **Step 3: Pass banks to KeypadView**

Update the `KeypadView` initializer call to pass the banks and callback:

```swift
KeypadView(
    viewModel: viewModel,
    fractionHotkeys: [(1, 2), (1, 4), (1, 8), (1, 16)],
    customHotkeys: customHotkeys,
    memoryBanks: memoryBanks,
    onBanksChanged: saveMemoryBanks
)
```

- [ ] **Step 4: Verify the project builds**

Run: `xcodebuild -project FracCalc.xcodeproj -scheme FracCalc -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add FracCalc/Views/CalculatorView.swift
git commit -m "feat: wire up persistent memory banks storage in CalculatorView"
```

---

### Task 5: Manual testing in Simulator

- [ ] **Step 1: Build and launch in Simulator**

Run: `xcodebuild -project FracCalc.xcodeproj -scheme FracCalc -destination 'platform=iOS Simulator,name=iPhone 16' build` then launch in Simulator.

- [ ] **Step 2: Test store into empty bank**

1. Type `2'` and press `=` (or just type `24"` so there's a currentResult)
2. Tap M1 — button should change from dimmed "M1" to showing `2'` (or `24"`) with indigo background
3. Tap C to clear — M1 should still show the stored value

- [ ] **Step 3: Test recall from filled bank**

1. Type `3` then press `×`
2. Tap M1 — display should show the stored value
3. Press `=` — should compute `3 × [stored value]`

- [ ] **Step 4: Test store raw input (no equals)**

1. Type `5' 6"` (don't press `=`)
2. Tap M2 — should finalize the input and store `5' 6"` into M2

- [ ] **Step 5: Test long-press to clear**

1. Long-press M1 — context menu should appear showing the full value and a "Clear" button
2. Tap "Clear" — M1 should revert to dimmed placeholder
3. Long-press M2 (filled) — should show full value and Clear option
4. Long-press M3 (empty) — no context menu should appear

- [ ] **Step 6: Test persistence across app restart**

1. Store values in M1 and M2
2. Force-quit the app in Simulator
3. Relaunch — M1 and M2 should still show their stored values

- [ ] **Step 7: Commit if any fixes were needed**

```bash
git add -A
git commit -m "fix: address issues found during memory banks testing"
```
