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
        std::cout << color::DIM << "Type 'help' for instructions, 'vars' to view memory, 'clear' to reset screen, 'exit' to quit." << color::RESET << "\n\n";

        std::string line;
        std::vector<std::string> multiline_buffer;
        bool in_multiline = false;

        while (true) {
            if (!in_multiline) {
                std::cout << color::BOLD << color::CYAN << "looping> " << color::RESET;
            } else {
                std::cout << color::DIM << "   ...> " << color::RESET;
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
                    std::cout << color::DIM << "   (No variables defined yet. Try: set score to 100)" << color::RESET << "\n\n";
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
                if (trimmed.rfind("python {", 0) == 0 || trimmed == "python:" || trimmed == "py:" || 
                    trimmed.rfind("function ", 0) == 0 || trimmed.rfind("repeat ", 0) == 0 || 
                    trimmed.rfind("while ", 0) == 0 || (trimmed.back() == '{' && trimmed.size() > 1)) {
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

            // If expression without print or set, evaluate and print return value
            if (trimmed.rfind("print ", 0) != 0 && trimmed.rfind("set ", 0) != 0 && 
                trimmed.find('=') == std::string::npos && trimmed.rfind("import ", 0) != 0 &&
                trimmed.rfind("use ", 0) != 0 && trimmed.rfind("call ", 0) != 0) {
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
        std::cout << color::BOLD << "📖 Looping Language Quick Syntax Reference" << color::RESET << "\n";
        std::cout << color::BOLD << color::PURPLE << "═══════════════════════════════════════════════════════════════" << color::RESET << "\n";
        std::cout << "  " << color::CYAN << "set <var> to <val>" << color::RESET << "       Assign variable (or: set x = 10, x += 5)\n";
        std::cout << "  " << color::CYAN << "print <expr>, ..." << color::RESET << "          Print values with string interpolation \"{var}\"\n";
        std::cout << "  " << color::CYAN << "if <cond> do <stmt>" << color::RESET << "        One-line conditional\n";
        std::cout << "  " << color::CYAN << "repeat <N> times { ... }" << color::RESET << "   Repeat loop with {i} index variable\n";
        std::cout << "  " << color::CYAN << "function <name>(...) { }" << color::RESET << "   Define reusable function\n";
        std::cout << "  " << color::CYAN << "call <name>(...)" << color::RESET << "            Invoke function\n";
        std::cout << "  " << color::CYAN << "py: <expr>" << color::RESET << "                  Inline Python evaluation (e.g. py: math.sqrt(25))\n";
        std::cout << "  " << color::CYAN << "python { ... }" << color::RESET << "              Multi-line Python block with looping_set()\n";
        std::cout << "  " << color::CYAN << "spawn sprite / platform" << color::RESET << "     Create 2D Game Entity with 60FPS physics\n";
        std::cout << "  " << color::CYAN << "draw card / button / input" << color::RESET << "  Render Frosted Glassmorphism UI\n";
        std::cout << "  " << color::CYAN << "play tone at X Hz for Y ms" << color::RESET << "  Synthesize audio frequency\n";
        std::cout << "\n  " << color::YELLOW << "Special REPL Commands:" << color::RESET << " vars, clear, help, exit\n";
        std::cout << color::BOLD << color::PURPLE << "═══════════════════════════════════════════════════════════════" << color::RESET << "\n\n";
    }
};

} // namespace looping
