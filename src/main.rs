mod adapters;
mod color;
mod detect;
mod state;
mod theme;

use anyhow::{bail, Context, Result};
use clap::{Parser, Subcommand};

use adapters::Adapter;

#[derive(Parser)]
#[command(
    name = "shellsuit",
    about = "One command. Every layer. Your terminal, your way.",
    version
)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Apply a theme across terminal + prompt
    Apply {
        /// Theme name to apply
        name: String,
        /// Override terminal detection (ghostty, termux)
        #[arg(long)]
        terminal: Option<String>,
        /// Only apply terminal colors
        #[arg(long)]
        terminal_only: bool,
        /// Only apply prompt palette
        #[arg(long)]
        prompt_only: bool,
        /// Skip config backup
        #[arg(long)]
        no_backup: bool,
    },
    /// List available themes
    List {
        /// Output as JSON
        #[arg(long)]
        json: bool,
        /// Filter by tag (e.g., --tag dark)
        #[arg(long)]
        tag: Option<String>,
    },
    /// Show the currently active theme
    Current,
    /// Preview a theme's colors without applying
    Preview {
        /// Theme name to preview
        name: String,
    },
    /// Create a new theme from template or existing theme
    Create {
        /// Name for the new theme (lowercase, hyphens allowed)
        name: String,
        /// Clone from an existing theme as starting point
        #[arg(long, value_name = "THEME")]
        from: Option<String>,
    },
    /// Show a themed greeting (add to .zshrc/.bashrc for shell startup)
    Greet,
    /// Apply a random theme
    Random {
        /// Only pick from themes matching these tags
        #[arg(long)]
        tag: Option<String>,
    },
    /// Show detailed information about a theme
    Info {
        /// Theme name to inspect
        name: String,
    },
    /// Import a theme from a directory or .toml file
    Import {
        /// Path to theme directory or .toml file
        path: String,
        /// Name for the imported theme (default: directory name)
        #[arg(long)]
        name: Option<String>,
    },
    /// Export a theme as a standalone directory
    Export {
        /// Theme name to export
        name: String,
        /// Output directory (default: ./<theme-name>)
        #[arg(long, short)]
        output: Option<String>,
    },
    /// Output shell integration code
    #[command(name = "shell-init")]
    ShellInit {
        /// Shell type (zsh, bash)
        shell: String,
    },
}

fn main() {
    let cli = Cli::parse();

    let result = match cli.command {
        Commands::Apply {
            name,
            terminal,
            terminal_only,
            prompt_only,
            no_backup: _,
        } => cmd_apply(&name, terminal.as_deref(), terminal_only, prompt_only),
        Commands::List { json, tag } => cmd_list(json, tag.as_deref()),
        Commands::Current => cmd_current(),
        Commands::Preview { name } => cmd_preview(&name),
        Commands::Create { name, from } => cmd_create(&name, from.as_deref()),
        Commands::Greet => cmd_greet(),
        Commands::Random { tag } => cmd_random(tag.as_deref()),
        Commands::Info { name } => cmd_info(&name),
        Commands::Import { path, name } => cmd_import(&path, name.as_deref()),
        Commands::Export { name, output } => cmd_export(&name, output.as_deref()),
        Commands::ShellInit { shell } => cmd_shell_init(&shell),
    };

    if let Err(e) = result {
        eprintln!("error: {:#}", e);
        std::process::exit(1);
    }
}

