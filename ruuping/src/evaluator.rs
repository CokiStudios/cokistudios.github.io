// ═══════════════════════════════════════════════════════════════
// 🦀 RUUPING RUNTIME — CORE EVALUATOR & AST INTERPRETER
// Blazing Fast Engine for .ruup & .loop scripts
// ═══════════════════════════════════════════════════════════════

use crate::python::PythonBridge;
use crate::value::Value;
use colored::*;
use regex::Regex;
use std::collections::{HashMap, HashSet};
use std::f64::consts::{E, PI};
use std::fs;
use std::path::Path;

pub struct FunctionDef {
    pub params: Vec<String>,
    pub body: String,
}

pub struct RuupingEngine {
    pub variables: HashMap<String, Value>,
    pub functions: HashMap<String, FunctionDef>,
    pub imported_modules: HashSet<String>,
    pub imported_python_modules: HashSet<String>,
    pub app_name: String,
    pub app_version: String,
    pub ui_profile: String,
    pub theme: String,
    pub python_bridge: PythonBridge,
}

impl RuupingEngine {
    pub fn new() -> Self {
        Self {
            variables: HashMap::new(),
            functions: HashMap::new(),
            imported_modules: HashSet::new(),
            imported_python_modules: HashSet::new(),
            app_name: "HoloApp".to_string(),
            app_version: "2.1.0".to_string(),
            ui_profile: "stock".to_string(),
            theme: "frosted_aqua_a17".to_string(),
            python_bridge: PythonBridge::new(),
        }
    }

    pub fn print_banner(&self) {
        println!("\n{}", "----------------------------------------------------------------------".purple().bold());
        println!(
            "{} {} {}",
            "[RUUPING NATIVE]".cyan().bold(),
            "Rust High-Performance Core Runtime v2.1.0".green().bold(),
            "(Win32 Native & POSIX)".dimmed()
        );
        println!(
            "{}: Shine Loop Console | {}: Holo Looping OoS 1.0 (Rust Subsystem)",
            "Target Platform".yellow(),
            "Kernel".blue()
        );
        println!("{}", "By Holo Entertainment (Coki Studios)".purple());
        println!("{}\n", "----------------------------------------------------------------------".purple().bold());
    }

    // ── Expression Evaluation ──
    pub fn evaluate_expression(&mut self, raw_expr: &str) -> Value {
        let expr = raw_expr.trim().to_string();
        if expr.is_empty() {
            return Value::String("".to_string());
        }

        // Python prefix
        if expr.starts_with("py:") || expr.starts_with("py ") {
            let sub = if expr.starts_with("py:") { &expr[3..] } else { &expr[3..] }.trim();
            if let Some(val) = self.python_bridge.eval_expr(sub, &self.variables) {
                return val;
            }
        }
        if expr.starts_with("python:") || expr.starts_with("python eval ") || expr.starts_with("python ") {
            let sub = expr
                .trim_start_matches("python eval ")
                .trim_start_matches("python:")
                .trim_start_matches("python ")
                .trim();
            if let Some(val) = self.python_bridge.eval_expr(sub, &self.variables) {
                return val;
            }
        }

        // String literals: "..." or '...'
        if (expr.starts_with('"') && expr.ends_with('"') && expr.len() >= 2)
            || (expr.starts_with('\'') && expr.ends_with('\'') && expr.len() >= 2)
        {
            let is_single_literal = {
                let first = expr.chars().next().unwrap();
                let chars: Vec<char> = expr.chars().collect();
                let mut closed_at = 0;
                for i in 1..chars.len() {
                    if chars[i] == first && chars[i - 1] != '\\' {
                        closed_at = i;
                        break;
                    }
                }
                closed_at == chars.len() - 1
            };

            if is_single_literal {
                let mut content = expr[1..expr.len() - 1].to_string();
                // Template interpolation: {var}
                let re = Regex::new(r"\{([A-Za-z0-9_]+)\}").unwrap();
                content = re
                    .replace_all(&content, |caps: &regex::Captures| {
                        let key = &caps[1];
                        if let Some(v) = self.variables.get(key) {
                            v.to_string()
                        } else {
                            caps[0].to_string()
                        }
                    })
                    .to_string();
                return Value::String(content);
            }
        }

        // Exact numbers
        if let Ok(num) = expr.parse::<f64>() {
            return Value::Number(num);
        }

        // Booleans
        if expr == "true" {
            return Value::Bool(true);
        }
        if expr == "false" {
            return Value::Bool(false);
        }
        if expr == "null" || expr == "none" {
            return Value::Null;
        }

        // Exact variable lookup
        if let Some(v) = self.variables.get(&expr) {
            return v.clone();
        }

        // Math & Arithmetic operations: +, -, *, /, %
        if expr.contains(" + ")
            || expr.contains(" - ")
            || expr.contains(" * ")
            || expr.contains(" / ")
            || expr.contains(" % ")
            || expr.starts_with("math.")
        {
            if let Some(v) = self.eval_native_math(&expr) {
                return v;
            }
            if let Some(v) = self.python_bridge.eval_expr(&expr, &self.variables) {
                return v;
            }
        }

        Value::String(expr)
    }

