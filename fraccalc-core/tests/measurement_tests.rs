use fraccalc_core::{Measurement, add, subtract, multiply, divide, divide_measurements};

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

#[test]
fn test_add_whole_inches() {
    let a = Measurement::from_inches(5);
    let b = Measurement::from_inches(3);
    let result = add(a, b);
    assert_eq!(result, Measurement::from_inches(8));
}

#[test]
fn test_add_fractions() {
    // 3/8 + 1/4 = 3/8 + 2/8 = 5/8
    let a = Measurement::from_fraction(3, 8);
    let b = Measurement::from_fraction(1, 4);
    let result = add(a, b);
    assert_eq!(result.numerator(), 5);
    assert_eq!(result.denominator(), 8);
}

#[test]
fn test_add_feet_and_inches() {
    // 3' 5-3/8" + 2' 11-1/2" = 6' 4-7/8"
    let a = Measurement::from_feet_inches(3, 5, 3, 8);
    let b = Measurement::from_feet_inches(2, 11, 1, 2);
    let result = add(a, b);
    // 6' 4-7/8" = 76 + 7/8 = 615/8
    assert_eq!(result.numerator(), 615);
    assert_eq!(result.denominator(), 8);
}

#[test]
fn test_subtract() {
    // 10' - 3' 5-1/2" = 6' 6-1/2"
    let a = Measurement::from_feet_inches(10, 0, 0, 1);
    let b = Measurement::from_feet_inches(3, 5, 1, 2);
    let result = subtract(a, b);
    // 120 - 41.5 = 78.5 = 157/2
    assert_eq!(result.numerator(), 157);
    assert_eq!(result.denominator(), 2);
}

#[test]
fn test_multiply_by_scalar() {
    // 3' 5-3/8" * 4 = 331/8 * 4 = 1324/8 = 331/2
    let a = Measurement::from_feet_inches(3, 5, 3, 8);
    let result = multiply(a, 4);
    assert_eq!(result.numerator(), 331);
    assert_eq!(result.denominator(), 2);
}

#[test]
fn test_divide_by_scalar() {
    // 10' / 3 = 120/3 = 40
    let a = Measurement::from_feet_inches(10, 0, 0, 1);
    let result = divide(a, 3);
    assert_eq!(result.numerator(), 40);
    assert_eq!(result.denominator(), 1);
}

#[test]
fn test_divide_measurements() {
    // 10' / 3' = 120/36 = 10/3
    let a = Measurement::from_feet_inches(10, 0, 0, 1);
    let b = Measurement::from_feet_inches(3, 0, 0, 1);
    let result = divide_measurements(a, b);
    assert!((result - 10.0 / 3.0).abs() < 1e-10);
}
