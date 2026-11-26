//! The message logger, as Vencord's MessageLogger: a message deleted while
//! its channel is loaded stays, marked deleted, and an edited one keeps
//! what it said before. Only what this session saw is kept. Messages this
//! account deletes itself go as before. Settings → Kairo turns it off, or
//! has it let bots' messages go.

use std::{
    collections::HashSet,
    sync::{
        LazyLock, Mutex,
        atomic::{AtomicBool, Ordering},
    },
};

static ENABLED: AtomicBool = AtomicBool::new(true);
static IGNORES_BOTS: AtomicBool = AtomicBool::new(false);

/// Messages this account deleted, by id, which the logger lets go.
static DISMISSED: LazyLock<Mutex<HashSet<String>>> = LazyLock::new(Mutex::default);

/// Whether the logger keeps deleted messages and earlier versions.
pub fn enabled() -> bool {
    ENABLED.load(Ordering::Relaxed)
}

/// Turns the logger on or off.
pub fn set_enabled(on: bool) {
    ENABLED.store(on, Ordering::Relaxed);
}

/// Whether the logger lets bots' deleted messages go.
pub fn ignores_bots() -> bool {
    IGNORES_BOTS.load(Ordering::Relaxed)
}

/// Has the logger let bots' deleted messages go, or keep them.
pub fn set_ignores_bots(on: bool) {
    IGNORES_BOTS.store(on, Ordering::Relaxed);
}

/// This account is deleting message `id`: it goes, not kept.
pub fn dismiss(id: &str) {
    DISMISSED.lock().unwrap().insert(id.to_owned());
}

/// Whether a deleted message `id` is kept: the logger is on, and this
/// account didn't delete it.
pub fn keeps(id: &str) -> bool {
    enabled() && !DISMISSED.lock().unwrap().contains(id)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn keeps_others_deletions_and_lets_own_go() {
        assert!(keeps("message-log-test-1"));
        dismiss("message-log-test-2");
        assert!(!keeps("message-log-test-2"));
    }
}
