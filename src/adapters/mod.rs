pub mod alacritty;
pub mod ghostty;
pub mod kitty;
pub mod starship;
pub mod termux;

use anyhow::Result;

use crate::theme::Theme;

/// Adapter trait — each tool implements this
pub trait Adapter {
    /// Human-readable name
    fn name(&self) -> &str;

    /// Is this tool available on the current system?
    fn detect(&self) -> bool;

    /// Apply the theme to this tool's config
    fn apply(&self, theme: &Theme, theme_slug: &str) -> Result<()>;

    /// Reload the tool to pick up changes
    fn reload(&self) -> Result<()>;
}
