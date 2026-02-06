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
    },
    /// Show the currently active theme
    Current,
    /// Preview a theme's colors without applying
    Preview {
        /// Theme name to preview
        name: String,
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
        Commands::List { json } => cmd_list(json),
        Commands::Current => cmd_current(),
        Commands::Preview { name } => cmd_preview(&name),
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
                .with_context(|| format!("unknown terminal '{}'. supported: ghostty, termux", t))?,
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
                detect::Terminal::Ghostty => Box::new(adapters::ghostty::GhosttyAdapter),
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

fn cmd_list(json: bool) -> Result<()> {
    let themes = theme::list_themes()?;
    let current = state::current_theme()?.unwrap_or_default();

    if json {
        print!("[");
        for (i, t) in themes.iter().enumerate() {
            if i > 0 {
                print!(",");
            }
            print!(
                "{{\"name\":\"{}\",\"display_name\":\"{}\",\"description\":{},\"active\":{},\"builtin\":{}}}",
                t.name,
                t.display_name,
                t.description
                    .as_ref()
                    .map(|d| format!("\"{}\"", d.replace('"', "\\\"")))
                    .unwrap_or_else(|| "null".to_string()),
                t.name == current,
                t.builtin,
            );
        }
        println!("]");
        return Ok(());
    }

    println!();
    for t in &themes {
        let marker = if t.name == current { "*" } else { " " };
        let desc = t.description.as_deref().unwrap_or("");
        println!("  {} {:<20} {}", marker, t.name, desc);
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
