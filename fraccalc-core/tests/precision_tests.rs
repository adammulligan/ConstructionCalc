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
    // 4/8 with max_denominator=4 -> 1/2
    let m = Measurement::from_fraction(4, 8);
    let result = simplify(m, 4);
    assert_eq!(result.numerator(), 1);
    assert_eq!(result.denominator(), 2);
}

#[test]
fn test_snap_exact() {
    let m = Measurement::from_fraction(3, 8);
    let result = snap_to_precision(m, 8);
    assert_eq!(result.value.numerator(), 3);
    assert_eq!(result.value.denominator(), 8);
    assert!(!result.is_approximate);
}

#[test]
fn test_snap_approximate() {
    // 3/32 with max_denominator=16 -> 3/32 = 0.09375
    // nearest 1/16ths: 1/16=0.0625, 2/16=0.125 -> rounds to 2/16 = 1/8
    let m = Measurement::from_fraction(3, 32);
    let result = snap_to_precision(m, 16);
    assert_eq!(result.value.numerator(), 1);
    assert_eq!(result.value.denominator(), 8);
    assert!(result.is_approximate);
}

#[test]
fn test_snap_whole_number_unaffected() {
    let m = Measurement::from_inches(42);
    let result = snap_to_precision(m, 16);
    assert_eq!(result.value.numerator(), 42);
    assert_eq!(result.value.denominator(), 1);
    assert!(!result.is_approximate);
}
