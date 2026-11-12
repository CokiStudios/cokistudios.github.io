#pragma once

#include "LoopingInterpreter.hpp"
#include <iostream>
#include <string>
#include <vector>
#include <unistd.h>
#include <signal.h>
#include <sys/wait.h>

namespace looping {

class REPL {
public:
    static void run(Interpreter& vm) {
        run_internal(vm, false, 0, "");
    }

    static void run_persistent(Interpreter& vm, pid_t win_pid = 0, const std::string& win_title = "") {
        run_internal(vm, true, win_pid, win_title);
    }

private:
    static void run_internal(Interpreter& vm, bool is_persistent, pid_t win_pid, const std::string& win_title) {
        if (is_persistent) {
            std::cout << color::BOLD << color::CYAN << "⚡ [PERSISTENT TERMINAL]" << color::RESET
                      << " Interactive Looping session active (Arch " << vm.arch_version << " • Metal 4 / Python Bridge)\n";
            if (!win_title.empty()) {
                std::cout << "  • Active Window : " << color::GREEN << win_title << color::RESET;
                if (win_pid > 0) std::cout << " (PID: " << win_pid << ")";
                std::cout << "\n";
            }
            std::cout << "  • Mode          : Persistent terminal session (like py -i) — window remains open.\n";
            std::cout << "  • Commands      : Type 'vars', 'funcs', 'metal4', 'window', or Looping statements. Type 'exit' to quit.\n\n";
        } else {
            vm.print_banner();
            std::cout << color::BOLD << color::CYAN << "✨ Welcome to " << vm.channel_name << " Interactive C++ Shell (v" << vm.engine_version << " • Arch " << vm.arch_version << ")" << color::RESET << "\n";
            std::cout << "Type 'help' for syntax guide, 'vars' for memory, 'funcs' for functions, 'bench' for speed test, 'reset' to clear state, 'exit' to quit.\n\n";
        }

        std::string line;
        std::vector<std::string> multiline_buffer;
        bool in_multiline = false;
        int brace_depth = 0;

        auto cleanup_window = [&]() {
            if (win_pid > 0) {
#ifndef _WIN32
                kill(win_pid, SIGTERM);
                int status = 0;
                waitpid(win_pid, &status, WNOHANG);
#endif
                win_pid = 0;
            }
        };

        while (true) {
            if (!in_multiline) {
                std::cout << color::BOLD << color::CYAN << "looping> " << color::RESET;
            } else {
                std::cout << color::PURPLE << "   ...> " << color::RESET;
            }

            if (!std::getline(std::cin, line)) {
                cleanup_window();
                break;
            }

            // Trim
            size_t start = line.find_first_not_of(" \t\r\n");
            std::string trimmed = (start == std::string::npos) ? "" : line.substr(start);
            while (!trimmed.empty() && (trimmed.back() == ' ' || trimmed.back() == '\t' || trimmed.back() == '\r')) {
                trimmed.pop_back();
            }

            if (!in_multiline && (trimmed == "exit" || trimmed == "quit")) {
                cleanup_window();
                std::cout << color::GREEN << "Goodbye! Making the world Shine, together." << color::RESET << "\n";
                break;
            }

            if (!in_multiline && (trimmed == "clear" || trimmed == "cls")) {
                std::cout << "\033[2J\033[1;1H";
                continue;
            }

            if (!in_multiline && (trimmed == "window" || trimmed == "gui")) {
                std::cout << "\n" << color::BOLD << color::CYAN << "🖥️  Active Window Subsystem:" << color::RESET << "\n";
                std::cout << "  • Title        : " << color::GREEN << (win_title.empty() ? vm.current_window.title : win_title) << color::RESET << "\n";
                if (win_pid > 0) {
                    std::cout << "  • Process PID  : " << win_pid << "\n";
                }
                std::cout << "  • Target UI    : " << vm.current_window.target_ui << " (" << resolve_ui_profile(vm.current_window.target_ui).pipeline << ")\n";
                std::cout << "  • Cards        : " << vm.current_window.cards.size() << " registered\n";
                std::cout << "  • Buttons      : " << vm.current_window.buttons.size() << " registered\n";
                if (!vm.last_exported_native_script.empty()) {
                    std::cout << "  • Native Script: " << vm.last_exported_native_script << "\n";
                }
                std::cout << "\n";
                continue;
            }

            if (!in_multiline && (trimmed == "metal4" || trimmed == "metal" || trimmed == "gpu")) {
                std::cout << "\n" << color::BOLD << color::CYAN << "⚡ [METAL 4 GRAPHICS ACCELERATION SUBSYSTEM]" << color::RESET << "\n";
                std::cout << "  • Metal API    : Metal 4.0 (MSL 4.0 / Apple Silicon APU)\n";
                std::cout << "  • Hardware GPU : Apple M4 (Unified Memory Architecture)\n";
                std::cout << "  • Target FPS   : 240Hz ProMotion (<0.1ms render latency)\n";
                std::cout << "  • Features     : Hardware Raytracing, Mesh Shaders, MetalFX Temporal Scaler\n";
                std::cout << "  • Status       : " << color::GREEN << "ACTIVE & COMPATIBLE (Apple Silicon Host)" << color::RESET << "\n\n";
                continue;
            }

            if (!in_multiline && (trimmed == "vars" || trimmed == "variables")) {
                std::cout << "\n" << color::BOLD << color::CYAN << "📋 Active Memory Variables (" 
                          << vm.variables.size() << "):" << color::RESET << "\n";
                if (vm.variables.empty()) {
                    std::cout << "   (No variables defined yet. Try: let score = 100)\n\n";
                } else {
                    for (const auto& [k, v] : vm.variables) {
                        std::cout << "   " << color::YELLOW << k << color::RESET << " = " 
                                  << color::GREEN << v.to_repr() << color::RESET << "\n";
                    }
                    std::cout << "\n";
                }
                continue;
            }

            if (!in_multiline && (trimmed == "funcs" || trimmed == "functions")) {
                std::cout << "\n" << color::BOLD << color::CYAN << "⚡ Registered User Functions (" 
                          << vm.functions.size() << "):" << color::RESET << "\n";
                if (vm.functions.empty()) {
                    std::cout << "   (No functions defined yet. Try: fn square(x) => x * x)\n\n";
                } else {
                    for (const auto& [fname, fn_ptr] : vm.functions) {
                        std::cout << "   " << color::BLUE << "fn " << color::BOLD << fname << color::RESET << "(";
                        for (size_t i = 0; i < fn_ptr->params.size(); ++i) {
                            if (i > 0) std::cout << ", ";
                            std::cout << fn_ptr->params[i];
                            if (i < fn_ptr->default_values.size() && fn_ptr->default_values[i]) {
                                std::cout << "=...";
                            }
                        }
                        std::cout << ")\n";
                    }
                    std::cout << "\n";
                }
                continue;
            }

            if (!in_multiline && trimmed == "reset") {
                vm.variables.clear();
                vm.functions.clear();
                vm.python_snippets.clear();
                vm.init_builtins();
                std::cout << color::GREEN << "✔ [VM RESET]" << color::RESET << " Memory variables and user functions cleared.\n\n";
                continue;
            }

            if (!in_multiline && (trimmed == "bench" || trimmed == "benchmark")) {
                auto t0 = std::chrono::high_resolution_clock::now();
                vm.execute_code("fn __repl_b(x) => (x * 7 + 3) % 101\nmut __b_acc = 0\nfor (__bi in 1..=1000) { __b_acc += __repl_b(__bi) }");
                auto t1 = std::chrono::high_resolution_clock::now();
                double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
                std::cout << color::GREEN << "⚡ [REPL BENCH]" << color::RESET << " 1,000 calls + loop completed in "
                          << std::fixed << std::setprecision(3) << ms << " ms (acc=" << vm.variables["__b_acc"].as_int() << ")\n\n";
                vm.variables.erase("__b_acc");
                vm.variables.erase("__bi");
                vm.functions.erase("__repl_b");
                continue;
            }

            if (!in_multiline && (trimmed == "help" || trimmed == "?")) {
                print_help();
                continue;
            }

            // Check if entering a multi-line block
            if (!in_multiline) {
                bool starts_block = (
                    trimmed.rfind("python {", 0) == 0 || trimmed.rfind("py! {", 0) == 0 || 
                    trimmed.rfind("py {", 0) == 0 || trimmed == "python:" || trimmed == "py:" || 
                    ((trimmed.rfind("fn ", 0) == 0 || trimmed.rfind("fun ", 0) == 0 || trimmed.rfind("function ", 0) == 0) && trimmed.find("=>") == std::string::npos) ||
                    trimmed.rfind("repeat ", 0) == 0 || trimmed.rfind("loop ", 0) == 0 || trimmed.rfind("loop(", 0) == 0 ||
                    trimmed.rfind("for ", 0) == 0 || trimmed.rfind("while ", 0) == 0 ||
                    trimmed.rfind("match ", 0) == 0 || trimmed.rfind("match(", 0) == 0 ||
                    trimmed == "try {" || trimmed == "try:" || trimmed == "try" ||
                    trimmed.rfind("compile program ", 0) == 0 || trimmed.rfind("insert ", 0) == 0 ||
                    (trimmed.back() == '{' && trimmed.size() > 1)
                );
                if (starts_block) {
                    in_multiline = true;
                    brace_depth = 0;
                    for (char c : trimmed) {
                        if (c == '{') brace_depth++;
                        else if (c == '}') brace_depth--;
                    }
                    if (brace_depth == 0 && (trimmed.back() == ':' || trimmed == "try")) brace_depth = 1;
                    multiline_buffer.push_back(line);
                    continue;
                }
            } else {
                multiline_buffer.push_back(line);
                for (char c : trimmed) {
                    if (c == '{') brace_depth++;
                    else if (c == '}') brace_depth--;
                }
                bool is_try_waiting_catch = (trimmed == "} catch" || trimmed.rfind("} catch", 0) == 0 || trimmed.rfind("catch", 0) == 0);
                if (!is_try_waiting_catch && (brace_depth <= 0 || trimmed == "end" || trimmed == "py:end")) {
                    in_multiline = false;
                    brace_depth = 0;
                    std::string full_block = "";
                    for (const auto& l : multiline_buffer) full_block += l + "\n";
                    multiline_buffer.clear();
                    vm.execute_code(full_block);
                    continue;
                }
                continue;
            }

            // Single line execution
            if (trimmed.empty()) continue;

            // If expression without statement prefix, evaluate and print return value
            bool is_stmt = (
                trimmed.rfind("let ", 0) == 0 || trimmed.rfind("mut ", 0) == 0 ||
                trimmed.rfind("val ", 0) == 0 || trimmed.rfind("var ", 0) == 0 ||
                trimmed.find(":=") != std::string::npos ||
                trimmed.rfind("print ", 0) == 0 || trimmed.rfind("print(", 0) == 0 ||
                trimmed.rfind("out ", 0) == 0 || trimmed.rfind("out(", 0) == 0 ||
                trimmed.rfind("set ", 0) == 0 || trimmed.rfind("import ", 0) == 0 ||
                trimmed.rfind("use ", 0) == 0 || trimmed.rfind("call ", 0) == 0 ||
                trimmed.rfind("ui.", 0) == 0 || trimmed.rfind("@ui", 0) == 0 ||
                trimmed.rfind("spawn.", 0) == 0 || trimmed.rfind("@spawn", 0) == 0 ||
                trimmed.rfind("spawn3d.", 0) == 0 || trimmed.rfind("scene3d.world(", 0) == 0 ||
                trimmed.rfind("camera3d.set(", 0) == 0 || trimmed.rfind("light3d.", 0) == 0 ||
                trimmed.rfind("physics3d.config(", 0) == 0 || trimmed.rfind("game.mode(", 0) == 0 ||
                trimmed.rfind("audio.", 0) == 0 || trimmed.rfind("@audio", 0) == 0 ||
                trimmed.rfind("fx.", 0) == 0 || trimmed.rfind("@fx", 0) == 0 ||
                trimmed == "!exec" || trimmed.rfind("!exec ", 0) == 0 || trimmed.rfind("!exec\t", 0) == 0 ||
                trimmed.rfind("return", 0) == 0 || trimmed == "break"
            );

            if (!is_stmt && trimmed.find('=') == std::string::npos) {
                Parser p(trimmed);
                auto expr = p.parse_single_expr(trimmed);
                Value val = vm.eval(expr);
                if (val.type != ValueType::Nil) {
                    std::cout << color::CYAN << "=> " << color::GREEN << val.as_string() << color::RESET << "\n";
                    continue;
                }
            }

            vm.execute_code(trimmed);
            vm.has_thrown = false;
        }
    }

