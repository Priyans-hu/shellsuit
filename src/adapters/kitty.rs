use anyhow::{Context, Result};
use std::path::PathBuf;

use crate::adapters::Adapter;
use crate::state;
use crate::theme::Theme;

pub struct KittyAdapter;

impl KittyAdapter {
    fn config_dir(&self) -> Option<PathBuf> {
        dirs::config_dir().map(|d| d.join("kitty"))
    }

    fn config_path(&self) -> Option<PathBuf> {
        self.config_dir().map(|d| d.join("kitty.conf"))
    }

    fn theme_conf_path(&self) -> Option<PathBuf> {
        self.config_dir().map(|d| d.join("current-theme.conf"))
    }

    fn render_theme(&self, theme: &Theme) -> String {
        let c = &theme.colors;
        let mut lines = Vec::new();

        lines.push(format!("background {}", c.background.hex()));
        lines.push(format!("foreground {}", c.foreground.hex()));
        lines.push(format!("cursor {}", c.cursor.hex()));
        lines.push(format!("cursor_text_color {}", c.sel_fg().hex()));
        lines.push(format!("selection_background {}", c.sel_bg().hex()));
        lines.push(format!("selection_foreground {}", c.sel_fg().hex()));
        lines.push(String::new());

        let color_names = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"];

        // Normal colors (color0-color7)
        for (i, color) in c.normal_ordered().iter().enumerate() {
            lines.push(format!("color{} {}", i, color.hex()));
        }
        lines.push(String::new());

        // Bright colors (color8-color15)
        for (i, color) in c.bright_ordered().iter().enumerate() {
            lines.push(format!("color{} {}", i + 8, color.hex()));
        }
        lines.push(String::new());

        let _ = color_names; // suppress warning
        lines.join("\n")
    }
}

impl Adapter for KittyAdapter {
    fn name(&self) -> &str {
        "Kitty"
    }

    fn detect(&self) -> bool {
        // Check TERM_PROGRAM
        if let Ok(term) = std::env::var("TERM_PROGRAM") {
            if term == "xterm-kitty" {
                return true;
            }
        }
        // Check TERM
        if let Ok(term) = std::env::var("TERM") {
            if term == "xterm-kitty" {
                return true;
            }
        }
        // Fallback: kitty binary exists
        which::which("kitty").is_ok()
    }

    fn apply(&self, theme: &Theme, _theme_slug: &str) -> Result<()> {
        let config_dir = self
            .config_dir()
            .context("could not determine Kitty config directory")?;

        std::fs::create_dir_all(&config_dir).context("failed to create Kitty config directory")?;

        // Backup existing theme conf
        if let Some(theme_path) = self.theme_conf_path() {
            let _ = state::backup_file(&theme_path, "kitty-theme.bak");
        }

        // Write theme conf
        let theme_path = self
            .theme_conf_path()
            .context("could not determine Kitty theme path")?;
        let content = self.render_theme(theme);
        std::fs::write(&theme_path, &content)
            .with_context(|| format!("failed to write Kitty theme to {}", theme_path.display()))?;

        // Ensure kitty.conf includes the theme file
        if let Some(config_path) = self.config_path() {
            if config_path.exists() {
                let config = std::fs::read_to_string(&config_path)
                    .context("failed to read kitty.conf")?;
                if !config.contains("current-theme.conf") {
                    let _ = state::backup_file(&config_path, "kitty-conf.bak");
                    let mut new_config = config;
                    new_config.push_str("\n# Shellsuit theme\ninclude current-theme.conf\n");
                    std::fs::write(&config_path, &new_config)
                        .context("failed to update kitty.conf")?;
                }
            }
        }

        Ok(())
    }

    fn reload(&self) -> Result<()> {
        // Try kitty remote control for live reload
        if let Some(theme_path) = self.theme_conf_path() {
            let status = std::process::Command::new("kitty")
                .arg("@")
                .arg("set-colors")
                .arg("--all")
                .arg(&theme_path)
                .status();

            match status {
                Ok(s) if s.success() => {}
                _ => {
                    // Remote control might not be enabled — silent fail
                }
            }
        }
        Ok(())
    }
}
