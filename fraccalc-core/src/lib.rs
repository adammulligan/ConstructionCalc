uniffi::setup_scaffolding!();

mod measurement;
mod parser;
mod formatter;
mod precision;

pub use measurement::{Measurement, add, subtract, multiply, divide, divide_measurements};
pub use parser::parse_measurement;
pub use formatter::{format_feet_inches, format_inches_only};
pub use precision::{simplify, snap_to_precision};
