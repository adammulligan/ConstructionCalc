# FracCalc Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build an iOS construction calculator with fractional imperial arithmetic, powered by a shared Rust core.

**Architecture:** Rust `fraccalc-core` crate handles all arithmetic, parsing, and formatting via exact integer math. Swift/iOS app consumes it via uniffi-generated bindings. Custom keypad UI with configurable fraction hotkeys.

**Tech Stack:** Rust (core engine, uniffi), Swift/SwiftUI (iOS app), SwiftData (history persistence), cargo-swift or manual XCFramework build.

**Design doc:** `docs/plans/2026-03-04-fraccalc-design.md`

---

## Task 1: Project Scaffolding

**Files:**
- Create: `fraccalc-core/Cargo.toml`
- Create: `fraccalc-core/src/lib.rs`
- Create: `fraccalc-core/src/bin/uniffi-bindgen.rs`
- Create: `fraccalc-core/src/measurement.rs`
- Create: `fraccalc-core/src/parser.rs`
- Create: `fraccalc-core/src/formatter.rs`
- Create: `fraccalc-core/src/precision.rs`
- Create: `build.sh`

**Step 1: Create the Rust crate**

```bash
cd /Users/ammullig/src
mkdir -p fraccalc-core/src/bin
```

**Step 2: Write Cargo.toml**

```toml
# fraccalc-core/Cargo.toml
[package]
name = "fraccalc-core"
version = "0.1.0"
edition = "2021"

[lib]
name = "fraccalc_core"
crate-type = ["staticlib", "cdylib"]

[[bin]]
name = "uniffi-bindgen"
path = "src/bin/uniffi-bindgen.rs"

[dependencies]
uniffi = { version = "0.29", features = ["cli"] }
thiserror = "2"

[dev-dependencies]
proptest = "1"

[build-dependencies]
uniffi = { version = "0.29", features = ["build"] }

[profile.release]
opt-level = "z"
lto = true
strip = true
panic = "abort"
debug = false
```

**Step 3: Write initial source files**

```rust
// fraccalc-core/src/bin/uniffi-bindgen.rs
fn main() {
    uniffi::uniffi_bindgen_main()
}
```

```rust
// fraccalc-core/src/lib.rs
uniffi::setup_scaffolding!();

mod measurement;
mod parser;
mod formatter;
mod precision;

pub use measurement::Measurement;
pub use parser::parse_measurement;
pub use formatter::{format_feet_inches, format_inches_only};
pub use precision::{simplify, snap_to_precision};
```

Create empty module files for `measurement.rs`, `parser.rs`, `formatter.rs`, `precision.rs` with placeholder structs/functions (just enough to compile).

**Step 4: Verify it compiles**

```bash
cd fraccalc-core && cargo build
```

Expected: successful compilation with warnings about unused code.

**Step 5: Initialize git repo and commit**

```bash
cd /Users/ammullig/src
git init fraccalc
# Move fraccalc-core into fraccalc/ and set up repo structure
git add -A
git commit -m "chore: scaffold fraccalc-core Rust crate with uniffi"
```

---

## Task 2: Measurement Type + Basic Arithmetic (TDD)

**Files:**
- Modify: `fraccalc-core/src/measurement.rs`
- Create: `fraccalc-core/tests/measurement_tests.rs`

**Step 1: Write failing tests for Measurement construction and normalization**

```rust
// fraccalc-core/tests/measurement_tests.rs
use fraccalc_core::Measurement;

#[test]
fn test_new_whole_inches() {
    let m = Measurement::from_inches(5);
    assert_eq!(m.numerator(), 5);
    assert_eq!(m.denominator(), 1);
}

#[test]
fn test_new_fractional_inches() {
    let m = Measurement::from_fraction(3, 8);
    assert_eq!(m.numerator(), 3);
    assert_eq!(m.denominator(), 8);
}

#[test]
fn test_from_feet_and_inches() {
    // 3' 5" = 41 inches
    let m = Measurement::from_feet_inches(3, 5, 0, 1);
    assert_eq!(m.numerator(), 41);
    assert_eq!(m.denominator(), 1);
}

#[test]
fn test_from_feet_inches_fraction() {
    // 3' 5-3/8" = 41 + 3/8 = 328/8 + 3/8 = 331/8
    let m = Measurement::from_feet_inches(3, 5, 3, 8);
    assert_eq!(m.numerator(), 331);
    assert_eq!(m.denominator(), 8);
}

#[test]
fn test_negative_measurement() {
    let m = Measurement::from_inches(-5);
    assert_eq!(m.numerator(), -5);
    assert_eq!(m.denominator(), 1);
}
```

**Step 2: Run tests to verify they fail**

```bash
cd fraccalc-core && cargo test
```

Expected: compilation errors — `Measurement` type not defined yet.

**Step 3: Implement Measurement type**

```rust
// fraccalc-core/src/measurement.rs
use uniffi;

#[derive(Debug, Clone, Copy, PartialEq, Eq, uniffi::Record)]
pub struct Measurement {
    pub numerator: i64,
    pub denominator: i64,
}

impl Measurement {
    /// Normalize: ensure denominator is positive, reduce to lowest terms
    /// while keeping denominator as a power of 2.
    fn normalize(numerator: i64, denominator: i64) -> Self {
        assert!(denominator > 0, "denominator must be positive");
        // GCD to simplify, but only remove non-power-of-2 factors
        let g = gcd(numerator.unsigned_abs(), denominator.unsigned_abs());
        // Keep denominator as power of 2: only divide by the largest
        // power-of-2 factor of g
        let power_of_2_factor = g & g.wrapping_neg(); // isolate lowest set bit of g
        // Actually, we want to divide both by gcd but preserve power-of-2 denominator
        // Simpler: just divide both by gcd
        let num = numerator / g as i64;
        let den = denominator / g as i64;
        Measurement { numerator: num, denominator: den }
    }

    pub fn from_inches(inches: i64) -> Self {
        Measurement { numerator: inches, denominator: 1 }
    }

    pub fn from_fraction(numerator: i64, denominator: i64) -> Self {
        Self::normalize(numerator, denominator)
    }

    pub fn from_feet_inches(feet: i64, inches: i64, frac_num: i64, frac_den: i64) -> Self {
        let total_inches = feet * 12 + inches;
        let numerator = total_inches * frac_den + frac_num;
        Self::normalize(numerator, frac_den)
    }

    pub fn numerator(&self) -> i64 {
        self.numerator
    }

    pub fn denominator(&self) -> i64 {
        self.denominator
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
```