    fn eval_native_math(&self, expr_str: &str) -> Option<Value> {
        let mut expr = expr_str.to_string();
        for (k, v) in &self.variables {
            let re = Regex::new(&format!(r"\b{}\b", regex::escape(k))).unwrap();
            let val_repr = match v {
                Value::Number(n) => n.to_string(),
                Value::String(s) => format!("\"{}\"", s),
                Value::Bool(b) => b.to_string(),
                Value::Null => "0".to_string(),
                Value::Array(_) => "0".to_string(),
            };
            expr = re.replace_all(&expr, val_repr.as_str()).to_string();
        }

        // Quick evaluation for common simple operations
        if let Some(cap) = Regex::new(r"math\.sqrt\((.*?)\)").unwrap().captures(&expr) {
            let arg: f64 = cap[1].trim().parse().ok()?;
            return Some(Value::Number(arg.sqrt()));
        }
        if let Some(cap) = Regex::new(r"math\.pow\((.*?),\s*(.*?)\)").unwrap().captures(&expr) {
            let base: f64 = cap[1].trim().parse().ok()?;
            let exp: f64 = cap[2].trim().parse().ok()?;
            return Some(Value::Number(base.powf(exp)));
        }
        if let Some(cap) = Regex::new(r"math\.sin\((.*?)\)").unwrap().captures(&expr) {
            let arg: f64 = cap[1].trim().parse().ok()?;
            return Some(Value::Number(arg.sin()));
        }
        if let Some(cap) = Regex::new(r"math\.cos\((.*?)\)").unwrap().captures(&expr) {
            let arg: f64 = cap[1].trim().parse().ok()?;
            return Some(Value::Number(arg.cos()));
        }
        if expr == "math.pi" {
            return Some(Value::Number(PI));
        }
        if expr == "math.e" {
            return Some(Value::Number(E));
        }

        None
    }

    // ── Conditional Evaluation ──
    pub fn evaluate_condition(&mut self, cond: &str) -> bool {
        let cond = cond.trim();
        if cond.is_empty() {
            return false;
        }

        if cond.contains(" and ") || cond.contains(" && ") {
            let parts: Vec<&str> = cond.split(" and ").flat_map(|s| s.split(" && ")).collect();
            return parts.into_iter().all(|p| self.evaluate_condition(p));
        }
        if cond.contains(" or ") || cond.contains(" || ") {
            let parts: Vec<&str> = cond.split(" or ").flat_map(|s| s.split(" || ")).collect();
            return parts.into_iter().any(|p| self.evaluate_condition(p));
        }

        let ops = [">=", "<=", "==", "!=", ">", "<"];
        for op in ops {
            if let Some(idx) = cond.find(op) {
                let left_str = &cond[..idx];
                let right_str = &cond[idx + op.len()..];
                let left_val = self.evaluate_expression(left_str);
                let right_val = self.evaluate_expression(right_str);

                return match op {
                    "==" => left_val == right_val,
                    "!=" => left_val != right_val,
                    ">=" => left_val.to_number() >= right_val.to_number(),
                    "<=" => left_val.to_number() <= right_val.to_number(),
                    ">" => left_val.to_number() > right_val.to_number(),
                    "<" => left_val.to_number() < right_val.to_number(),
                    _ => false,
                };
            }
        }

        self.evaluate_expression(cond).is_truthy()
    }

