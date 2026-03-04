#[derive(Debug, Clone, Copy, PartialEq, Eq, uniffi::Record)]
pub struct Measurement {
    pub numerator: i64,
    pub denominator: i64,
}
