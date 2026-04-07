import Foundation

/// Thin Swift wrapper around the Rust fraccalc_core uniffi bindings.
/// uniffi generates top-level functions and types (no namespace),
/// so we call them directly here.
struct FracCalcBridge {
    // Note: The uniffi-generated `Measurement` type shadows Foundation's
    // `Measurement` type. This is fine since we only use the Rust one.

    static func addMeasurements(_ a: Measurement, _ b: Measurement) -> Measurement {
        add(a: a, b: b)
    }

    static func subtractMeasurements(_ a: Measurement, _ b: Measurement) -> Measurement {
        subtract(a: a, b: b)
    }

    static func multiplyMeasurement(_ a: Measurement, by scalar: Int64) -> Measurement {
        multiply(a: a, scalar: scalar)
    }

    static func divideMeasurement(_ a: Measurement, by scalar: Int64) -> Measurement {
        divide(a: a, scalar: scalar)
    }

    static func parse(_ input: String) throws -> Measurement {
        try parseMeasurement(input: input)
    }

    static func fmtFeetInches(_ m: Measurement) -> String {
        formatFeetInches(m: m)
    }

    static func fmtInchesOnly(_ m: Measurement) -> String {
        formatInchesOnly(m: m)
    }

    static func fmtDecimal(_ m: Measurement) -> String {
    formatDecimal(m: m)
    }

    static func snap(_ m: Measurement, maxDenominator: Int64) -> SnapResult {
        snapToPrecision(m: m, maxDenominator: maxDenominator)
    }
}
