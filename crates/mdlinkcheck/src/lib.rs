//! `mdlinkcheck` library crate.
//!
//! Exposes the `scanner` module publicly so that integration tests in `tests/`
//! can reach its functions. This is the conventional Rust pattern for testing
//! an effectful module: the binary (`main.rs`) is a thin wrapper; the library
//! owns all testable logic.
//!
//! Integration tests import via:
//!   `use mdlinkcheck::scanner;`

pub mod scanner;
