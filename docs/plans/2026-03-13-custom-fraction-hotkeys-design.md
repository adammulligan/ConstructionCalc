# Custom Fraction Hotkeys — Design

**Goal:** Let users configure up to 4 custom fraction hotkey buttons on the calculator keypad.

## Keypad Layout

```
Row 1 (fixed, purple):    [1/2] [1/4] [1/8] [1/16]
Row 2 (custom, teal):     [3/8] [5/8] [3/16] [7/16]   ← user-configured, 0-4 buttons
─────────────────────────────────────────────────────
[7] [8] [9] [÷] [']
...rest of keypad...
```

- Row 2 is hidden when the user has no custom fractions configured.
- Custom buttons use teal color to distinguish from the fixed purple row.
- Both rows call the same `fractionHotkeyPressed(numerator:denominator:)` method.

## Settings UI

- **Selected list** at top showing current custom fractions with ✕ remove buttons.
- **Preset grid** of common fractions (1/3, 3/8, 5/8, 7/8, 3/16, 5/16, 7/16, 9/16, 3/32, 5/32, 7/32) — tap to toggle.
- **"Add custom fraction"** button — alert with numerator/denominator text fields for unusual fractions.
- Max 4 enforced — add buttons disabled when at capacity.

## Persistence

`@AppStorage("customHotkeys")` stores JSON-encoded `[(Int, Int)]` array. Decoded in `CalculatorView`, passed to `KeypadView`.

## Data Flow

`SettingsView` writes to `@AppStorage` → `CalculatorView` reads and decodes → `KeypadView` receives `customHotkeys` array → buttons call `fractionHotkeyPressed`.
