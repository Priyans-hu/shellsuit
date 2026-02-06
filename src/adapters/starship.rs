use anyhow::{Context, Result};
use std::path::PathBuf;

use crate::adapters::Adapter;
use crate::state;
use crate::theme::Theme;

pub struct StarshipAdapter;

impl StarshipAdapter {
    fn config_path(&self) -> PathBuf {
        // Respect STARSHIP_CONFIG env var
        if let Ok(path) = std::env::var("STARSHIP_CONFIG") {
            return PathBuf::from(path);
        }
        dirs::config_dir()
            .unwrap_or_else(|| dirs::home_dir().unwrap_or_default().join(".config"))
            .join("starship.toml")
    }

    /// Inject shellsuit palette into existing starship.toml content
    fn inject_palette(&self, existing: &str, theme: &Theme) -> Result<String> {
        use toml_edit::{value, DocumentMut, Item, Table};

        let mut doc: DocumentMut = existing
            .parse()
            .context("failed to parse existing starship.toml")?;

        // Set palette = "shellsuit" at top level
        doc["palette"] = value("shellsuit");

        // Build palette table
        let mut palette = Table::new();

        // Core colors from theme
        palette["bg"] = value(theme.colors.background.hex());
        palette["fg"] = value(theme.colors.foreground.hex());
        palette["cursor"] = value(theme.colors.cursor.hex());

        // Semantic colors from prompt config or fallback to theme colors
        palette["path"] = value(
            theme
                .prompt
                .path_color
                .as_ref()
                .unwrap_or(&theme.colors.normal.blue)
                .hex(),
        );
        palette["git"] = value(
            theme
                .prompt
                .git_color
                .as_ref()
                .unwrap_or(&theme.colors.normal.yellow)
                .hex(),
        );
        palette["error"] = value(theme.colors.normal.red.hex());
        palette["success"] = value(theme.colors.normal.green.hex());
        palette["warn"] = value(theme.colors.normal.yellow.hex());
        palette["muted"] = value(
            theme
                .colors
                .bright
                .as_ref()
                .map(|b| &b.black)
                .unwrap_or(&theme.colors.normal.black)
                .hex(),
        );

        // ANSI colors for direct use
        palette["red"] = value(theme.colors.normal.red.hex());
        palette["green"] = value(theme.colors.normal.green.hex());
        palette["yellow"] = value(theme.colors.normal.yellow.hex());
        palette["blue"] = value(theme.colors.normal.blue.hex());
        palette["magenta"] = value(theme.colors.normal.magenta.hex());
        palette["cyan"] = value(theme.colors.normal.cyan.hex());

        // Ensure [palettes] table exists
        if doc.get("palettes").is_none() {
            doc["palettes"] = Item::Table(Table::new());
        }

        // Set [palettes.shellsuit]
        if let Some(palettes) = doc["palettes"].as_table_mut() {
            palettes["shellsuit"] = Item::Table(palette);
        }

        Ok(doc.to_string())
    }
}

impl Adapter for StarshipAdapter {
    fn name(&self) -> &str {
        "Starship"
    }

    fn detect(&self) -> bool {
        which::which("starship").is_ok()
    }

    fn apply(&self, theme: &Theme, _theme_slug: &str) -> Result<()> {
        let config_path = self.config_path();

        // Read existing config or start empty
        let existing = if config_path.exists() {
            // Backup first
            let _ = state::backup_file(&config_path, "starship.toml.bak");
            std::fs::read_to_string(&config_path).context("failed to read starship.toml")?
        } else {
            String::new()
        };

        // Inject palette
        let new_config = self.inject_palette(&existing, theme)?;

        // Ensure parent dir exists
        if let Some(parent) = config_path.parent() {
            std::fs::create_dir_all(parent).context("failed to create starship config directory")?;
        }

        std::fs::write(&config_path, &new_config).context("failed to write starship.toml")?;

        Ok(())
    }

    fn reload(&self) -> Result<()> {
        // Starship re-reads config on every prompt render — automatic
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::theme::resolve_theme;

    #[test]
    fn inject_palette_into_empty() {
        let adapter = StarshipAdapter;
        let theme = resolve_theme("edith").unwrap();
        let result = adapter.inject_palette("", &theme).unwrap();
        assert!(result.contains("palette = \"shellsuit\""));
        assert!(result.contains("[palettes.shellsuit]"));
        assert!(result.contains("bg = "));
    }

    #[test]
    fn inject_palette_preserves_existing() {
        let adapter = StarshipAdapter;
        let theme = resolve_theme("edith").unwrap();
        let existing = "add_newline = false\ncommand_timeout = 1000\n";
        let result = adapter.inject_palette(existing, &theme).unwrap();
        assert!(result.contains("add_newline = false"));
        assert!(result.contains("palette = \"shellsuit\""));
    }
}