**Step 4: Run tests to verify they pass**

```bash
cargo test
```

Expected: all 5 tests pass.

**Step 5: Write failing tests for arithmetic operations**

```rust
// Append to fraccalc-core/tests/measurement_tests.rs

#[test]
fn test_add_whole_inches() {
    let a = Measurement::from_inches(5);
    let b = Measurement::from_inches(3);
    let result = fraccalc_core::add(a, b);
    assert_eq!(result, Measurement::from_inches(8));
}

#[test]
fn test_add_fractions() {
    // 3/8 + 1/4 = 3/8 + 2/8 = 5/8
    let a = Measurement::from_fraction(3, 8);
    let b = Measurement::from_fraction(1, 4);
    let result = fraccalc_core::add(a, b);
    assert_eq!(result.numerator(), 5);
    assert_eq!(result.denominator(), 8);
}

#[test]
fn test_add_feet_and_inches() {
    // 3' 5-3/8" + 2' 11-1/2" = 6' 4-7/8"
    let a = Measurement::from_feet_inches(3, 5, 3, 8);
    let b = Measurement::from_feet_inches(2, 11, 1, 2);
    let result = fraccalc_core::add(a, b);
    // 6' 4-7/8" = 76 + 7/8 = 615/8
    assert_eq!(result.numerator(), 615);
    assert_eq!(result.denominator(), 8);
}

#[test]
fn test_subtract() {
    // 10' - 3' 5-1/2" = 6' 6-1/2"
    let a = Measurement::from_feet_inches(10, 0, 0, 1);
    let b = Measurement::from_feet_inches(3, 5, 1, 2);
    let result = fraccalc_core::subtract(a, b);
    // 120 - 41.5 = 78.5 = 157/2
    assert_eq!(result.numerator(), 157);
    assert_eq!(result.denominator(), 2);
}

#[test]
fn test_multiply_by_scalar() {
    // 3' 5-3/8" * 4 = 13' 9-1/2"
    let a = Measurement::from_feet_inches(3, 5, 3, 8);
    let result = fraccalc_core::multiply(a, 4);
    // 331/8 * 4 = 1324/8 = 165.5" = 165-1/2" = 13' 9-1/2"
    assert_eq!(result.numerator(), 331);
    assert_eq!(result.denominator(), 2);
}

#[test]
fn test_divide_by_scalar() {
    // 10' / 3 = 40"
    let a = Measurement::from_feet_inches(10, 0, 0, 1);
    let result = fraccalc_core::divide(a, 3);
    // 120 / 3 = 40
    assert_eq!(result.numerator(), 40);
    assert_eq!(result.denominator(), 1);
}

#[test]
fn test_divide_measurements() {
    // 10' / 3' = 4.0 (dimensionless)
    let a = Measurement::from_feet_inches(10, 0, 0, 1);
    let b = Measurement::from_feet_inches(3, 0, 0, 1);
    let result = fraccalc_core::divide_measurements(a, b);
    assert!((result - 4.0).abs() < 1e-10);
}
```

**Step 6: Run tests to verify they fail**

```bash
cargo test
```

Expected: compilation errors — `add`, `subtract`, `multiply`, `divide`, `divide_measurements` not defined.

**Step 7: Implement arithmetic operations**

```rust
// fraccalc-core/src/measurement.rs (add to bottom of file)

#[uniffi::export]
pub fn add(a: Measurement, b: Measurement) -> Measurement {
    let num = a.numerator * b.denominator + b.numerator * a.denominator;
    let den = a.denominator * b.denominator;
    Measurement::normalize(num, den)
}

#[uniffi::export]
pub fn subtract(a: Measurement, b: Measurement) -> Measurement {
    let num = a.numerator * b.denominator - b.numerator * a.denominator;
    let den = a.denominator * b.denominator;
    Measurement::normalize(num, den)
}

#[uniffi::export]
pub fn multiply(a: Measurement, scalar: i64) -> Measurement {
    Measurement::normalize(a.numerator * scalar, a.denominator)
}

#[uniffi::export]
pub fn divide(a: Measurement, scalar: i64) -> Measurement {
    assert!(scalar != 0, "division by zero");
    Measurement::normalize(a.numerator, a.denominator * scalar)
}

#[uniffi::export]
pub fn divide_measurements(a: Measurement, b: Measurement) -> f64 {
    assert!(b.numerator != 0, "division by zero");
    let num = a.numerator as f64 * b.denominator as f64;
    let den = a.denominator as f64 * b.numerator as f64;
    num / den
}
```

Export these from `lib.rs`:

```rust
pub use measurement::{add, subtract, multiply, divide, divide_measurements};
```

**Step 8: Run tests to verify they pass**

```bash
cargo test
```

Expected: all 12 tests pass.

**Step 9: Commit**

```bash
git add fraccalc-core/src/measurement.rs fraccalc-core/tests/measurement_tests.rs fraccalc-core/src/lib.rs
git commit -m "feat: Measurement type with arithmetic operations (add, sub, mul, div)"
```

---

## Task 3: Precision — Simplification and Snapping (TDD)

