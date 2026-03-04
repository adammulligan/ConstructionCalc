use crate::measurement::Measurement;

#[derive(Debug, Clone, Copy, PartialEq, Eq, uniffi::Record)]
pub struct SnapResult {
    pub value: Measurement,
    pub is_approximate: bool,
}

/// Simplify a measurement to lowest terms.
#[uniffi::export]
pub fn simplify(m: Measurement, max_denominator: i64) -> Measurement {
    let g = gcd(m.numerator.unsigned_abs(), m.denominator.unsigned_abs());
    let num = m.numerator / g as i64;
    let den = m.denominator / g as i64;

    if den > max_denominator {
        let snapped = snap_to_precision(m, max_denominator);
        return snapped.value;
    }

    Measurement { numerator: num, denominator: den }
}

/// Snap to nearest representable value at given precision.
/// Returns SnapResult with value and whether it's approximate.
#[uniffi::export]
pub fn snap_to_precision(m: Measurement, max_denominator: i64) -> SnapResult {
    let scaled = m.numerator as f64 * max_denominator as f64 / m.denominator as f64;
    let rounded = scaled.round() as i64;

    let exact = (rounded * m.denominator) == (m.numerator * max_denominator);

    let g = gcd(rounded.unsigned_abs(), max_denominator.unsigned_abs());
    let num = rounded / g as i64;
    let den = max_denominator / g as i64;

    SnapResult {
        value: Measurement { numerator: num, denominator: den },
        is_approximate: !exact,
    }
}

fn gcd(mut a: u64, mut b: u64) -> u64 {
    while b != 0 {
        let t = b;
        b = a % b;
        a = t;
    }
    a
}
