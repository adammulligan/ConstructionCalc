# FracCalc - Construction Calculator

iOS construction calculator with fractional imperial arithmetic (feet, inches, fractions), powered by a shared Rust core.

## Architecture

```
fraccalc-core/  (Rust crate)  -->  uniffi bindings  -->  FracCalc/ (SwiftUI iOS app)
```

- **Rust core** (`fraccalc-core/`): Exact rational arithmetic using `i64` numerator/denominator pairs. No floating point. Handles parsing, formatting, precision snapping, and all math operations.
- **uniffi** (v0.29): Generates Swift bindings + C FFI header from Rust. Produces an XCFramework for iOS device + simulator.
- **Swift app** (`FracCalc/`): SwiftUI with `@Observable` view models, SwiftData for history persistence.

## Key Technical Details

### uniffi quirks
- uniffi generates **top-level Swift functions**, NOT namespaced under a module. Call `parseMeasurement(input:)` directly, not `fraccalc_core.parseMeasurement(...)`.
- uniffi does not support tuple returns. Use `#[derive(uniffi::Record)]` structs instead (see `SnapResult`).
- `FracCalcBridge.swift` wraps the raw uniffi functions with clearer names to avoid Swift naming collisions.

### Rust crate
- `crate-type = ["lib", "staticlib", "cdylib"]` — all three are needed. `lib` for integration tests, `staticlib` for iOS linking, `cdylib` for uniffi bindgen.
- 42 tests: unit tests for measurement/parser/formatter/precision + property-based tests with `proptest`.
- Run tests: `cargo test --manifest-path fraccalc-core/Cargo.toml`

### Build pipeline
- `./build.sh` builds for 3 iOS targets (device arm64, sim arm64, sim x86_64), merges sim slices with lipo, generates Swift bindings, and creates the XCFramework.
- Requires full Xcode (not just Command Line Tools): `DEVELOPER_DIR` must point to `/Applications/Xcode.app/Contents/Developer`.
- Output: `FracCalc/Frameworks/FracCalcCore.xcframework/` and `bindings/fraccalc_core.swift`.

### iOS app structure
- `FracCalcApp.swift` — entry point with `.modelContainer(for: HistoryEntry.self)`
- `CalculatorView.swift` — main view, wires up model context + AppStorage settings
- `CalculatorViewModel.swift` — state machine handling all calculator logic
- `CalculatorState.swift` — enums (`Operator`, `InputMode`, `DisplayFormat`) and state struct
- `KeypadView.swift` — digit grid, operator buttons, fraction hotkey rows
- `DisplayView.swift` — monospaced display with memory indicator
- `FracCalcBridge.swift` — thin wrapper over uniffi-generated functions
- `HistoryEntry.swift` — SwiftData `@Model` for calculation history
- `SettingsView.swift` — precision picker + custom fraction hotkeys config
- `FracCalc-Bridging-Header.h` — includes `fraccalc_coreFFI.h`

### Xcode project setup
- The `.xcodeproj` references files in-place (does not copy them into the project).
- The XCFramework and generated Swift binding must be added to the Xcode project manually after running `build.sh`.
- Bridging header path must be set in Build Settings.

## Persistence
- **History**: SwiftData (`HistoryEntry` model) — entries saved on each `=` press.
- **Settings**: `@AppStorage` — `maxDenominator` (Int), `customHotkeys` (JSON-encoded `[[Int]]`).

## Plans & Docs
- `docs/plans/2026-03-04-fraccalc-design.md` — original design spec
- `docs/plans/2026-03-04-fraccalc-implementation.md` — 14-task implementation plan (completed)
- `docs/plans/2026-03-13-custom-fraction-hotkeys-design.md` — custom hotkeys feature design

## Common Commands
```bash
# Run Rust tests
cargo test --manifest-path fraccalc-core/Cargo.toml

# Rebuild XCFramework + bindings after Rust changes
./build.sh

# Then rebuild in Xcode (Cmd+B) or xcodebuild
```