**Files:**
- Modify: `fraccalc-core/src/precision.rs`
- Create: `fraccalc-core/tests/precision_tests.rs`

**Step 1: Write failing tests**

```rust
// fraccalc-core/tests/precision_tests.rs
use fraccalc_core::{Measurement, simplify, snap_to_precision};

#[test]
fn test_simplify_already_simple() {
    let m = Measurement::from_fraction(3, 8);
    let result = simplify(m, 32);
    assert_eq!(result.numerator(), 3);
    assert_eq!(result.denominator(), 8);
}

#[test]
fn test_simplify_reducible() {
    // 6/16 -> 3/8
    let m = Measurement { numerator: 6, denominator: 16 };
    let result = simplify(m, 32);
    assert_eq!(result.numerator(), 3);
    assert_eq!(result.denominator(), 8);
}

#[test]
fn test_simplify_respects_max_denominator() {
    // 3/8 with max_denominator=4 -> snap needed
    // 3/8 = 0.375" -> nearest 1/4 = 0.25 or 2/4=0.5 -> 0.375 rounds to 0.5 = 1/2
    // Actually simplify should just reduce, snapping is separate
    let m = Measurement::from_fraction(4, 8);
    let result = simplify(m, 4);
    assert_eq!(result.numerator(), 1);
    assert_eq!(result.denominator(), 2);
}

#[test]
fn test_snap_exact() {
    // 3/8 with max_denominator=8 -> exact, no approximation
    let m = Measurement::from_fraction(3, 8);
    let (result, approx) = snap_to_precision(m, 8);
    assert_eq!(result.numerator(), 3);
    assert_eq!(result.denominator(), 8);
    assert!(!approx);
}

#[test]
fn test_snap_approximate() {
    // 3/32 with max_denominator=16 -> 3/32 = 0.09375
    // nearest 1/16ths: 1/16=0.0625, 2/16=0.125 -> rounds to 2/16 = 1/8
    let m = Measurement::from_fraction(3, 32);
    let (result, approx) = snap_to_precision(m, 16);
    assert_eq!(result.numerator(), 1);
    assert_eq!(result.denominator(), 8); // 2/16 simplified = 1/8
    assert!(approx);
}

#[test]
fn test_snap_whole_number_unaffected() {
    let m = Measurement::from_inches(42);
    let (result, approx) = snap_to_precision(m, 16);
    assert_eq!(result.numerator(), 42);
    assert_eq!(result.denominator(), 1);
    assert!(!approx);
}
```

**Step 2: Run tests to verify they fail**

```bash
cargo test
```

**Step 3: Implement simplify and snap_to_precision**

```rust
// fraccalc-core/src/precision.rs
use crate::measurement::Measurement;

/// Simplify a measurement to lowest terms.
#[uniffi::export]
pub fn simplify(m: Measurement, max_denominator: i64) -> Measurement {
    // First reduce to lowest terms
    let g = gcd(m.numerator.unsigned_abs(), m.denominator.unsigned_abs());
    let mut num = m.numerator / g as i64;
    let mut den = m.denominator / g as i64;

    // If denominator exceeds max, snap to nearest
    if den > max_denominator {
        let (snapped, _) = snap_to_precision(m, max_denominator);
        return snapped;
    }

    Measurement { numerator: num, denominator: den }
}

/// Snap to nearest representable value at given precision.
/// Returns (snapped_measurement, is_approximate).
#[uniffi::export]
pub fn snap_to_precision(m: Measurement, max_denominator: i64) -> (Measurement, bool) {
    // Convert to max_denominator scale
    let scaled = m.numerator as f64 * max_denominator as f64 / m.denominator as f64;
    let rounded = scaled.round() as i64;

    // Check if exact
    let exact = (rounded * m.denominator) == (m.numerator * max_denominator);

    // Simplify the result
    let g = gcd(rounded.unsigned_abs(), max_denominator.unsigned_abs());
    let num = rounded / g as i64;
    let den = max_denominator / g as i64;

    (Measurement { numerator: num, denominator: den }, !exact)
}

fn gcd(mut a: u64, mut b: u64) -> u64 {
    while b != 0 {
        let t = b;
        b = a % b;
        a = t;
    }
    a
}
```

**Step 4: Run tests to verify they pass**

```bash
cargo test
```

Expected: all precision tests pass.

**Step 5: Commit**

```bash
git add fraccalc-core/src/precision.rs fraccalc-core/tests/precision_tests.rs
git commit -m "feat: simplify and snap_to_precision for configurable fraction precision"
```

---

## Task 4: Parser (TDD)

**Files:**
- Modify: `fraccalc-core/src/parser.rs`
- Create: `fraccalc-core/tests/parser_tests.rs`

**Step 1: Write failing tests**

