// ═══════════════════════════════════════════════════════════════
// 🦀 RUUPING — OFFICIAL NATIVE RUST RUNTIME & CLI v2.1.0
// Next-Generation High-Speed Looping Variant
// Developed by Holo Entertainment (Coki Studios)
// ═══════════════════════════════════════════════════════════════

mod evaluator;
mod python;
mod repl;
mod value;

use colored::*;
use evaluator::RuupingEngine;
use std::env;

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();
    let mut engine = RuupingEngine::new();

    if args.is_empty() || args.contains(&"--help".to_string()) || args.contains(&"-h".to_string()) {
        engine.print_banner();
        println!("{}", "Usage:".bold());
        println!("  ruuping <file.ruup | file.loop>             Execute script with native Rust performance");
        println!("  ruuping --gui <file.ruup | file.loop> [-v]  Launch native desktop window @ 60 FPS");
        println!("  ruuping build <file.ruup | file.loop> [-o]  Compile to Standalone Executable HTML5/Game");
        println!("  ruuping compile <file> [-o <out.html>]      Alias for build");
        println!("  ruuping eval \"<code>\"                       Evaluate inline code or expression");
        println!("  ruuping repl                                Start interactive low-latency Rust shell");
        println!("  ruuping --version                           Display Ruuping version info\n");
        return;
    }

    if args.contains(&"--version".to_string()) || (args.contains(&"-v".to_string()) && args.len() == 1) {
        println!("🦀 Ruuping Runtime v2.1.0 (Native Rust Edition / Holo Looping OoS)");
        return;
    }

    if args[0] == "repl" {
        repl::start_repl(&mut engine);
    } else if args[0] == "eval" {
        let code = args[1..].join(" ").replace(";", "\n");
        engine.execute_script(&code);
    } else if args.contains(&"--gui".to_string()) || args.contains(&"-g".to_string()) {
        let is_verbose = args.contains(&"--verbose".to_string()) || args.contains(&"-v".to_string());
        let file = args.iter().find(|a| a.ends_with(".ruup") || a.ends_with(".loop"))
            .cloned()
            .unwrap_or_else(|| args[1].clone());
        engine.launch_gui(&file, is_verbose);
    } else if args[0] == "build" || args[0] == "compile" {
        let file = if args.len() > 1 { &args[1] } else { "" };
        if file.is_empty() {
            eprintln!("{} Error: No target file provided for build.", "❌".red());
            std::process::exit(1);
        }
        let mut out_file = None;
        if let Some(pos) = args.iter().position(|x| x == "-o") {
            if pos + 1 < args.len() {
                out_file = Some(args[pos + 1].as_str());
            }
        }
        engine.compile_to_standalone(file, out_file);
    } else if args[0] == "run" && args.len() > 1 {
        engine.run_file(&args[1]);
    } else {
        engine.run_file(&args[0]);
    }
}
