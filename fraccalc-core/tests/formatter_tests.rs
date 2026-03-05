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