```rust
// fraccalc-core/tests/parser_tests.rs
use fraccalc_core::{Measurement, parse_measurement};

#[test]
fn test_parse_whole_inches() {
    let m = parse_measurement("5\"").unwrap();
    assert_eq!(m, Measurement::from_inches(5));
}

#[test]
fn test_parse_whole_feet() {
    let m = parse_measurement("3'").unwrap();
    // 3' = 36"
    assert_eq!(m.numerator(), 36);
    assert_eq!(m.denominator(), 1);
}

#[test]
fn test_parse_feet_and_inches() {
    let m = parse_measurement("3' 5\"").unwrap();
    assert_eq!(m.numerator(), 41);
    assert_eq!(m.denominator(), 1);
}

#[test]
fn test_parse_feet_inches_fraction() {
    let m = parse_measurement("3' 5-3/8\"").unwrap();
    assert_eq!(m.numerator(), 331);
    assert_eq!(m.denominator(), 8);
}

#[test]
fn test_parse_inches_fraction_only() {
    let m = parse_measurement("5-3/8\"").unwrap();
    assert_eq!(m.numerator(), 43);
    assert_eq!(m.denominator(), 8);
}

#[test]
fn test_parse_fraction_only() {
    let m = parse_measurement("3/8").unwrap();
    assert_eq!(m.numerator(), 3);
    assert_eq!(m.denominator(), 8);
}

#[test]
fn test_parse_bare_number_as_inches() {
    let m = parse_measurement("5").unwrap();
    assert_eq!(m, Measurement::from_inches(5));
}

#[test]
fn test_parse_ft_in_suffix() {
    let m = parse_measurement("3ft 5-3/8in").unwrap();
    assert_eq!(m.numerator(), 331);
    assert_eq!(m.denominator(), 8);
}

#[test]
fn test_parse_negative() {
    let m = parse_measurement("-3' 5\"").unwrap();
    assert_eq!(m.numerator(), -41);
    assert_eq!(m.denominator(), 1);
}

#[test]
fn test_parse_invalid() {
    assert!(parse_measurement("abc").is_err());
}

#[test]
fn test_parse_whitespace_variations() {
    // Should handle with or without spaces
    let m1 = parse_measurement("3'5-3/8\"").unwrap();
    let m2 = parse_measurement("3'  5-3/8\"").unwrap();
    assert_eq!(m1, m2);
}
```

**Step 2: Run tests to verify they fail**

```bash
cargo test
```

**Step 3: Implement parser**

```rust
// fraccalc-core/src/parser.rs
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
    let (negative, input) = if input.starts_with('-') {
        (true, input[1..].trim_start())
    } else {
        (false, input)
    };

    // Normalize ft/in suffixes to '/\"
    let input = input.replace("ft", "'").replace("in", "\"");
    let input = input.trim();

    let mut feet: i64 = 0;
    let mut inch_whole: i64 = 0;
    let mut frac_num: i64 = 0;
    let mut frac_den: i64 = 1;
    let mut has_any = false;

    let remaining = if let Some(tick_pos) = input.find('\'') {
        // Has feet
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
        // Try to parse: "5-3/8" or "5" or "3/8"
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
```

**Step 4: Run tests to verify they pass**

```bash
cargo test
```

Expected: all parser tests pass.

**Step 5: Commit**

```bash
git add fraccalc-core/src/parser.rs fraccalc-core/tests/parser_tests.rs fraccalc-core/src/lib.rs
git commit -m "feat: lenient parser for imperial measurement strings"
```

---

## Task 5: Formatter (TDD)

**Files:**
- Modify: `fraccalc-core/src/formatter.rs`
- Create: `fraccalc-core/tests/formatter_tests.rs`

**Step 1: Write failing tests**

```rust
// fraccalc-core/tests/formatter_tests.rs
use fraccalc_core::{Measurement, format_feet_inches, format_inches_only};

#[test]
fn test_format_feet_inches_whole() {
    let m = Measurement::from_feet_inches(3, 5, 0, 1);
    assert_eq!(format_feet_inches(m), "3' 5\"");
}

#[test]
fn test_format_feet_inches_fraction() {
    let m = Measurement::from_feet_inches(3, 5, 3, 8);
    assert_eq!(format_feet_inches(m), "3' 5-3/8\"");
}

#[test]
fn test_format_feet_only() {
    let m = Measurement::from_feet_inches(10, 0, 0, 1);
    assert_eq!(format_feet_inches(m), "10'");
}

#[test]
fn test_format_inches_only_whole() {
    let m = Measurement::from_inches(41);
    assert_eq!(format_inches_only(m), "41\"");
}

#[test]
fn test_format_inches_only_fraction() {
    let m = Measurement::from_feet_inches(3, 5, 3, 8);
    assert_eq!(format_inches_only(m), "41-3/8\"");
}

#[test]
fn test_format_zero() {
    let m = Measurement::from_inches(0);
    assert_eq!(format_feet_inches(m), "0\"");
    assert_eq!(format_inches_only(m), "0\"");
}

#[test]
fn test_format_negative() {
    let m = Measurement::from_inches(-5);
    assert_eq!(format_inches_only(m), "-5\"");
}

#[test]
fn test_format_fraction_only() {
    // 3/8" — less than one inch
    let m = Measurement::from_fraction(3, 8);
    assert_eq!(format_inches_only(m), "3/8\"");
    assert_eq!(format_feet_inches(m), "3/8\"");
}

#[test]
fn test_format_omit_zero_inches() {
    // 3' 0-1/2" should display as "3' 1/2\""
    let m = Measurement::from_feet_inches(3, 0, 1, 2);
    assert_eq!(format_feet_inches(m), "3' 1/2\"");
}
```

**Step 2: Run tests to verify they fail**

```bash
cargo test
```

**Step 3: Implement formatters**

```rust
// fraccalc-core/src/formatter.rs
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
```

**Step 4: Run tests to verify they pass**

```bash
cargo test
```

**Step 5: Commit**

```bash
git add fraccalc-core/src/formatter.rs fraccalc-core/tests/formatter_tests.rs
git commit -m "feat: format measurements as feet+inches or inches-only"
```

---

## Task 6: Property-Based Tests

**Files:**
- Create: `fraccalc-core/tests/property_tests.rs`

**Step 1: Write property-based tests for arithmetic invariants**

