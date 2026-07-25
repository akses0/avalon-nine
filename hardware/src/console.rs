use core::fmt::Write;

use crate::Console;
use crate::logger::{ActionState, Logger, Severity};

impl Logger for Console {
    fn log(&mut self, action: ActionState, severity: Severity, message: &str) {
        let _ = write!(self, "[{:?}] [{:?}] {}\n", action, severity, message);
    }
}
