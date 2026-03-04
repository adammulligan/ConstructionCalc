# FracCalc: Imperial Fractional Construction Calculator

**Date:** 2026-03-04
**Status:** Approved

## Overview

A native iOS calculator focused on fractional arithmetic for US construction trades. Users perform quick field math with imperial measurements (feet, inches, fractions) using a custom keypad. A shared Rust arithmetic engine enables future Android support.

## Architecture

```
┌──────────────────────┐      ┌──────────────────────┐
│   SwiftUI iOS App    │      │  Future: Compose App  │
│   (native UI)        │      │  (native UI)          │
└────────┬─────────────┘      └────────┬──────────────┘
         │ uniffi bindings             │ uniffi bindings
         └────────────┬────────────────┘
                      │
              ┌───────▼───────┐
              │ fraccalc-core │
              │  (Rust crate) │
              └───────────────┘
```

## Rust Core (`fraccalc-core`)

### Data Model

A `Measurement` is a rational number of inches:

```rust
struct Measurement {
    numerator: i64,
    denominator: i64, // always a power of 2
}
```

No `feet` field — feet are purely a display formatting concern. `3' 5-3/8"` is internally `41/8` (inches).

### Operations

- `add(a, b) -> Measurement`
- `subtract(a, b) -> Measurement`
- `multiply(a, scalar) -> Measurement`
- `divide(a, scalar) -> Measurement`
- `divide_measurements(a, b) -> f64` (dimensionless ratio)
- `simplify(m, max_denominator) -> Measurement`
- `snap_to_precision(m, max_denominator) -> (Measurement, bool)` — nearest representable value + approximate flag

All arithmetic is exact integer math. No floating point except `divide_measurements`.

### Parser

Lenient input parsing — accepts:
- `3' 5-3/8"`
- `3ft 5-3/8in`
- `41/8`
- `5.375"`

### Formatter

Two output modes:
- Feet + inches: `10' 1-1/2"`
- Inches only: `121-1/2"`

Default matches input style; user can toggle with a feet↔inches button.

Fractions simplify to lowest terms but never exceed the configured max denominator. Results that can't be exactly represented show an approximate indicator.

### Crate Structure

```
fraccalc-core/
├── src/
│   ├── lib.rs           // uniffi exports
│   ├── measurement.rs   // Measurement type, arithmetic ops
│   ├── parser.rs        // input string → Measurement
│   ├── formatter.rs     // Measurement → display string
│   └── precision.rs     // simplification, snapping, precision config
├── tests/
├── Cargo.toml
└── uniffi.toml
```

Property-based testing (proptest/quickcheck) for arithmetic invariants.

## iOS App (SwiftUI)

### Project Structure

```
FracCalc/
├── FracCalcApp.swift
├── Views/
│   ├── CalculatorView.swift       // main screen
│   ├── DisplayView.swift          // result + format toggle
│   ├── KeypadView.swift           // custom keypad (composed from sub-views)
│   └── HistoryView.swift          // scrollable history
├── ViewModels/
│   ├── CalculatorViewModel.swift  // calculator state machine
│   └── HistoryViewModel.swift
├── Models/
│   ├── CalculatorState.swift
│   └── HistoryEntry.swift
├── Services/
│   ├── FracCalcBridge.swift       // wrapper around uniffi bindings
│   └── PersistenceService.swift   // SwiftData
└── Settings/
    └── SettingsView.swift         // precision, hotkey config
```

### Keypad Layout

Composed from independent sub-views (`FractionHotkeysRow`, `DigitGrid`, `OperatorColumn`, `UnitKeys`) arranged in a VStack. Layout is flexible — sub-views can be reordered freely.

```
┌─────────────────────────────────┐
│         DisplayView             │
├─────────────────────────────────┤
│   [1/2] [1/4] [1/8] [1/16]     │  ← configurable fraction hotkeys
├─────────────────────────────────┤
│ [7] [8] [9]  [÷]  [']          │
│ [4] [5] [6]  [×]  ["]          │
│ [1] [2] [3]  [−]  [/]          │
│ [0] [.] [=]  [+]  [C]          │
└─────────────────────────────────┘
```

Keys: digits, operators (+−×÷=), unit markers (' and "), fraction slash (/), configurable fraction hotkeys, C (clear), backspace, ±, feet↔inches toggle.

### Calculator State Machine

```
Idle → Entering First Operand → Operator Selected → Entering Second Operand → Result
  ↑                                                                            │
  └────────────────────── (chain or clear) ────────────────────────────────────┘
```

### Memory Functions

M+ (add to memory), M− (subtract from memory), MR (recall), MC (clear memory).

## History & Persistence

### HistoryEntry Model (SwiftData)

```
HistoryEntry {
    id: UUID
    expression: String
    resultNumerator: Int64
    resultDenominator: Int64
    displayFormat: .feetInches | .inchesOnly
    timestamp: Date
}
```

### Behavior

- Scrollable list (slide-up sheet or tab — TBD)
- Tap entry to load result as current operand
- Swipe to delete, "Clear All" option
- Local persistence only, no sync

## Settings (UserDefaults)

- Max precision: denominator of 2, 4, 8, 16, or 32
- Fraction hotkeys: which buttons to show
- Default display format preference

## Scope

### v1 (In Scope)

- Rust `fraccalc-core` with uniffi Swift bindings
- Native SwiftUI iOS app with custom keypad
- Four arithmetic operations on imperial measurements
- Configurable precision (1/2 through 1/32)
- Customizable fraction hotkeys
- Feet↔inches display toggle
- Memory functions (M+, M−, MR, MC)
- Calculation history with local persistence
- Tap history to reuse result

### Out of Scope (Future)

- Android app (Kotlin/Compose with same Rust crate)
- Area/volume calculations
- Unit conversions (board feet, square footage)
- iCloud sync
- History export
- Customizable keypad layout arrangement
- Monetization infrastructure
- Widgets / Apple Watch
