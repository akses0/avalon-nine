use crate::Console;

#[derive(Debug)]
pub enum ActionState {
    Ok,
    NotOk,
}
#[derive(Debug)]
pub enum Severity {
    /// Debug: reserved for log messages related to describing execution paths and trace information
    Debug,
    /// Info: reserved for log messages related to describing normal program states
    Info,
    /// Warning: reserved for log messages related to unexpected, non-fatal program states
    Warning,
    /// Fatal: reserved for log messages related to unexpected or unhandled errors that force the
    /// kernel to cease running a process or operation.
    Fatal,
    /// Panic: reserved for log messages related to a kernel Meditation State
    Meditation,
}
pub trait Logger {
    fn log(&mut self, action: ActionState, severity: Severity, message: &str);
}

/// Write a formatted log line to a [`Logger`] implementor.
///
/// Prefixes the message with `[ACTION] [SEVERITY]` using [`Debug`] formatting,
/// then appends the user's format string as a newline-terminated line.
///
/// Relies on [`core::fmt::Write`] internally, so the logger must implement both
/// [`Logger`] and [`core::fmt::Write`] (as [`super::Console`] does).
///
/// # Usage
///
/// ```no_run
/// use hardware::logger::{ActionState, Severity};
/// use hardware::Console;
///
/// let mut console = Console;
/// klog!(console, Severity::Info, ActionState::OK, "hello");
/// klog!(console, Severity::Warning, ActionState::Error, "failed: code={}", 42);
/// // Output:
/// // [OK] [Info] hello
/// // [Not_OK] [Warning] failed: code=42
/// ```
#[macro_export]
macro_rules! klog {
    ($logger:expr, $severity:expr, $action:expr, $($arg:tt)*) => {{
       use core::fmt::Write;
        let _ = write!($logger, "[{:?}] [{:?}] ",  $action, $severity);
        let _ = writeln!($logger, $($arg)*);
    }};
}

#[test]
fn test_klog() {
    let mut console = Console;
    klog!(console, Severity::Info, ActionState::OK, "hello");
}
