use anyhow::{Context, Result};
use serde::Deserialize;
use std::collections::HashMap;
use std::path::PathBuf;

use crate::color::HexColor;

#[derive(Debug, Deserialize)]
pub struct Theme {
    pub metadata: Metadata,
    pub colors: Colors,
    #[serde(default)]
    pub prompt: PromptConfig,
    #[serde(default)]
    pub greeting: GreetingConfig,
}

#[derive(Debug, Deserialize)]
pub struct Metadata {
    pub name: String,
    pub author: String,
    #[serde(default)]
    pub description: Option<String>,
    pub version: String,
    #[serde(default)]
    pub tags: Vec<String>,
}

#[derive(Debug, Deserialize)]
pub struct Colors {
    pub background: HexColor,
    pub foreground: HexColor,
    pub cursor: HexColor,
    pub selection_bg: Option<HexColor>,
    pub selection_fg: Option<HexColor>,
    pub normal: AnsiColors,
    pub bright: Option<AnsiColors>,
}

#[derive(Debug, Deserialize)]
pub struct AnsiColors {
    pub black: HexColor,
    pub red: HexColor,
    pub green: HexColor,
    pub yellow: HexColor,
    pub blue: HexColor,
    pub magenta: HexColor,
    pub cyan: HexColor,
    pub white: HexColor,
}

#[derive(Debug, Deserialize, Default)]
pub struct PromptConfig {
    pub icon: Option<String>,
    pub home_symbol: Option<String>,
    pub path_color: Option<HexColor>,
    pub git_color: Option<HexColor>,
    pub success_symbol: Option<String>,
    pub error_symbol: Option<String>,
}

#[derive(Debug, Deserialize, Default)]
pub struct GreetingConfig {
    pub name: Option<String>,
    pub address: Option<String>,
    #[serde(default)]
    pub quotes: Vec<String>,
}

impl Colors {
    /// Selection background — falls back to cursor color
    pub fn sel_bg(&self) -> &HexColor {
        self.selection_bg.as_ref().unwrap_or(&self.cursor)
    }

    /// Selection foreground — falls back to background color
    pub fn sel_fg(&self) -> &HexColor {
        self.selection_fg.as_ref().unwrap_or(&self.background)
    }

    /// Get normal colors as ordered slice (ANSI 0-7)
    pub fn normal_ordered(&self) -> [&HexColor; 8] {
        [
            &self.normal.black,
            &self.normal.red,
            &self.normal.green,
            &self.normal.yellow,
            &self.normal.blue,
            &self.normal.magenta,
            &self.normal.cyan,
            &self.normal.white,
        ]
    }

    /// Get bright colors as ordered slice (ANSI 8-15), falling back to normal
    pub fn bright_ordered(&self) -> [&HexColor; 8] {
        match &self.bright {
            Some(b) => [
                &b.black, &b.red, &b.green, &b.yellow, &b.blue, &b.magenta, &b.cyan, &b.white,
            ],
            None => self.normal_ordered(),
        }
    }
}

/// Built-in themes embedded at compile time
const BUILTIN_THEMES: &[(&str, &str)] = &[
    ("edith", include_str!("../themes/edith.toml")),
    ("jarvis", include_str!("../themes/jarvis.toml")),
    ("friday", include_str!("../themes/friday.toml")),
    (
        "catppuccin-mocha",
        include_str!("../themes/catppuccin-mocha.toml"),
    ),
    ("tokyo-night", include_str!("../themes/tokyo-night.toml")),
];

/// Resolve a theme by name: check user dir first, then built-ins
pub fn resolve_theme(name: &str) -> Result<Theme> {
    // Check user themes directory
    if let Some(config_dir) = dirs::config_dir() {
        let user_theme = config_dir
            .join("shellsuit")
            .join("themes")
            .join(name)
            .join("theme.toml");
        if user_theme.exists() {
            let content = std::fs::read_to_string(&user_theme)
                .with_context(|| format!("failed to read {}", user_theme.display()))?;
            let theme: Theme = toml::from_str(&content)
                .with_context(|| format!("failed to parse {}", user_theme.display()))?;
            return Ok(theme);
        }
    }

    // Check built-in themes
    for (builtin_name, content) in BUILTIN_THEMES {
        if *builtin_name == name {
            let theme: Theme =
                toml::from_str(content).with_context(|| format!("failed to parse built-in theme '{}'", name))?;
            return Ok(theme);
        }
    }

    anyhow::bail!(
        "theme '{}' not found. Run `shellsuit list` to see available themes.",
        name
    );
}

