use std::env;

#[derive(Debug, Clone, PartialEq)]
pub enum Terminal {
    Alacritty,
    Ghostty,
    Kitty,
    Termux,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Prompt {
    Starship,
}

impl std::fmt::Display for Terminal {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Terminal::Alacritty => write!(f, "Alacritty"),
            Terminal::Ghostty => write!(f, "Ghostty"),
            Terminal::Kitty => write!(f, "Kitty"),
            Terminal::Termux => write!(f, "Termux"),
        }
    }
}

impl std::fmt::Display for Prompt {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Prompt::Starship => write!(f, "Starship"),
        }
    }
}

/// Auto-detect the running terminal emulator
pub fn detect_terminal() -> Option<Terminal> {
    // Termux first — if on Android, skip desktop terminals
    if env::var("TERMUX_VERSION").is_ok() {
        return Some(Terminal::Termux);
    }

    // Check TERM_PROGRAM
    if let Ok(term) = env::var("TERM_PROGRAM") {
        match term.to_lowercase().as_str() {
            "ghostty" => return Some(Terminal::Ghostty),
            "xterm-kitty" => return Some(Terminal::Kitty),
            "alacritty" => return Some(Terminal::Alacritty),
            _ => {}
        }
    }

    // Check TERM for kitty
    if let Ok(term) = env::var("TERM") {
        if term == "xterm-kitty" {
            return Some(Terminal::Kitty);
        }
    }

    // Fallback: check if ghostty config exists
    if let Some(config_dir) = dirs::config_dir() {
        if config_dir.join("ghostty").join("config").exists() {
            return Some(Terminal::Ghostty);
        }
    }

    None
}

/// Auto-detect prompt engine
pub fn detect_prompt() -> Option<Prompt> {
    if which::which("starship").is_ok() {
        return Some(Prompt::Starship);
    }
    None
}

/// Parse terminal name from --terminal flag
pub fn parse_terminal(name: &str) -> Option<Terminal> {
    match name.to_lowercase().as_str() {
        "alacritty" => Some(Terminal::Alacritty),
        "ghostty" => Some(Terminal::Ghostty),
        "kitty" => Some(Terminal::Kitty),
        "termux" => Some(Terminal::Termux),
        _ => None,
    }
}
