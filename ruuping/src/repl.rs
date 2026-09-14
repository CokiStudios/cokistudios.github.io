// ═══════════════════════════════════════════════════════════════
// 🦀 RUUPING RUNTIME — NATIVE INTERACTIVE REPL
// Ultra Low Latency Terminal Interface
// ═══════════════════════════════════════════════════════════════

use crate::evaluator::RuupingEngine;
use colored::*;
use std::io::{self, BufRead, Write};

pub fn start_repl(engine: &mut RuupingEngine) {
    engine.print_banner();
    println!("{}", "🦀 Ruuping Native Interactive REPL v2.1.0 (Rust Engine)".cyan());
    println!(
        "{}(Type {}{}{} for guide, {}{}{} for variables, {}{}{} to exit)\n",
        "".dimmed(),
        "help".green(),
        "".dimmed(),
        "",
        "vars".green(),
        "".dimmed(),
        "",
        "exit".green(),
        "".dimmed(),
        ""
    );

    let stdin = io::stdin();
    let mut multiline_buf: Vec<String> = Vec::new();
    let mut in_block = false;

    loop {
        if in_block {
            print!("{}", "...   ".dimmed());
        } else {
            print!("{} ", "ruuping>".purple().bold());
        }
        io::stdout().flush().unwrap();

        let mut line = String::new();
        if stdin.lock().read_line(&mut line).unwrap_or(0) == 0 {
            break; // EOF
        }

        let trimmed = line.trim();

        if !in_block && (trimmed == "exit" || trimmed == "quit") {
            println!("{}", "Goodbye! Ruuping Rust session closed.".cyan());
            break;
        }

        // Entering block
        if !in_block && (trimmed.ends_with('{') || trimmed == "python:" || trimmed == "py:" || trimmed == "py:begin") {
            in_block = true;
            multiline_buf.push(line);
            continue;
        }

        if in_block {
            let is_block_end = trimmed == "}" || trimmed == "end" || trimmed == "py:end";
            multiline_buf.push(line);
            if is_block_end {
                in_block = false;
                let full_script = multiline_buf.join("");
                multiline_buf.clear();
                engine.execute_script(&full_script);
            }
            continue;
        }

        if !trimmed.is_empty() {
            engine.execute_line(trimmed);
        }
    }
}
