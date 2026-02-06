use anyhow::{Context, Result};
use std::path::PathBuf;

use crate::adapters::Adapter;
use crate::state;
use crate::theme::Theme;

pub struct AlacrittyAdapter;

impl AlacrittyAdapter {
    fn config_dir(&self) -> Option<PathBuf> {
        dirs::config_dir().map(|d| d.join("alacritty"))
    }

    fn config_path(&self) -> Option<PathBuf> {
        self.config_dir().map(|d| d.join("alacritty.toml"))
    }

    fn theme_path(&self) -> Option<PathBuf> {
        self.config_dir().map(|d| d.join("themes").join("shellsuit.toml"))
    }

    fn render_theme(&self, theme: &Theme) -> String {
        let c = &theme.colors;
        let mut lines = Vec::new();

        lines.push("[colors.primary]".to_string());
        lines.push(format!("background = \"{}\"", c.background.hex()));
        lines.push(format!("foreground = \"{}\"", c.foreground.hex()));
        lines.push(String::new());

        lines.push("[colors.cursor]".to_string());
        lines.push(format!("cursor = \"{}\"", c.cursor.hex()));
        lines.push(format!("text = \"{}\"", c.sel_fg().hex()));
        lines.push(String::new());

        lines.push("[colors.selection]".to_string());
        lines.push(format!("background = \"{}\"", c.sel_bg().hex()));
        lines.push(format!("text = \"{}\"", c.sel_fg().hex()));
        lines.push(String::new());

        lines.push("[colors.normal]".to_string());
        lines.push(format!("black = \"{}\"", c.normal.black.hex()));
        lines.push(format!("red = \"{}\"", c.normal.red.hex()));
        lines.push(format!("green = \"{}\"", c.normal.green.hex()));
        lines.push(format!("yellow = \"{}\"", c.normal.yellow.hex()));
        lines.push(format!("blue = \"{}\"", c.normal.blue.hex()));
        lines.push(format!("magenta = \"{}\"", c.normal.magenta.hex()));
        lines.push(format!("cyan = \"{}\"", c.normal.cyan.hex()));
        lines.push(format!("white = \"{}\"", c.normal.white.hex()));
        lines.push(String::new());

        if let Some(ref b) = c.bright {
            lines.push("[colors.bright]".to_string());
            lines.push(format!("black = \"{}\"", b.black.hex()));
            lines.push(format!("red = \"{}\"", b.red.hex()));
            lines.push(format!("green = \"{}\"", b.green.hex()));
            lines.push(format!("yellow = \"{}\"", b.yellow.hex()));
            lines.push(format!("blue = \"{}\"", b.blue.hex()));
            lines.push(format!("magenta = \"{}\"", b.magenta.hex()));
            lines.push(format!("cyan = \"{}\"", b.cyan.hex()));
            lines.push(format!("white = \"{}\"", b.white.hex()));
            lines.push(String::new());
        }

        lines.join("\n")
    }
}

impl Adapter for AlacrittyAdapter {
    fn name(&self) -> &str {
        "Alacritty"
    }

    fn detect(&self) -> bool {
        // Check TERM_PROGRAM
        if let Ok(term) = std::env::var("TERM_PROGRAM") {
            if term.to_lowercase() == "alacritty" {
                return true;
            }
        }
        // Check if alacritty binary exists
        if which::which("alacritty").is_ok() {
            return true;
        }
        // Check if config exists
        self.config_path().map_or(false, |p| p.exists())
    }

    fn apply(&self, theme: &Theme, _theme_slug: &str) -> Result<()> {
        let themes_dir = self
            .config_dir()
            .map(|d| d.join("themes"))
            .context("could not determine Alacritty config directory")?;

        std::fs::create_dir_all(&themes_dir)
            .context("failed to create Alacritty themes directory")?;

        // Backup existing theme
        if let Some(theme_path) = self.theme_path() {
            let _ = state::backup_file(&theme_path, "alacritty-theme.bak");
        }

        // Write theme file
        let theme_path = self
            .theme_path()
            .context("could not determine Alacritty theme path")?;
        let content = self.render_theme(theme);
        std::fs::write(&theme_path, &content)
            .with_context(|| format!("failed to write Alacritty theme to {}", theme_path.display()))?;

        // Ensure import in main config
        if let Some(config_path) = self.config_path() {
            if config_path.exists() {
                let config = std::fs::read_to_string(&config_path)
                    .context("failed to read alacritty.toml")?;
                if !config.contains("themes/shellsuit.toml") {
                    let _ = state::backup_file(&config_path, "alacritty-conf.bak");
                    let import_line = "\n[general]\nimport = [\"~/.config/alacritty/themes/shellsuit.toml\"]\n";
                    let mut new_config = config;
                    new_config.push_str(import_line);
                    std::fs::write(&config_path, &new_config)
                        .context("failed to update alacritty.toml")?;
                }
            }
        }

        Ok(())
    }

    fn reload(&self) -> Result<()> {
        // Alacritty auto-reloads on config file change
        Ok(())
    }
}