fn cmd_apply(
    name: &str,
    terminal_override: Option<&str>,
    terminal_only: bool,
    prompt_only: bool,
) -> Result<()> {
    // Resolve theme
    let theme = theme::resolve_theme(name)?;

    // Detect or override terminal
    let detected_terminal = if let Some(t) = terminal_override {
        Some(
            detect::parse_terminal(t)
                .with_context(|| format!("unknown terminal '{}'. supported: alacritty, ghostty, kitty, termux", t))?,
        )
    } else {
        detect::detect_terminal()
    };

    let detected_prompt = detect::detect_prompt();

    let mut applied_any = false;

    // Apply terminal adapter
    if !prompt_only {
        if let Some(ref terminal) = detected_terminal {
            let adapter: Box<dyn Adapter> = match terminal {
                detect::Terminal::Alacritty => Box::new(adapters::alacritty::AlacrittyAdapter),
                detect::Terminal::Ghostty => Box::new(adapters::ghostty::GhosttyAdapter),
                detect::Terminal::Kitty => Box::new(adapters::kitty::KittyAdapter),
                detect::Terminal::Termux => Box::new(adapters::termux::TermuxAdapter),
            };

            adapter
                .apply(&theme, name)
                .with_context(|| format!("failed to apply {} theme", adapter.name()))?;
            adapter.reload()?;
            println!("  \x1b[32m✓\x1b[0m {} colors applied", adapter.name());
            applied_any = true;
        }
    }

    // Apply prompt adapter
    if !terminal_only {
        if let Some(detect::Prompt::Starship) = detected_prompt {
            let adapter = adapters::starship::StarshipAdapter;
            adapter
                .apply(&theme, name)
                .context("failed to apply Starship palette")?;
            adapter.reload()?;
            println!("  \x1b[32m✓\x1b[0m Starship palette injected");
            applied_any = true;
        }
    }

    if !applied_any {
        if detected_terminal.is_none() && !prompt_only {
            eprintln!(
                "  \x1b[33m!\x1b[0m Could not detect terminal. Use --terminal to specify."
            );
        }
        if detected_prompt.is_none() && !terminal_only {
            eprintln!("  \x1b[33m!\x1b[0m Starship not found in PATH. Prompt colors skipped.");
        }
        bail!("no adapters could be applied");
    }

    // Save current theme
    state::set_current_theme(name)?;
    println!(
        "  Theme \x1b[1m\"{}\"\x1b[0m is now active.",
        theme.metadata.name
    );

    Ok(())
}

fn cmd_list(json: bool, tag_filter: Option<&str>) -> Result<()> {
    let all_themes = theme::list_themes()?;
    let current = state::current_theme()?.unwrap_or_default();

    // Filter by tag if requested (tags are now on ThemeEntry directly)
    let themes: Vec<&theme::ThemeEntry> = if let Some(tag) = tag_filter {
        all_themes
            .iter()
            .filter(|t| t.tags.iter().any(|tt| tt == tag))
            .collect()
    } else {
        all_themes.iter().collect()
    };

    if json {
        print!("[");
        for (i, t) in themes.iter().enumerate() {
            if i > 0 {
                print!(",");
            }
            let tags_json: Vec<String> = t.tags.iter().map(|tag| format!("\"{}\"", tag)).collect();
            print!(
                "{{\"name\":\"{}\",\"display_name\":\"{}\",\"description\":{},\"tags\":[{}],\"active\":{},\"builtin\":{}}}",
                t.name,
                t.display_name,
                t.description
                    .as_ref()
                    .map(|d| format!("\"{}\"", d.replace('"', "\\\"")))
                    .unwrap_or_else(|| "null".to_string()),
                tags_json.join(","),
                t.name == current,
                t.builtin,
            );
        }
        println!("]");
        return Ok(());
    }

    println!();
    if themes.is_empty() {
        if let Some(tag) = tag_filter {
            println!("  No themes found with tag \"{}\".", tag);
        } else {
            println!("  No themes found.");
        }
    } else {
        for t in &themes {
            let marker = if t.name == current { "*" } else { " " };
            let desc = t.description.as_deref().unwrap_or("");
            let tags = if t.tags.is_empty() {
                String::new()
            } else {
                format!(" \x1b[90m[{}]\x1b[0m", t.tags.join(", "))
            };
            println!("  {} {:<20} {}{}", marker, t.name, desc, tags);
        }
    }
    println!();
    if !current.is_empty() {
        println!("  * = currently active");
    }

    Ok(())
}

fn cmd_current() -> Result<()> {
    let current = state::current_theme()?;
    match current {
        None => {
            println!("No theme applied. Run: shellsuit apply <theme>");
        }
        Some(name) => {
            let theme = theme::resolve_theme(&name)?;
            println!();
            println!("  Theme: {}", theme.metadata.name);
            println!("  Author: {}", theme.metadata.author);
            if let Some(ref desc) = theme.metadata.description {
                println!("  Description: {}", desc);
            }
            println!();
            print_color_swatches(&theme);
        }
    }
    Ok(())
}

fn cmd_preview(name: &str) -> Result<()> {
    let theme = theme::resolve_theme(name)?;
    println!();
    let desc = theme.metadata.description.as_deref().unwrap_or("");
    println!("  Theme: {} — {}", theme.metadata.name, desc);
    println!();
    print_color_swatches(&theme);
    println!();
    println!("  Apply with: shellsuit apply {}", name);
    Ok(())
}