/// List all available themes (user + built-in, deduplicated)
pub fn list_themes() -> Result<Vec<ThemeEntry>> {
    let mut themes: HashMap<String, ThemeEntry> = HashMap::new();

    // Built-in themes first
    for (name, content) in BUILTIN_THEMES {
        if let Ok(theme) = toml::from_str::<Theme>(content) {
            themes.insert(
                name.to_string(),
                ThemeEntry {
                    name: name.to_string(),
                    display_name: theme.metadata.name,
                    description: theme.metadata.description,
                    tags: theme.metadata.tags,
                    builtin: true,
                },
            );
        }
    }

    // User themes override built-ins
    if let Some(config_dir) = dirs::config_dir() {
        let themes_dir = config_dir.join("shellsuit").join("themes");
        if themes_dir.exists() {
            if let Ok(entries) = std::fs::read_dir(&themes_dir) {
                for entry in entries.flatten() {
                    if entry.file_type().map_or(false, |ft| ft.is_dir()) {
                        let name = entry.file_name().to_string_lossy().to_string();
                        let theme_file = entry.path().join("theme.toml");
                        if theme_file.exists() {
                            if let Ok(content) = std::fs::read_to_string(&theme_file) {
                                if let Ok(theme) = toml::from_str::<Theme>(&content) {
                                    themes.insert(
                                        name.clone(),
                                        ThemeEntry {
                                            name,
                                            display_name: theme.metadata.name,
                                            description: theme.metadata.description,
                                            tags: theme.metadata.tags,
                                            builtin: false,
                                        },
                                    );
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    let mut result: Vec<ThemeEntry> = themes.into_values().collect();
    result.sort_by(|a, b| a.name.cmp(&b.name));
    Ok(result)
}

#[derive(Debug)]
pub struct ThemeEntry {
    pub name: String,
    pub display_name: String,
    pub description: Option<String>,
    pub tags: Vec<String>,
    pub builtin: bool,
}

/// Get user themes directory path
pub fn user_themes_dir() -> Option<PathBuf> {
    dirs::config_dir().map(|d| d.join("shellsuit").join("themes"))
}

/// Resolve a theme's raw TOML content (for cloning)
pub fn resolve_theme_raw(name: &str) -> Result<String> {
    if let Some(config_dir) = dirs::config_dir() {
        let user_theme = config_dir
            .join("shellsuit")
            .join("themes")
            .join(name)
            .join("theme.toml");
        if user_theme.exists() {
            return std::fs::read_to_string(&user_theme)
                .with_context(|| format!("failed to read {}", user_theme.display()));
        }
    }

    for (builtin_name, content) in BUILTIN_THEMES {
        if *builtin_name == name {
            return Ok(content.to_string());
        }
    }

    anyhow::bail!("theme '{}' not found", name);
}

/// Generate a template theme.toml for a new theme
pub fn template_theme_toml(name: &str) -> String {
    format!(
        r##"[metadata]
name = "{name}"
author = "your-name"
description = "A custom shellsuit theme"
version = "1.0.0"
tags = ["dark", "custom"]

[colors]
background = "#1A1B26"
foreground = "#C0CAF5"
cursor = "#C0CAF5"
selection_bg = "#33467C"
selection_fg = "#C0CAF5"

[colors.normal]
black = "#15161E"
red = "#F7768E"
green = "#9ECE6A"
yellow = "#E0AF68"
blue = "#7AA2F7"
magenta = "#BB9AF7"
cyan = "#7DCFFF"
white = "#A9B1D6"

[colors.bright]
black = "#414868"
red = "#F7768E"
green = "#9ECE6A"
yellow = "#E0AF68"
blue = "#7AA2F7"
magenta = "#BB9AF7"
cyan = "#7DCFFF"
white = "#C0CAF5"

[prompt]
# icon = "◆"
# home_symbol = "HOME"
# path_color = "#7AA2F7"
# git_color = "#E0AF68"
# success_symbol = "❯"
# error_symbol = "✘"

[greeting]
# name = "{name}"
# address = "user"
# quotes = [
#   "Ready to go.",
#   "All systems online.",
# ]
"##,
        name = name
    )
}
