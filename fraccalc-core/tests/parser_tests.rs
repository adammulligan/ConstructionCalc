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