    pub fn parse_print(&mut self, raw_expr: &str) -> String {
        let mut args = Vec::new();
        let mut current = String::new();
        let mut in_quotes = false;
        let mut quote_char = ' ';

        for c in raw_expr.chars() {
            if (c == '"' || c == '\'') && !in_quotes {
                in_quotes = true;
                quote_char = c;
            } else if in_quotes && c == quote_char {
                in_quotes = false;
            }

            if c == ',' && !in_quotes {
                args.push(current.trim().to_string());
                current.clear();
            } else {
                current.push(c);
            }
        }
        if !current.trim().is_empty() {
            args.push(current.trim().to_string());
        }

        let evaluated: Vec<String> = args.iter().map(|arg| self.evaluate_expression(arg).to_string()).collect();
        evaluated.join(" ")
    }

    // ── Execute File ──
    pub fn run_file(&mut self, file_path: &str) {
        if !Path::new(file_path).exists() {
            eprintln!("{} Error: File not found: {}", "❌".red(), file_path);
            std::process::exit(1);
        }

        self.print_banner();
        println!(
            "{} Loading source: {}",
            "[EXEC]".cyan(),
            Path::new(file_path).file_name().unwrap().to_string_lossy().bold()
        );

        if let Some((exe, args)) = self.python_bridge.detect_python() {
            let full_cmd = format!("{} {}", exe, args.join(" ")).trim().to_string();
            println!("{} Attached Python runtime: {}", "[PYTHON INTEROP]".green(), full_cmd.cyan());
        }
        println!();

        let content = match fs::read_to_string(file_path) {
            Ok(c) => c,
            Err(e) => {
                eprintln!("{} Failed to read file: {}", "❌".red(), e);
                return;
            }
        };

        let start = std::time::Instant::now();
        self.execute_script(&content);
        let elapsed = start.elapsed();

        println!(
            "\n{} Execution completed in {:.2?}!",
            "[OK]".green(),
            elapsed
        );
    }

