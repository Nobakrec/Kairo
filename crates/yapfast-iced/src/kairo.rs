//! Kairo's own features and the switches Settings → Kairo turns them on
//! and off with, kept in `layout.json` under `kairo`. Most are on unless
//! turned off; those that change what this account sends are off.

/// Kairo's switches.
#[derive(Clone, Copy, Debug, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(default)]
pub struct Kairo {
    /// Deleted messages stay, in red, and edits keep what they replaced.
    pub message_logger: bool,
    /// The message logger lets bots' deleted messages go.
    pub logger_ignores_bots: bool,
    /// A deleted message of pictures or files alone says "(deleted)".
    pub deleted_tag: bool,
    /// Custom emoji and stickers go as links even when this account could
    /// use them, to try FakeNitro with Nitro.
    pub emoji_links_always: bool,
    /// Device icons beside names in the member list.
    pub platform_indicators: bool,
    /// Online and member counts over a server's member list.
    pub member_count: bool,
    /// Someone's username beside the name a server or friend gave them.
    pub show_usernames: bool,
    /// The time on the message a reply quotes.
    pub reply_timestamps: bool,
    /// People's voice and stream sliders go to 400.
    pub volume_boost: bool,
}

impl Default for Kairo {
    fn default() -> Self {
        Self {
            message_logger: true,
            logger_ignores_bots: false,
            deleted_tag: true,
            emoji_links_always: false,
            platform_indicators: true,
            member_count: true,
            show_usernames: true,
            reply_timestamps: true,
            volume_boost: true,
        }
    }
}

/// One of Kairo's switches, as Settings → Kairo flips it.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Switch {
    MessageLogger,
    LoggerIgnoresBots,
    DeletedTag,
    EmojiLinksAlways,
    PlatformIndicators,
    MemberCount,
    ShowUsernames,
    ReplyTimestamps,
    VolumeBoost,
}

impl Kairo {
    /// Tells the core the switches it follows itself: the message logger's
    /// and emoji links'.
    pub fn apply(&self) {
        yapfast_core::yapfast_discord::message_log::set_enabled(self.message_logger);
        yapfast_core::yapfast_discord::message_log::set_ignores_bots(self.logger_ignores_bots);
        yapfast_core::emoji::set_links_always(self.emoji_links_always);
    }

    /// Flips `switch` to `on`, and tells the core.
    pub fn set(&mut self, switch: Switch, on: bool) {
        let field = match switch {
            Switch::MessageLogger => &mut self.message_logger,
            Switch::LoggerIgnoresBots => &mut self.logger_ignores_bots,
            Switch::DeletedTag => &mut self.deleted_tag,
            Switch::EmojiLinksAlways => &mut self.emoji_links_always,
            Switch::PlatformIndicators => &mut self.platform_indicators,
            Switch::MemberCount => &mut self.member_count,
            Switch::ShowUsernames => &mut self.show_usernames,
            Switch::ReplyTimestamps => &mut self.reply_timestamps,
            Switch::VolumeBoost => &mut self.volume_boost,
        };
        *field = on;
        self.apply();
    }

    /// How far a person's voice and stream sliders go.
    pub fn person_slider(&self) -> u32 {
        if self.volume_boost {
            yapfast_core::volume::PERSON_SLIDER
        } else {
            200
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_what_layout_json_keeps_and_defaults_the_rest() {
        let kept: Kairo = serde_json::from_str(r#"{"member_count": false}"#).unwrap();
        assert!(!kept.member_count);
        assert!(kept.message_logger, "on unless turned off");
        assert!(!kept.emoji_links_always, "off unless turned on");
        let mut kairo = Kairo::default();
        kairo.set(Switch::VolumeBoost, false);
        assert_eq!(kairo.person_slider(), 200);
    }
}
