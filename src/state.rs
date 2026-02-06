use anyhow::{Context, Result};
use std::path::PathBuf;

/// Get the shellsuit config directory (~/.config/shellsuit/)
fn config_dir() -> Result<PathBuf> {
    let dir = dirs::config_dir()
        .context("could not determine config directory")?
        .join("shellsuit");
    Ok(dir)
}

/// Read the currently active theme name
pub fn current_theme() -> Result<Option<String>> {
    let path = config_dir()?.join("current");
    if !path.exists() {
        return Ok(None);
    }
    let name = std::fs::read_to_string(&path)
        .context("failed to read current theme state")?
        .trim()
        .to_string();
    if name.is_empty() {
        Ok(None)
    } else {
        Ok(Some(name))
    }
}

/// Write the active theme name
pub fn set_current_theme(name: &str) -> Result<()> {
    let dir = config_dir()?;
    std::fs::create_dir_all(&dir).context("failed to create shellsuit config directory")?;
    std::fs::write(dir.join("current"), name).context("failed to write current theme state")?;
    Ok(())
}

/// Get the backups directory, creating it if needed
pub fn backups_dir() -> Result<PathBuf> {
    let dir = config_dir()?.join("backups");
    std::fs::create_dir_all(&dir).context("failed to create backups directory")?;
    Ok(dir)
}

/// Backup a file before overwriting (silent, best-effort)
pub fn backup_file(source: &std::path::Path, backup_name: &str) -> Result<()> {
    if !source.exists() {
        return Ok(());
    }
    let dir = backups_dir()?;
    std::fs::copy(source, dir.join(backup_name))
        .with_context(|| format!("failed to backup {}", source.display()))?;
    Ok(())
}
