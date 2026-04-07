use crate::measurement::Measurement;
use thiserror::Error;

#[derive(Debug, Error, uniffi::Error)]
pub enum ParseError {
    #[error("Invalid measurement format: {input}")]
    InvalidFormat { input: String },
}

/// Parse a string like "3' 5-3/8\"" into a Measurement.
///
/// Accepted formats:
/// - "5" or "5\"" (inches)
/// - "3'" or "3ft" (feet)
/// - "3' 5\"" or "3ft 5in" (feet and inches)
/// - "3' 5-3/8\"" (feet, inches, fraction)
/// - "5-3/8\"" or "5-3/8" (inches with fraction)
/// - "5\"3/8" (inches with fraction, " as delimiter)
/// - "3/8" (fraction only)
/// - Negative values with leading "-"
#[uniffi::export]
pub fn parse_measurement(input: &str) -> Result<Measurement, ParseError> {
    let input = input.trim();
    if input.is_empty() {
        return Err(ParseError::InvalidFormat { input: input.to_string() });
    }

    // Handle negative sign
    let (negative, input) = if let Some(rest) = input.strip_prefix('-') {
        (true, rest.trim_start())
    } else {
        (false, input)
    };

    // Normalize ft/in suffixes to '/"
    let input = input.replace("ft", "'").replace("in", "\"");
    let input = input.trim();

    let mut feet_num: i64 = 0;
    let mut feet_den: i64 = 1;
    let mut inch_whole: i64 = 0;
    let mut frac_num: i64 = 0;
    let mut frac_den: i64 = 1;
    let mut has_any = false;

    let remaining_ref = if let Some(tick_pos) = input.find('\'') {
        let feet_str = input[..tick_pos].trim();
        let (n, d) = parse_decimal_or_int(feet_str).ok_or_else(|| ParseError::InvalidFormat {
            input: input.to_string(),
        })?;
        feet_num = n;
        feet_den = d;
        has_any = true;
        input[tick_pos + 1..].trim().trim_end_matches('"').trim()
    } else {
        input.trim_end_matches('"').trim()
    };

    // Handle "2"3/16" format: interior " acts as inches-fraction delimiter (like dash)
    let remaining_owned;
    let remaining = if let Some(quote_pos) = remaining_ref.find('"') {
        remaining_owned = format!("{}-{}", &remaining_ref[..quote_pos], &remaining_ref[quote_pos + 1..]);
        remaining_owned.as_str()
    } else {
        remaining_ref
    };

    if !remaining.is_empty() {
        if let Some(dash_pos) = remaining.find('-') {
            // "5-3/8"
            let whole_str = &remaining[..dash_pos];
            let frac_str = &remaining[dash_pos + 1..];

            inch_whole = whole_str.parse::<i64>().map_err(|_| ParseError::InvalidFormat {
                input: input.to_string(),
            })?;

            let (n, d) = parse_fraction(frac_str).ok_or_else(|| ParseError::InvalidFormat {
                input: input.to_string(),
            })?;
            frac_num = n;
            frac_den = d;
            has_any = true;
        } else if remaining.contains('/') {
            // Pure fraction "3/8"
            let (n, d) = parse_fraction(remaining).ok_or_else(|| ParseError::InvalidFormat {
                input: input.to_string(),
            })?;
            frac_num = n;
            frac_den = d;
            has_any = true;
        } else if remaining.contains('.') {
            // Decimal inches "1.5"
            let (n, d) = parse_decimal_or_int(remaining).ok_or_else(|| ParseError::InvalidFormat {
                input: input.to_string(),
            })?;
            // Treat as fractional inches: n/d inches
            frac_num = n;
            frac_den = d;
            inch_whole = 0;
            has_any = true;
        } else {
            // Whole inches "5"
            inch_whole = remaining.parse::<i64>().map_err(|_| ParseError::InvalidFormat {
                input: input.to_string(),
            })?;
            has_any = true;
        }
    }

    if !has_any {
        return Err(ParseError::InvalidFormat { input: input.to_string() });
    }

    // Convert feet to inches: feet_num/feet_den feet = feet_num*12/feet_den inches
    // Combine with inch_whole and frac_num/frac_den
    // Total = (feet_num * 12) / feet_den + inch_whole + frac_num / frac_den
    let sign = if negative { -1 } else { 1 };

    // Common denominator: feet_den * frac_den
    let common_den = feet_den * frac_den;
    let total_num = feet_num * 12 * frac_den + (inch_whole * frac_den + frac_num) * feet_den;

    Ok(Measurement::normalize(total_num * sign, common_den))
}

/// Parse a string as either a decimal ("1.5") or integer ("3"), returning (numerator, denominator).
fn parse_decimal_or_int(s: &str) -> Option<(i64, i64)> {
    let s = s.trim();
    if let Some(dot_pos) = s.find('.') {
        let int_part = &s[..dot_pos];
        let dec_part = &s[dot_pos + 1..];
        if dec_part.is_empty() {
            // Trailing dot like "3." — treat as integer
            let n = int_part.parse::<i64>().ok()?;
            return Some((n, 1));
        }
        let dec_digits = dec_part.len() as u32;
        let denominator = 10_i64.pow(dec_digits);
        let int_val = if int_part.is_empty() { 0 } else { int_part.parse::<i64>().ok()? };
        let dec_val = dec_part.parse::<i64>().ok()?;
        let numerator = int_val * denominator + dec_val;
        Some((numerator, denominator))
    } else {
        let n = s.parse::<i64>().ok()?;
        Some((n, 1))
    }
}

fn parse_fraction(s: &str) -> Option<(i64, i64)> {
    let parts: Vec<&str> = s.split('/').collect();
    if parts.len() != 2 {
        return None;
    }
    let num = parts[0].trim().parse::<i64>().ok()?;
    let den = parts[1].trim().parse::<i64>().ok()?;
    if den == 0 {
        return None;
    }
    Some((num, den))
}
