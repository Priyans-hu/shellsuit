use anyhow::{Context, Result};
use std::path::PathBuf;

use crate::adapters::Adapter;
use crate::state;
use crate::theme::Theme;

pub struct TermuxAdapter;

impl TermuxAdapter {
    fn termux_dir(&self) -> PathBuf {
        // On Termux, HOME is /data/data/com.termux/files/home
        let home = dirs::home_dir().unwrap_or_else(|| PathBuf::from("/data/data/com.termux/files/home"));
        home.join(".termux")
    }

    fn colors_path(&self) -> PathBuf {
        self.termux_dir().join("colors.properties")
    }

    fn render_colors(&self, theme: &Theme, theme_slug: &str) -> String {
        let c = &theme.colors;
        let mut lines = Vec::new();

        lines.push(format!("# Shellsuit theme: {}", theme_slug));
        lines.push(format!("background={}", c.background.hash_upper()));
        lines.push(format!("foreground={}", c.foreground.hash_upper()));
        lines.push(format!("cursor={}", c.cursor.hash_upper()));
        lines.push(String::new());

        // Normal colors (0-7)
        lines.push("# Normal colors".to_string());
        for (i, color) in c.normal_ordered().iter().enumerate() {
            lines.push(format!("color{}={}", i, color.hash_upper()));
        }
        lines.push(String::new());

        // Bright colors (8-15)
        lines.push("# Bright colors".to_string());
        for (i, color) in c.bright_ordered().iter().enumerate() {
            lines.push(format!("color{}={}", i + 8, color.hash_upper()));
        }
        lines.push(String::new());

        lines.join("\n")
    }
}

impl Adapter for TermuxAdapter {
    fn name(&self) -> &str {
        "Termux"
    }

    fn detect(&self) -> bool {
        std::env::var("TERMUX_VERSION").is_ok() || self.termux_dir().exists()
    }

    fn apply(&self, theme: &Theme, theme_slug: &str) -> Result<()> {
        let termux_dir = self.termux_dir();
        std::fs::create_dir_all(&termux_dir).context("failed to create ~/.termux directory")?;

        // Backup existing colors
        let colors_path = self.colors_path();
        let _ = state::backup_file(&colors_path, "termux-colors.bak");

        // Write colors.properties
        let content = self.render_colors(theme, theme_slug);
        std::fs::write(&colors_path, &content)
            .context("failed to write Termux colors.properties")?;

        Ok(())
    }

    fn reload(&self) -> Result<()> {
        // termux-reload-settings applies changes instantly
        let status = std::process::Command::new("termux-reload-settings")
            .status();

        match status {
            Ok(s) if s.success() => Ok(()),
            Ok(_) => {
                eprintln!("  warning: termux-reload-settings exited with error");
                Ok(())
            }
            Err(_) => {
                // Not on Termux or command not found — silently skip
                Ok(())
            }
        }
    }
}
