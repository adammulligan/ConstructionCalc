use crate::measurement::Measurement;

/// Format as feet and inches: "3' 5-3/8\""
/// Omits zero parts (e.g., "3'" not "3' 0\"", "3/8\"" not "0' 3/8\"").
#[uniffi::export]
pub fn format_feet_inches(m: Measurement) -> String {
    let negative = m.numerator < 0;
    let abs_num = m.numerator.abs();
    let den = m.denominator;

    let total_inches = abs_num / den;
    let frac_num = abs_num % den;

    let feet = total_inches / 12;
    let inches = total_inches % 12;

    let sign = if negative { "-" } else { "" };

    match (feet, inches, frac_num) {
        (0, 0, 0) => "0\"".to_string(),
        (0, 0, f) => format!("{sign}{f}/{den}\""),
        (0, i, 0) => format!("{sign}{i}\""),
        (0, i, f) => format!("{sign}{i}-{f}/{den}\""),
        (ft, 0, 0) => format!("{sign}{ft}'"),
        (ft, 0, f) => format!("{sign}{ft}' {f}/{den}\""),
        (ft, i, 0) => format!("{sign}{ft}' {i}\""),
        (ft, i, f) => format!("{sign}{ft}' {i}-{f}/{den}\""),
    }
}

/// Format as inches only: "41-3/8\""
#[uniffi::export]
pub fn format_inches_only(m: Measurement) -> String {
    let negative = m.numerator < 0;
    let abs_num = m.numerator.abs();
    let den = m.denominator;

    let whole = abs_num / den;
    let frac_num = abs_num % den;

    let sign = if negative { "-" } else { "" };

    match (whole, frac_num) {
        (0, 0) => "0\"".to_string(),
        (0, f) => format!("{sign}{f}/{den}\""),
        (w, 0) => format!("{sign}{w}\""),
        (w, f) => format!("{sign}{w}-{f}/{den}\""),
    }
}