fn cmd_info(name: &str) -> Result<()> {
    let theme = theme::resolve_theme(name)?;
    let m = &theme.metadata;

    println!();
    println!("  \x1b[1m{}\x1b[0m ({})", m.name, name);
    println!("  Author: {}", m.author);
    println!("  Version: {}", m.version);
    if let Some(ref desc) = m.description {
        println!("  Description: {}", desc);
    }
    if !m.tags.is_empty() {
        println!("  Tags: {}", m.tags.join(", "));
    }

    // Show prompt config if present
    if theme.prompt.icon.is_some() || theme.prompt.success_symbol.is_some() {
        println!();
        println!("  Prompt:");
        if let Some(ref icon) = theme.prompt.icon {
            println!("    Icon: {}", icon);
        }
        if let Some(ref s) = theme.prompt.success_symbol {
            println!("    Success: {}", s);
        }
        if let Some(ref s) = theme.prompt.error_symbol {
            println!("    Error: {}", s);
        }
    }

    // Show greeting config if present
    if theme.greeting.name.is_some() || !theme.greeting.quotes.is_empty() {
        println!();
        println!("  Greeting:");
        if let Some(ref n) = theme.greeting.name {
            println!("    AI Name: {}", n);
        }
        if let Some(ref a) = theme.greeting.address {
            println!("    Address: {}", a);
        }
        if !theme.greeting.quotes.is_empty() {
            println!("    Quotes: {} loaded", theme.greeting.quotes.len());
        }
    }

    // Show colors
    println!();
    print_color_swatches(&theme);
    println!();

    Ok(())
}

fn cmd_create(name: &str, from: Option<&str>) -> Result<()> {
    // Validate name
    if !name
        .chars()
        .all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '-')
    {
        bail!("theme name must be lowercase alphanumeric with hyphens only");
    }

    let themes_dir = theme::user_themes_dir().context("could not determine themes directory")?;
    let theme_dir = themes_dir.join(name);

    if theme_dir.exists() {
        bail!(
            "theme '{}' already exists at {}",
            name,
            theme_dir.display()
        );
    }

    std::fs::create_dir_all(&theme_dir)
        .with_context(|| format!("failed to create {}", theme_dir.display()))?;

    let content = if let Some(source) = from {
        // Clone from existing theme
        let source_theme = theme::resolve_theme(source)?;
        let source_toml = theme::resolve_theme_raw(source)?;
        println!(
            "  \x1b[32m✓\x1b[0m Cloned from \"{}\"",
            source_theme.metadata.name
        );
        source_toml
    } else {
        // Generate template
        theme::template_theme_toml(name)
    };

    let theme_file = theme_dir.join("theme.toml");
    std::fs::write(&theme_file, &content)
        .with_context(|| format!("failed to write {}", theme_file.display()))?;

    println!();
    println!("  Created theme scaffold:");
    println!("    {}/", theme_dir.display());
    println!("    └── theme.toml");
    println!();
    println!(
        "  Edit theme.toml, then run: shellsuit apply {}",
        name
    );

    Ok(())
}