    static void print_help() {
        std::cout << "\n" << color::BOLD << color::PURPLE << "═══════════════════════════════════════════════════════════════" << color::RESET << "\n";
        std::cout << color::BOLD << "📖 Looping Language Quick Syntax Reference (v1.1 / Arch 3.0A)" << color::RESET << "\n";
        std::cout << color::CYAN << "   Channels: Looping (Prod) • Omega Looping (RC) • Alpha! Looping (Super Experimental)" << color::RESET << "\n";
        std::cout << color::BOLD << color::PURPLE << "═══════════════════════════════════════════════════════════════" << color::RESET << "\n";
        std::cout << "  " << color::CYAN << "let x = 10 / mut hp = 100" << color::RESET << "  Declarations (also: val max = 50, count := 0)\n";
        std::cout << "  " << color::CYAN << "let [a, b] = [10, 20]" << color::RESET << "       Destructuring lists & 2D tuples\n";
        std::cout << "  " << color::CYAN << "hp += 15, hp %= 4, count++" << color::RESET << "  Shorthand math, modulo & increment operators\n";
        std::cout << "  " << color::CYAN << "out(...) / print(...)" << color::RESET << "          Output with string interpolation \"{var}\" or $\"...\"\n";
        std::cout << "  " << color::CYAN << "fn name(a, b = 10) => a + b" << color::RESET << "  Functions with default args (arrow or { ... })\n";
        std::cout << "  " << color::CYAN << "for (i in 1..=10 step 2)" << color::RESET << "      Inclusive/exclusive ranges & collection iteration\n";
        std::cout << "  " << color::CYAN << "match x { 90..=100 => ... }" << color::RESET << "   Pattern matching (multi-pattern '|' & ranges)\n";
        std::cout << "  " << color::CYAN << "try { ... } catch (err)" << color::RESET << "       Structured exception handling & throw / assert\n";
        std::cout << "  " << color::CYAN << "expr |> func / s.upper()" << color::RESET << "      Pipeline operator & method-style variable calls\n";
        std::cout << "  " << color::CYAN << "csid.*, csms.*, game.*" << color::RESET << "        Integrated CS ID (PKCE), CSMS E2EE, Game Plus 2D/3D\n";
        std::cout << "  " << color::CYAN << "math3d.*, physics3d.*, spawn3d.*" << color::RESET << " 3D Quaternions, Mat4, Raycast, 120Hz Physics & Z-Buffer\n";
        std::cout << "  " << color::CYAN << "utils.*, sound.*, ai.*" << color::RESET << "        Core Utils, Synthesizer tones, AI inference, Math\n";
        std::cout << "  " << color::CYAN << "ui.card(...) / window.*" << color::RESET << "       Glassmorphism UI & native OS desktop windows\n";
        std::cout << "\n  " << color::YELLOW << "Special REPL Commands:" << color::RESET << " vars, funcs, bench, reset, clear, help, exit\n";
        std::cout << color::BOLD << color::PURPLE << "═══════════════════════════════════════════════════════════════" << color::RESET << "\n\n";
    }
};

} // namespace looping