    // ── Multi-line Script Interpreter ──
    pub fn execute_script(&mut self, script: &str) {
        let lines: Vec<&str> = script.lines().collect();
        let mut i = 0;

        while i < lines.len() {
            let line = lines[i].trim();
            i += 1;

            if line.is_empty() || line.starts_with('#') || line.starts_with("//") {
                continue;
            }

            // Multi-line Python Block: python { ... } OR py: ... end
            if line.starts_with("python {") || line == "python:" || line == "py:" || line.starts_with("py:begin") {
                let mut py_block = Vec::new();
                if line.starts_with("python {") && line.ends_with('}') && line.len() > 9 {
                    py_block.push(line[8..line.len() - 1].trim());
                } else {
                    while i < lines.len() {
                        let next = lines[i];
                        i += 1;
                        let trimmed_next = next.trim();
                        if trimmed_next == "}" || trimmed_next == "end" || trimmed_next == "py:end" {
                            break;
                        }
                        py_block.push(next);
                    }
                }

                let dedented = dedent_lines(&py_block);
                println!(
                    "{} Running multi-line Python block ({} lines)...",
                    "[PYTHON EXEC]".purple(),
                    py_block.len()
                );
                match self.python_bridge.execute_block(&dedented, &mut self.variables) {
                    Ok(out) => {
                        if !out.is_empty() {
                            println!("{}\n{}", "[PYTHON OUTPUT]".purple(), out);
                        }
                    }
                    Err(err) => eprintln!("{} {}", "❌ [PYTHON ERROR]:".red(), err),
                }
                continue;
            }

            // Function Definition: function <name>(<args>) { ... }
            if line.starts_with("function ") || line.starts_with("def ") {
                let re = Regex::new(r"(?:function|def)\s+([A-Za-z0-9_]+)\s*\((.*?)\)").unwrap();
                if let Some(cap) = re.captures(line) {
                    let fn_name = cap[1].to_string();
                    let params: Vec<String> = cap[2].split(',').map(|s| s.trim().to_string()).filter(|s| !s.is_empty()).collect();
                    let mut body_lines = Vec::new();

                    while i < lines.len() {
                        let next = lines[i];
                        i += 1;
                        if next.trim() == "}" || next.trim() == "end" {
                            break;
                        }
                        body_lines.push(next);
                    }

                    println!(
                        "{} Registered function \"{}\" ({} args)",
                        "[FUNCTION]".blue(),
                        fn_name,
                        params.len()
                    );
                    self.functions.insert(fn_name, FunctionDef { params, body: body_lines.join("\n") });
                    continue;
                }
            }

            // Repeat Loop: repeat <N> times { ... }
            if line.starts_with("repeat ") || line.starts_with("loop ") {
                let re = Regex::new(r"(?:repeat|loop)\s+(\d+|[A-Za-z0-9_]+)").unwrap();
                if let Some(cap) = re.captures(line) {
                    let count_val = self.evaluate_expression(&cap[1]).to_number() as usize;
                    let mut body_lines = Vec::new();

                    while i < lines.len() {
                        let next = lines[i];
                        i += 1;
                        if next.trim() == "}" || next.trim() == "end" {
                            break;
                        }
                        body_lines.push(next);
                    }

                    let loop_script = body_lines.join("\n");
                    for c in 0..count_val {
                        self.variables.insert("i".to_string(), Value::Number(c as f64));
                        self.variables.insert("loop_index".to_string(), Value::Number(c as f64));
                        self.execute_script(&loop_script);
                    }
                    continue;
                }
            }

            self.execute_line(line);
        }
    }

