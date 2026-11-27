//! Kairo: switches for the features Kairo adds to Yapfast.

use iced::{Element, widget::text};

use super::Pref;
use crate::kairo::Switch;
use crate::settings::Page;
use crate::{app::Message, form};

impl<'a> Page<'a> {
    pub(in crate::settings) fn kairo_page(self) -> Element<'a, Message> {
        let theme = self.cx.look.theme;
        let kairo = &self.cx.layout.kairo;
        let heading = |words: &'a str| -> Element<'a, Message> {
            text(words)
                .size(12)
                .font(crate::fonts::SEMIBOLD)
                .color(theme.muted)
                .into()
        };
        iced::widget::column(vec![
            form::title(theme, "Kairo"),
            heading("MESSAGES"),
            self.flip(
                "Message Logger",
                "Deleted messages stay in the chat in red, and edited ones show what they said before. Only what you saw while Kairo was open. Right-click a deleted one to remove it.",
                kairo.message_logger,
                |on| Pref::Kairo(Switch::MessageLogger, on),
            ),
            self.flip(
                "Ignore bots",
                "The message logger lets bots' deleted messages go.",
                kairo.logger_ignores_bots,
                |on| Pref::Kairo(Switch::LoggerIgnoresBots, on),
            ),
            self.flip(
                "Tag deleted pictures and files",
                "A deleted message with only pictures or files says (deleted), since it has no text to turn red.",
                kairo.deleted_tag,
                |on| Pref::Kairo(Switch::DeletedTag, on),
            ),
            self.flip(
                "Show reply times",
                "The message a reply quotes shows when it was sent.",
                kairo.reply_timestamps,
                |on| Pref::Kairo(Switch::ReplyTimestamps, on),
            ),
            self.flip(
                "Always send emoji as links",
                "Custom emoji and stickers go as picture links even when you could use them. Without Nitro, the ones you can't use always go as links. Turn this on to try it while you have Nitro.",
                kairo.emoji_links_always,
                |on| Pref::Kairo(Switch::EmojiLinksAlways, on),
            ),
            heading("PEOPLE"),
            self.flip(
                "Show usernames",
                "Someone's username shows beside the nickname a server or you gave them, so you always know who's who.",
                kairo.show_usernames,
                |on| Pref::Kairo(Switch::ShowUsernames, on),
            ),
            self.flip(
                "Platform indicators",
                "Icons beside names in the member list show which devices people are on: desktop, web or phone.",
                kairo.platform_indicators,
                |on| Pref::Kairo(Switch::PlatformIndicators, on),
            ),
            self.flip(
                "Member count",
                "How many members are online, and how many a server has, over its member list.",
                kairo.member_count,
                |on| Pref::Kairo(Switch::MemberCount, on),
            ),
            heading("VOICE"),
            self.flip(
                "Volume booster",
                "People's voice and stream volume sliders go to 400% instead of 200%.",
                kairo.volume_boost,
                |on| Pref::Kairo(Switch::VolumeBoost, on),
            ),
        ])
        .spacing(16)
        .into()
    }
}
