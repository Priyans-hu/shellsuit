use anyhow::{bail, Result};

/// Validated hex color (#RRGGBB format)
#[derive(Debug, Clone, serde::Deserialize)]
#[serde(try_from = "String")]
pub struct HexColor {
    pub r: u8,
    pub g: u8,
    pub b: u8,
    raw: String,
}

impl TryFrom<String> for HexColor {
    type Error = anyhow::Error;

    fn try_from(s: String) -> Result<Self> {
        parse_hex(&s)
    }
}

impl std::fmt::Display for HexColor {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.raw)
    }
}

impl HexColor {
    /// #RRGGBB (uppercase, with hash)
    pub fn hex(&self) -> &str {
        &self.raw
    }

    /// rrggbb (lowercase, no hash) — for Ghostty bg/fg/cursor
    pub fn bare_lower(&self) -> String {
        format!("{:02x}{:02x}{:02x}", self.r, self.g, self.b)
    }

    /// #RRGGBB (uppercase, with hash) — for Termux, Ghostty palette
    pub fn hash_upper(&self) -> String {
        format!("#{:02X}{:02X}{:02X}", self.r, self.g, self.b)
    }

    /// Print a colored block using ANSI true-color escape
    pub fn ansi_block(&self) -> String {
        format!("\x1b[48;2;{};{};{}m  \x1b[0m", self.r, self.g, self.b)
    }
}

fn parse_hex(s: &str) -> Result<HexColor> {
    let s = s.trim();
    let hex = s.strip_prefix('#').unwrap_or(s);

    if hex.len() != 6 {
        bail!("invalid hex color '{}': expected 6 hex digits", s);
    }

    let r = u8::from_str_radix(&hex[0..2], 16)
        .map_err(|_| anyhow::anyhow!("invalid hex color '{}'", s))?;
    let g = u8::from_str_radix(&hex[2..4], 16)
        .map_err(|_| anyhow::anyhow!("invalid hex color '{}'", s))?;
    let b = u8::from_str_radix(&hex[4..6], 16)
        .map_err(|_| anyhow::anyhow!("invalid hex color '{}'", s))?;

    let raw = format!("#{:02X}{:02X}{:02X}", r, g, b);
    Ok(HexColor { r, g, b, raw })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_with_hash() {
        let c: HexColor = "#FF5500".to_string().try_into().unwrap();
        assert_eq!(c.r, 255);
        assert_eq!(c.g, 85);
        assert_eq!(c.b, 0);
        assert_eq!(c.bare_lower(), "ff5500");
        assert_eq!(c.hash_upper(), "#FF5500");
    }

    #[test]
    fn parse_without_hash() {
        let c: HexColor = "0f1419".to_string().try_into().unwrap();
        assert_eq!(c.hex(), "#0F1419");
    }

    #[test]
    fn invalid_hex() {
        assert!(HexColor::try_from("ZZZZZZ".to_string()).is_err());
        assert!(HexColor::try_from("#FFF".to_string()).is_err());
    }
}
