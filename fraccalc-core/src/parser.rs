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

    let mut feet: i64 = 0;
    let mut inch_whole: i64 = 0;
    let mut frac_num: i64 = 0;
    let mut frac_den: i64 = 1;
    let mut has_any = false;

    let remaining = if let Some(tick_pos) = input.find('\'') {
        let feet_str = input[..tick_pos].trim();
        feet = feet_str.parse::<i64>().map_err(|_| ParseError::InvalidFormat {
            input: input.to_string(),
        })?;
        has_any = true;
        input[tick_pos + 1..].trim().trim_end_matches('"').trim()
    } else {
        input.trim_end_matches('"').trim()
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

    let total_num = (feet * 12 + inch_whole) * frac_den + frac_num;
    let sign = if negative { -1 } else { 1 };

    Ok(Measurement::normalize(total_num * sign, frac_den))
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
