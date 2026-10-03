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
        std::cout << color::BOLD << color::CYAN << "✨ Welcome to Looping Interactive C++ Shell" << color::RESET << "\n";
        std::cout << "Type 'help' for syntax guide, 'vars' to view memory, 'clear' to reset screen, 'exit' to quit.\n\n";

        std::string line;
        std::vector<std::string> multiline_buffer;
        bool in_multiline = false;

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

            if (trimmed == "exit" || trimmed == "quit") {
                std::cout << color::GREEN << "Goodbye! Making the world Shine, together." << color::RESET << "\n";
                break;
            }

            if (trimmed == "clear" || trimmed == "cls") {
                std::cout << "\033[2J\033[1;1H";
                continue;
            }

            if (trimmed == "vars" || trimmed == "variables") {
                std::cout << "\n" << color::BOLD << color::CYAN << "📋 Active Memory Variables (" 
                          << vm.variables.size() << "):" << color::RESET << "\n";
                if (vm.variables.empty()) {
                    std::cout << "   (No variables defined yet. Try: let score = 100)\n\n";
                } else {
                    for (const auto& [k, v] : vm.variables) {
                        std::cout << "   " << color::YELLOW << k << color::RESET << " = " 
                                  << color::GREEN << v.as_string() << color::RESET << "\n";
                    }
                    std::cout << "\n";
                }
                continue;
            }

            if (trimmed == "help" || trimmed == "?") {
                print_help();
                continue;
            }

            // Check if entering a multi-line block
            if (!in_multiline) {
                if (trimmed.rfind("python {", 0) == 0 || trimmed.rfind("py! {", 0) == 0 || 
                    trimmed.rfind("py {", 0) == 0 || trimmed == "python:" || trimmed == "py:" || 
                    trimmed.rfind("fn ", 0) == 0 || trimmed.rfind("fun ", 0) == 0 || 
                    trimmed.rfind("function ", 0) == 0 || trimmed.rfind("repeat ", 0) == 0 || 
                    trimmed.rfind("loop ", 0) == 0 || trimmed.rfind("loop(", 0) == 0 || 
                    trimmed.rfind("for ", 0) == 0 || trimmed.rfind("while ", 0) == 0 || 
                    (trimmed.back() == '{' && trimmed.size() > 1)) {
                    in_multiline = true;
                    multiline_buffer.push_back(line);
                    continue;
                }
            } else {
                multiline_buffer.push_back(line);
                if (trimmed == "}" || trimmed == "end" || trimmed == "py:end") {
                    in_multiline = false;
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
        std::cout << color::BOLD << "📖 Looping Language Quick Syntax Reference (v2.5 Signature)" << color::RESET << "\n";
        std::cout << color::BOLD << color::PURPLE << "═══════════════════════════════════════════════════════════════" << color::RESET << "\n";
        std::cout << "  " << color::CYAN << "let x = 10 / mut hp = 100" << color::RESET << "  Declarations (also: val max = 50, count := 0)\n";
        std::cout << "  " << color::CYAN << "hp += 15, count++" << color::RESET << "           Shorthand math & increment operators\n";
        std::cout << "  " << color::CYAN << "out(...) / print(...)" << color::RESET << "          Output with string interpolation \"{var}\" or $\"...\"\n";
        std::cout << "  " << color::CYAN << "fn name(a, b) => a + b" << color::RESET << "        Function definition (arrow or block with { ... })\n";
        std::cout << "  " << color::CYAN << "loop (5) { ... }" << color::RESET << "               Count loop with {i} index variable\n";
        std::cout << "  " << color::CYAN << "for (i in 0..10) { ... }" << color::RESET << "        Range loop\n";
        std::cout << "  " << color::CYAN << "while (cond) { ... }" << color::RESET << "            Condition loop (with break / return)\n";
        std::cout << "  " << color::CYAN << "if (cond) { ... } else" << color::RESET << "        Conditional branching (or: if (cond) -> stmt)\n";
        std::cout << "  " << color::CYAN << "expr |> func" << color::RESET << "                    Pipeline operator (e.g. 16 |> math.sqrt |> out)\n";
        std::cout << "  " << color::CYAN << "py!(expr) / py! { ... }" << color::RESET << "         Python bridge inline macro & sync blocks\n";
        std::cout << "  " << color::CYAN << "ui.card(...) / ui.btn(...)" << color::RESET << "     Glassmorphism UI components (pos, size, title)\n";
        std::cout << "  " << color::CYAN << "spawn.sprite / platform" << color::RESET << "        Physics 2D entities (spawn.coin, spawn.bubbly)\n";
        std::cout << "  " << color::CYAN << "audio.tone(freq, ms)" << color::RESET << "           Synthesize audio tone frequency\n";
        std::cout << "  " << color::CYAN << "fx.particles(at, color)" << color::RESET << "        Particle physics burst\n";
        std::cout << "\n  " << color::YELLOW << "Special REPL Commands:" << color::RESET << " vars, clear, help, exit\n";
        std::cout << color::BOLD << color::PURPLE << "═══════════════════════════════════════════════════════════════" << color::RESET << "\n\n";
    }
};

} // namespace looping