```rust
// fraccalc-core/tests/property_tests.rs
use proptest::prelude::*;
use fraccalc_core::{Measurement, add, subtract, multiply};

fn arb_measurement() -> impl Strategy<Value = Measurement> {
    (1i64..=10000, prop_oneof![Just(1i64), Just(2), Just(4), Just(8), Just(16), Just(32)])
        .prop_map(|(num, den)| Measurement { numerator: num, denominator: den })
}

proptest! {
    #[test]
    fn add_commutative(a in arb_measurement(), b in arb_measurement()) {
        let ab = add(a, b);
        let ba = add(b, a);
        prop_assert_eq!(ab, ba);
    }

    #[test]
    fn add_subtract_roundtrip(a in arb_measurement(), b in arb_measurement()) {
        let sum = add(a, b);
        let result = subtract(sum, b);
        prop_assert_eq!(result, a);
    }

    #[test]
    fn multiply_by_one_identity(a in arb_measurement()) {
        let result = multiply(a, 1);
        prop_assert_eq!(result, a);
    }

    #[test]
    fn add_zero_identity(a in arb_measurement()) {
        let zero = Measurement { numerator: 0, denominator: 1 };
        let result = add(a, zero);
        prop_assert_eq!(result, a);
    }
}
```

**Step 2: Run property tests**

```bash
cargo test property
```

Expected: all property tests pass (runs many random cases).

**Step 3: Commit**

```bash
git add fraccalc-core/tests/property_tests.rs
git commit -m "test: property-based tests for arithmetic invariants"
```

---

## Task 7: uniffi Bindings Build Script

**Files:**
- Create: `build.sh` (at repo root)
- Verify uniffi Swift binding generation works

**Step 1: Install Rust iOS targets**

```bash
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
```

**Step 2: Create build script**

```bash
#!/usr/bin/env bash
set -euo pipefail

LIB_NAME="fraccalc_core"
CRATE_DIR="fraccalc-core"
BINDINGS_DIR="./bindings"
XCFRAMEWORK_DIR="./FracCalc/Frameworks/FracCalcCore.xcframework"

echo "==> Building for iOS device..."
cargo build --release --target aarch64-apple-ios --manifest-path "$CRATE_DIR/Cargo.toml"

echo "==> Building for iOS Simulator (ARM64)..."
cargo build --release --target aarch64-apple-ios-sim --manifest-path "$CRATE_DIR/Cargo.toml"

echo "==> Building for iOS Simulator (x86_64)..."
cargo build --release --target x86_64-apple-ios --manifest-path "$CRATE_DIR/Cargo.toml"

echo "==> Merging simulator slices..."
mkdir -p target/ios-sim-fat/release
lipo -create \
    "target/aarch64-apple-ios-sim/release/lib${LIB_NAME}.a" \
    "target/x86_64-apple-ios/release/lib${LIB_NAME}.a" \
    -output "target/ios-sim-fat/release/lib${LIB_NAME}.a"

echo "==> Generating Swift bindings..."
cargo build --manifest-path "$CRATE_DIR/Cargo.toml"
cargo run --manifest-path "$CRATE_DIR/Cargo.toml" --bin uniffi-bindgen generate \
    --library "./target/debug/lib${LIB_NAME}.dylib" \
    --language swift \
    --out-dir "$BINDINGS_DIR"

mv "${BINDINGS_DIR}/${LIB_NAME}FFI.modulemap" "${BINDINGS_DIR}/module.modulemap"

echo "==> Creating XCFramework..."
rm -rf "$XCFRAMEWORK_DIR"
xcodebuild -create-xcframework \
    -library "./target/aarch64-apple-ios/release/lib${LIB_NAME}.a" \
        -headers "$BINDINGS_DIR" \
    -library "./target/ios-sim-fat/release/lib${LIB_NAME}.a" \
        -headers "$BINDINGS_DIR" \
    -output "$XCFRAMEWORK_DIR"

echo "Done."
echo "XCFramework: $XCFRAMEWORK_DIR"
echo "Swift binding: $BINDINGS_DIR/${LIB_NAME}.swift"
echo ""
echo "Add the .xcframework and .swift file to your Xcode project."
```

**Step 3: Run the build script**

```bash
chmod +x build.sh && ./build.sh
```

Expected: XCFramework created at `FracCalc/Frameworks/FracCalcCore.xcframework`, Swift binding at `bindings/fraccalc_core.swift`.

**Step 4: Commit**

```bash
git add build.sh
git commit -m "chore: build script for XCFramework + Swift bindings"
```

---

## Task 8: Xcode Project Setup

**Files:**
- Create: Xcode project `FracCalc/` via Xcode (SwiftUI App template)
- Add: XCFramework and generated Swift binding
- Create: `FracCalc/Services/FracCalcBridge.swift`

**Step 1: Create Xcode project**

Open Xcode → New Project → iOS App → SwiftUI → Product name: "FracCalc" → Save to repo root.

**Step 2: Add XCFramework**

- Drag `FracCalc/Frameworks/FracCalcCore.xcframework` into project navigator
- Ensure "Do Not Embed" (static library)
- Drag `bindings/fraccalc_core.swift` into project sources

**Step 3: Create bridging header**

Create `FracCalc/FracCalc-Bridging-Header.h`:

```c
#include "fraccalc_coreFFI.h"
```

Set in Build Settings → "Objective-C Bridging Header" → `FracCalc/FracCalc-Bridging-Header.h`

**Step 4: Write FracCalcBridge.swift — thin Swift wrapper**

```swift
// FracCalc/Services/FracCalcBridge.swift
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

    static func snap(_ m: Measurement, maxDenominator: Int64) -> (Measurement, Bool) {
        fraccalc_core.snapToPrecision(m: m, maxDenominator: maxDenominator)
    }
}
```

**Step 5: Verify it builds in Xcode**

Build the project (Cmd+B). Expected: successful build, no errors.

**Step 6: Commit**

```bash
git add FracCalc/
git commit -m "chore: Xcode project with XCFramework integration and bridge layer"
```

---

## Task 9: Calculator State Machine

**Files:**
- Create: `FracCalc/Models/CalculatorState.swift`
- Create: `FracCalc/ViewModels/CalculatorViewModel.swift`

**Step 1: Define the state model**

