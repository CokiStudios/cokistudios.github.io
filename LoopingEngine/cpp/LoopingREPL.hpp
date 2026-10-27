#pragma once

#include "LoopingInterpreter.hpp"
#include <iostream>
#include <string>
#include <vector>

namespace looping {

class REPL {
public:
    static void run(Interpreter& vm) {
        vm.print_banner();
        std::cout << color::BOLD << color::CYAN << "✨ Welcome to Looping Interactive C++ Shell (v" << vm.app_version << ")" << color::RESET << "\n";
        std::cout << "Type 'help' for syntax guide, 'vars' for memory, 'funcs' for functions, 'bench' for speed test, 'reset' to clear state, 'exit' to quit.\n\n";

        std::string line;
        std::vector<std::string> multiline_buffer;
        bool in_multiline = false;
        int brace_depth = 0;

        while (true) {
            if (!in_multiline) {
                std::cout << color::BOLD << color::CYAN << "looping> " << color::RESET;
            } else {
                std::cout << color::PURPLE << "   ...> " << color::RESET;
            }

            if (!std::getline(std::cin, line)) {
                break;
            }

            // Trim
            size_t start = line.find_first_not_of(" \t\r\n");
            std::string trimmed = (start == std::string::npos) ? "" : line.substr(start);
            while (!trimmed.empty() && (trimmed.back() == ' ' || trimmed.back() == '\t' || trimmed.back() == '\r')) {
                trimmed.pop_back();
            }

            if (!in_multiline && (trimmed == "exit" || trimmed == "quit")) {
                std::cout << color::GREEN << "Goodbye! Making the world Shine, together." << color::RESET << "\n";
                break;
            }

            if (!in_multiline && (trimmed == "clear" || trimmed == "cls")) {
                std::cout << "\033[2J\033[1;1H";
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
                trimmed.rfind("audio.", 0) == 0 || trimmed.rfind("@audio", 0) == 0 ||
                trimmed.rfind("fx.", 0) == 0 || trimmed.rfind("@fx", 0) == 0 ||
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
        }
    }

    static void print_help() {
        std::cout << "\n" << color::BOLD << color::PURPLE << "═══════════════════════════════════════════════════════════════" << color::RESET << "\n";
        std::cout << color::BOLD << "📖 Looping Language Quick Syntax Reference (v1.0.0 Commercial / Arch 2.8A)" << color::RESET << "\n";
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
        std::cout << "  " << color::CYAN << "math.*, crypto.*, csv.*" << color::RESET << "       Vectors, stats, SHA-256, CRC32, CSMS E2EE, CSV, JSON\n";
        std::cout << "  " << color::CYAN << "ui.card(...) / window.*" << color::RESET << "       Glassmorphism UI & native OS desktop windows\n";
        std::cout << "\n  " << color::YELLOW << "Special REPL Commands:" << color::RESET << " vars, funcs, bench, reset, clear, help, exit\n";
        std::cout << color::BOLD << color::PURPLE << "═══════════════════════════════════════════════════════════════" << color::RESET << "\n\n";
    }
};

} // namespace looping