fn cmd_greet() -> Result<()> {
    let current = state::current_theme()?;
    let name = match current {
        Some(n) => n,
        None => {
            // No theme active, print a default greeting
            println!("  shellsuit — no theme active");
            return Ok(());
        }
    };

    let theme = theme::resolve_theme(&name)?;
    let greeting = &theme.greeting;

    // Time-based greeting
    let hour: u32 = {
        use std::time::{SystemTime, UNIX_EPOCH};
        let secs = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        // Rough local hour — good enough for greeting
        // Use timezone offset from system
        let local_secs = secs as i64 + local_utc_offset_secs();
        ((local_secs % 86400) / 3600) as u32
    };

    let time_greeting = if hour >= 5 && hour < 12 {
        "Good morning"
    } else if hour >= 12 && hour < 17 {
        "Good afternoon"
    } else if hour >= 17 && hour < 21 {
        "Good evening"
    } else {
        "Working late"
    };

    let ai_name = greeting
        .name
        .as_deref()
        .unwrap_or(&theme.metadata.name);
    let address = greeting.address.as_deref().unwrap_or("user");
    let icon = theme.prompt.icon.as_deref().unwrap_or("◆");

    // Pick a random quote
    let quote = if !greeting.quotes.is_empty() {
        use std::time::{SystemTime, UNIX_EPOCH};
        let seed = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis() as usize;
        &greeting.quotes[seed % greeting.quotes.len()]
    } else {
        "Ready."
    };

    // Use theme accent color for the box
    let accent = &theme.colors.cursor;
    let fg_color = &theme.colors.foreground;
    let muted = theme
        .colors
        .bright
        .as_ref()
        .map(|b| &b.black)
        .unwrap_or(&theme.colors.normal.black);

    let c1 = format!("\x1b[38;2;{};{};{}m", accent.r, accent.g, accent.b);
    let c2 = format!("\x1b[38;2;{};{};{}m", fg_color.r, fg_color.g, fg_color.b);
    let dim = format!("\x1b[38;2;{};{};{}m", muted.r, muted.g, muted.b);
    let reset = "\x1b[0m";

    println!();
    println!(
        "  {c1}╭──────────────────────────────────────────────╮{reset}"
    );
    println!(
        "  {c1}│{reset}  {c1}{icon}{reset}  {c1}{ai_name}{reset} {dim}v1.0{reset}                        {c1}│{reset}"
    );
    println!(
        "  {c1}│{reset}                                              {c1}│{reset}"
    );
    println!(
        "  {c1}│{reset}  {c2}{time_greeting}, {address}.{reset}                      {c1}│{reset}"
    );
    println!(
        "  {c1}│{reset}  {dim}{quote}{reset}"
    );
    println!(
        "  {c1}╰──────────────────────────────────────────────╯{reset}"
    );
    println!();

    Ok(())
}

fn cmd_random(tag_filter: Option<&str>) -> Result<()> {
    let themes = theme::list_themes()?;

    let filtered: Vec<&theme::ThemeEntry> = if let Some(tag) = tag_filter {
        // Need to load full theme to check tags
        themes
            .iter()
            .filter(|t| {
                if let Ok(full) = theme::resolve_theme(&t.name) {
                    full.metadata.tags.iter().any(|tt| tt == tag)
                } else {
                    false
                }
            })
            .collect()
    } else {
        themes.iter().collect()
    };

    if filtered.is_empty() {
        bail!("no themes found matching filter");
    }

    // Pick random
    use std::time::{SystemTime, UNIX_EPOCH};
    let seed = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_nanos() as usize;
    let picked = &filtered[seed % filtered.len()];

    println!("  Rolling the dice... \x1b[1m{}\x1b[0m!", picked.name);
    cmd_apply(&picked.name, None, false, false)
}

fn cmd_import(path: &str, name_override: Option<&str>) -> Result<()> {
    let source = std::path::Path::new(path);

    if !source.exists() {
        bail!("path '{}' does not exist", path);
    }

    // Determine source TOML content and theme name
    let (content, inferred_name) = if source.is_dir() {
        let theme_file = source.join("theme.toml");
        if !theme_file.exists() {
            bail!(
                "directory '{}' does not contain a theme.toml file",
                path
            );
        }
        let content = std::fs::read_to_string(&theme_file)
            .with_context(|| format!("failed to read {}", theme_file.display()))?;
        let dir_name = source
            .file_name()
            .map(|n| n.to_string_lossy().to_string())
            .unwrap_or_else(|| "imported".to_string());
        (content, dir_name)
    } else {
        // Single .toml file
        let content = std::fs::read_to_string(source)
            .with_context(|| format!("failed to read {}", source.display()))?;
        let file_stem = source
            .file_stem()
            .map(|n| n.to_string_lossy().to_string())
            .unwrap_or_else(|| "imported".to_string());
        (content, file_stem)
    };

    // Validate the TOML parses as a valid theme
    let _theme: theme::Theme = toml::from_str(&content)
        .with_context(|| format!("'{}' is not a valid shellsuit theme", path))?;

    let theme_name = name_override.unwrap_or(&inferred_name);
    let themes_dir = theme::user_themes_dir().context("could not determine themes directory")?;
    let dest_dir = themes_dir.join(theme_name);

    if dest_dir.exists() {
        bail!(
            "theme '{}' already exists. Remove it first or use --name to pick a different name.",
            theme_name
        );
    }

    std::fs::create_dir_all(&dest_dir)
        .with_context(|| format!("failed to create {}", dest_dir.display()))?;

    let dest_file = dest_dir.join("theme.toml");
    std::fs::write(&dest_file, &content)
        .with_context(|| format!("failed to write {}", dest_file.display()))?;

    println!();
    println!(
        "  \x1b[32m✓\x1b[0m Imported theme \"{}\" to {}",
        theme_name,
        dest_dir.display()
    );
    println!("  Apply with: shellsuit apply {}", theme_name);

    Ok(())
}