```swift
// FracCalc/Models/CalculatorState.swift
import Foundation

enum Operator {
    case add, subtract, multiply, divide
}

enum InputMode {
    case inches
    case feet
}

enum DisplayFormat {
    case feetInches
    case inchesOnly
}

struct CalculatorState {
    var displayText: String = "0\""
    var inputBuffer: String = ""
    var firstOperand: Measurement? = nil
    var pendingOperator: Operator? = nil
    var currentResult: Measurement? = nil
    var displayFormat: DisplayFormat = .feetInches
    var memory: Measurement? = nil
    var isApproximate: Bool = false
}
```

**Step 2: Implement CalculatorViewModel**

```swift
// FracCalc/ViewModels/CalculatorViewModel.swift
import SwiftUI

@Observable
class CalculatorViewModel {
    var state = CalculatorState()
    var maxDenominator: Int64 = 16  // from settings

    func digitPressed(_ digit: String) {
        state.inputBuffer += digit
        state.displayText = state.inputBuffer
    }

    func unitPressed(_ unit: String) {
        // Append ' or " to input buffer
        state.inputBuffer += unit
        state.displayText = state.inputBuffer
    }

    func fractionSlashPressed() {
        state.inputBuffer += "/"
        state.displayText = state.inputBuffer
    }

    func fractionHotkeyPressed(numerator: Int, denominator: Int) {
        state.inputBuffer += "-\(numerator)/\(denominator)"
        state.displayText = state.inputBuffer
    }

    func operatorPressed(_ op: Operator) {
        if !state.inputBuffer.isEmpty {
            evaluateCurrentInput()
        }
        if let result = state.currentResult {
            state.firstOperand = result
        }
        state.pendingOperator = op
        state.inputBuffer = ""
    }

    func equalsPressed() {
        if !state.inputBuffer.isEmpty {
            evaluateCurrentInput()
        }
        guard let first = state.firstOperand,
              let op = state.pendingOperator,
              let second = state.currentResult else {
            return
        }

        let result: Measurement
        switch op {
        case .add: result = FracCalcBridge.add(first, second)
        case .subtract: result = FracCalcBridge.subtract(first, second)
        case .multiply:
            let scalar = second.numerator / second.denominator
            result = FracCalcBridge.multiply(first, by: scalar)
        case .divide:
            let scalar = second.numerator / second.denominator
            result = FracCalcBridge.divide(first, by: scalar)
        }

        let (snapped, approx) = FracCalcBridge.snap(result, maxDenominator: maxDenominator)
        state.currentResult = snapped
        state.isApproximate = approx
        state.firstOperand = nil
        state.pendingOperator = nil
        updateDisplay(snapped)
    }

    func clearPressed() {
        state = CalculatorState()
    }

    func backspacePressed() {
        if !state.inputBuffer.isEmpty {
            state.inputBuffer.removeLast()
            state.displayText = state.inputBuffer.isEmpty ? "0\"" : state.inputBuffer
        }
    }

    func toggleDisplayFormat() {
        state.displayFormat = (state.displayFormat == .feetInches) ? .inchesOnly : .feetInches
        if let m = state.currentResult {
            updateDisplay(m)
        }
    }

    // MARK: - Memory

    func memoryAdd() {
        guard let current = state.currentResult else { return }
        if let mem = state.memory {
            state.memory = FracCalcBridge.add(mem, current)
        } else {
            state.memory = current
        }
    }

    func memorySubtract() {
        guard let current = state.currentResult else { return }
        if let mem = state.memory {
            state.memory = FracCalcBridge.subtract(mem, current)
        } else {
            // Store negative
            state.memory = Measurement(numerator: -current.numerator, denominator: current.denominator)
        }
    }

    func memoryRecall() {
        guard let mem = state.memory else { return }
        state.currentResult = mem
        updateDisplay(mem)
    }

    func memoryClear() {
        state.memory = nil
    }

    // MARK: - Private

    private func evaluateCurrentInput() {
        guard let parsed = try? FracCalcBridge.parse(state.inputBuffer) else {
            state.displayText = "Error"
            return
        }
        state.currentResult = parsed
    }

    private func updateDisplay(_ m: Measurement) {
        let prefix = state.isApproximate ? "\u{2248} " : ""
        switch state.displayFormat {
        case .feetInches:
            state.displayText = prefix + FracCalcBridge.formatFeetInches(m)
        case .inchesOnly:
            state.displayText = prefix + FracCalcBridge.formatInchesOnly(m)
        }
    }
}
```

**Step 3: Build and verify**

Cmd+B in Xcode. Expected: compiles.

**Step 4: Commit**

```bash
git add FracCalc/Models/CalculatorState.swift FracCalc/ViewModels/CalculatorViewModel.swift
git commit -m "feat: calculator state machine and view model"
```

---

## Task 10: Custom Keypad UI

**Files:**
- Create: `FracCalc/Views/KeypadView.swift`
- Create: `FracCalc/Views/Components/CalcButton.swift`

**Step 1: Create reusable button component**

```swift
// FracCalc/Views/Components/CalcButton.swift
import SwiftUI

struct CalcButton: View {
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.title2)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}
```

**Step 2: Build keypad from sub-views**

