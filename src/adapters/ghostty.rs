use anyhow::{Context, Result};
use std::path::PathBuf;

use crate::adapters::Adapter;
use crate::state;
use crate::theme::Theme;

pub struct GhosttyAdapter;

impl GhosttyAdapter {
    fn config_dir(&self) -> Option<PathBuf> {
        dirs::config_dir().map(|d| d.join("ghostty"))
    }

    fn themes_dir(&self) -> Option<PathBuf> {
        self.config_dir().map(|d| d.join("themes"))
    }

    fn config_path(&self) -> Option<PathBuf> {
        self.config_dir().map(|d| d.join("config"))
    }

    /// Generate Ghostty theme file content from a Theme
    fn render_theme(&self, theme: &Theme) -> String {
        let c = &theme.colors;
        let mut lines = Vec::new();

        lines.push(format!("background = {}", c.background.bare_lower()));
        lines.push(format!("foreground = {}", c.foreground.bare_lower()));
        lines.push(String::new());
        lines.push(format!("cursor-color = {}", c.cursor.bare_lower()));
        lines.push(format!("cursor-text = {}", c.sel_fg().bare_lower()));
        lines.push(String::new());
        lines.push(format!(
            "selection-background = {}",
            c.sel_bg().bare_lower()
        ));
        lines.push(format!(
            "selection-foreground = {}",
            c.sel_fg().bare_lower()
        ));

        // Normal colors (palette 0-7)
        lines.push(String::new());
        for (i, color) in c.normal_ordered().iter().enumerate() {
            lines.push(format!("palette = {}={}", i, color.hash_upper()));
        }

        // Bright colors (palette 8-15)
        lines.push(String::new());
        for (i, color) in c.bright_ordered().iter().enumerate() {
            lines.push(format!("palette = {}={}", i + 8, color.hash_upper()));
        }

        lines.push(String::new());
        lines.join("\n")
    }
}

impl Adapter for GhosttyAdapter {
    fn name(&self) -> &str {
        "Ghostty"
    }

    fn detect(&self) -> bool {
        // Check TERM_PROGRAM
        if let Ok(term) = std::env::var("TERM_PROGRAM") {
            if term.to_lowercase() == "ghostty" {
                return true;
            }
        }
        // Fallback: config exists
        self.config_path().map_or(false, |p| p.exists())
    }

    fn apply(&self, theme: &Theme, theme_slug: &str) -> Result<()> {
        let themes_dir = self
            .themes_dir()
            .context("could not determine Ghostty themes directory")?;

        std::fs::create_dir_all(&themes_dir)
            .context("failed to create Ghostty themes directory")?;

        // Backup existing config
        if let Some(config) = self.config_path() {
            let _ = state::backup_file(&config, "ghostty-config.bak");
        }

        // Write theme file
        let theme_file = themes_dir.join(theme_slug);
        let content = self.render_theme(theme);
        std::fs::write(&theme_file, &content)
            .with_context(|| format!("failed to write Ghostty theme to {}", theme_file.display()))?;

        // Update main config to use this theme
        if let Some(config_path) = self.config_path() {
            if config_path.exists() {
                let config = std::fs::read_to_string(&config_path)
                    .context("failed to read Ghostty config")?;

                let new_config = update_ghostty_theme_line(&config, theme_slug);
                std::fs::write(&config_path, new_config)
                    .context("failed to update Ghostty config")?;
            }
        }

        Ok(())
    }

    fn reload(&self) -> Result<()> {
        // Ghostty watches config files — automatic on write
        Ok(())
    }
}

/// Update or insert `theme = "name"` line in Ghostty config
fn update_ghostty_theme_line(config: &str, theme_name: &str) -> String {
    let mut found = false;
    let mut lines: Vec<String> = config
        .lines()
        .map(|line| {
            let trimmed = line.trim();
            if trimmed.starts_with("theme") && trimmed.contains('=') {
                found = true;
                format!("theme = \"{}\"", theme_name)
            } else {
                line.to_string()
            }
        })
        .collect();

    if !found {
        lines.push(format!("theme = \"{}\"", theme_name));
    }

    let mut result = lines.join("\n");
    if !result.ends_with('\n') {
        result.push('\n');
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn update_existing_theme_line() {
        let config = "font-size = 14\ntheme = \"old-theme\"\nwindow-padding-x = 8\n";
        let result = update_ghostty_theme_line(config, "edith");
        assert!(result.contains("theme = \"edith\""));
        assert!(!result.contains("old-theme"));
    }

    #[test]
    fn insert_theme_line() {
        let config = "font-size = 14\nwindow-padding-x = 8\n";
        let result = update_ghostty_theme_line(config, "jarvis");
        assert!(result.contains("theme = \"jarvis\""));
    }
}
