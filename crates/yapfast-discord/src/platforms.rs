//! Which devices each person is on, from the `client_status` of their
//! presence: desktop, mobile and web, each with its own status, as
//! Vencord's PlatformIndicators shows them by their name. Kept by user id
//! for the session, as presences come; nothing is saved.

use std::{
    collections::HashMap,
    sync::{LazyLock, RwLock},
};

use serde_json::Value;

/// A person's status on one device.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Status {
    Online,
    Idle,
    DoNotDisturb,
}

impl Status {
    fn parse(value: &Value) -> Option<Self> {
        match value.as_str()? {
            "online" => Some(Self::Online),
            "idle" => Some(Self::Idle),
            "dnd" => Some(Self::DoNotDisturb),
            _ => None,
        }
    }
}

/// The devices someone is on, and their status on each; none for one
/// they're not on.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Platforms {
    pub desktop: Option<Status>,
    pub mobile: Option<Status>,
    pub web: Option<Status>,
}

impl Platforms {
    /// Reads a presence object's `client_status`.
    pub fn parse(presence: &Value) -> Self {
        let clients = &presence["client_status"];
        Self {
            desktop: Status::parse(&clients["desktop"]),
            mobile: Status::parse(&clients["mobile"]),
            web: Status::parse(&clients["web"]),
        }
    }

    pub fn is_empty(&self) -> bool {
        *self == Self::default()
    }
}

static KNOWN: LazyLock<RwLock<HashMap<String, Platforms>>> = LazyLock::new(RwLock::default);

/// Learns `user`'s devices from a presence of theirs; one on none is
/// forgotten.
pub fn record(user: &str, presence: &Value) {
    let platforms = Platforms::parse(presence);
    let mut known = KNOWN.write().unwrap();
    if platforms.is_empty() {
        known.remove(user);
    } else {
        known.insert(user.to_owned(), platforms);
    }
}

/// The devices `user` was last seen on; none if unknown or offline.
pub fn get(user: &str) -> Platforms {
    KNOWN.read().unwrap().get(user).copied().unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use serde_json::json;

    use super::*;

    #[test]
    fn reads_each_device_and_forgets_on_offline() {
        record(
            "platforms-test-1",
            &json!({"status": "online", "client_status": {"desktop": "dnd", "mobile": "online"}}),
        );
        assert_eq!(
            get("platforms-test-1"),
            Platforms {
                desktop: Some(Status::DoNotDisturb),
                mobile: Some(Status::Online),
                web: None,
            }
        );
        record(
            "platforms-test-1",
            &json!({"status": "offline", "client_status": {}}),
        );
        assert!(get("platforms-test-1").is_empty());
        assert!(get("platforms-test-unknown").is_empty());
    }
}