fn cmd_export(name: &str, output_dir: Option<&str>) -> Result<()> {
    let content = theme::resolve_theme_raw(name)?;

    // Validate it still parses
    let theme: theme::Theme = toml::from_str(&content)
        .with_context(|| format!("theme '{}' failed to parse", name))?;

    let dest = output_dir
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|| std::path::PathBuf::from(name));

    if dest.exists() {
        bail!(
            "output directory '{}' already exists. Remove it or use --output.",
            dest.display()
        );
    }

    std::fs::create_dir_all(&dest)
        .with_context(|| format!("failed to create {}", dest.display()))?;

    let theme_file = dest.join("theme.toml");
    std::fs::write(&theme_file, &content)
        .with_context(|| format!("failed to write {}", theme_file.display()))?;

    println!();
    println!(
        "  \x1b[32m✓\x1b[0m Exported \"{}\" to {}/",
        theme.metadata.name,
        dest.display()
    );
    println!("    └── theme.toml");

    Ok(())
}

fn cmd_shell_init(shell: &str) -> Result<()> {
    match shell {
        "zsh" => {
            println!(r#"# shellsuit shell integration
# Add this to your ~/.zshrc:
#   eval "$(shellsuit shell-init zsh)"

if command -v shellsuit &>/dev/null; then
  export SHELLSUIT_CURRENT="$(cat ~/.config/shellsuit/current 2>/dev/null)"

  shellsuit-greet() {{
    shellsuit greet 2>/dev/null
  }}

  # Show greeting on new interactive shells
  [[ -o interactive ]] && shellsuit-greet
fi"#);
        }
        "bash" => {
            println!(r#"# shellsuit shell integration
# Add this to your ~/.bashrc:
#   eval "$(shellsuit shell-init bash)"

if command -v shellsuit &>/dev/null; then
  export SHELLSUIT_CURRENT="$(cat ~/.config/shellsuit/current 2>/dev/null)"

  shellsuit-greet() {{
    shellsuit greet 2>/dev/null
  }}

  # Show greeting on new interactive shells
  [[ $- == *i* ]] && shellsuit-greet
fi"#);
        }
        _ => bail!("unsupported shell '{}'. supported: zsh, bash", shell),
    }
    Ok(())
}

/// Get local UTC offset in seconds (rough — uses libc on unix)
fn local_utc_offset_secs() -> i64 {
    #[cfg(unix)]
    {
        extern "C" {
            fn time(t: *mut i64) -> i64;
            fn localtime(t: *const i64) -> *const Tm;
        }
        #[repr(C)]
        struct Tm {
            tm_sec: i32,
            tm_min: i32,
            tm_hour: i32,
            _tm_mday: i32,
            _tm_mon: i32,
            _tm_year: i32,
            _tm_wday: i32,
            _tm_yday: i32,
            _tm_isdst: i32,
            tm_gmtoff: i64,
        }
        unsafe {
            let mut t: i64 = 0;
            time(&mut t);
            let tm = localtime(&t);
            if tm.is_null() {
                0
            } else {
                (*tm).tm_gmtoff
            }
        }
    }
    #[cfg(not(unix))]
    {
        0
    }
}

fn print_color_swatches(theme: &theme::Theme) {
    let c = &theme.colors;

    println!(
        "  bg: {} {}   fg: {} {}   cursor: {} {}",
        c.background.ansi_block(),
        c.background.hex(),
        c.foreground.ansi_block(),
        c.foreground.hex(),
        c.cursor.ansi_block(),
        c.cursor.hex(),
    );

    println!();
    print!("  Normal: ");
    for color in c.normal_ordered() {
        print!("{} ", color.ansi_block());
    }
    println!();

    print!("  Bright: ");
    for color in c.bright_ordered() {
        print!("{} ", color.ansi_block());
    }
    println!();
}
