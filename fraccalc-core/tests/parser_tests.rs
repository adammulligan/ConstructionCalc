use fraccalc_core::{Measurement, parse_measurement};

#[test]
fn test_parse_whole_inches() {
    let m = parse_measurement("5\"").unwrap();
    assert_eq!(m, Measurement::from_inches(5));
}

#[test]
fn test_parse_whole_feet() {
    let m = parse_measurement("3'").unwrap();
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
    let m1 = parse_measurement("3'5-3/8\"").unwrap();
    let m2 = parse_measurement("3'  5-3/8\"").unwrap();
    assert_eq!(m1, m2);
}

#[test]
fn test_parse_decimal_inches() {
    // 1.5" = 3/2 inches
    let m = parse_measurement("1.5\"").unwrap();
    assert_eq!(m.numerator(), 3);
    assert_eq!(m.denominator(), 2);
}

#[test]
fn test_parse_decimal_feet() {
    // 1.5' = 18 inches
    let m = parse_measurement("1.5'").unwrap();
    assert_eq!(m.numerator(), 18);
    assert_eq!(m.denominator(), 1);
}

#[test]
fn test_parse_decimal_bare() {
    // 2.25 = 9/4 inches
    let m = parse_measurement("2.25").unwrap();
    assert_eq!(m.numerator(), 9);
    assert_eq!(m.denominator(), 4);
}

#[test]
fn test_parse_decimal_negative() {
    let m = parse_measurement("-1.5\"").unwrap();
    assert_eq!(m.numerator(), -3);
    assert_eq!(m.denominator(), 2);
}

#[test]
fn test_parse_decimal_feet_plus_inches() {
    // 1.5' 3" = 18 + 3 = 21 inches
    let m = parse_measurement("1.5' 3\"").unwrap();
    assert_eq!(m.numerator(), 21);
    assert_eq!(m.denominator(), 1);
}

#[test]
fn test_parse_decimal_roundtrip_with_fraction() {
    // 1.2" and 1-1/5" should produce the same measurement
    let m1 = parse_measurement("1.2\"").unwrap();
    let m2 = parse_measurement("1-1/5\"").unwrap();
    assert_eq!(m1, m2);
}

#[test]
fn test_parse_quote_as_fraction_delimiter() {
    // 2"3/16 should parse the same as 2-3/16
    let m1 = parse_measurement("2\"3/16").unwrap();
    let m2 = parse_measurement("2-3/16").unwrap();
    assert_eq!(m1, m2);
}

#[test]
fn test_parse_quote_delimiter_with_trailing_quote() {
    // 2"3/16" (trailing quote too) should work
    let m = parse_measurement("2\"3/16\"").unwrap();
    assert_eq!(m.numerator(), 35);
    assert_eq!(m.denominator(), 16);
}

#[test]
fn test_parse_quote_delimiter_with_feet() {
    // 3' 2"3/16 should parse as 3 feet + 2-3/16 inches
    let m1 = parse_measurement("3' 2\"3/16").unwrap();
    let m2 = parse_measurement("3' 2-3/16\"").unwrap();
    assert_eq!(m1, m2);
}
