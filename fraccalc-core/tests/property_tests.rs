use proptest::prelude::*;
use fraccalc_core::{Measurement, add, subtract, multiply};

fn arb_measurement() -> impl Strategy<Value = Measurement> {
    (1i64..=10000, prop_oneof![Just(1i64), Just(2), Just(4), Just(8), Just(16), Just(32)])
        .prop_map(|(num, den)| Measurement::from_fraction(num, den))
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
