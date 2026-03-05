import Foundation

/// Thin Swift wrapper around the Rust fraccalc_core uniffi bindings.
/// Provides a more Swifty API surface.
struct FracCalcBridge {
    static func add(_ a: Measurement, _ b: Measurement) -> Measurement {
        fraccalc_core.add(a: a, b: b)
    }

    static func subtract(_ a: Measurement, _ b: Measurement) -> Measurement {
        fraccalc_core.subtract(a: a, b: b)
    }

    static func multiply(_ a: Measurement, by scalar: Int64) -> Measurement {
        fraccalc_core.multiply(a: a, scalar: scalar)
    }

    static func divide(_ a: Measurement, by scalar: Int64) -> Measurement {
        fraccalc_core.divide(a: a, scalar: scalar)
    }

    static func parse(_ input: String) throws -> Measurement {
        try fraccalc_core.parseMeasurement(input: input)
    }

    static func formatFeetInches(_ m: Measurement) -> String {
        fraccalc_core.formatFeetInches(m: m)
    }

    static func formatInchesOnly(_ m: Measurement) -> String {
        fraccalc_core.formatInchesOnly(m: m)
    }

    static func snap(_ m: Measurement, maxDenominator: Int64) -> SnapResult {
        fraccalc_core.snapToPrecision(m: m, maxDenominator: maxDenominator)
    }
}
