# Persistent Memory Banks

## Overview

Four persistent memory bank slots (M1-M4) that store measurement values across app sessions. Unlike the existing cumulative memory (M+/MR/MC), these are direct store/recall slots with long-press-to-clear UX.

## Data Model

### MemoryBank struct

```swift
struct MemoryBank: Codable, Equatable {
    let numerator: Int64
    let denominator: Int64
    let displayMode: String  // DisplayMode raw value
}
```

A bank stores the raw `Measurement` (numerator/denominator pair) plus the `DisplayMode` that was active when the value was stored. This preserves the original formatting for display on the button label.

### Persistence

- `@AppStorage("memoryBanks")` as a JSON-encoded string of `[MemoryBank?]` with length 4.
- Default value: `"[null,null,null,null]"`.
- Follows the same pattern as the existing `@AppStorage("customHotkeys")`.
- `DisplayMode` gains `Codable` conformance (trivial since it is already `RawRepresentable` with `String`).

### Ownership

`CalculatorView` owns the `@AppStorage` property and handles JSON encode/decode. The decoded `[MemoryBank?]` array is passed to `KeypadView` for rendering. Mutations flow through the view model methods, which call back to update the stored JSON via a binding or closure.

## View Layout

Top-to-bottom order in `KeypadView`:

1. Preset fraction hotkeys (1/2, 1/4, 1/8, 1/16)
2. Custom fraction hotkeys (if configured)
3. **Memory banks row** - 4 equal-width buttons (M1, M2, M3, M4)
4. Digit/operator grid
5. Bottom row (backspace, sign, format toggles, MC, MR, M+)

### Button Appearance

**Empty bank:** Label shows `M1`/`M2`/`M3`/`M4` in a dimmed style.

**Filled bank:** Shows the stored value formatted in its *original* display mode (the mode active when stored), truncated to fit. Uses `.lineLimit(1)` and `.minimumScaleFactor(0.5)` so SwiftUI auto-shrinks text to fit the fixed button width. The bank label (M1, etc.) appears as a small superscript or subtitle.

## Interactions

### Tap

| Bank state | Calculator has result? | Behavior |
|---|---|---|
| Empty | Yes | Store `currentResult` + current `displayMode` into the bank. If `inputBuffer` is non-empty but `currentResult` is nil, finalize input first via `finalizeInputIfNeeded`. |
| Empty | No | No-op |
| Filled | (any) | Recall: set `currentResult` to the bank's measurement, clear `inputBuffer`, update display using the *calculator's current* display mode (not the bank's stored mode). Behaves like MR. |

### Long-press (filled bank)

Standard iOS `.contextMenu` with:
- A label row showing the full formatted value in the bank's stored display mode
- A "Clear" destructive button that sets the bank slot to nil

### Long-press (empty bank)

No context menu (nothing to act on).

## ViewModel Changes

New methods on `CalculatorViewModel`:

- `bankTapped(index: Int, banks: [MemoryBank?]) -> [MemoryBank?]` - Handles store-or-recall logic. Returns updated banks array for persistence.
- `bankCleared(index: Int, banks: [MemoryBank?]) -> [MemoryBank?]` - Sets slot to nil. Returns updated banks array.

The view model does not own `@AppStorage` directly (consistent with existing patterns where `maxDenominator` is passed in from `CalculatorView`).

## Files Changed

- `FracCalc/Models/CalculatorState.swift` - Add `MemoryBank` struct, `Codable` conformance on `DisplayMode`
- `FracCalc/ViewModels/CalculatorViewModel.swift` - Add `bankTapped` and `bankCleared` methods
- `FracCalc/Views/KeypadView.swift` - Add memory banks row, accept banks array as parameter
- `FracCalc/Views/CalculatorView.swift` - Add `@AppStorage("memoryBanks")`, decode/encode logic, pass to KeypadView
