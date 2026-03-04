#[derive(Debug, Clone, Copy, PartialEq, Eq, uniffi::Record)]
pub struct Measurement {
    pub numerator: i64,
    pub denominator: i64,
}

impl Measurement {
    /// Normalize: reduce to lowest terms via GCD.
    pub(crate) fn normalize(numerator: i64, denominator: i64) -> Self {
        assert!(denominator > 0, "denominator must be positive");
        let g = gcd(numerator.unsigned_abs(), denominator.unsigned_abs());
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