```swift
// FracCalc/Views/KeypadView.swift
import SwiftUI

struct KeypadView: View {
    let viewModel: CalculatorViewModel
    let fractionHotkeys: [(Int, Int)]  // (numerator, denominator) pairs

    var body: some View {
        VStack(spacing: 8) {
            fractionHotkeyRow
            digitAndOperatorGrid
            bottomRow
        }
        .padding(8)
    }

    private var fractionHotkeyRow: some View {
        HStack(spacing: 8) {
            ForEach(fractionHotkeys, id: \.1) { (num, den) in
                CalcButton(label: "\(num)/\(den)", color: .purple) {
                    viewModel.fractionHotkeyPressed(numerator: num, denominator: den)
                }
            }
        }
        .frame(height: 48)
    }

    private var digitAndOperatorGrid: some View {
        let rows: [[KeyDef]] = [
            [.digit("7"), .digit("8"), .digit("9"), .op("÷", .divide), .unit("'")],
            [.digit("4"), .digit("5"), .digit("6"), .op("×", .multiply), .unit("\"")],
            [.digit("1"), .digit("2"), .digit("3"), .op("−", .subtract), .slash],
            [.digit("0"), .decimal, .equals, .op("+", .add), .clear],
        ]

        return VStack(spacing: 8) {
            ForEach(0..<rows.count, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<rows[row].count, id: \.self) { col in
                        keyButton(rows[row][col])
                    }
                }
            }
        }
    }

    private var bottomRow: some View {
        HStack(spacing: 8) {
            CalcButton(label: "⌫", color: .gray) { viewModel.backspacePressed() }
            CalcButton(label: "±", color: .gray) { /* toggle sign */ }
            CalcButton(label: "ft↔in", color: .blue) { viewModel.toggleDisplayFormat() }
            CalcButton(label: "MR", color: .gray) { viewModel.memoryRecall() }
            CalcButton(label: "M+", color: .gray) { viewModel.memoryAdd() }
        }
        .frame(height: 48)
    }

    @ViewBuilder
    private func keyButton(_ key: KeyDef) -> some View {
        switch key {
        case .digit(let d):
            CalcButton(label: d, color: .secondary) { viewModel.digitPressed(d) }
        case .op(let label, let op):
            CalcButton(label: label, color: .orange) { viewModel.operatorPressed(op) }
        case .unit(let u):
            CalcButton(label: u, color: .teal) { viewModel.unitPressed(u) }
        case .slash:
            CalcButton(label: "/", color: .teal) { viewModel.fractionSlashPressed() }
        case .decimal:
            CalcButton(label: ".", color: .secondary) { viewModel.digitPressed(".") }
        case .equals:
            CalcButton(label: "=", color: .orange) { viewModel.equalsPressed() }
        case .clear:
            CalcButton(label: "C", color: .red) { viewModel.clearPressed() }
        }
    }
}

private enum KeyDef {
    case digit(String)
    case op(String, Operator)
    case unit(String)
    case slash
    case decimal
    case equals
    case clear
}
```

**Step 3: Build and verify**

Cmd+B in Xcode.

**Step 4: Commit**

```bash
git add FracCalc/Views/
git commit -m "feat: custom keypad UI with fraction hotkeys"
```

---

## Task 11: Display View + Main Calculator Screen

**Files:**
- Create: `FracCalc/Views/DisplayView.swift`
- Create: `FracCalc/Views/CalculatorView.swift`
- Modify: `FracCalc/FracCalcApp.swift`

**Step 1: Display view**

```swift
// FracCalc/Views/DisplayView.swift
import SwiftUI

struct DisplayView: View {
    let text: String
    let hasMemory: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if hasMemory {
                Text("M")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Text(text)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
```

**Step 2: Main calculator view**

```swift
// FracCalc/Views/CalculatorView.swift
import SwiftUI

struct CalculatorView: View {
    @State private var viewModel = CalculatorViewModel()
    @AppStorage("maxDenominator") private var maxDenominator: Int = 16
    @AppStorage("fractionHotkeys") private var hotkeyData: Data = defaultHotkeyData()

    var body: some View {
        VStack(spacing: 12) {
            DisplayView(
                text: viewModel.state.displayText,
                hasMemory: viewModel.state.memory != nil
            )

            KeypadView(
                viewModel: viewModel,
                fractionHotkeys: decodedHotkeys
            )
        }
        .padding()
        .onChange(of: maxDenominator) {
            viewModel.maxDenominator = Int64(maxDenominator)
        }
    }

    private var decodedHotkeys: [(Int, Int)] {
        // Decode from AppStorage; default: 1/2, 1/4, 1/8, 1/16
        (try? JSONDecoder().decode([(Int, Int)].self, from: hotkeyData))
            ?? [(1, 2), (1, 4), (1, 8), (1, 16)]
    }

    private static func defaultHotkeyData() -> Data {
        (try? JSONEncoder().encode([(1, 2), (1, 4), (1, 8), (1, 16)])) ?? Data()
    }
}
```

**Step 3: Update app entry point**

```swift
// FracCalc/FracCalcApp.swift
import SwiftUI

@main
struct FracCalcApp: App {
    var body: some Scene {
        WindowGroup {
            CalculatorView()
        }
    }
}
```

**Step 4: Build and run in simulator**

Cmd+R in Xcode. Expected: app launches with display and keypad visible.

**Step 5: Commit**

```bash
git add FracCalc/
git commit -m "feat: calculator main screen with display and keypad"
```

---

## Task 12: History Persistence

**Files:**
- Create: `FracCalc/Models/HistoryEntry.swift`
- Create: `FracCalc/ViewModels/HistoryViewModel.swift`
- Create: `FracCalc/Views/HistoryView.swift`
- Create: `FracCalc/Services/PersistenceService.swift`

**Step 1: Define SwiftData model**

```swift
// FracCalc/Models/HistoryEntry.swift
import Foundation
import SwiftData

@Model
class HistoryEntry {
    var id: UUID
    var expression: String
    var resultNumerator: Int64
    var resultDenominator: Int64
    var displayFormatRaw: String  // "feetInches" or "inchesOnly"
    var timestamp: Date

    init(expression: String, resultNumerator: Int64, resultDenominator: Int64, displayFormat: DisplayFormat) {
        self.id = UUID()
        self.expression = expression
        self.resultNumerator = resultNumerator
        self.resultDenominator = resultDenominator
        self.displayFormatRaw = displayFormat == .feetInches ? "feetInches" : "inchesOnly"
        self.timestamp = Date()
    }

    var displayFormat: DisplayFormat {
        displayFormatRaw == "feetInches" ? .feetInches : .inchesOnly
    }

    var resultMeasurement: Measurement {
        Measurement(numerator: resultNumerator, denominator: resultDenominator)
    }
}
```