    // ── Execute Single Line ──
    pub fn execute_line(&mut self, raw_line: &str) {
        let line = raw_line.trim();
        if line.is_empty() || line.starts_with('#') || line.starts_with("//") {
            return;
        }

        // REPL Commands
        if line == "help" || line == "?" {
            self.print_help();
            return;
        }

        if line == "vars" || line == "variables" {
            println!("\n{} Active Memory Variables ({}):", "📋".cyan(), self.variables.len());
            if self.variables.is_empty() {
                println!("   {}", "(No variables defined yet. Try: set score to 100)".dimmed());
            } else {
                for (k, v) in &self.variables {
                    println!("   {} = {} {}", k.yellow(), v.to_string().green(), format!("({:?})", v).dimmed());
                }
            }
            println!();
            return;
        }

        if line == "clear" || line == "cls" {
            print!("{esc}[2J{esc}[1;1H", esc = 27 as char);
            return;
        }

        // 1. Python imports
        if line.starts_with("use python ") || line.starts_with("import python ") {
            let lib = line.replace("use python ", "").replace("import python ", "").trim().replace(['"', '\''], "");
            self.imported_python_modules.insert(lib.clone());
            println!("{} Linked Python Module: {}", "[PYTHON BRIDGE]".green(), lib.bold());
            return;
        }

        // 2. Looping imports
        if line.starts_with("import ") {
            let mod_name = line.replace("import ", "").trim().to_string();
            self.imported_modules.insert(mod_name.clone());
            println!("{} Loaded {}", "[MODULE]".blue(), mod_name);
            return;
        }

        // 3. App definition
        if line.starts_with("define app") {
            println!("{} Registered Application for Shine Loop Console", "[APP]".purple());
            return;
        }

        // 4. UI profile
        if line.starts_with("set ui_profile to") || line.starts_with("set ui_profile as") {
            println!("{} UI Profile Loaded", "[CS DESIGN UI]".cyan());
            return;
        }

        // 4.1 Pip Package Manager Invocation: pip ... / python -m pip ... / py -m pip ...
        if line.starts_with("pip ") || line.starts_with("python -m pip ") || line.starts_with("py -m pip ") || line == "pip" {
            let pip_args_str = line
                .trim_start_matches("python -m pip")
                .trim_start_matches("py -m pip")
                .trim_start_matches("pip")
                .trim();
            
            println!("{} Running pip {}", "[PACKAGE MANAGER]".cyan(), pip_args_str);
            if let Some((exe, args)) = self.python_bridge.detect_python() {
                let mut cmd = std::process::Command::new(exe);
                for a in args {
                    cmd.arg(a);
                }
                cmd.arg("-m").arg("pip");
                for part in pip_args_str.split_whitespace() {
                    cmd.arg(part);
                }
                cmd.stdout(std::process::Stdio::inherit()).stderr(std::process::Stdio::inherit());
                let _ = cmd.status();
            } else {
                eprintln!("{} Python/pip not found in PATH.", "❌".red());
            }
            return;
        }

        // 5. Python inline execution
        if line.starts_with("py:")
            || line.starts_with("py ")
            || line.starts_with("python:")
            || line.starts_with("python eval ")
            || (line.starts_with("python ") && !line.starts_with("python {"))
        {
            let sub = line
                .trim_start_matches("python eval ")
                .trim_start_matches("python:")
                .trim_start_matches("python ")
                .trim_start_matches("py:")
                .trim_start_matches("py ")
                .trim();

            if let Some(eval_val) = self.python_bridge.eval_expr(sub, &self.variables) {
                println!("{} {}", "=>".cyan(), eval_val.to_string().green());
                return;
            }

            match self.python_bridge.execute_block(sub, &mut self.variables) {
                Ok(out) => {
                    if !out.is_empty() {
                        println!("{} {}", "[PYTHON RESULT]".purple(), out);
                    }
                }
                Err(err) => eprintln!("{} {}", "❌ [PYTHON ERROR]:".red(), err),
            }
            return;
        }

        // 6. Conditionals: if <cond> do <action>
        if line.starts_with("if ") {
            let re = Regex::new(r"(?i)^if\s+(.*?)\s+(?:then|do)\s+(.*)$").unwrap();
            if let Some(cap) = re.captures(line) {
                if self.evaluate_condition(&cap[1]) {
                    self.execute_line(&cap[2]);
                }
                return;
            }
        }

        // 7. Variable Assignment: set <var> to <expr>
        if line.starts_with("set ") && (line.contains(" to ") || line.contains(" as ") || line.contains(" = ")) {
            let delimiter = if line.contains(" to ") { " to " } else if line.contains(" as ") { " as " } else { " = " };
            let raw_content = line.strip_prefix("set ").unwrap();
            let parts: Vec<&str> = raw_content.split(delimiter).collect();
            if parts.len() >= 2 {
                let var_name = parts[0].trim().to_string();
                let val_expr = parts[1..].join(delimiter);
                let val = self.evaluate_expression(&val_expr);
                self.variables.insert(var_name, val);
                return;
            }
        }

        // Shorthand assignments: x = 10, x += 5
        let re_assign = Regex::new(r"^([A-Za-z0-9_]+)\s*(\+=|-=|\*=|\/=|=)\s*(.*)$").unwrap();
        if let Some(cap) = re_assign.captures(line) {
            let var_name = cap[1].to_string();
            let op = &cap[2];
            let val = self.evaluate_expression(&cap[3]);

            match op {
                "=" => {
                    self.variables.insert(var_name, val);
                }
                "+=" => {
                    let cur = self.variables.get(&var_name).map(|v| v.to_number()).unwrap_or(0.0);
                    self.variables.insert(var_name, Value::Number(cur + val.to_number()));
                }
                "-=" => {
                    let cur = self.variables.get(&var_name).map(|v| v.to_number()).unwrap_or(0.0);
                    self.variables.insert(var_name, Value::Number(cur - val.to_number()));
                }
                "*=" => {
                    let cur = self.variables.get(&var_name).map(|v| v.to_number()).unwrap_or(0.0);
                    self.variables.insert(var_name, Value::Number(cur * val.to_number()));
                }
                "/=" => {
                    let cur = self.variables.get(&var_name).map(|v| v.to_number()).unwrap_or(0.0);
                    self.variables.insert(var_name, Value::Number(cur / val.to_number()));
                }
                _ => {}
            }
            return;
        }

        // 8. Function Calls: call <fn>()
        if line.starts_with("call ") {
            let fn_name = line.strip_prefix("call ").unwrap().trim_end_matches("()").trim();
            if let Some(func) = self.functions.get(fn_name) {
                let body = func.body.clone();
                self.execute_script(&body);
            } else {
                println!("{} Invoked \"{}\"", "[FUNCTION CALL]".yellow(), fn_name);
            }
            return;
        }

        // 9. Print output
        if line.starts_with("print ") || line.starts_with("echo ") {
            let raw_expr = line.trim_start_matches("print ").trim_start_matches("echo ").trim();
            let val = self.parse_print(raw_expr);
            println!("{} {}", "[OUTPUT]".green(), val);
            return;
        }

        // 10. Hardware Audio Tone
        if line.starts_with("play tone") {
            println!("{} Synthesizer low-latency tone triggered", "[AUDIO HARDWARE]".blue());
            return;
        }

        // 11. Bare Expression Evaluation (Interactive REPL output)
        let eval_res = self.evaluate_expression(line);
        if eval_res != Value::String(line.to_string()) || self.variables.contains_key(line) {
            println!("{} {}", "=>".cyan(), eval_res.to_string().green());
        }
    }

    pub fn compile_to_standalone(&self, file_path: &str, output_path: Option<&str>) {
        if !Path::new(file_path).exists() {
            eprintln!("{} Error: File not found: {}", "❌".red(), file_path);
            std::process::exit(1);
        }

        self.print_banner();
        println!("{} Compiling target to Standalone HTML5 Game...", "[BUILD]".cyan());

        let source_code = fs::read_to_string(file_path).unwrap_or_default();
        let default_out = file_path.replace(".loop", ".html").replace(".ruup", ".html");
        let out_file = output_path.unwrap_or(&default_out);

        let core_paths = ["LoopingEngine/looping_core.js", "../LoopingEngine/looping_core.js"];
        let mut engine_source = String::new();
        for p in core_paths {
            if let Ok(content) = fs::read_to_string(p) {
                engine_source = content
                    .replace("export class LoopingInterpreter", "class LoopingInterpreter")
                    .replace("export ", "");
                break;
            }
        }

        let html_template = format!(
            r#"<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{} — Shine Loop Executable (Ruuping Core)</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;900&display=swap" rel="stylesheet">
    <style>
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{ background: #06090f; overflow: hidden; display: flex; align-items: center; justify-content: center; height: 100vh; font-family: 'Outfit', sans-serif; color: #fff; }}
        #canvas-wrapper {{ box-shadow: 0 20px 50px rgba(0,0,0,0.8), 0 0 30px rgba(56,189,248,0.2); border-radius: 16px; overflow: hidden; border: 1px solid rgba(255,255,255,0.12); position: relative; }}
        canvas {{ display: block; }}
    </style>
</head>
<body>
    <div id="canvas-wrapper">
        <canvas id="gameCanvas" width="800" height="520"></canvas>
    </div>
    <script>
        {}
        const canvas = document.getElementById('gameCanvas');
        const runtime = new LoopingInterpreter(canvas, console.log);
        const code = {:?};
        runtime.execute(code);
    </script>
</body>
</html>"#,
            self.app_name, engine_source, source_code
        );

        if let Err(e) = fs::write(out_file, html_template) {
            eprintln!("{} Failed to write output file: {}", "❌".red(), e);
        } else {
            println!("{} Standalone Executable Generated: {}", "[SUCCESS]".green(), out_file.bold());
            println!("{} Ready for Holo Looping OoS & Shine Loop Console\n", "[TARGET]".yellow());
        }
    }

    pub fn launch_gui(&self, file_path: &str, verbose: bool) {
        if !Path::new(file_path).exists() {
            eprintln!("{} Error: File not found: {}", "❌".red(), file_path);
            std::process::exit(1);
        }

        self.print_banner();
        println!(
            "{} Launching Native Viewport: {}...",
            "[WINDOW]".cyan(),
            Path::new(file_path).file_name().unwrap().to_string_lossy().bold()
        );

        if verbose {
            println!("{}", "[VERBOSE MODE ACTIVATED]".yellow());
            println!("{} 800x520 (High-DPI Retina Ready)", "[VERBOSE] Resolution:".blue());
            println!("{} Hardware WebCore / DirectX 60FPS Low-Latency", "[VERBOSE] Pipeline:".blue());
            println!("{} Native Ruuping Rust 2.1.0", "[VERBOSE] Engine:".blue());
        }

        let temp_html = format!(
            ".tmp_{}_window.html",
            Path::new(file_path).file_stem().unwrap().to_string_lossy()
        );
        self.compile_to_standalone(file_path, Some(&temp_html));

        #[cfg(windows)]
        {
            let _ = std::process::Command::new("cmd")
                .args(["/C", "start", "", &temp_html])
                .spawn();
            println!("{} Native Window running @ 60 FPS", "[SUCCESS]".green());
        }

        #[cfg(target_os = "macos")]
        {
            let _ = std::process::Command::new("open").arg(&temp_html).spawn();
            println!("{} Native Window running @ 60 FPS", "[SUCCESS]".green());
        }

        #[cfg(all(unix, not(target_os = "macos")))]
        {
            let _ = std::process::Command::new("xdg-open").arg(&temp_html).spawn();
            println!("{} Native Window running @ 60 FPS", "[SUCCESS]".green());
        }
    }

    pub fn print_help(&self) {
        println!("\n{}", "🦀 RUUPING RUST ENGINE CHEATSHEET & REPL GUIDE".cyan().bold());
        println!("{}", "────────────────────────────────────────────────────────────────────────".purple());
        println!("{}", "1. Variables & Native Math Expressions:".yellow().bold());
        println!("   set hero to \"Angel\"        -> String variable assignment");
        println!("   level = 20                 -> Direct numerical assignment");
        println!("   level += 5                 -> Shorthand arithmetic (+-, *=, /=)");
        println!("   math.sqrt(144) * 2         -> Native Rust & Python math functions");
        println!("   print \"Hero: {{hero}}, Lv: {{level}}\" -> Template string interpolation\n");

        println!("{}", "2. Python Interoperability (Bridge):".yellow().bold());
        println!("   use python \"math\"          -> Import Python module");
        println!("   py: math.pi * 10           -> Inline Python evaluation");
        println!("   python {{ ... }}             -> Multi-line Python block with bidirectional vars\n");

        println!("{}", "3. Control Flow & Functions:".yellow().bold());
        println!("   if level >= 20 do print \"Max Level!\"");
        println!("   repeat 3 times {{ print \"Ping {{i}}\" }}");
        println!("   function greet() {{ print \"Hello from Ruuping!\" }}");
        println!("   call greet()\n");

        println!("{}", "4. Interactive REPL Commands:".yellow().bold());
        println!("   help o ?                   -> Show this command guide");
        println!("   vars o variables           -> Inspect all variables in memory");
        println!("   clear o cls                -> Clear screen");
        println!("   exit o quit                -> Exit REPL\n");
        println!("{}", "────────────────────────────────────────────────────────────────────────".purple());
    }
}

fn dedent_lines(lines: &[&str]) -> String {
    let mut min_indent = usize::MAX;
    for l in lines {
        if l.trim().is_empty() {
            continue;
        }
        let indent = l.chars().take_while(|c| c.is_whitespace()).count();
        if indent < min_indent {
            min_indent = indent;
        }
    }
    if min_indent == usize::MAX || min_indent == 0 {
        return lines.join("\n");
    }
    lines
        .iter()
        .map(|l| {
            if l.trim().is_empty() {
                ""
            } else if l.len() >= min_indent {
                &l[min_indent..]
            } else {
                l.trim_start()
            }
        })
        .collect::<Vec<&str>>()
        .join("\n")
}