**Step 2: History view model**

```swift
// FracCalc/ViewModels/HistoryViewModel.swift
import SwiftUI
import SwiftData

@Observable
class HistoryViewModel {
    var entries: [HistoryEntry] = []

    func load(context: ModelContext) {
        let descriptor = FetchDescriptor<HistoryEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        entries = (try? context.fetch(descriptor)) ?? []
    }

    func addEntry(_ entry: HistoryEntry, context: ModelContext) {
        context.insert(entry)
        try? context.save()
        load(context: context)
    }

    func deleteEntry(_ entry: HistoryEntry, context: ModelContext) {
        context.delete(entry)
        try? context.save()
        load(context: context)
    }

    func clearAll(context: ModelContext) {
        for entry in entries {
            context.delete(entry)
        }
        try? context.save()
        entries = []
    }
}
```

**Step 3: History view**

```swift
// FracCalc/Views/HistoryView.swift
import SwiftUI

struct HistoryView: View {
    let viewModel: HistoryViewModel
    let onSelect: (HistoryEntry) -> Void
    let onClearAll: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.entries, id: \.id) { entry in
                    Button {
                        onSelect(entry)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(entry.expression)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formattedResult(entry))
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                    }
                }
                .onDelete { indexSet in
                    // handle swipe delete
                }
            }
            .navigationTitle("History")
            .toolbar {
                Button("Clear All", role: .destructive) { onClearAll() }
            }
        }
    }

    private func formattedResult(_ entry: HistoryEntry) -> String {
        let m = entry.resultMeasurement
        switch entry.displayFormat {
        case .feetInches: return FracCalcBridge.formatFeetInches(m)
        case .inchesOnly: return FracCalcBridge.formatInchesOnly(m)
        }
    }
}
```

**Step 4: Wire SwiftData into app entry point**

```swift
// Update FracCalcApp.swift
@main
struct FracCalcApp: App {
    var body: some Scene {
        WindowGroup {
            CalculatorView()
        }
        .modelContainer(for: HistoryEntry.self)
    }
}
```

**Step 5: Build and verify**

Cmd+B. Expected: compiles.

**Step 6: Commit**

```bash
git add FracCalc/
git commit -m "feat: calculation history with SwiftData persistence"
```

---

## Task 13: Settings View

**Files:**
- Create: `FracCalc/Settings/SettingsView.swift`
- Modify: `FracCalc/Views/CalculatorView.swift` (add settings navigation)

**Step 1: Build settings view**

```swift
// FracCalc/Settings/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @AppStorage("maxDenominator") private var maxDenominator: Int = 16

    private let precisionOptions = [
        (2, "1/2\""),
        (4, "1/4\""),
        (8, "1/8\""),
        (16, "1/16\""),
        (32, "1/32\""),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Precision") {
                    Picker("Maximum fraction", selection: $maxDenominator) {
                        ForEach(precisionOptions, id: \.0) { (value, label) in
                            Text(label).tag(value)
                        }
                    }
                }

                Section("Fraction Hotkeys") {
                    Text("Configure which fraction buttons appear on the keypad.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    // TODO: hotkey configuration UI
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

**Step 2: Add settings access from calculator view**

Add a gear icon button to `CalculatorView` that presents `SettingsView` as a sheet.

**Step 3: Build and verify**

Cmd+B.

**Step 4: Commit**

```bash
git add FracCalc/Settings/ FracCalc/Views/CalculatorView.swift
git commit -m "feat: settings view with precision and hotkey configuration"
```

---

## Task 14: Integration Testing & Polish

**Files:**
- Verify end-to-end flow in simulator
- Fix any issues found during manual testing

**Step 1: Manual test checklist**

Run in simulator and verify:
- [ ] Type `3' 5-3/8" + 2' 11-1/2"` → result shows `6' 4-7/8"`
- [ ] Toggle feet↔inches → shows `76-7/8"`
- [ ] Memory: perform calculation, M+, clear, new calc, M+, MR → shows sum
- [ ] History: calculation appears in history list
- [ ] History tap: loads result as current operand
- [ ] Settings: change precision, verify fraction display updates
- [ ] Fraction hotkeys: tap 1/8, verify it appends to input
- [ ] Backspace: removes last character
- [ ] Clear: resets to `0"`
- [ ] Chaining: `= + 5"` chains from previous result
- [ ] Negative result: `3" - 5"` → `-2"`
- [ ] Approximate indicator: set precision to 1/4, compute something requiring 1/8 → shows ≈

**Step 2: Fix any bugs found**

Address issues discovered during testing.

**Step 3: Commit**

```bash
git add -A
git commit -m "fix: integration testing fixes and polish"
```

---

## Summary

| Task | Description | Estimated Steps |
|------|-------------|----------------|
| 1 | Project scaffolding | 5 |
| 2 | Measurement type + arithmetic (TDD) | 9 |
| 3 | Precision — simplify & snap (TDD) | 5 |
| 4 | Parser (TDD) | 5 |
| 5 | Formatter (TDD) | 5 |
| 6 | Property-based tests | 3 |
| 7 | uniffi build script | 4 |
| 8 | Xcode project setup | 6 |
| 9 | Calculator state machine | 4 |
| 10 | Custom keypad UI | 4 |
| 11 | Display + main screen | 5 |
| 12 | History persistence | 6 |
| 13 | Settings view | 4 |
| 14 | Integration testing | 3 |

**Total: 14 tasks, ~68 steps**

Tasks 1–6 are pure Rust, testable without Xcode. Tasks 7–8 bridge to iOS. Tasks 9–13 are SwiftUI. Task 14 is validation.
